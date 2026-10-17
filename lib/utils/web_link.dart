/// 일반 웹 링크 유틸 — 유튜브가 아닌 http(s) 링크를 뽑는다.
library;

import 'youtube.dart';

/// 문장 부호까지 링크로 삼키지 않게 뒤쪽 구두점은 잘라낸다.
final _trailingJunk = RegExp("[.,;:!?)\\]}>'\"…]+\$");

/// 본문에서 열 수 있는 첫 웹 링크. 유튜브 동영상 링크는 전용 위젯이
/// 맡으므로 건너뛴다. 없으면 null.
String? firstWebUrl(String content) {
  final matches = RegExp(r'https?://[^\s<>"]+').allMatches(content);
  for (final m in matches) {
    final url = m.group(0)!.replaceAll(_trailingJunk, '');
    if (url.isEmpty) continue;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) continue;
    if (youtubeVideoId(url) != null) continue;
    return url;
  }
  return null;
}

/// 파비콘 — Google s2 서비스 (API 키 불필요, 못 찾으면 기본 아이콘을 돌려준다).
String faviconUrl(String host) =>
    'https://www.google.com/s2/favicons?domain=$host&sz=64';
