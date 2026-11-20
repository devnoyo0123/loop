import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/widgets/log_card.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  LogEntry entry(String id, String content, DateTime at) =>
      LogEntry(id: id, content: content, createdAt: at, originalCreatedAt: at);

  Widget host(void Function(LogMenuAction) onAction, LogEntry log) =>
      MaterialApp(
        locale: const Locale('ko'), // 위젯 테스트 기본 로케일은 en — ko 고정
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [LogCard(log: log, onAction: onAction)],
          ),
        ),
      );

  testWidgets('본문 상세에 [Loop 걸기] 버튼이 있다 — ⋯ 메뉴 없이도 루프를 발견한다', (tester) async {
    final actions = <LogMenuAction>[];
    await tester.pumpWidget(
      host(actions.add, entry('a', '상세를 펼쳐볼 로그', DateTime(2026, 10, 30, 9))),
    );

    // 접힌 상태엔 버튼이 없다 — 타임라인 스크롤은 순수하게.
    expect(find.text(l10n.loopArm), findsNothing);

    // 본문 탭 = 상세 펼침 → 루프 버튼이 보인다.
    await tester.tap(find.text('상세를 펼쳐볼 로그'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.loopArm), findsOneWidget);

    // 탭하면 ⋯ 메뉴의 루프와 같은 액션으로 Loop 시트가 열린다.
    await tester.tap(find.text(l10n.loopArm));
    await tester.pumpAndSettle();
    expect(actions, [LogMenuAction.loop]);
  });

  testWidgets('빈 루프 도착 로그는 탭 자체가 루프 시트로 — 버튼 없음', (tester) async {
    final actions = <LogMenuAction>[];
    final arrived = LogEntry(
      id: 'f1',
      content: '',
      createdAt: DateTime(2026, 10, 30, 9),
      originalCreatedAt: DateTime(2026, 10, 30, 9),
      parentId: 'a',
    );
    await tester.pumpWidget(host(actions.add, arrived));
    // 빈 도착 로그는 미리보기만 — 상세 펼침이 아니라 바로 액션 시트.
    expect(find.text(l10n.loopArm), findsNothing);
  });

  group('반복 중지 — 어디서든 (v10.1)', () {
    LogEntry fork() => LogEntry(
      id: 'f1',
      content: '',
      createdAt: DateTime(2026, 10, 30, 9),
      originalCreatedAt: DateTime(2026, 10, 30, 9),
      parentId: 'a',
      repeatRuleId: 'r1',
    );

    testWidgets('발화 포크에 살아있는 반복이 있으면 ⋯ 메뉴에 [루프 중지]', (tester) async {
      final actions = <LogMenuAction>[];
      final rule = RepeatRule(
        id: 'r1',
        sourceLogId: 'a',
        kind: RepeatKind.daily,
        timeOfDay: '21:00',
        nextFireAt: DateTime(2026, 10, 31, 21),
        createdAt: DateTime(2026, 10, 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                LogCard(
                  log: fork(),
                  onAction: actions.add,
                  activeRepeatAsFork: rule,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text(l10n.loopStop), findsOneWidget);

      await tester.tap(find.text(l10n.loopStop));
      await tester.pumpAndSettle();
      expect(actions, [LogMenuAction.stopRepeat]);
    });

    testWidgets('반복이 끝났으면 [루프 중지] 항목이 없다', (tester) async {
      final actions = <LogMenuAction>[];
      final ended = RepeatRule(
        id: 'r1',
        sourceLogId: 'a',
        kind: RepeatKind.daily,
        timeOfDay: '21:00',
        nextFireAt: DateTime(2026, 10, 31, 21),
        createdAt: DateTime(2026, 10, 30),
        active: false,
        stoppedAt: DateTime(2026, 10, 30, 20),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                LogCard(
                  log: fork(),
                  onAction: actions.add,
                  activeRepeatAsFork: ended,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text(l10n.loopStop), findsNothing);
    });
  });

  group('동영상 프리뷰 — 유튜브 스타일 (v10.2)', () {
    testWidgets('썸네일이 있으면 카드에 재생 오버레이 프리뷰, 탭하면 재생 액션', (tester) async {
      final actions = <LogMenuAction>[];
      final videoLog = LogEntry(
        id: 'v',
        content: '', // 동영상만 찍은 로그 — 내용 없어도 저장된다
        createdAt: DateTime(2026, 10, 30, 10),
        originalCreatedAt: DateTime(2026, 10, 30, 10),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                LogCard(
                  log: videoLog,
                  onAction: actions.add,
                  videoCount: 1,
                  videoThumbLoader: () => Uint8List.fromList([1, 2, 3]),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 프리뷰의 재생 아이콘 — 유튜브 스타일
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      // 프리뷰 탭 = 바로 재생 액션
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();
      expect(actions, [LogMenuAction.openVideo]);
    });

    testWidgets('썸네일이 없으면 아이콘 행으로 폴백', (tester) async {
      final actions = <LogMenuAction>[];
      final videoLog = LogEntry(
        id: 'v',
        content: '',
        createdAt: DateTime(2026, 10, 30, 10),
        originalCreatedAt: DateTime(2026, 10, 30, 10),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                LogCard(
                  log: videoLog,
                  onAction: actions.add,
                  videoCount: 1,
                  videoThumbLoader: () => null, // 썸네일 없음
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(lookupAppLocalizations(const Locale('ko')).videoOpenRow),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.play_circle_filled), findsNothing);
    });
  });

  group('Loop 공유 메뉴 — 모든 기록에서 (2026-11-01)', () {
    Future<void> openMenu(WidgetTester tester, LogEntry log, List<LogMenuAction> actions) async {
      await tester.pumpWidget(host(actions.add, log));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
    }

    testWidgets('루프 없는 혼자인 기록에도 [Loop 공유]가 있다', (tester) async {
      final actions = <LogMenuAction>[];
      await openMenu(tester, entry('a', '그냥 메모', DateTime(2026, 11, 1, 9)), actions);
      expect(find.text(l10n.shareChainAction), findsOneWidget);
      await tester.tap(find.text(l10n.shareChainAction));
      await tester.pumpAndSettle();
      expect(actions, [LogMenuAction.share]);
    });

    testWidgets('이어진 기록(포크)에도 그대로 있다', (tester) async {
      final actions = <LogMenuAction>[];
      final child = LogEntry(
        id: 'c',
        content: '이어 쓰기',
        createdAt: DateTime(2026, 11, 1, 10),
        originalCreatedAt: DateTime(2026, 11, 1, 10),
        parentId: 'a',
        rootId: 'a',
        depth: 1,
        path: 'a/c',
      );
      await openMenu(tester, child, actions);
      expect(find.text(l10n.shareChainAction), findsOneWidget);
    });

    test('이름은 "Loop 공유"', () {
      expect(l10n.shareChainAction, 'Loop 공유');
    });
  });
}
