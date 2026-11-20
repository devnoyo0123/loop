package com.loop.loop

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory
import kotlin.math.roundToInt

/// 타임라인 네이티브 광고 — Loop 톤으로 직접 그린다 (2026-11-05).
///
/// 구글 small 템플릿은 콘텐츠(~110dp)보다 큰 고정 높이(150dp)를 주면 카드 안에
/// 빈 밴드가 남아 타임라인에서 "틈"으로 보였다. 플랫폼 뷰 특성상 Flutter 쪽
/// 고정 높이는 어쩔 수 없으므로, 레이아웃을 직접 그려 콘텐츠가 박스를 꽉 채우게
/// 만든다 — 남는 여백은 상하 ~5dp 수준.
///
/// 2026-11-11: 왼쪽에 120dp 정사각 미디어 슬롯(광고 이미지·동영상)을 둔다.
/// 미디어가 없으면 아이콘을 슬롯 가운데에, 둘 다 없으면 슬롯을 접는다.
///
/// 색·간격은 lib/design/tokens.dart와 **수동 동기화** — 토큰 바꾸면 여기도.
/// AdChoices 아이콘은 NativeAdView가 기본(우상단)에 자동으로 얹는다.
/// 별점은 문자열(★)로 표시 — 등록 자산이 아니라 클릭 대상이 아니다.
class LoopNativeAdFactory(private val context: Context) : NativeAdFactory {
    companion object {
        /// Flutter NativeAdCard._baseHeight 와 짝 — 박스 높이 기준(dp).
        /// = 상하 패딩 10+10 + 미디어 슬롯 120 (2026-11-11 이미지 썸네일 도입).
        const val designHeightDp = 140

        /// 왼쪽 미디어 슬롯 한 변(dp) — AdMob 정책 최소 120x120.
        const val mediaSizeDp = 120

        /// Dart AdsService 쪽에서 쓰는 factoryId.
        const val factoryId = "loopSmall"
    }

    // LoopColors (tokens.dart) — 수동 동기화
    private val cSurface = 0xFF12151D.toInt()
    private val cSurfaceHi = 0xFF1A1E2A.toInt()
    private val cText = 0xFFE8EAF2.toInt()
    private val cTextDim = 0xFF8B90A0.toInt()
    private val cLavender = 0xFFA78BFA.toInt()
    private val cBg = 0xFF0B0D12.toInt()

    private fun dp(v: Float): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, context.resources.displayMetrics)
            .roundToInt()

    private fun TextView.style(sizeSp: Float, color: Int, bold: Boolean = false) {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
        setTextColor(color)
        setTypeface(typeface, if (bold) Typeface.BOLD else Typeface.NORMAL)
    }

    /// customOptions는 플러그인이 null로 넘길 수 있다(1.0.19 크래시 원인) —
    /// nullable로 받고 본문에서는 어차피 쓰지 않는다.
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val media = nativeAd.mediaContent
        val texts = NativeAdTexts.plan(
            headline = nativeAd.headline,
            body = nativeAd.body,
            callToAction = nativeAd.callToAction,
            hasMedia = media != null && (media.hasVideoContent() || media.mainImage != null),
            hasIcon = nativeAd.icon?.drawable != null,
        )

        val root = NativeAdView(context)
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10f), dp(10f), dp(14f), dp(10f))
            background = GradientDrawable().apply {
                setColor(cSurface)
                cornerRadius = dp(12f).toFloat()
            }
        }

        // 왼쪽 정사각 슬롯 — AdMob 정책상 MediaView는 최소 120x120dp.
        val slot = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(mediaSizeDp.toFloat()), dp(mediaSizeDp.toFloat()))
            background = GradientDrawable().apply {
                setColor(cSurfaceHi)
                cornerRadius = dp(8f).toFloat()
            }
            clipToOutline = true
            visibility = if (texts.visual == NativeAdTexts.Visual.NONE) View.GONE else View.VISIBLE
        }
        var mediaView: MediaView? = null
        var icon: ImageView? = null
        when (texts.visual) {
            NativeAdTexts.Visual.MEDIA -> {
                mediaView = MediaView(context).apply {
                    setImageScaleType(ImageView.ScaleType.CENTER_CROP)
                }
                slot.addView(
                    mediaView,
                    FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
                )
            }
            NativeAdTexts.Visual.ICON -> {
                icon = ImageView(context).apply {
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    setImageDrawable(nativeAd.icon?.drawable)
                }
                slot.addView(icon, FrameLayout.LayoutParams(dp(64f), dp(64f), Gravity.CENTER))
            }
            NativeAdTexts.Visual.NONE -> Unit
        }

        val col = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(if (texts.visual == NativeAdTexts.Visual.NONE) 4f else 12f)
            }
        }

        val ko = context.resources.configuration.locales[0].language == "ko"
        val badge = TextView(context).apply {
            text = if (ko) "광고" else "Ad"
            style(10f, cBg, bold = true)
            background = GradientDrawable().apply {
                setColor(cLavender)
                cornerRadius = dp(4f).toFloat()
            }
            setPadding(dp(6f), dp(1f), dp(6f), dp(1f))
        }

        val stars = TextView(context).apply {
            nativeAd.starRating?.let { r ->
                val full = r.roundToInt().coerceIn(1, 5)
                text = "★".repeat(full) + "☆".repeat(5 - full)
                style(11f, cTextDim)
                visibility = View.VISIBLE
            } ?: run { visibility = View.GONE }
        }

        val badgeRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(badge)
            addView(stars, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                marginStart = dp(6f)
            })
        }

        val headline = TextView(context).apply {
            text = texts.headline
            style(15f, cText, bold = true)
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(4f)
            }
        }

        val body = TextView(context).apply {
            text = texts.body
            style(12f, cTextDim)
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
            visibility = if (texts.showBody) View.VISIBLE else View.GONE
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(2f)
            }
        }

        // CTA는 텍스트 아래 왼쪽 — 썸네일이 폭을 차지하므로 오른쪽에 두면 제목이 너무 좁아진다.
        val cta = TextView(context).apply {
            text = texts.cta
            style(13f, cBg, bold = true)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(cLavender)
                cornerRadius = dp(8f).toFloat()
            }
            setPadding(dp(14f), dp(6f), dp(14f), dp(6f))
            minimumWidth = dp(64f)
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
            visibility = if (texts.showCta) View.VISIBLE else View.GONE
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(8f)
            }
        }

        col.addView(badgeRow)
        col.addView(headline)
        col.addView(body)
        col.addView(cta)

        row.addView(slot)
        row.addView(col)
        root.addView(
            row,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        // 자산 등록 — SDK가 클릭·임프레션·미디어 재생을 처리한다. 텍스트는 위에서 직접 채웠다.
        root.headlineView = headline
        root.bodyView = body
        root.callToActionView = cta
        mediaView?.let { root.mediaView = it }
        icon?.let { root.iconView = it }
        root.setNativeAd(nativeAd)
        return root
    }
}
