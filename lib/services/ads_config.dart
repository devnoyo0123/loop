import 'package:flutter/foundation.dart' show kReleaseMode;

/// 광고 ID와 스위치 — 한 곳에서만 관리한다.
///
/// 릴리스 빌드(kReleaseMode)는 실제 광고 단위, 디버그·프로필 실행은 구글
/// 테스트 단위를 쓴다 — 개발 기기에서 실제 광고가 나가고 클릭되는 사고
/// (계정 정지 위험)를 구조적으로 막는다. (2026-11-11 스토어 공개 후 전환)
///
/// 실제 서빙엔 코드 밖 조건이 더 있다: AdMob 콘솔에서 앱↔Play 스토어 연결,
/// 앱 검토 통과, 광고 단위 승인, 지급 정보 등록. 검토 전엔 로드 실패로
/// NativeAdCard가 조용히 접힌다 — 빈 박스는 없다.
class AdsConfig {
  /// 광고 표시 스위치.
  static const bool enabled = true;

  /// AndroidManifest의 APPLICATION_ID와 동일 — 실제 앱 ID.
  /// (AdMob 앱 설정: Loop / Android, 2026-10-18 등록)
  static const String appId = 'ca-app-pub-5337207847889765~2305999987';

  /// 네이티브 광고 단위 — 릴리스는 실제 단위, 개발 중엔 구글 테스트 단위.
  static final String nativeUnit =
      kReleaseMode ? prodNativeUnit : 'ca-app-pub-3940256099942544/2247696110';

  /// 실제 네이티브 광고 단위 (timeline native).
  static const String prodNativeUnit =
      'ca-app-pub-5337207847889765/3015437269';
}
