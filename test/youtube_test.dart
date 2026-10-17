import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/youtube.dart';

void main() {
  group('youtubeVideoId — 본문에서 id 추출', () {
    test('watch?v= 형식', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          'dQw4w9WgXcQ');
    });

    test('watch?v= 뒤에 파라미터가 더 붙어도', () {
      expect(
          youtubeVideoId(
              'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s'),
          'dQw4w9WgXcQ');
    });

    test('파라미터 순서가 바뀌어도 (watch?app=…&v=…)', () {
      expect(
          youtubeVideoId(
              'https://m.youtube.com/watch?app=desktop&v=dQw4w9WgXcQ'),
          'dQw4w9WgXcQ');
    });

    test('youtu.be 단축', () {
      expect(youtubeVideoId('보다가 https://youtu.be/dQw4w9WgXcQ 저장'),
          'dQw4w9WgXcQ');
    });

    test('shorts', () {
      expect(youtubeVideoId('https://youtube.com/shorts/dQw4w9WgXcQ?feature=share'),
          'dQw4w9WgXcQ');
    });

    test('embed', () {
      expect(youtubeVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
          'dQw4w9WgXcQ');
    });

    test('문장 속 여러 링크 — 앞쪽 것 우선', () {
      expect(
          youtubeVideoId('https://youtu.be/AAAAAAAAAAA 이따가 '
              'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          'AAAAAAAAAAA');
    });

    test('유튜브가 아니면 null', () {
      expect(youtubeVideoId('https://example.com/watch?v=dQw4w9WgXcQ'), isNull);
      expect(youtubeVideoId('링크 없는 그냥 생각'), isNull);
      expect(youtubeVideoId(''), isNull);
    });

    test('id가 11자가 아니면 안 잡힌다', () {
      expect(youtubeVideoId('https://youtu.be/short'), isNull);
    });
  });

  test('썸네일 URL — API 키 없는 img.youtube.com', () {
    expect(youtubeThumbUrl('dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg');
  });

  test('열기 URI', () {
    expect(youtubeWatchUri('dQw4w9WgXcQ').toString(),
        'https://youtu.be/dQw4w9WgXcQ');
  });
}
