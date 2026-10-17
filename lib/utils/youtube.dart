/// 유튜브 링크 유틸 — API 키 없이 썸네일을 쓴다.
library;

/// YouTube는 `img.youtube.com/vi/{id}/{품질}.jpg`를 무료로 제공하므로
/// 본문에서 video id만 뽑으면 된다. (docs/ui-design.md — 유튜브 썸네일)

final _ytPatterns = [
  // watch?v=… (파라미터 순서 무관: watch?app=…&v=… 도)
  RegExp(r'youtube\.com/watch\?(?:[^#\s]*&)?v=([A-Za-z0-9_-]{11})'),
  RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
  RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{11})'),
  RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{11})'),
];

/// 본문에서 첫 유튜브 동영상 id. 텍스트 앞쪽에 나온 링크 우선. 없으면 null.
String? youtubeVideoId(String content) {
  Match? best;
  for (final p in _ytPatterns) {
    final m = p.firstMatch(content);
    if (m != null && (best == null || m.start < best.start)) best = m;
  }
  return best?.group(1);
}

/// 작은 인라인 썸네일용 — mqdefault는 320x180으로 검은 레터박스가 없다.
String youtubeThumbUrl(String videoId) =>
    'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

/// 유튜브 앱/브라우저로 열 주소.
Uri youtubeWatchUri(String videoId) => Uri.parse('https://youtu.be/$videoId');
