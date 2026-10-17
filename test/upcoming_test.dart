import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/screens/upcoming_sheet.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  late Directory tmp;
  late LoopDb db;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_upcoming_test');
    db = LoopDb(tmp)..open();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  LogEntry entry(String id, String content, DateTime at, {DateTime? loopAt}) =>
      LogEntry(
          id: id, content: content, createdAt: at, originalCreatedAt: at,
          loopAt: loopAt);

  test('창 안의 단발+매일+평일+고빈도를 시간순으로 한 장에 모은다', () {
    final now = DateTime(2026, 10, 15, 12, 0); // 목요일
    db.insert(entry(
        'once1', '한 번 루프', DateTime(2026, 10, 15, 11),
        loopAt: DateTime(2026, 10, 16, 9)));
    db.insert(entry('daily-src', '매일 읽기', DateTime(2026, 10, 14)));
    db.insertRepeatRule(RepeatRule(
      id: 'r-daily',
      sourceLogId: 'daily-src',
      kind: RepeatKind.daily,
      timeOfDay: '08:00',
      nextFireAt: DateTime(2026, 10, 16, 8),
      createdAt: DateTime(2026, 10, 14),
    ));
    db.insert(entry('wk-src', '평일 스트레칭', DateTime(2026, 10, 14)));
    db.insertRepeatRule(RepeatRule(
      id: 'r-wk',
      sourceLogId: 'wk-src',
      kind: RepeatKind.weekday,
      timeOfDay: '19:00',
      // 10/16(금) 다음은 주말을 건너뛴 10/19(월).
      nextFireAt: DateTime(2026, 10, 16, 19),
      createdAt: DateTime(2026, 10, 14),
    ));
    db.insert(entry('fast-src', '10분 돌아보기', DateTime(2026, 10, 14)));
    db.insertRepeatRule(RepeatRule(
      id: 'r-fast',
      sourceLogId: 'fast-src',
      kind: RepeatKind.minutes,
      everyN: 10,
      nextFireAt: now.add(const Duration(minutes: 10)),
      createdAt: DateTime(2026, 10, 14),
    ));

    final items = UpcomingSheet.itemsFor(db, l10n, now: now);

    // 매일 08:00 — 창 안 7일치 매 발화.
    final daily = items.where((i) => i.logId == 'daily-src').toList();
    expect(daily, hasLength(7));
    expect(daily.first.at, DateTime(2026, 10, 16, 8));
    expect(daily.last.at, DateTime(2026, 10, 22, 8));

    // 평일 19:00 — 10/16(금) 다음엔 주말을 건너뛴 10/19(월).
    // 창은 10/22 12:00까지라 10/22 19:00 발화는 다음 주에 보인다.
    final weekday = items.where((i) => i.logId == 'wk-src').toList();
    expect(weekday.map((i) => i.at).toList(), [
      DateTime(2026, 10, 16, 19),
      DateTime(2026, 10, 19, 19),
      DateTime(2026, 10, 20, 19),
      DateTime(2026, 10, 21, 19),
    ]);
    expect(weekday.first.ruleLabel, '평일 19:00');
    expect(weekday.first.repeated, isTrue);

    // 고빈도(10분) 반복 — 다음 발화 하나만.
    final fast = items.where((i) => i.logId == 'fast-src').toList();
    expect(fast, hasLength(1));

    // 단발 — 한 번 라벨로.
    final once = items.where((i) => i.logId == 'once1').toList();
    expect(once, hasLength(1));
    expect(once.first.ruleLabel, l10n.loopModeOnce);
    expect(once.first.repeated, isFalse);
    expect(once.first.title, '한 번 루프');

    // 전체는 시간순.
    final times = items.map((i) => i.at).toList();
    final sorted = [...times]..sort();
    expect(times, sorted);
  });

  test('창 안에 아무 것도 없으면 빈 목록', () {
    final now = DateTime(2026, 10, 15, 12, 0);
    expect(UpcomingSheet.itemsFor(db, l10n, now: now), isEmpty);
  });
}
