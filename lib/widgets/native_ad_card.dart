import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../services/ads_config.dart';
import '../services/ads_service.dart';

/// 타임라인에 끼어드는 네이티브 광고 카드. (2026-10-18 결정)
///
/// Android는 Kotlin LoopNativeAdFactory(커스텀 레이아웃, 높이=콘텐츠)로
/// 그린다 — 구글 small 템플릿은 콘텐츠보다 큰 고정 높이에서 빈 밴드가
/// 남아 타임라인에 "틈"으로 보였기 때문 (2026-11-05). 박스 높이는
/// LoopNativeAdFactory.designHeightDp(140dp)와 짝이다 — 왼쪽 120dp
/// 이미지 슬롯 + 상하 패딩 (2026-11-11 이미지 썸네일 도입, 이전 100dp).
/// 그 밖의 플랫폼(iOS — 현재 광고 미설정)은 구글 템플릿(small) 폴백.
/// 로드에 실패하면 조용히 사라진다 — 빈 박스 금지.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AdsConfig.enabled) {
      _failed = true;
      return;
    }
    // SDK 초기화 전에 만들면 메인 스레드가 SDK 락을 기다려 ANR — 기다린다.
    final ready = await AdsService.ready;
    if (!mounted) return;
    if (!ready) {
      setState(() => _failed = true);
      return;
    }
    _ad = NativeAd(
      adUnitId: AdsConfig.nativeUnit,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _failed = true; // 조용히 접힌다 — 빈 박스 금지
            _ad = null;
          });
        },
      ),
      // Android: Kotlin 커스텀 팩토리. 나머지: 구글 템플릿(small) 폴백.
      factoryId: Platform.isAndroid ? 'loopSmall' : null,
      nativeTemplateStyle: Platform.isAndroid
          ? null
          : NativeTemplateStyle(
              templateType: TemplateType.small,
              mainBackgroundColor: LoopColors.surface,
              cornerRadius: 12.0,
              primaryTextStyle: NativeTemplateTextStyle(
                textColor: LoopColors.text,
                backgroundColor: Colors.transparent,
                style: NativeTemplateFontStyle.bold,
                size: 14,
              ),
              secondaryTextStyle: NativeTemplateTextStyle(
                textColor: LoopColors.textDim,
                backgroundColor: Colors.transparent,
                style: NativeTemplateFontStyle.normal,
                size: 12,
              ),
              tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: LoopColors.bg,
                backgroundColor: LoopColors.lavender,
                style: NativeTemplateFontStyle.bold,
                size: 12,
              ),
            ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  /// 광고 카드 기준 높이 — LoopNativeAdFactory.designHeightDp(140dp)와 짝.
  /// Kotlin 레이아웃이 콘텐츠를 박스에 꽉 채우므로 빈 밴드가 없다.
  /// 텍스트는 sp라 시스템 글자 크기에 따라 커지므로 박스도 비례해 키운다.
  static const _baseHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    if (_failed || !_loaded || _ad == null) return const SizedBox.shrink();
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = (_baseHeight * scale).clamp(_baseHeight, 220.0);
    // 모서리·배경은 템플릿 스타일(cornerRadius·mainBackgroundColor)이 그린다.
    // Flutter 쪽에서 클리핑하면 광고 자산이 잘려 정책 위반으로 잡히므로 두지 않는다.
    //
    // small 템플릿은 폰 폭 기준이라 폴더 내부 화면(~700dp+)에 그대로 맡기면
    // CTA가 화면 끝까지 늘어나고 빈 공간만 남는다 (2026-10-24 Z Fold 4).
    // 플랫폼 뷰는 스스로 줄어들지 못 하므로 폰 상한(560dp)으로 묶고 가운데 정렬.
        // 클립 — 커스텀 팩토리(2026-11-05~)는 콘텐츠가 박스 안에 맞게 그려지므로
        // 정상 광고는 잘릴 게 없다. SDK가 가끔 웹뷰 크리에이티브의 "템플릿을
        // 사용할 수 없음" 에러 페이지를 카드 밖까지 거대하게 렌더하는 일이 있는데
        // (2026-11-09 목격) 이렇게 카드 경계 안에 가둔다.
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LoopSpacing.m,
              vertical: LoopSpacing.xs,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // maxWidth(느슨한 제약)가 아니라 "정확한 폭"을 강제해야 안드로이드
                // 네이티브 템플릿 뷰가 폭을 따른다 — 느슨한 max는 폴드 내부 화면에서
                // 무시되어 광고 자산이 뷰 밖으로 나간다 (2026-10-24 검수기 이슈).
                final width = constraints.maxWidth.clamp(0.0, 560.0);
                return Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: AdWidget(ad: _ad!),
                  ),
                );
              },
            ),
          ),
        );
  }
}
