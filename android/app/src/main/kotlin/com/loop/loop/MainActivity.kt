package com.loop.loop

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
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
    }

    // SAF 문서 생성은 액티비티 결과로 돌아오므로 대기 중인 콜백을 들고 있다.
    private var exportResult: MethodChannel.Result? = null
    private var importResult: MethodChannel.Result? = null
    private val exportSinks = HashMap<Int, Pair<OutputStream, Uri>>()
    private val importSources = HashMap<Int, InputStream>()
    private var nextHandle = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
