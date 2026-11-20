package com.loop.loop

/// 네이티브 광고 자산 → 카드 구성 판단 — Android 의존 없는 순수 함수(JVM 테스트).
/// LoopNativeAdFactory는 이 결과대로 뷰에 넣기만 한다.
///
/// NativeAdView는 headlineView 등을 "등록"만 할 뿐 텍스트를 채워 주지 않는다.
/// 1.0.22에서 이걸 빠뜨려 실광고가 와도 제목·본문·버튼이 빈 칸이었다(2026-11-11).
object NativeAdTexts {
    /// 왼쪽 정사각 슬롯에 무엇을 그리나.
    enum class Visual {
        /// 광고 이미지·동영상(MediaView) — 슬롯을 꽉 채운다.
        MEDIA,
        /// 미디어가 없고 아이콘만 있음 — 슬롯 가운데에 아이콘.
        ICON,
        /// 둘 다 없음 — 슬롯을 접고 텍스트만.
        NONE,
    }

    data class Plan(
        val headline: String,
        val body: String,
        val showBody: Boolean,
        val cta: String,
        val showCta: Boolean,
        val visual: Visual,
    )

    fun plan(
        headline: String?,
        body: String?,
        callToAction: String?,
        hasMedia: Boolean = false,
        hasIcon: Boolean = false,
    ): Plan {
        val b = body?.trim().orEmpty()
        val c = callToAction?.trim().orEmpty()
        return Plan(
            headline = headline?.trim().orEmpty(),
            body = b,
            showBody = b.isNotEmpty(),
            cta = c,
            showCta = c.isNotEmpty(),
            visual = when {
                hasMedia -> Visual.MEDIA
                hasIcon -> Visual.ICON
                else -> Visual.NONE
            },
        )
    }
}
