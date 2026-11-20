package com.loop.loop

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.io.OutputStream

/// Dart와 통신하는 두 채널:
///  - app.loop/browser : 설치된 브라우저 조회 + 지정 브라우저로 열기
///  - app.loop/export  : SAF "다른 이름으로 저장" → 스트리밍 기록 (.looplog)
///    + SAF "열기" → 청크 단위 읽기 (가져오기)
class MainActivity : FlutterActivity() {
    companion object {
        private const val REQUEST_EXPORT = 3001
        private const val REQUEST_IMPORT = 3002

        /// 알람 화면 [확인]로 열린 대상 로그 — Dart가 소비하면 null로 치워진다.
        @Volatile
        var pendingAlarmOpen: String? = null
    }

    // SAF 문서 생성은 액티비티 결과로 돌아오므로 대기 중인 콜백을 들고 있다.
    private var exportResult: MethodChannel.Result? = null
    private var importResult: MethodChannel.Result? = null
    private val exportSinks = HashMap<Int, Pair<OutputStream, Uri>>()
    private val importSources = HashMap<Int, InputStream>()
    private var nextHandle = 1

    /// 사슬 공유 Nearby 번역층 — 이벤트 싱크는 Dart가 구독할 때만 있다.
    private var nearbyEvents: EventChannel.EventSink? = null
    private var nearbyBridge: NearbyBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            LoopNativeAdFactory.factoryId,
            LoopNativeAdFactory(this),
        )
        // 사슬 공유 — Nearby Connections 직접 연동(STREAM 수신을 앱 폴더로).
        // 판단은 Dart가, 여기선 채널만 잇는다. docs/share-design.md §6.6
        val main = androidx.core.content.ContextCompat.getMainExecutor(this)
        val bridge = NearbyBridge(
            client = com.google.android.gms.nearby.Nearby.getConnectionsClient(this),
            emit = { event -> nearbyEvents?.success(event) },
            main = main,
            io = java.util.concurrent.Executors.newCachedThreadPool(),
        )
        nearbyBridge = bridge
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.loop/nearby")
            .setMethodCallHandler { call, result ->
                @Suppress("UNCHECKED_CAST")
                val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                try {
                    bridge.handle(
                        call.method,
                        args,
                        reply = { result.success(it) },
                        fail = { result.notImplemented() },
                    )
                } catch (e: Exception) {
                    result.error("nearby", e.message, null)
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "app.loop/nearby/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    nearbyEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    nearbyEvents = null
                }
            })
        // PC 연결 세션 유지(ADR-003) — 시작·정지는 Dart가, 알림 [연결 끊기]·
        // onTimeout은 서비스가 "ended"로 Dart에 알린다.
        val pcLinkChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.loop/pclink")
        PcLinkService.onEnded = { reason ->
            pcLinkChannel.invokeMethod("ended", mapOf("reason" to reason))
        }
        pcLinkChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(PcLinkService.start(this))
                "stop" -> {
                    PcLinkService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // 알람 화면 [확인]로 시작했다면 대상 로그를 기억해둔다 — Dart가 소비.
        pendingAlarmOpen = intent?.getStringExtra(NativeAlarms.EXTRA_LOG_ID)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.loop/browser")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBrowsers" -> {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
                        val infos = packageManager.queryIntentActivities(
                            intent, PackageManager.MATCH_ALL
                        )
                        val seen = HashSet<String>()
                        val browsers = ArrayList<Map<String, String>>()
                        for (info in infos) {
                            val pkg = info.activityInfo.packageName
                            if (pkg == packageName || !seen.add(pkg)) continue
                            val label = info.loadLabel(packageManager)?.toString() ?: pkg
                            browsers.add(mapOf("package" to pkg, "label" to label))
                        }
                        // 시스템 기본 브라우저 (설정 UI에서 표시용)
                        val def = packageManager.resolveActivity(
                            intent, PackageManager.MATCH_DEFAULT_ONLY
                        )?.activityInfo?.packageName
                        result.success(mapOf("browsers" to browsers, "default" to def))
                    }
                    "open" -> {
                        val url = call.argument<String>("url")!!
                        val target = call.argument<String>("package")
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        if (target != null) intent.setPackage(target)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    // 사슬 공유 — API 레벨(요청할 권한 조합이 다르다)과 기본 표시명.
                    // name: 사용자가 정한 기기 이름("민수의 Galaxy S25"), 없으면 null.
                    "deviceInfo" -> {
                        val name = try {
                            Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
                        } catch (e: Exception) {
                            null
                        }
                        result.success(
                            mapOf(
                                "sdkInt" to android.os.Build.VERSION.SDK_INT,
                                "model" to android.os.Build.MODEL,
                                "name" to name,
                            )
                        )
                    }
                    // 전체화면 알람("알람 및 리마인더") 특별권한 — Android 14+ 기본 거부.
                    // 시스템 팝업이 없어서 앱이 전용 설정 페이지로 직접 데려간다.
                    "fullScreenAllowed" -> {
                        val nm = getSystemService(NOTIFICATION_SERVICE)
                            as android.app.NotificationManager
                        result.success(nm.canUseFullScreenIntent())
                    }
                    // 동영상 재생 — FileProvider content URI로 시스템
                    // 플레이어에 위임한다. (v1: 내장 플레이어 없음)
                    // 동영상 대표 프레임 — 첫 프레임을 JPEG(너비 640)로.
                    // video_thumbnail 패키지의 Gradle 호환 문제를 우회하기
                    // 위해 네이티브에서 직접 추출한다. (v10.2)
                    "videoThumb" -> {
                        val path = call.argument<String>("path")!!
                        try {
                            val retriever = android.media.MediaMetadataRetriever()
                            retriever.setDataSource(path)
                            val frame = retriever.getFrameAtTime(
                                0,
                                android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                            )
                            val width = 640
                            val scaled = frame?.let {
                                val ratio = it.height.toFloat() / it.width
                                android.graphics.Bitmap.createScaledBitmap(
                                    it, width, (width * ratio).toInt().coerceAtLeast(1), true
                                )
                            }
                            val out = java.io.ByteArrayOutputStream()
                            scaled?.compress(
                                android.graphics.Bitmap.CompressFormat.JPEG, 75, out
                            )
                            scaled?.recycle()
                            retriever.release()
                            result.success(out.toByteArray())
                        } catch (_: Exception) {
                            result.success(null)
                        }
                    }
                    "openVideo" -> {
                        val path = call.argument<String>("path")!!
                        try {
                            val file = java.io.File(path)
                            android.util.Log.d(
                                "LoopVideo",
                                "openVideo path=$path exists=${file.exists()} size=${file.length()}"
                            )
                            val uri = androidx.core.content.FileProvider
                                .getUriForFile(
                                    this,
                                    "$packageName.fileprovider",
                                    file
                                )
                            android.util.Log.d("LoopVideo", "uri=$uri")
                            val intent = Intent(Intent.ACTION_VIEW)
                                .setDataAndType(uri, "video/*")
                                .addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                                        or Intent.FLAG_ACTIVITY_NEW_TASK
                                )
                            startActivity(intent)
                            android.util.Log.d("LoopVideo", "startActivity ok")
                            result.success(true)
                        } catch (e: Throwable) {
                            android.util.Log.e("LoopVideo", "openVideo failed", e)
                            result.success(false)
                        }
                    }
                    "openFullScreenSettings" -> {
                        try {
                            startActivity(
                                Intent(
                                    android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:$packageName")
                                )
                            )
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                startActivity(
                                    Intent(
                                        android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                        Uri.parse("package:$packageName")
                                    )
                                )
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    // ── 알람형 루프: setAlarmClock 네이티브 예약(전체화면 발화).
                    "scheduleNativeAlarm" -> {
                        try {
                            NativeAlarms.schedule(
                                this,
                                call.argument<String>("logId")!!,
                                // epoch ms는 int64로만 건너온다 — Int로 읽으면
                                // ClassCastException으로 예약이 항상 실패한다.
                                call.argument<Long>("atMs")!!,
                                call.argument<String>("content") ?: "",
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("scheduleNativeAlarm", e.message, null)
                        }
                    }
                    // 다른 앱 위에 알람 UI를 띄우는 특별 권한 — 알람 예약 전 확인.
                    "canDrawOverlays" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestDrawOverlays" -> {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName"),
                                )
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "cancelNativeAlarm" -> {
                        try {
                            NativeAlarms.cancel(this, call.argument<String>("logId")!!)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("cancelNativeAlarm", e.message, null)
                        }
                    }
                    // 스누즈 기록 — Dart가 다음 실행 때 DB(loop_at)에 반영.
                    "consumePendingSnoozes" -> {
                        result.success(NativeAlarms.consumeSnoozes(this))
                    }
                    // 알람 [확인]로 열린 대상 로그 — 꺼내면 치워진다.
                    "consumeAlarmOpen" -> {
                        val id = pendingAlarmOpen
                        pendingAlarmOpen = null
                        result.success(id)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.loop/export")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 저장 위치 다이얼로그를 띄우고, 결과(content:// Uri)를 돌려준다.
                    // 취소하면 null.
                    "create" -> {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = call.argument<String>("mime") ?: "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
                        }
                        try {
                            exportResult = result
                            startActivityForResult(intent, REQUEST_EXPORT)
                        } catch (_: Exception) {
                            exportResult = null
                            result.success(null)
                        }
                    }
                    // 스트림 열기 — 큰 파일도 청크로 나눠 쓰기 위해 핸들을 유지한다.
                    "open" -> {
                        try {
                            val uri = Uri.parse(call.argument<String>("uri")!!)
                            val os = contentResolver.openOutputStream(uri)
                                ?: throw IllegalStateException("openOutputStream returned null")
                            val handle = nextHandle++
                            exportSinks[handle] = Pair(os, uri)
                            result.success(handle)
                        } catch (e: Exception) {
                            result.error("open", e.message, null)
                        }
                    }
                    "write" -> {
                        try {
                            val sink = exportSinks[call.argument<Int>("handle")!!]
                                ?: throw IllegalStateException("no such handle")
                            sink.first.write(call.argument<String>("text")!!.toByteArray(Charsets.UTF_8))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("write", e.message, null)
                        }
                    }
                    // 정상 종료
                    "close" -> {
                        try {
                            exportSinks.remove(call.argument<Int>("handle")!!)?.first?.let {
                                it.flush(); it.close()
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("close", e.message, null)
                        }
                    }
                    // 실패 시 — 부분 파일을 닫고 지운다.
                    "abort" -> {
                        val sink = exportSinks.remove(call.argument<Int>("handle")!!)
                        try {
                            sink?.first?.close()
                            if (sink != null) {
                                try {
                                    android.provider.DocumentsContract.deleteDocument(
                                        contentResolver, sink.second
                                    )
                                } catch (_: Exception) {
                                    // 지울 수 없는 제공자(드라이브 등)도 있다 — 조용히 무시
                                }
                            }
                        } catch (_: Exception) {}
                        result.success(null)
                    }
                    // ── 가져오기: SAF "열기" 다이얼로그 → content:// Uri. 취소하면 null.
                    "pick" -> {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        try {
                            importResult = result
                            startActivityForResult(intent, REQUEST_IMPORT)
                        } catch (_: Exception) {
                            importResult = null
                            result.success(null)
                        }
                    }
                    // 스트림 열기 — 큰 파일도 청크로 나눠 읽기 위해 핸들을 유지한다.
                    "openRead" -> {
                        try {
                            val uri = Uri.parse(call.argument<String>("uri")!!)
                            val ins = contentResolver.openInputStream(uri)
                                ?: throw IllegalStateException("openInputStream returned null")
                            val handle = nextHandle++
                            importSources[handle] = ins
                            result.success(handle)
                        } catch (e: Exception) {
                            result.error("openRead", e.message, null)
                        }
                    }
                    // 최대 512KB 청크를 반환. 파일 끝이면 null.
                    "readChunk" -> {
                        try {
                            val ins = importSources[call.argument<Int>("handle")!!]
                                ?: throw IllegalStateException("no such handle")
                            val buf = ByteArray(512 * 1024)
                            val n = ins.read(buf)
                            result.success(if (n > 0) buf.copyOf(n) else null)
                        } catch (e: Exception) {
                            result.error("readChunk", e.message, null)
                        }
                    }
                    // 정상 종료
                    "closeRead" -> {
                        try {
                            importSources.remove(call.argument<Int>("handle")!!)?.close()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("closeRead", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// 엔진이 정리되면 Dart도 정리된다.
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Dart(링크)가 사라지면 붙들 세션도 없다 — 최근 앱에서 밀어 닫은 경우 등.
        PcLinkService.onEnded = null
        PcLinkService.stop(this)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 앱이 살아 있는 상태에서 알람 [확인]로 다시 불려온 경우.
        intent.getStringExtra(NativeAlarms.EXTRA_LOG_ID)?.let {
            pendingAlarmOpen = it
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_EXPORT) {
            val pending = exportResult
            exportResult = null
            pending?.success(data?.data?.toString())
        } else if (requestCode == REQUEST_IMPORT) {
            val pending = importResult
            importResult = null
            pending?.success(data?.data?.toString())
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
