import 'package:flutter/services.dart';

/// 동영상 재생 — 시스템 플레이어로 위임한다. (v1: video_player 내장 대신
/// 가장 가벼운 경로. FileProvider로 우리 앱 파일의 content URI를 건넨다)
class VideoOpener {
  static const _ch = MethodChannel('app.loop/browser');

  /// 열기 성공 여부. 재생할 앱이 없으면 false — 조용히 무시.
  static Future<bool> open(String path) async {
    try {
      return await _ch.invokeMethod<bool>('openVideo', {'path': path}) ?? false;
    } catch (_) {
      return false; // 안드로이드 외 환경
    }
  }

  /// 대표 프레임 추출 — MediaMetadataRetriever(네이티브)가 첫 프레임을
  /// JPEG(너비 640)로 돌려준다. 실패하면 null — 카드는 아이콘 행 폴백.
  static Future<Uint8List?> thumb(String path) async {
    try {
      return await _ch.invokeMethod<Uint8List>('videoThumb', {'path': path});
    } catch (_) {
      return null; // 안드로이드 외 환경
    }
  }
}
