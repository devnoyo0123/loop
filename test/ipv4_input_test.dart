import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/services/ipv4_input.dart';

const f = Ipv4InputFormatter();

TextEditingValue _at(String text) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

/// 키를 하나씩 친다 (커서는 끝). `<`는 백스페이스.
String type(String keys, {String from = ''}) {
  var v = _at(from);
  for (final k in keys.split('')) {
    final next = k == '<' ? v.text.substring(0, v.text.length - 1) : v.text + k;
    v = f.formatEditUpdate(v, _at(next));
    expect(v.selection.baseOffset, v.text.length, reason: '커서는 끝');
  }
  return v.text;
}

/// 한 번에 붙여넣기.
String paste(String chunk, {String from = ''}) =>
    f.formatEditUpdate(_at(from), _at(from + chunk)).text;

void main() {
  group('Ipv4InputFormatter', () {
    test('점 없이 숫자만 — 192168358 → 192.168.35.8', () {
      expect(type('192168358'), '192.168.35.8');
    });

    test('3자리면 바로 점', () {
      expect(type('192'), '192.');
      expect(type('1921'), '192.1');
    });

    test('다음 숫자로 255를 넘으면 새 옥텟 — 35 + 8 → 35.8', () {
      expect(type('35'), '35.'); // 어떤 숫자를 붙여도 255 초과
      expect(type('25'), '25'); // 250~255 가능 → 아직 열림
      expect(type('256'), '25.6');
      expect(type('255'), '255.');
    });

    test('"0" 옥텟은 앞자리 0 없이 끝난다', () {
      expect(type('0'), '0.');
      expect(type('100'), '100.');
      expect(type('1000'), '100.0.');
      expect(type('10005'), '100.0.5');
    });

    test('짧은 옥텟은 "."로 끝낸다 · 연속 점·선행 점은 무시', () {
      expect(type('192.168.3.5'), '192.168.3.5');
      expect(type('192168.3.'), '192.168.3.');
      expect(type('19..2'), '19.2');
      expect(type('.1'), '1');
      expect(type('192.'), '192.'); // 자동 점 뒤 습관적 "." → 하나만
    });

    test('쉼표 소수점 키패드도 점으로', () {
      expect(type('10,0'), '10.0.');
    });

    test('백스페이스 — 자동 점을 지우면 다시 붙지 않는다', () {
      expect(type('192<'), '192');
      expect(type('192<<'), '19');
      expect(type('1921<<'), '192');
      expect(type('192<1'), '192.1'); // 다시 치면 이어진다
      expect(type('192168358<<'), '192.168.35');
    });

    test('옥텟 4개까지 — 넘치는 입력은 버린다', () {
      expect(type('255255255255'), '255.255.255.255');
      expect(type('2552552552559'), '255.255.255.255');
      expect(type('1.2.3.4.5'), '1.2.3.45');
      expect(type('1.2.3.45.6'), '1.2.3.45');
    });

    test('붙여넣기 — 스킴·포트·경로 제거', () {
      expect(paste('192.168.35.8:8766'), '192.168.35.8');
      expect(paste('http://192.168.35.8:8766/'), '192.168.35.8');
      expect(paste(' 192.168.35.8 '), '192.168.35.8');
    });

    test('미리 채운 서브넷 뒤에 전체 주소를 붙여넣으면 그것만', () {
      expect(paste('192.168.0.8:8766', from: '192.168.35.'), '192.168.0.8');
      expect(paste('8', from: '192.168.35.'), '192.168.35.8');
      expect(paste('12', from: '192.168.35.'), '192.168.35.12');
    });

    test('글자가 있으면(호스트명) 손대지 않는다', () {
      expect(type('mac.local'), 'mac.local');
      expect(paste('my-mac.local:8766'), 'my-mac.local:8766');
    });

    test('중간 편집은 거르기만 하고 커서를 유지', () {
      const old = TextEditingValue(
        text: '192.168.3.5',
        selection: TextSelection.collapsed(offset: 7),
      );
      // "192.16|8" 앞에 "9" 삽입 — 재포맷하지 않는다.
      const edit = TextEditingValue(
        text: '192.1698.3.5',
        selection: TextSelection.collapsed(offset: 7),
      );
      expect(f.formatEditUpdate(old, edit), edit);
      // 중간에서 점을 지워도 그대로 둔다.
      const del = TextEditingValue(
        text: '192168.3.5',
        selection: TextSelection.collapsed(offset: 3),
      );
      expect(f.formatEditUpdate(old, del), del);
      // 허용 안 되는 문자만 빠지고 커서는 그만큼 당겨진다.
      final r = f.formatEditUpdate(
        old,
        const TextEditingValue(
          text: '192 .168.3.5',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(r.text, '192.168.3.5');
      expect(r.selection.baseOffset, 3);
    });
  });

  group('sanitizeHost', () {
    test('스킴·포트·경로·공백 제거', () {
      expect(sanitizeHost('192.168.35.8:8766'), '192.168.35.8');
      expect(sanitizeHost('http://192.168.35.8:8766/'), '192.168.35.8');
      expect(sanitizeHost('tcp://mac.local:8766/x/y'), 'mac.local');
      expect(sanitizeHost('  192.168.0.8  '), '192.168.0.8');
      expect(sanitizeHost('mac.local'), 'mac.local');
      expect(sanitizeHost('fe80::1'), 'fe80::1'); // IPv6는 건드리지 않음
    });
  });
}
