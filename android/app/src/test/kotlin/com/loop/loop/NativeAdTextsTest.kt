package com.loop.loop

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/// 2026-11-11 운영 1.0.22: 실광고가 로드됐는데 제목·본문·버튼이 빈 칸으로 보였다
/// (NativeAdView가 텍스트를 채워 준다고 오해). 자산 → 텍스트 판단을 고정한다.
class NativeAdTextsTest {
    @Test
    fun `자산이 모두 있으면 그대로 찍는다`() {
        val p = NativeAdTexts.plan("Loop 광고", "본문 설명", "설치")
        assertEquals("Loop 광고", p.headline)
        assertEquals("본문 설명", p.body)
        assertTrue(p.showBody)
        assertEquals("설치", p.cta)
        assertTrue(p.showCta)
    }

    @Test
    fun `본문 없음 - 본문 줄 숨김`() {
        val p = NativeAdTexts.plan("제목", null, "열기")
        assertFalse(p.showBody)
        assertEquals("", p.body)
    }

    @Test
    fun `버튼 문구 없음 또는 공백 - 빈 보라 버튼 대신 숨김`() {
        assertFalse(NativeAdTexts.plan("제목", "본문", null).showCta)
        assertFalse(NativeAdTexts.plan("제목", "본문", "  ").showCta)
    }

    @Test
    fun `미디어가 있으면 이미지 슬롯 - 아이콘보다 우선`() {
        assertEquals(NativeAdTexts.Visual.MEDIA, NativeAdTexts.plan("t", null, null, hasMedia = true, hasIcon = true).visual)
        assertEquals(NativeAdTexts.Visual.MEDIA, NativeAdTexts.plan("t", null, null, hasMedia = true, hasIcon = false).visual)
    }

    @Test
    fun `미디어 없고 아이콘만 - 아이콘 슬롯`() {
        assertEquals(NativeAdTexts.Visual.ICON, NativeAdTexts.plan("t", null, null, hasMedia = false, hasIcon = true).visual)
    }

    @Test
    fun `미디어도 아이콘도 없음(2026-11-11 시계 부품 광고) - 슬롯 접음`() {
        assertEquals(NativeAdTexts.Visual.NONE, NativeAdTexts.plan("NH35 NH36", "NH35", "열기").visual)
    }

    @Test
    fun `제목 null - 크래시 없이 빈 문자열`() {
        assertEquals("", NativeAdTexts.plan(null, null, null).headline)
    }
}
