package com.loop.loop

import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.lang.reflect.Proxy
import java.nio.file.Files
import java.util.concurrent.Executor

/// NearbyBridge — 가짜 ConnectionsClient(인터페이스 Proxy)와 주입 실행기로
/// 번역층 전체를 JVM에서 검증한다. 실제 전파(BLE·Wi-Fi Direct)만 실기기 몫.
class NearbyBridgeTest {
    /// 가짜 Nearby — 호출을 기록하고, Task는 성공(또는 [failNext]면 실패)으로.
    private class FakeClient {
        val calls = mutableListOf<Pair<String, List<Any?>>>()
        var failNext = false

        val client: ConnectionsClient = Proxy.newProxyInstance(
            ConnectionsClient::class.java.classLoader,
            arrayOf(ConnectionsClient::class.java),
        ) { _, method, args ->
            calls += method.name to (args?.toList() ?: emptyList())
            if (Task::class.java.isAssignableFrom(method.returnType)) {
                if (failNext) {
                    failNext = false
                    Tasks.forException<Void>(IOException("nearby says no"))
                } else {
                    Tasks.forResult<Void>(null)
                }
            } else {
                null
            }
        } as ConnectionsClient

        fun args(name: String) = calls.last { it.first == name }.second
        fun count(name: String) = calls.count { it.first == name }
    }

    /// 실행을 모아 두었다가 [run]으로 흘리는 실행기 — 스레드 전환 순서 검증.
    private class QueueExecutor : Executor {
        val queue = ArrayDeque<Runnable>()
        override fun execute(command: Runnable) {
            queue.addLast(command)
        }

        fun run() {
            while (queue.isNotEmpty()) queue.removeFirst().run()
        }
    }

    private val direct = Executor { it.run() }

    private lateinit var fake: FakeClient
    private lateinit var events: MutableList<Map<String, Any?>>
    private lateinit var tmp: File

    @Before
    fun setUp() {
        fake = FakeClient()
        events = mutableListOf()
        tmp = Files.createTempDirectory("nearby-bridge").toFile()
    }

    @After
    fun tearDown() {
        tmp.deleteRecursively()
    }

    private fun bridge(main: Executor = direct, io: Executor = direct) =
        NearbyBridge(fake.client, { events += it }, main, io)

    /// handle 호출 → (reply 값, fail 메시지)
    private fun call(b: NearbyBridge, method: String, args: Map<String, Any?> = emptyMap()): Pair<Any?, String?> {
        var reply: Any? = "<none>"
        var fail: String? = null
        b.handle(method, args, { reply = it }, { fail = it })
        return reply to fail
    }

    private fun advertising(b: NearbyBridge) {
        call(b, "startAdvertising", mapOf("name" to "민수", "serviceId" to "app.loop", "incomingDir" to tmp.path))
    }

    // ── 메서드 → Nearby 호출 ──────────────────────────────────

    @Test
    fun `탐색 시작 — serviceId와 P2P_STAR로, 성공이면 true`() {
        val (reply, _) = call(bridge(), "startDiscovery", mapOf("name" to "민수", "serviceId" to "app.loop"))
        assertEquals(true, reply)
        val a = fake.args("startDiscovery")
        assertEquals("app.loop", a[0])
        assertEquals(Strategy.P2P_STAR, (a[2] as DiscoveryOptions).strategy)
    }

    @Test
    fun `Nearby가 실패하면 false — 사유 판단은 Dart 몫`() {
        fake.failNext = true
        val (reply, _) = call(bridge(), "startDiscovery", mapOf("name" to "민수", "serviceId" to "app.loop"))
        assertEquals(false, reply)
    }

    @Test
    fun `광고 시작 — 이름·serviceId·P2P_STAR`() {
        val b = bridge()
        val (reply, _) = call(b, "startAdvertising", mapOf("name" to "민수", "serviceId" to "app.loop", "incomingDir" to tmp.path))
        assertEquals(true, reply)
        val a = fake.args("startAdvertising")
        assertEquals("민수", a[0])
        assertEquals("app.loop", a[1])
        assertEquals(Strategy.P2P_STAR, (a[3] as AdvertisingOptions).strategy)
    }

