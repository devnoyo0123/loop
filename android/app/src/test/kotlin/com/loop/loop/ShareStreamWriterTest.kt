package com.loop.loop

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.nio.file.Files

class ShareStreamWriterTest {
    private lateinit var tmp: File

    @Before
    fun setUp() {
        tmp = Files.createTempDirectory("stream-writer").toFile()
    }

    @After
    fun tearDown() {
        tmp.deleteRecursively()
    }

    @Test
    fun `끝까지 읽어 쓰고 바이트 수를 돌려준다 — 버퍼보다 큰 입력`() {
        val data = ByteArray(200_000) { (it % 251).toByte() }
        val dest = File(tmp, "a.part")
        val progress = mutableListOf<Long>()
        val n = ShareStreamWriter.drain(ByteArrayInputStream(data), dest) { progress += it }
        assertEquals(data.size.toLong(), n)
        assertTrue(dest.readBytes().contentEquals(data))
        assertEquals(data.size.toLong(), progress.last())
        assertEquals(progress.sorted(), progress) // 누적은 단조 증가
    }

    @Test
    fun `빈 입력은 0바이트 파일`() {
        val dest = File(tmp, "empty.part")
        assertEquals(0L, ShareStreamWriter.drain(ByteArrayInputStream(ByteArray(0)), dest))
        assertTrue(dest.exists())
    }

    @Test
    fun `없는 폴더는 만든다`() {
        val dest = File(tmp, "share/in/x.part")
        assertEquals(3L, ShareStreamWriter.drain(ByteArrayInputStream(byteArrayOf(1, 2, 3)), dest))
    }

    @Test
    fun `읽다 실패하면 -1, 쓴 만큼은 남긴다(삭제는 호출자)`() {
        val dest = File(tmp, "b.part")
        val input = object : InputStream() {
            var n = 0
            override fun read(): Int = if (n++ < 5) 7 else throw IOException("boom")
            override fun read(b: ByteArray, off: Int, len: Int): Int {
                if (n >= 5) throw IOException("boom")
                n = 5
                b.fill(7, off, off + 5)
                return 5
            }
        }
        assertEquals(-1L, ShareStreamWriter.drain(input, dest))
        assertEquals(5L, dest.length())
    }

    @Test
    fun `쓸 수 없는 위치면 -1`() {
        val blocker = File(tmp, "file").apply { writeText("x") }
        val dest = File(blocker, "child.part") // 파일 아래에 파일 — 불가
        assertEquals(-1L, ShareStreamWriter.drain(ByteArrayInputStream(byteArrayOf(1)), dest))
    }
}
