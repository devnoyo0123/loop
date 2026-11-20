package com.loop.loop

/// 알람 발화 때 "어떻게 보여줄지" 판단 — Android 의존 없는 순수 함수(JVM 테스트).
/// AlarmReceiver는 이 결과대로 알림을 게시·구성만 한다.
///
/// 경로:
/// - 화면 켜짐 + 오버레이 허용 → AlarmSoundService의 오버레이가 알람 UI (알림 생략)
/// - 그 밖 → 전체 화면 인텐트(FSI) 알림. FSI가 허용돼 있으면 잠금 화면 위
///   전체 화면 알람, 막혀 있으면(Android 14+ 특별 권한) 시스템이 일반 알림으로
///   낮춘다 — 그때 사용자가 원인을 알고 바로 켤 수 있게 "전체 화면 켜기" 버튼을
///   단다. (2026-11-01 실기기 Fold4: 소리만 나고 화면이 안 떴다)
object AlarmPresentation {
    data class Plan(
        /// 알림(FSI)을 게시하는가.
        val postNotification: Boolean,
        /// 알림에 "전체 화면 켜기"(권한 설정으로 이동) 버튼을 다는가.
        val offerEnableFullScreen: Boolean,
        /// 알림을 탭하면 알람 화면을 연다 — FSI가 막혀 일반 알림으로 왔을 때
        /// 사용자가 "어디서 울리는지" 찾지 않고 바로 알람 화면으로 간다.
        val tapOpensAlarm: Boolean,
    )

    /// Android 14(UPSIDE_DOWN_CAKE)부터 전체 화면 알림이 특별 권한.
    const val FSI_PERMISSION_SDK = 34

    fun plan(
        sdkInt: Int,
        screenOn: Boolean,
        overlayAllowed: Boolean,
        fullScreenAllowed: Boolean,
    ): Plan {
        val overlayHandles = screenOn && overlayAllowed
        val fsiBlocked = sdkInt >= FSI_PERMISSION_SDK && !fullScreenAllowed
        return Plan(
            postNotification = !overlayHandles,
            offerEnableFullScreen = !overlayHandles && fsiBlocked,
            tapOpensAlarm = true,
        )
    }
}