    @Test
    fun `연결 요청·수락·끊기·멈춤이 그대로 Nearby로 간다`() {
        val b = bridge()
        assertEquals(true, call(b, "requestConnection", mapOf("name" to "민수", "endpointId" to "E1")).first)
        assertEquals("E1", fake.args("requestConnection")[1])
        assertEquals(true, call(b, "acceptConnection", mapOf("endpointId" to "E1")).first)
        assertEquals("E1", fake.args("acceptConnection")[0])
        call(b, "disconnect", mapOf("endpointId" to "E1"))
        assertEquals("E1", fake.args("disconnectFromEndpoint")[0])
        call(b, "stopDiscovery")
        call(b, "stopAdvertising")
        assertEquals(1, fake.count("stopDiscovery"))
        assertEquals(1, fake.count("stopAdvertising"))
        assertEquals(0, fake.count("stopAllEndpoints")) // 광고까지 멈추는 전체 끊기는 안 쓴다
    }

    @Test
    fun `바이트 보내기 — BYTES 페이로드, 페이로드 id를 돌려준다`() {
        val (reply, _) = call(bridge(), "sendBytes", mapOf("endpointId" to "E1", "bytes" to byteArrayOf(1, 2, 3)))
        val p = fake.args("sendPayload")[1] as Payload
        assertEquals(Payload.Type.BYTES, p.type)
        assertArrayEquals(byteArrayOf(1, 2, 3), p.asBytes())
        assertEquals(p.id, reply)
    }

    @Test
    fun `파일 보내기 — FILE이 아니라 STREAM 페이로드로 (받는 쪽이 앱 폴더에 쓰게)`() {
        val f = File(tmp, "chain.looplog").apply { writeText("hello") }
        val (reply, _) = call(bridge(), "sendStream", mapOf("endpointId" to "E1", "path" to f.path))
        val p = fake.args("sendPayload")[1] as Payload
        assertEquals(Payload.Type.STREAM, p.type)
        assertEquals(p.id, reply)
    }

    @Test
    fun `없는 파일은 보내지 않고 null (id는 음수일 수 있어 -1을 표식으로 못 쓴다)`() {
        val (reply, _) = call(bridge(), "sendStream", mapOf("endpointId" to "E1", "path" to "${tmp.path}/none"))
        assertEquals(null, reply)
        assertEquals(0, fake.count("sendPayload"))
    }

    @Test
    fun `보내기 실패면 null`() {
        fake.failNext = true
        val (reply, _) = call(bridge(), "sendBytes", mapOf("endpointId" to "E1", "bytes" to byteArrayOf(1)))
        assertEquals(null, reply)
    }

    @Test
    fun `모르는 메서드는 fail`() {
        val (_, fail) = call(bridge(), "stopAllEndpoints")
        assertTrue(fail!!.contains("stopAllEndpoints"))
    }

    // ── 콜백 → 이벤트 ─────────────────────────────────────────

    @Test
    fun `발견·연결 이벤트 형식`() {
        val b = bridge()
        b.onFound("E1", "지민")
        b.onLost("E1")
        b.onInitiated("ad", "E2", "서연")
        b.onResult("ad", "E2", NearbyBridge.STATUS_OK)
        b.onResult("dis", "E3", 8004) // STATUS_CONNECTION_REJECTED
        b.onDisconnected("ad", "E2")
        assertEquals(mapOf("e" to "found", "id" to "E1", "name" to "지민"), events[0])
        assertEquals(mapOf("e" to "lost", "id" to "E1"), events[1])
        assertEquals(mapOf("e" to "initiated", "role" to "ad", "id" to "E2", "name" to "서연"), events[2])
        assertEquals(true, events[3]["ok"])
        assertEquals(false, events[4]["ok"])
        assertEquals(8004, events[4]["code"])
        assertEquals(mapOf("e" to "disconnected", "role" to "ad", "id" to "E2"), events[5])
    }

