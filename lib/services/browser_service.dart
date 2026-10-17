import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 웹 링크를 여는 브라우저 제어.
/// - 설정에서 고른 브라우저(preferredPackage)로 항상 연다 — "한 번 정하면
///   그 브라우저에서 이어가기". (explicit intent, Android)
/// - 미설정이면 시스템 기본 브라우저.
class BrowserService {
  static const _channel = MethodChannel('app.loop/browser');

  /// 앱 설정에서 고른 브라우저 패키지. null이면 시스템 기본값.
  static String? preferredPackage;

  /// 설치된 브라우저 목록 + 시스템 기본 패키지.
  static Future<
          ({
            List<({String package, String label})> browsers,
            String? systemDefault
          })> browsers() async {
    ({List<({String package, String label})> browsers, String? systemDefault})
        empty() => (browsers: const [], systemDefault: null);
    try {
      final res = await _channel
          .invokeMethod<Map<Object?, Object?>>('getBrowsers');
      final list = (res?['browsers'] as List<Object?>? ?? [])
          .whereType<Map<Object?, Object?>>()
          .map((m) => (
                package: m['package'] as String,
                label: m['label'] as String,
              ))
          .toList();
      return (browsers: list, systemDefault: res?['default'] as String?);
    } catch (_) {
      return empty();
    }
  }

  /// 웹 링크 열기 — 고른 브라우저가 실패하면 시스템 기본으로 재시도.
  static Future<bool> open(String url) async {
    final pkg = preferredPackage;
    if (pkg != null) {
      try {
        final ok = await _channel
            .invokeMethod<bool>('open', {'url': url, 'package': pkg});
        if (ok == true) return true;
      } catch (_) {
        // 폰밖 — 아래 시스템 기본 시도로 폴백
      }
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {
      return false;
    }
  }
}
