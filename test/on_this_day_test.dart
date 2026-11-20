import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/utils/on_this_day.dart';

LogEntry entry(String id, String content, DateTime at) =>
    LogEntry(id: id, content: content, createdAt: at, originalCreatedAt: at);

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  group('onThisDayDatesFor — 1주·1개월·1년 전 날짜', () {
    test('보통 날짜', () {
      final d = onThisDayDatesFor(DateTime(2026, 10, 25));
      expect(d.week, DateTime(2026, 10, 18));
      expect(d.month, DateTime(2026, 9, 25));
      expect(d.year, DateTime(2025, 10, 25));
    });

    test('말일 클램프 — 3월 31일의 1개월 전은 2월 28일', () {
      expect(
        onThisDayDatesFor(DateTime(2026, 3, 31)).month,
        DateTime(2026, 2, 28),
      );
    });

    test('2월 29일의 1년 전은 2월 28일', () {
      expect(
        onThisDayDatesFor(DateTime(2028, 2, 29)).year,
        DateTime(2027, 2, 28),
      );
    });

    test('1월의 1개월 전은 전년 12월', () {
      expect(
        onThisDayDatesFor(DateTime(2026, 1, 15)).month,
        DateTime(2025, 12, 15),
      );
    });
  });

  group('selectOnThisDay — 재회 고르기', () {
    test('1년 전 우선 — 세 거리 다 있으면 가장 먼 것', () {
      final pick = selectOnThisDay(
        weekAgo: [entry('w1', '주 전', DateTime(2026, 10, 18, 8))],
        monthAgo: [entry('m1', '월 전', DateTime(2026, 9, 25, 8))],
        yearAgo: [entry('y1', '년 전', DateTime(2025, 10, 25, 8))],
      );
      expect(pick!.log.id, 'y1');
      expect(pick.distance, OnThisDayDistance.year);
    });

    test('1년 전이 없으면 1개월 전', () {
      final pick = selectOnThisDay(
        weekAgo: [entry('w1', '주 전', DateTime(2026, 10, 18, 8))],
        monthAgo: [entry('m1', '월 전', DateTime(2026, 9, 25, 8))],
      );
      expect(pick!.log.id, 'm1');
      expect(pick.distance, OnThisDayDistance.month);
    });

    test('빈 포크는 건너뛰고 그날 첫 "내용 있는" 기록을 고른다', () {
      final pick = selectOnThisDay(
        weekAgo: [
          entry('empty', '', DateTime(2026, 10, 18, 7)), // 반복 발화 빈 포크
          entry('blank', '  ', DateTime(2026, 10, 18, 7, 30)),
          entry('first', '첫 생각', DateTime(2026, 10, 18, 8)),
          entry('second', '두번째', DateTime(2026, 10, 18, 9)),
        ],
      );
      expect(pick!.log.id, 'first');
      expect(pick.distance, OnThisDayDistance.week);
    });

    test('후보가 전부 비어 있으면 null', () {
      expect(selectOnThisDay(), isNull);
      expect(
        selectOnThisDay(weekAgo: [entry('e', '', DateTime(2026, 10, 18))]),
        isNull,
      );
    });

    test('알림 본문 — "미리보기 · N년 전 오늘"', () {
      final pick = OnThisDayPick(
        log: entry('y1', '새벽에 떠오른 생각', DateTime(2025, 10, 25)),
        distance: OnThisDayDistance.year,
      );
      expect(
        pick.notificationBody(l10n),
        '새벽에 떠오른 생각 · ${l10n.onThisDayYearAgo}',
      );
    });

    test('미리보기 — 48자(rune) 넘으면 자르고 …', () {
      expect(OnThisDayPick.previewOf('짧은 글'), '짧은 글');
      final long = '아' * 60;
      final preview = OnThisDayPick.previewOf(long);
      expect(preview.length, 49); // 48자 + …
      expect(preview.endsWith('…'), isTrue);
      // 이모지가 경계에서 깨지지 않는다
      final emoji = '🌊' * 60;
      expect(OnThisDayPick.previewOf(emoji).runes.length, 49);
    });
  });

  group('LoopDb.logsOnDay — 로컬 자정 경계', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('on_this_day_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('그날 00:00은 포함, 다음 날 00:00은 제외 — 시간 순 정렬', () {
      db.insert(entry('a', '아침', DateTime(2026, 10, 18, 0, 0)));
      db.insert(entry('b', '밤', DateTime(2026, 10, 18, 23, 59)));
      db.insert(entry('c', '다음날 자정', DateTime(2026, 10, 19, 0, 0)));
      db.insert(entry('d', '전날 끝', DateTime(2026, 10, 17, 23, 59)));

      final logs = db.logsOnDay(DateTime(2026, 10, 18));
      expect(logs.map((l) => l.id).toList(), ['a', 'b']);
    });
  });
}
