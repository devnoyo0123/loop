package com.loop.loop

import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

/// 사슬 공유 수신 — Nearby STREAM 페이로드를 앱 폴더의 파일로 흘려 쓴다.
/// Android 클래스에 의존하지 않는 순수 JVM 로직이라 단위 테스트 대상.
/// (docs/share-design.md §6.6)
///
/// 판단은 하지 않는다: 실패해도 파일을 지우지 않고 결과만 돌려준다 —
/// 지울지는 Dart(전송 계층)가 정한다.
object ShareStreamWriter {
    private const val BUFFER = 64 * 1024

    /// [input]을 끝까지 읽어 [dest]에 쓴다. 쓴 바이트 수, 읽기·쓰기가
    /// 실패하면 -1. Nearby 문서대로 파이프가 막히지 않게 쉬지 않고 읽는다.
    /// [onProgress]는 버퍼마다 누적 바이트로 불린다(호출 스레드 그대로).
    fun drain(input: InputStream, dest: File, onProgress: (Long) -> Unit = {}): Long {
        var total = 0L
        return try {
            dest.parentFile?.mkdirs()
            input.use { src ->
                FileOutputStream(dest).use { out ->
                    val buf = ByteArray(BUFFER)
                    while (true) {
                        val n = src.read(buf)
                        if (n < 0) break
                        if (n == 0) continue
                        out.write(buf, 0, n)
                        total += n
                        onProgress(total)
                    }
                    out.flush()
                    out.fd.sync()
                }
            }
            total
        } catch (e: IOException) {
            -1L
        }
    }
}
