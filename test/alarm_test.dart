import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/services/loop_notifications.dart';

void main() {
  group('LoopPayload 코덱', () {
    test('dbDir 없으면 legacy 단일 id 형식 — decode도 둘 다 읽는다', () {
      final encoded = LoopPayload(logId: 'abc').encode();
      expect(encoded, 'abc');
      final decoded = LoopPayload.decode(encoded);
      expect(decoded.logId, 'abc');
      expect(decoded.dbDir, isNull);
    });

    test('dbDir 있으면 JSON {i,d} — 이전 앱이 쓰던 단순 id도 폴백으로 읽힌다', () {
      final encoded = LoopPayload(
        logId: 'log1',
        dbDir: '/data/user/0/x',
      ).encode();
      expect(encoded, contains('"i"'));
      final decoded = LoopPayload.decode(encoded);
      expect(decoded.logId, 'log1');
      expect(decoded.dbDir, '/data/user/0/x');

      // 이전 버전이 예약한 알림(payload = logId)도 탭 처리돼야 한다.
      expect(LoopPayload.decode('legacy-id').logId, 'legacy-id');
      expect(LoopPayload.decode(null).logId, isEmpty);
      expect(LoopPayload.decode('{broken').logId, isEmpty);
    });
  });

  group('루프별 알람 플래그 (v7 loop_alarm)', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_alarm_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    LogEntry entry(String id, DateTime at, {bool loopAlarm = false}) =>
        LogEntry(
          id: id,
          content: '',
          createdAt: at,
          originalCreatedAt: at,
          loopAt: at.add(const Duration(hours: 1)),
          loopAlarm: loopAlarm,
        );

    test('루프마다 저장된다 — 알림과 알람이 섞여 있어도 각자 유지', () {
      final t = DateTime(2026, 10, 18, 9);
      db.insert(entry('soft', t));
      db.insert(entry('hard', t, loopAlarm: true));

      expect(db.byId('soft')!.loopAlarm, isFalse);
      expect(db.byId('hard')!.loopAlarm, isTrue);
    });

    test('재예약 시 alarm 지정/미지정 — null이면 기존 플래그 유지', () {
      final t = DateTime(2026, 10, 18, 9);
      db.insert(entry('x', t, loopAlarm: true));

      db.updateLoopAt('x', t.add(const Duration(days: 1)));
      expect(db.byId('x')!.loopAlarm, isTrue); // 유지

      db.updateLoopAt('x', t.add(const Duration(days: 2)), alarm: false);
      expect(db.byId('x')!.loopAlarm, isFalse); // 바뀜

      db.updateLoopAt('x', t.add(const Duration(days: 3)), alarm: true);
      expect(db.byId('x')!.loopAlarm, isTrue);

      // 소화 재설정(loop_done=0)과 무관하게 플래그는 유지된다.
      expect(db.byId('x')!.loopDone, isFalse);
    });

    test('내보내기→가져오기에서도 플래그가 온전하다', () async {
      final t = DateTime(2026, 10, 18, 9);
      db.insert(entry('soft', t));
      db.insert(entry('hard', t, loopAlarm: true));

      final tmp2 = Directory.systemTemp.createTempSync('loop_alarm_b');
      final db2 = LoopDb(tmp2)..open();
      addTearDown(() {
        db2.close();
        tmp2.deleteSync(recursive: true);
      });

      final stats = await db2.importLines(
        Stream.fromIterable(db.exportLines()),
      );
      expect(stats.logs, 2);
      expect(db2.byId('soft')!.loopAlarm, isFalse);
      expect(db2.byId('hard')!.loopAlarm, isTrue);
    });

    test('pendingOneShotLoops는 플래그를 함께 돌려준다 — 재예약이 알람 등급을 따름', () {
      final t = DateTime(2026, 10, 18, 9);
      db.insert(entry('hard', t, loopAlarm: true));
      final pending = db.pendingOneShotLoops();
      expect(pending.single.id, 'hard');
      expect(pending.single.loopAlarm, isTrue);
    });

    test('스누즈는 updateLoopAt(alarm: true)로 재걸린다 — 시각만 미래로', () {
      final t = DateTime(2026, 10, 18, 9);
      db.insert(entry('x', t, loopAlarm: true));
      final snoozedAt = t.add(LoopNotifications.snoozeAfter);
      db.updateLoopAt('x', snoozedAt, alarm: true);

      final log = db.byId('x')!;
      expect(log.loopAt, snoozedAt);
      expect(log.loopAlarm, isTrue);
      expect(db.pendingOneShotLoops().single.id, 'x');
    });
  });
}