    @Test
    fun `진행 상태 이름 — Nearby 상수 그대로 매핑`() {
        val b = bridge()
        b.onUpdate("E1", 7, PayloadTransferUpdate.Status.IN_PROGRESS, 10, -1)
        b.onUpdate("E1", 7, PayloadTransferUpdate.Status.SUCCESS, 100, -1)
        b.onUpdate("E1", 7, PayloadTransferUpdate.Status.FAILURE, 0, 0)
        b.onUpdate("E1", 7, PayloadTransferUpdate.Status.CANCELED, 0, 0)
        assertEquals(listOf("progress", "success", "failure", "canceled"), events.map { it["status"] })
        assertEquals(-1L, events[0]["total"]) // STREAM은 전체 크기를 모른다 — Dart가 헤더로 안다
    }

    @Test
    fun `받은 바이트는 그대로 넘긴다 (크기 헤더 등)`() {
        bridge().onBytes("E1", 5, byteArrayOf(9, 8))
        assertEquals("bytes", events[0]["e"])
        assertArrayEquals(byteArrayOf(9, 8), events[0]["data"] as ByteArray)
    }

    // ── STREAM 수신 → 앱 폴더 ─────────────────────────────────

    @Test
    fun `받는 STREAM은 받기 폴더의 part 파일로 쓰고, 끝나면 streamDone`() {
        val b = bridge()
        advertising(b)
        b.onStream("E:1", 42, ByteArrayInputStream("payload".toByteArray()))

        val start = events.single { it["e"] == "stream" }
        val path = start["path"] as String
        assertTrue(path.startsWith(tmp.path))
        assertTrue(path.endsWith("in-E_1-42.part")) // id는 파일 이름에 안전하게
        val done = events.single { it["e"] == "streamDone" }
        assertEquals(true, done["ok"])
        assertEquals(7L, done["bytes"])
        assertEquals("payload", File(path).readText())
    }

    @Test
    fun `쓰기는 io에서, 완료 이벤트는 main에서 — 순서 보장`() {
        val main = QueueExecutor()
        val io = QueueExecutor()
        val b = bridge(main = main, io = io)
        advertising(b)
        main.run() // startAdvertising 결과 정리
        events.clear()

        b.onStream("E1", 1, ByteArrayInputStream(ByteArray(10)))
        assertEquals(listOf("stream"), events.map { it["e"] }) // 시작 알림은 즉시(메인 콜백 위)
        main.run()
        assertEquals(1, events.size) // io가 안 돌았으면 완료도 없다
        io.run()
        assertEquals(1, events.size) // io가 끝나도 main에 올려야 알린다
        main.run()
        assertEquals("streamDone", events.last()["e"])
    }

    @Test
    fun `읽다 끊기면 ok=false — 파일 삭제는 Dart가 정한다`() {
        val b = bridge()
        advertising(b)
        val broken = object : InputStream() {
            var n = 0
            override fun read(): Int = if (n++ < 3) 1 else throw IOException("pipe closed")
        }
        b.onStream("E1", 1, broken)
        val done = events.single { it["e"] == "streamDone" }
        assertEquals(false, done["ok"])
        assertTrue(File(done["path"] as String).exists()) // 남겨 둔다 — Dart가 지움
    }

    @Test
    fun `받기 대기 전에 온 STREAM은 읽지 않는다`() {
        var read = false
        val input = object : InputStream() {
            override fun read(): Int {
                read = true
                return -1
            }
        }
        bridge().onStream("E1", 1, input)
        assertTrue(events.isEmpty())
        assertFalse(read)
    }

    @Test
    fun `safe — 파일 이름에 못 쓰는 문자 치환`() {
        assertEquals("a_b-C_9", NearbyBridge.safe("a/b-C:9"))
    }

    @Test
    fun `statusName — 모르는 값은 progress`() {
        assertEquals("progress", NearbyBridge.statusName(999))
    }
}
