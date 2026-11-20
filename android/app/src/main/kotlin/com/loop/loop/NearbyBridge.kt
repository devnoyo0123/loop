package com.loop.loop

import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import com.google.android.gms.tasks.Task
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.util.concurrent.Executor

/// 사슬 공유 — Google Nearby Connections ↔ Dart 번역층. (docs/share-design.md §6.6)
///
/// 원칙: **판단하지 않고 옮기기만 한다.** 수락 여부·시간 초과·재시도·완료
/// 판정·파일 삭제는 전부 Dart(`NativeNearbyTransport`, `ShareSendController`)가
/// 한다. 여기는 호출을 Nearby로, 콜백을 이벤트 맵으로 바꾼다.
///
/// 테스트: [client]는 인터페이스, [main]/[io]는 주입 — JVM 단위 테스트가 가짜
/// 클라이언트와 동기 실행기로 전체를 돌린다(NearbyBridgeTest). Nearby 콜백
/// 객체는 필드만 꺼내 원시값 핸들러(on*)로 넘기는 한 줄 어댑터다.
///
/// 이벤트는 항상 [main]에서 [emit]된다(EventChannel은 메인 스레드 전용).
class NearbyBridge(
    private val client: ConnectionsClient,
    private val emit: (Map<String, Any?>) -> Unit,
    private val main: Executor,
    private val io: Executor,
) {
    /// 받는 STREAM을 쓸 폴더 — startAdvertising 때 Dart가 정한다.
    private var incomingDir: File? = null

    // ── 메서드 채널 ─────────────────────────────────────────────

    /// Dart 호출 처리. [reply]는 성공 값, [fail]은 잘못된 호출.
    fun handle(method: String, args: Map<String, Any?>, reply: (Any?) -> Unit, fail: (String) -> Unit) {
        when (method) {
            "startDiscovery" -> done(
                client.startDiscovery(
                    args.str("serviceId"),
                    discovery,
                    DiscoveryOptions.Builder().setStrategy(Strategy.P2P_STAR).build(),
                ),
                reply,
            )
            "stopDiscovery" -> { client.stopDiscovery(); reply(null) }
            "startAdvertising" -> {
                incomingDir = File(args.str("incomingDir"))
                done(
                    client.startAdvertising(
                        args.str("name"),
                        args.str("serviceId"),
                        lifecycle("ad"),
                        AdvertisingOptions.Builder().setStrategy(Strategy.P2P_STAR).build(),
                    ),
                    reply,
                )
            }
            "stopAdvertising" -> { client.stopAdvertising(); reply(null) }
            "requestConnection" -> done(
                client.requestConnection(args.str("name"), args.str("endpointId"), lifecycle("dis")),
                reply,
            )
            "acceptConnection" -> done(client.acceptConnection(args.str("endpointId"), payloads), reply)
            "disconnect" -> { client.disconnectFromEndpoint(args.str("endpointId")); reply(null) }
            "sendBytes" -> send(args.str("endpointId"), Payload.fromBytes(args["bytes"] as ByteArray), reply)
            "sendStream" -> {
                val file = File(args.str("path"))
                if (!file.isFile) return reply(null)
                send(args.str("endpointId"), Payload.fromStream(FileInputStream(file)), reply)
            }
            "cancelPayload" -> done(client.cancelPayload((args["payloadId"] as Number).toLong()), reply)
            else -> fail("unknown method $method")
        }
    }

    /// Task 결과를 true/false로 — 실패 사유(ALREADY_* 등)는 Dart가 상태로 판단.
    private fun done(task: Task<Void>, reply: (Any?) -> Unit) {
        task.addOnSuccessListener(main) { reply(true) }
            .addOnFailureListener(main) { reply(false) }
    }

    /// 보낸 페이로드 id(진행 이벤트와 맞추는 열쇠), 실패면 null.
    /// (-1 같은 표식은 못 쓴다 — 페이로드 id는 음수일 수도 있는 임의 64비트 값.)
    private fun send(endpointId: String, payload: Payload, reply: (Any?) -> Unit) {
        client.sendPayload(endpointId, payload)
            .addOnSuccessListener(main) { reply(payload.id) }
            .addOnFailureListener(main) { reply(null) }
    }

    // ── 원시값 핸들러 (테스트가 직접 부른다) ───────────────────

    fun onFound(id: String, name: String) = emit(mapOf("e" to "found", "id" to id, "name" to name))

    fun onLost(id: String) = emit(mapOf("e" to "lost", "id" to id))

    fun onInitiated(role: String, id: String, name: String) =
        emit(mapOf("e" to "initiated", "role" to role, "id" to id, "name" to name))

    fun onResult(role: String, id: String, statusCode: Int) =
        emit(mapOf("e" to "result", "role" to role, "id" to id, "ok" to (statusCode == STATUS_OK), "code" to statusCode))

    fun onDisconnected(role: String, id: String) =
        emit(mapOf("e" to "disconnected", "role" to role, "id" to id))

    fun onBytes(id: String, payloadId: Long, data: ByteArray) =
        emit(mapOf("e" to "bytes", "id" to id, "pid" to payloadId, "data" to data))

    /// 받는 STREAM — 앱 폴더의 `.part`로 바로 흘려 쓴다(파이프를 비워야 전송이
    /// 진행된다). 받기 대기 중이 아니면(폴더 없음) 읽지 않는다.
    fun onStream(id: String, payloadId: Long, input: InputStream) {
        val dir = incomingDir ?: return
        val dest = File(dir, "in-${safe(id)}-$payloadId.part")
        emit(mapOf("e" to "stream", "id" to id, "pid" to payloadId, "path" to dest.path))
        io.execute {
            val bytes = ShareStreamWriter.drain(input, dest)
            main.execute {
                emit(
                    mapOf(
                        "e" to "streamDone", "id" to id, "pid" to payloadId,
                        "path" to dest.path, "ok" to (bytes >= 0), "bytes" to bytes,
                    ),
                )
            }
        }
    }

    fun onUpdate(id: String, payloadId: Long, status: Int, bytes: Long, total: Long) =
        emit(
            mapOf(
                "e" to "update", "id" to id, "pid" to payloadId,
                "status" to statusName(status), "bytes" to bytes, "total" to total,
            ),
        )

    // ── Nearby 콜백 어댑터 (필드만 꺼낸다) ─────────────────────

    private val discovery = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) =
            onFound(endpointId, info.endpointName)

        override fun onEndpointLost(endpointId: String) = onLost(endpointId)
    }

    private fun lifecycle(role: String) = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) =
            onInitiated(role, endpointId, info.endpointName)

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) =
            onResult(role, endpointId, resolution.status.statusCode)

        override fun onDisconnected(endpointId: String) = onDisconnected(role, endpointId)
    }

    private val payloads = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            when (payload.type) {
                Payload.Type.BYTES -> payload.asBytes()?.let { onBytes(endpointId, payload.id, it) }
                Payload.Type.STREAM -> payload.asStream()?.asInputStream()?.let { onStream(endpointId, payload.id, it) }
                else -> Unit // FILE은 쓰지 않는다 — Downloads에 남기 때문(§6.6)
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) =
            onUpdate(endpointId, update.payloadId, update.status, update.bytesTransferred, update.totalBytes)
    }

    companion object {
        /// ConnectionsStatusCodes.STATUS_OK
        const val STATUS_OK = 0

        /// PayloadTransferUpdate.Status 값 → 이벤트 이름.
        fun statusName(status: Int) = when (status) {
            PayloadTransferUpdate.Status.SUCCESS -> "success"
            PayloadTransferUpdate.Status.FAILURE -> "failure"
            PayloadTransferUpdate.Status.CANCELED -> "canceled"
            else -> "progress"
        }

        /// 엔드포인트 id를 파일 이름에 안전하게.
        fun safe(id: String) = id.replace(Regex("[^A-Za-z0-9_-]"), "_")

        private fun Map<String, Any?>.str(key: String) = this[key] as String
    }
}
