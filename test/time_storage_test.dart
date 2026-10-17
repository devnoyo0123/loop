import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/utils/time_format.dart';

/// 시간 저장 원칙 (docs/data-model.md "시간 저장 원칙"):
/// - SQLite에는 전부 epoch 밀리초 = UTC 절대시각으로 저장한다.
/// - 읽을 때 기기의 현재 시간대(로컬)로 변환해 표시한다.
/// - 언어는 표기 형식(l10n)만 관장한다 — 시간대는 언어가 아니라 기기 설정.
void main() {
  group('시간 저장 원칙 — UTC 저장 / 로컬 표시', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_time_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('라운드트립 — 저장한 절대시각이 값 하나도 안 바뀌고 나온다', () {
      // UTC로 만든 시각도 에포크 밀리초 관점에선 절대시각 — 타임존 무관.
      final t = DateTime.utc(2026, 9, 3, 0, 30);
      db.insert(LogEntry(
        id: 'a', content: '시간 원칙', createdAt: t, originalCreatedAt: t,
      ));

      final read = db.byId('a')!;
      expect(read.createdAt.millisecondsSinceEpoch, t.millisecondsSinceEpoch);
      expect(read.originalCreatedAt.millisecondsSinceEpoch,
          t.millisecondsSinceEpoch);
    });

    test('읽은 시각은 기기 시간대(로컬)로 변환된다', () {
      final t = DateTime.utc(2026, 9, 3, 0, 30);
      db.insert(LogEntry(
        id: 'a', content: '로컬 변환', createdAt: t, originalCreatedAt: t,
      ));

      final read = db.byId('a')!;
      // isUtc=false = 표시 로직(t.hour 등)이 기기 시간대를 쓴다는 계약.
      expect(read.createdAt.isUtc, isFalse);
      // 로컬 시각으로 재구성한 것과 구성요소가 동일해야 한다.
      final local = DateTime.fromMillisecondsSinceEpoch(
          t.millisecondsSinceEpoch);
      expect(read.createdAt.hour, local.hour);
      expect(read.createdAt.minute, local.minute);
      expect(read.createdAt.day, local.day);
    });

    test('loop_at도 동일 원칙 — 알림·정산이 같은 절대시각을 본다', () {
      final t = DateTime.utc(2026, 9, 3, 5, 0);
      db.insert(LogEntry(
        id: 'src', content: '루프', createdAt: t, originalCreatedAt: t,
      ));
      db.updateLoopAt('src', t.add(const Duration(hours: 1)));

      final read = db.byId('src')!;
      expect(read.loopAt!.millisecondsSinceEpoch,
          t.add(const Duration(hours: 1)).millisecondsSinceEpoch);
      expect(read.loopAt!.isUtc, isFalse);
    });

    test('표시 포맷은 로컬 구성요소를 그대로 쓴다 — 당일은 HH:mm', () {
      final now = DateTime.now(); // 로컬
      final t = DateTime(now.year, now.month, now.day, 14, 5);
      expect(formatMixed(t, now, '어제'), '14:05');
      expect(formatCard(t, now), '${now.month}.${now.day} 14:05');
    });

    test('어제 경계도 로컬 달력 기준 — UTC 자정 기준이 아니다', () {
      final now = DateTime.now(); // 로컬
      final yesterdayLocal = DateTime(now.year, now.month, now.day - 1, 9, 0);
      final label = formatMixed(yesterdayLocal, now, '어제');
      expect(label, contains('어제'));
      expect(label, contains('09:00'));
    });
  });
}
