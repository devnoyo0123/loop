import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/screens/loop_sheet.dart';
import 'package:loop/services/loop_notifications.dart';

void main() {
  // 라벨 검증은 ko 로케일로 고정.
  final l10n = lookupAppLocalizations(const Locale('ko'));

  group('RepeatRule 주기 수학', () {
    final t = DateTime(2026, 9, 1, 9, 0);

    test('10분마다 — 다음 발화는 +10분', () {
      final r = _rule(kind: RepeatKind.minutes, everyN: 10, next: t);
      expect(r.nextFireAfter(t), t.add(const Duration(minutes: 10)));
    });

    test('3시간마다 — 다음 발화는 +3시간', () {
      final r = _rule(kind: RepeatKind.hours, everyN: 3, next: t);
      expect(r.nextFireAfter(t), t.add(const Duration(hours: 3)));
    });

    test('매일 — 다음 발화는 정확히 +1일 (시각 유지)', () {
      final r = _rule(kind: RepeatKind.daily, next: t, timeOfDay: '09:00');
      expect(r.nextFireAfter(t), DateTime(2026, 9, 2, 9, 0));
    });

    test('매일 첫 발화 — 오늘 그 시각이 아직 안 됐으면 오늘', () {
      final now = DateTime(2026, 9, 1, 8, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.daily,
          timeOfDay: '21:30', now: now);
      expect(first, DateTime(2026, 9, 1, 21, 30));
    });

    test('매일 첫 발화 — 오늘 그 시각이 지났으면 내일', () {
      final now = DateTime(2026, 9, 1, 22, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.daily,
          timeOfDay: '21:30', now: now);
      expect(first, DateTime(2026, 9, 2, 21, 30));
    });

    test('직접 입력 첫 발화 — 지금부터 N분 뒤', () {
      final now = DateTime(2026, 9, 1, 9, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.minutes,
          everyN: 45, now: now);
      expect(first, DateTime(2026, 9, 1, 9, 45));
    });

    test('라벨', () {
      expect(
          _rule(kind: RepeatKind.minutes, everyN: 10, next: t).label(l10n),
          '10분마다');
      expect(
          _rule(kind: RepeatKind.hours, everyN: 3, next: t).label(l10n),
          '3시간마다');
      expect(
          _rule(kind: RepeatKind.daily, next: t, timeOfDay: '09:00')
              .label(l10n),
          '매일 09:00');
      // 영문도 함께 확인 — locale별 분기 검증.
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
          _rule(kind: RepeatKind.hours, everyN: 3, next: t).label(en),
          'Every 3 hr');
      expect(
          _rule(kind: RepeatKind.daily, next: t, timeOfDay: '09:00')
              .label(en),
          'Daily at 09:00');
    });

    test('반복 알림 id — 규칙마다·슬롯마다 다르고 안정적', () {
      expect(LoopNotifications.repeatIdFor('rule1', 0),
          LoopNotifications.repeatIdFor('rule1', 0));
      expect(LoopNotifications.repeatIdFor('rule1', 0),
          isNot(LoopNotifications.repeatIdFor('rule1', 1)));
      expect(LoopNotifications.repeatIdFor('rule1', 0),
          isNot(LoopNotifications.repeatIdFor('rule2', 0)));
    });

    test('매일 첫 발화 — 분 없는 레거시 시각("09")도 크래시 없이 파싱', () {
      // 폰에서 RangeError (length)가 났던 케이스 — 시간만 저장된 값 방어.
      final now = DateTime(2026, 9, 1, 8, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.daily,
          timeOfDay: '09', now: now);
      expect(first, DateTime(2026, 9, 1, 9, 0));
    });

    test('매일 첫 발화 — 시각 형식이 아예 깨졌으면 00:00로 폴백', () {
      final now = DateTime(2026, 9, 1, 8, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.daily,
          timeOfDay: 'abc', now: now);
      expect(first, DateTime(2026, 9, 1, 0, 0).add(const Duration(days: 1)));
    });

    test('평일 — 금요일 다음 발화는 주말을 건너뛰어 월요일', () {
      final r = _rule(kind: RepeatKind.weekday, next: t, timeOfDay: '09:00');
      // 2026-10-16은 금요일.
      expect(r.nextFireAfter(DateTime(2026, 10, 16, 9, 0)),
          DateTime(2026, 10, 19, 9, 0));
    });

    test('평일 — 공휴일(2026 한글날 10/9 금)도 건너뛴다', () {
      final r = _rule(kind: RepeatKind.weekday, next: t, timeOfDay: '09:00');
      // 10/8(목) 다음 근무일은 10/9(한글날)·10/10(토)·10/11(일)을 지나 10/12(월).
      expect(r.nextFireAfter(DateTime(2026, 10, 8, 9, 0)),
          DateTime(2026, 10, 12, 9, 0));
    });

    test('평일 연쇄 — 한글날+주말 구간을 지나는 발화 나열', () {
      final r = _rule(kind: RepeatKind.weekday, next: t, timeOfDay: '09:00');
      final times = <DateTime>[];
      var cur = DateTime(2026, 10, 8, 9, 0);
      final end = DateTime(2026, 10, 13, 0, 0);
      while (cur.isBefore(end)) {
        times.add(cur);
        cur = r.nextFireAfter(cur);
      }
      expect(times, [DateTime(2026, 10, 8, 9, 0), DateTime(2026, 10, 12, 9, 0)]);
    });

    test('평일 첫 발화 — 오늘이 토요일이면 다음 근무일(월)로', () {
      // 2026-10-17은 토요일 — 오늘 09:00은 이미 지났고 일요일도 건너뛴다.
      final now = DateTime(2026, 10, 17, 10, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.weekday,
          timeOfDay: '09:00', now: now);
      expect(first, DateTime(2026, 10, 19, 9, 0));
    });

    test('평일 첫 발화 — 내일이 공휴일(2026 광복절 대체 8/17 월)이면 다음 날로', () {
      // 2026-08-16(일) 20:00 → 후보 8/17(월, 대체공휴일) → 8/18(화).
      final now = DateTime(2026, 8, 16, 20, 0);
      final first = RepeatRule.firstFireOf(RepeatKind.weekday,
          timeOfDay: '21:00', now: now);
      expect(first, DateTime(2026, 8, 18, 21, 0));
    });

    test('평일 라벨', () {
      expect(
          _rule(kind: RepeatKind.weekday, next: t, timeOfDay: '09:00')
              .label(l10n),
          '평일 09:00');
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
          _rule(kind: RepeatKind.weekday, next: t, timeOfDay: '09:00')
              .label(en),
          'Weekdays at 09:00');
    });
  });

  group('RepeatRule DB', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_repeat_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    LogEntry entry(String id, String content, DateTime at) => LogEntry(
          id: id, content: content, createdAt: at, originalCreatedAt: at,
        );

    test('규칙 저장·조회 roundtrip', () {
      // DB는 밀리초까지 저장 — 테스트 시각도 ms로 맞춘다.
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      final next = DateTime.fromMillisecondsSinceEpoch(
          now.add(const Duration(days: 1)).millisecondsSinceEpoch);
      final rule = _rule(
          kind: RepeatKind.daily,
          next: next,
          timeOfDay: '22:00',
          createdAt: now);
      db.insertRepeatRule(rule);

      final loaded = db.repeatRuleById(rule.id);
      expect(loaded, isNotNull);
      expect(loaded!.sourceLogId, rule.sourceLogId);
      expect(loaded.kind, RepeatKind.daily);
      expect(loaded.timeOfDay, '22:00');
      expect(loaded.nextFireAt, next);
      expect(loaded.active, isTrue);
      expect(db.activeRepeatRules(), hasLength(1));
    });

    test('평일 규칙도 저장·조회된다 (kind 텍스트는 이름 기반이라 무마이그레이션)', () {
      final now = DateTime.now();
      final rule = _rule(
          kind: RepeatKind.weekday,
          next: DateTime(2026, 10, 19, 9, 0),
          timeOfDay: '09:00',
          createdAt: now);
      db.insertRepeatRule(rule);

      final loaded = db.repeatRuleById(rule.id);
      expect(loaded!.kind, RepeatKind.weekday);
      expect(loaded.timeOfDay, '09:00');
      expect(loaded.nextFireAt, DateTime(2026, 10, 19, 9, 0));
    });

    test('settleRepeats — 놓친 발화를 발화 시각대로 몰아 생성', () {
      // DB는 밀리초까지 저장 — 경계 판정이 필요한 만큼 ms로 정규화.
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      db.insert(entry('src', '매일 돌아오는 생각', now));

      // 10분마다, 첫 발화가 35분 전 — 0/10/20/30분 전, 4회 발화해야 한다.
      final start = DateTime.fromMillisecondsSinceEpoch(
          now.subtract(const Duration(minutes: 35)).millisecondsSinceEpoch);
      db.insertRepeatRule(_rule(
          source: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          next: start,
          createdAt: now));

      final created = db.settleRepeats();
      expect(created, 4);

      final forks = db
          .window(limit: 100)
          .where((l) => l.repeatRuleId != null)
          .toList();
      expect(forks, hasLength(4));
      for (final f in forks) {
        expect(f.content, isEmpty); // 빈 로그
        expect(f.parentId, 'src');
        expect(f.rootId, 'src');
        expect(f.depth, 1);
        expect(f.path, startsWith('src/'));
        expect(f.createdAt.isBefore(start), isFalse);
      }
      // 발화 시각이 그대로 로그의 시계열 위치가 된다.
      final times = forks.map((f) => f.createdAt).toSet();
      expect(times, hasLength(4));

      // 규칙은 미래로 밀리고 카운트가 올라간다.
      final rule = db.repeatRuleById('r1')!;
      expect(rule.nextFireAt, start.add(const Duration(minutes: 40)));
      expect(rule.fireCount, 4);
      expect(rule.nextFireAt.isAfter(now), isTrue);

      // 다시 settle해도 새로 생기는 게 없다.
      expect(db.settleRepeats(), 0);
    });

    test('settleRepeats — 미래 발화는 생성하지 않는다', () {
      final now = DateTime.now();
      db.insert(entry('src', '아직', now));
      db.insertRepeatRule(_rule(
          source: 'src',
          kind: RepeatKind.hours,
          everyN: 1,
          next: now.add(const Duration(hours: 1)),
          createdAt: now));
      expect(db.settleRepeats(), 0);
    });

    test('settleExpiredLoops — 발화 시각이 지난 단발 루프는 빈 포크를 만든다', () {
      // DB는 밀리초까지 저장 — 경계 판정이 필요한 만큼 ms로 정규화.
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      db.insert(entry('src', '10분 뒤에 돌아오기', now));

      // 10분 전에 발화 예정이었던 단발 루프.
      db.updateLoopAt('src', now.subtract(const Duration(minutes: 10)));

      expect(db.settleExpiredLoops(), 1);
      // 원본은 소화 — 다시 정산해도 0.
      expect(db.byId('src')!.loopDone, isTrue);
      expect(db.settleExpiredLoops(), 0);

      // 발화 시각대의 빈 포크가 생긴다.
      final forks = db
          .window(limit: 100)
          .where((l) => l.parentId == 'src')
          .toList();
      expect(forks, hasLength(1));
      final f = forks.single;
      expect(f.content, isEmpty);
      expect(f.createdAt, now.subtract(const Duration(minutes: 10)));
      expect(f.depth, 1);
      expect(f.rootId, 'src');
      expect(f.path, startsWith('src/'));

      // 사슬 — 루프 보기가 원본→포크를 잡는다.
      expect(db.lineage(f.id).map((l) => l.id), ['src', f.id]);
    });

    test('settleExpiredLoops — 미래 단발 루프는 건드리지 않는다', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      db.insert(entry('src', '아직 시간 안 된 루프', now));
      db.updateLoopAt('src', now.add(const Duration(hours: 1)));
      expect(db.settleExpiredLoops(), 0);
      expect(db.byId('src')!.loopDone, isFalse);
    });

    test('중지하면 더 이상 발화하지 않는다', () {
      final now = DateTime.now();
      db.insert(entry('src', '그만', now));
      final rule = _rule(
          source: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          next: now.subtract(const Duration(minutes: 5)),
          createdAt: now);
      db.insertRepeatRule(rule);

      db.stopRepeat(rule.id);
      expect(db.settleRepeats(), 0);
      expect(db.activeRepeatRules(), isEmpty);
      final stopped = db.repeatRuleById(rule.id)!;
      expect(stopped.active, isFalse);
      expect(stopped.stoppedAt, isNotNull);
      expect(stopped.fireCount, 0); // 기록은 남는다
    });

    test('원본 로그를 삭제하면 그 원본의 반복도 멈춘다', () {
      final now = DateTime.now();
      db.insert(entry('src', '지워질 원본', now));
      db.insertRepeatRule(_rule(
          source: 'src',
          kind: RepeatKind.daily,
          next: now.add(const Duration(days: 1)),
          timeOfDay: '09:00',
          createdAt: now));
      expect(db.activeRepeatForSource('src'), isNotNull);

      db.delete('src');
      expect(db.activeRepeatForSource('src'), isNull);
      expect(db.activeRepeatRules(), isEmpty);
    });
  });

  group('망각곡선 카운트', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_curve_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    LogEntry entry(String id, String content, DateTime at) => LogEntry(
          id: id, content: content, createdAt: at, originalCreatedAt: at,
        );

    test('단발 루프 발화마다 원본 카운트가 올라가고 포크는 이어받는다', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch);
      db.insert(entry('src', '망각곡선', now));

      // 1회차 발화 — 원본 1, 포크 1로 태어난다.
      db.updateLoopAt('src', now.subtract(const Duration(minutes: 10)));
      expect(db.settleExpiredLoops(), 1);
      expect(db.byId('src')!.loopCount, 1);
      final fork1 = db
          .window(limit: 50)
          .firstWhere((l) => l.id != 'src' && l.parentId == 'src');
      expect(fork1.loopCount, 1);

      // 2회차 — 다시 걸고 다시 발화하면 원본 2. 포크는 태어난 시점의 카운트.
      db.updateLoopAt('src', now.subtract(const Duration(minutes: 5)));
      expect(db.settleExpiredLoops(), 1);
      expect(db.byId('src')!.loopCount, 2);
      final forks = db
          .window(limit: 50)
          .where((l) => l.id != 'src' && l.parentId == 'src')
          .toList();
      expect(forks, hasLength(2));
      expect(forks.map((f) => f.loopCount).toSet(), {1, 2});
    });

    test('발화 전 이어쓰기로 소비해도 카운트는 올라간다', () {
      final now = DateTime.now();
      db.insert(entry('src', '기다리지 않고 돌아옴', now));
      db.updateLoopAt('src', now.add(const Duration(hours: 1)));
      db.markLoopDone('src');
      db.incrementLoopCount('src');
      expect(db.byId('src')!.loopCount, 1);
    });

    test('사다리 인덱스 — N번 돌아온 로그는 N번째 간격, 끝에선 유지', () {
      expect(LoopSheet.curveIndexFor(0), 0);
      expect(LoopSheet.curveIndexFor(1), 1);
      expect(LoopSheet.curveIndexFor(2), 2);
      expect(LoopSheet.curveIndexFor(4), 4);
      expect(LoopSheet.curveIndexFor(7), 4); // 1달에서 유지
      expect(LoopSheet.curveIndexFor(-1), 0); // 방어
    });
  });
}

RepeatRule _rule({
  String source = 'src',
  required RepeatKind kind,
  int? everyN,
  String? timeOfDay,
  required DateTime next,
  DateTime? createdAt,
  String id = 'r1',
}) =>
    RepeatRule(
      id: id,
      sourceLogId: source,
      kind: kind,
      everyN: everyN,
      timeOfDay: timeOfDay,
      nextFireAt: next,
      createdAt: createdAt ?? DateTime.now(),
    );
