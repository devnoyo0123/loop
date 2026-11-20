import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/screens/stats_sheet.dart';
import 'package:loop/utils/loop_stats.dart';

DateTime day(int y, int m, int d, [int h = 9]) => DateTime(y, m, d, h);
int ms(DateTime t) => t.millisecondsSinceEpoch;

void main() {
  group('LoopStats — 순수 계산 (기기 시간대 기준)', () {
    test('기본 집계 — 총 기록·기록한 날·스트릭', () {
      final now = DateTime(2026, 10, 25, 20); // 일요일
      final stats = LoopStats.fromTimestamps([
        for (final d in [
          day(2026, 10, 25),
          day(2026, 10, 24),
          day(2026, 10, 23),
        ])
          ms(d),
        ms(day(2026, 10, 20)), // 갭 — 여기서 연속이 끊긴다
        ms(day(2026, 10, 20, 22)), // 같은 날 두 번째 기록
      ], now: now);
      expect(stats.totalLogs, 5); // 타임스탬프 5개
      expect(stats.activeDays, 4); // 고유한 날은 4일
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('오늘 안 썼어도 어제까지 이어졌으면 스트릭은 살아 있다', () {
      final now = DateTime(2026, 10, 25, 8);
      final stats = LoopStats.fromTimestamps([
        ms(day(2026, 10, 24)),
        ms(day(2026, 10, 23)),
      ], now: now);
      expect(stats.currentStreak, 2);
      expect(stats.longestStreak, 2);
    });

    test('오늘·어제 모두 없으면 현재 스트릭 0 — 최장은 유지', () {
      final stats = LoopStats.fromTimestamps([
        ms(day(2026, 10, 10)),
        ms(day(2026, 10, 11)),
        ms(day(2026, 10, 12)),
      ], now: DateTime(2026, 10, 25));
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 3);
    });

    test('월 경계·연 경계 연속 판정 — 달력상 전날 비교', () {
      final stats = LoopStats.fromTimestamps([
        ms(DateTime(2026, 12, 31)),
        ms(DateTime(2027, 1, 1)),
        ms(DateTime(2027, 1, 2)),
      ], now: DateTime(2027, 1, 2, 21));
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('빈 입력 — 전부 0, 히트맵은 미래 칸만큼 -1', () {
      final now = DateTime(2026, 10, 21, 15); // 수요일
      final stats = LoopStats.fromTimestamps(const [], now: now);
      expect(stats.totalLogs, 0);
      expect(stats.activeDays, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      // 창은 이번 주를 끝으로 15주 — 시작은 15주 전 월요일(2026-07-13).
      // 오늘(10/21)까지 101칸이 과거(0), 그 뒤 4칸은 미래(-1).
      expect(stats.heatmapStart, DateTime(2026, 7, 13));
      expect(stats.heatmapStart.weekday, DateTime.monday);
      expect(stats.heatmap.sublist(0, 101), everyElement(0));
      expect(stats.heatmap.sublist(101, 105), everyElement(-1));
    });

    test('히트맵 창 정렬 — 항상 월요일 시작, 주 수 × 7칸', () {
      for (final now in [
        DateTime(2026, 10, 25), // 일요일
        DateTime(2026, 10, 19), // 월요일
        DateTime(2026, 10, 31), // 토요일
      ]) {
        final stats = LoopStats.fromTimestamps(
          [ms(now)], // 오늘 하루 기록
          now: now,
          heatmapWeeks: 3,
        );
        expect(stats.heatmap.length, 3 * 7);
        expect(stats.heatmapStart.weekday, DateTime.monday);
        // 오늘 칸 = 마지막 주의 오늘 요일 위치 (첫 주 오프셋 14 + 요일-1).
        // 창 안에 오늘이 있으므로 그 칸은 미래(-1)가 아니라 개수다.
        final todayIdx = 14 + (now.weekday - 1);
        expect(stats.heatmap[todayIdx], 1);
        // 오늘 뒤의 칸들은 전부 미래 표시
        expect(stats.heatmap.sublist(todayIdx + 1), everyElement(-1));
      }
    });

    test('농도 단계 — 0/1~2/3~5/6+', () {
      expect(LoopStats.levelFor(0), 0);
      expect(LoopStats.levelFor(1), 1);
      expect(LoopStats.levelFor(2), 1);
      expect(LoopStats.levelFor(3), 2);
      expect(LoopStats.levelFor(5), 2);
      expect(LoopStats.levelFor(6), 3);
      expect(LoopStats.levelFor(30), 3);
    });
  });

  group('LoopDb 통계 쿼리', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_stats_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    LogEntry log(
      String id,
      String content,
      DateTime at, {
      String? parentId,
      String? rootId,
      int depth = 0,
      int loopCount = 0,
    }) => LogEntry(
      id: id,
      content: content,
      createdAt: at,
      originalCreatedAt: at,
      parentId: parentId,
      rootId: rootId,
      depth: depth,
      loopCount: loopCount,
    );

    test('writtenLogTimestamps — 내용 있는 로그만 (빈 포크 제외)', () {
      db.insert(log('a', '첫 생각', day(2026, 10, 20)));
      db.insert(log('b', '', day(2026, 10, 21))); // 반복 발화 빈 포크
      db.insert(log('c', '   ', day(2026, 10, 22))); // 공백만
      db.insert(log('d', '둘', day(2026, 10, 23)));
      final ts = db.writtenLogTimestamps();
      expect(ts.length, 2);
      expect(ts, contains(ms(day(2026, 10, 20))));
      expect(ts, contains(ms(day(2026, 10, 23))));
    });

    test('loopReturnCount — 체인별 최댓값 합 + 반복 발화 수', () {
      // 사슬1: 원본 loop_count 2, 포크가 이어받은 3 → 체인 복습 3회
      db.insert(log('r1', '원본', day(2026, 10, 1), loopCount: 2));
      db.insert(
        log(
          'f1',
          '이어쓰기',
          day(2026, 10, 2),
          parentId: 'r1',
          rootId: 'r1',
          depth: 1,
          loopCount: 3,
        ),
      );
      // 사슬2: 원본만, 복습 1회
      db.insert(log('r2', '또 다른 생각', day(2026, 10, 3), loopCount: 1));
      // 사슬 없는 단독 로그 — 0
      db.insert(log('solo', '단독', day(2026, 10, 4)));
      // 반복 규칙 5회 발화
      db.insertRepeatRule(
        RepeatRule(
          id: 'rule1',
          sourceLogId: 'r2',
          kind: RepeatKind.minutes,
          everyN: 10,
          nextFireAt: day(2026, 10, 5),
          createdAt: day(2026, 10, 4),
          fireCount: 5,
        ),
      );
      expect(db.loopReturnCount(), 3 + 1 + 5);
    });

    test('topChains — 포크 2개 이상 체인만, 크기 내림차순, 머리는 원본', () {
      db.insert(log('r1', '긴 사슬 원본', day(2026, 10, 1)));
      db.insert(
        log(
          'f1',
          '1',
          day(2026, 10, 2),
          parentId: 'r1',
          rootId: 'r1',
          depth: 1,
        ),
      );
      db.insert(
        log(
          'f2',
          '2',
          day(2026, 10, 3),
          parentId: 'f1',
          rootId: 'r1',
          depth: 2,
        ),
      );
      db.insert(log('r2', '짧은 사슬', day(2026, 10, 4)));
      db.insert(
        log(
          'f3',
          '3',
          day(2026, 10, 5),
          parentId: 'r2',
          rootId: 'r2',
          depth: 1,
        ),
      );
      db.insert(log('solo', '혼자', day(2026, 10, 6)));

      final top = db.topChains();
      expect(top.length, 2); // 단독 로그는 제외
      expect(top[0].chainId, 'r1');
      expect(top[0].count, 3);
      expect(top[0].logId, 'r1'); // 살아있는 원본이 머리
      expect(top[1].chainId, 'r2');
      expect(top[1].count, 2);
    });

    test('topChains — 원본이 지워졌으면 살아있는 최상위 포크가 머리', () {
      db.insert(log('r1', '원본', day(2026, 10, 1)));
      db.insert(
        log(
          'f1',
          '포크1',
          day(2026, 10, 2),
          parentId: 'r1',
          rootId: 'r1',
          depth: 1,
        ),
      );
      db.insert(
        log(
          'f2',
          '포크2',
          day(2026, 10, 3),
          parentId: 'r1',
          rootId: 'r1',
          depth: 1,
        ),
      );
      db.delete('r1');
      final top = db.topChains();
      expect(top.single.count, 2);
      expect(top.single.logId, 'f1'); // 남은 것 중 가장 이른 포크
    });
  });

  group('StatsSheet — 렌더 스모크', () {
    testWidgets('빈 상태 → 데이터 있는 상태까지 크래시 없이 그려진다', (tester) async {
      final tmp = Directory.systemTemp.createTempSync('stats_sheet_test');
      final db = LoopDb(tmp)..open();
      addTearDown(() {
        db.close();
        tmp.deleteSync(recursive: true);
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => StatsPage.show(context, db: db),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // 빈 상태 — 안내 문구
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.text(lookupAppLocalizations(const Locale('en')).statsEmpty),
        findsOneWidget,
      );
      // 페이지는 전체 화면 라우트 — 다음 단계 전에 닫아둔다.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      // 기록 추가 — 숫자·히트맵·사슬까지 전체 경로
      final now = DateTime.now();
      db.insert(
        LogEntry(
          id: 'r1',
          content: '물 마시기',
          createdAt: now,
          originalCreatedAt: now,
        ),
      );
      final yesterday = now.subtract(const Duration(days: 1));
      db.insert(
        LogEntry(
          id: 'f1',
          content: '마셨다',
          createdAt: yesterday,
          originalCreatedAt: yesterday,
          parentId: 'r1',
          rootId: 'r1',
          depth: 1,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.statsTitle), findsOneWidget);
      expect(find.text(l10n.statsTotalLogs), findsOneWidget);
      expect(find.text(l10n.statsTopChains), findsOneWidget);
      expect(find.text(l10n.statsChainLinkings(2)), findsOneWidget);
    });
  });
}
