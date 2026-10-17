import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/web_link.dart';

void main() {
  group('firstWebUrl', () {
    test('일반 URL 검출', () {
      expect(firstWebUrl('https://example.com 보자'),
          'https://example.com');
      expect(
          firstWebUrl('문서 http://docsflutter.org/aaa/bb 참고'),
          'http://docsflutter.org/aaa/bb');
    });

    test('문장 부호가 붙어도 잘라낸다', () {
      expect(firstWebUrl('https://example.com.'),
          'https://example.com');
      expect(firstWebUrl('https://example.com/a) 참고'),
          'https://example.com/a');
      expect(firstWebUrl('링크: https://example.com/x, 그리고 다음'),
          'https://example.com/x');
    });

    test('URL 없으면 null', () {
      expect(firstWebUrl('그냥 텍스트뿐'), isNull);
      expect(firstWebUrl(''), isNull);
    });

    test('유튜브 동영상 링크는 건너뛴다 — 전용 위젯이 맡는다', () {
      expect(firstWebUrl('https://youtu.be/dQw4w9WgXcQ'), isNull);
      expect(firstWebUrl('https://www.youtube.com/watch?v=abc12345678'),
          isNull);
    });

    test('유튜브 뒤의 일반 링크는 잡는다', () {
      expect(
        firstWebUrl(
            'https://youtu.be/dQw4w9WgXcQ 보고 https://example.com 도 봐'),
        'https://example.com',
      );
    });

    test('여러 링크면 첫 번째', () {
      expect(
        firstWebUrl('https://a.com 이랑 https://b.com'),
        'https://a.com',
      );
    });

    test('유튜브가 아닌 youtube.com 링크는 웹 링크로 취급', () {
      // 채널/검색 페이지는 video id가 없으므로 브라우저로 연다.
      expect(firstWebUrl('https://www.youtube.com/@loop'),
          'https://www.youtube.com/@loop');
    });
  });

  group('faviconUrl', () {
    test('Google s2 서비스', () {
      expect(faviconUrl('example.com'),
          'https://www.google.com/s2/favicons?domain=example.com&sz=64');
    });
  });
}
