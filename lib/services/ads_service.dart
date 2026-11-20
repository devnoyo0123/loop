import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';

/// 광고 SDK 초기화 + 유럽 사용자 동의(UMP).
/// 앱 시작 때 한 번 — 실패해도 앱 동작에는 지장 없게 조용히 넘어간다.
class AdsService {
  static bool _initialized = false;
  static final _ready = Completer<bool>();

  /// SDK 초기화가 끝났는가 — 광고 로드는 반드시 이걸 기다린 뒤에.
  ///
  /// 초기화 중(WebView 준비가 SDK 내부 락을 쥔 동안) 메인 스레드에서
  /// NativeAd를 만들면 AdLoader.Builder가 그 락을 기다리며 메인 스레드가
  /// 막혀 ANR이 난다 (2026-11-01 회귀 테스트, play-services-ads 25.4.0
  /// 스택으로 확인). false = 광고 끔 또는 초기화 실패 → 로드하지 않는다.
  static Future<bool> get ready => _ready.future;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (!AdsConfig.enabled) {
      _ready.complete(false);
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _ready.complete(true);
      _consent();
    } catch (_) {
      // 동의·초기화 실패 — 광고만 안 나오면 된다.
      if (!_ready.isCompleted) _ready.complete(false);
    }
  }

  /// UMP — EEA 사용자에게 동의 폼을 필요할 때만 보여준다. (콜백 기반 API)
  static void _consent() {
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        try {
          ConsentInformation.instance.isConsentFormAvailable().then((available) {
            if (available) {
              ConsentForm.loadAndShowConsentFormIfRequired((error) {});
            }
          });
        } catch (_) {}
      },
      (FormError error) {},
    );
  }
}
