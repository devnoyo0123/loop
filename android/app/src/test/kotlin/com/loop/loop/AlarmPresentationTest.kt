package com.loop.loop

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/// 알람 표시 경로 판단 — 2026-11-01 실기기(Fold4, Android 16): 화면 꺼짐 +
/// 전체 화면 알림 권한 없음 → 소리만 나고 화면이 안 떴다.
class AlarmPresentationTest {
    @Test
    fun `화면 꺼짐 + FSI 허용 - 전체 화면 알림, 켜기 버튼 없음`() {
        val p = AlarmPresentation.plan(sdkInt = 36, screenOn = false, overlayAllowed = false, fullScreenAllowed = true)
        assertTrue(p.postNotification)
        assertFalse(p.offerEnableFullScreen)
    }

    @Test
    fun `화면 꺼짐 + FSI 막힘(Android 14+) - 알림에 전체 화면 켜기 버튼`() {
        val p = AlarmPresentation.plan(sdkInt = 36, screenOn = false, overlayAllowed = false, fullScreenAllowed = false)
        assertTrue(p.postNotification)
        assertTrue(p.offerEnableFullScreen)
        assertTrue(p.tapOpensAlarm) // 탭하면 알람 화면 — 어디서 울리는지 찾지 않게
    }

    @Test
    fun `화면 꺼짐이면 오버레이 권한이 있어도 알림 경로 (오버레이는 화면 켜짐 전용)`() {
        val p = AlarmPresentation.plan(sdkInt = 36, screenOn = false, overlayAllowed = true, fullScreenAllowed = false)
        assertTrue(p.postNotification)
        assertTrue(p.offerEnableFullScreen)
    }

    @Test
    fun `화면 켜짐 + 오버레이 허용 - 오버레이가 맡고 알림 생략`() {
        val p = AlarmPresentation.plan(sdkInt = 36, screenOn = true, overlayAllowed = true, fullScreenAllowed = false)
        assertFalse(p.postNotification)
        assertFalse(p.offerEnableFullScreen)
    }

    @Test
    fun `화면 켜짐 + 오버레이 없음 + FSI 막힘 - 알림에 켜기 버튼`() {
        val p = AlarmPresentation.plan(sdkInt = 34, screenOn = true, overlayAllowed = false, fullScreenAllowed = false)
        assertTrue(p.postNotification)
        assertTrue(p.offerEnableFullScreen)
    }

    @Test
    fun `Android 13 이하 - FSI는 특별 권한이 아니라 버튼 없음`() {
        val p = AlarmPresentation.plan(sdkInt = 33, screenOn = false, overlayAllowed = false, fullScreenAllowed = false)
        assertTrue(p.postNotification)
        assertFalse(p.offerEnableFullScreen)
    }

    @Test
    fun `특별 권한 기준 API 레벨은 34`() {
        assertEquals(34, AlarmPresentation.FSI_PERMISSION_SDK)
    }
}
