import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/make_demo_db.dart';

/// 데모 DB 생성 — 환경변수 DEMO_OUT이 있을 때만 동작하는 도구용 테스트.
///   DEMO_OUT=/tmp/demo_ko DEMO_LANG=ko flutter test test/make_demo_db_test.dart
void main() {
  final out = Platform.environment['DEMO_OUT'];
  test('demo db', () {
    buildDemoDb(out!, Platform.environment['DEMO_LANG'] ?? 'ko');
    expect(File('$out/loop.db').existsSync(), isTrue);
  }, skip: out == null ? 'DEMO_OUT 미지정' : false);
}
