import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/screens/loop_sheet.dart';

/// "루프는 사슬의 끝에서 이어진다" (v8) — 부착 대상 결정과 반복 체인형.
/// 기획 배경: docs/growth-ideas.md 이후 사용자 논의 (2026-10-30) —
/// 보인 로그가 사슬 중간이면 루프는 기본적으로 그 줄기의 끝에 건다.
void main() {

  LogEntry entry(
    String id,
    String content,
    DateTime at, {
    String? parentId,
    String? rootId,
    int depth = 0,
    String? path,
  }) => LogEntry(
    id: id,
    content: content,
    createdAt: at,
    originalCreatedAt: at,
    parentId: parentId,
    rootId: rootId,
    depth: depth,
    path: path,
  );

  group('LoopDb.latestLeafOf — 사슬이 지금 끝나는 지점', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_leaf_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('하위가 없으면 자기 자신', () {
      db.insert(entry('a', '혼자', DateTime(2026, 10, 1)));
      expect(db.latestLeafOf('a')!.id, 'a');
    });

    test('하위가 있으면 가장 최근 것 — 원본이 아니라 줄기의 끝', () {
      db.insert(entry('a', '원본', DateTime(2026, 10, 1)));
      db.insert(
        entry(
          'b',
          '1번째',
          DateTime(2026, 10, 2),
          parentId: 'a',
          rootId: 'a',
          depth: 1,
          path: 'a/b',
        ),
      );
      db.insert(
        entry(
          'c',
          '2번째',
          DateTime(2026, 10, 3),
          parentId: 'b',
          rootId: 'a',
          depth: 2,
          path: 'a/b/c',
        ),
      );
      expect(db.latestLeafOf('a')!.id, 'c');
      // 중간 로그에서 봐도 그 아래줄기의 끝.
      expect(db.latestLeafOf('b')!.id, 'c');
    });

    test('시간 수정으로 순서가 바뀌면 최신을 따라간다', () {
      db.insert(entry('a', '원본', DateTime(2026, 10, 1)));
      db.insert(
        entry(
          'b',
          '옛날',
          DateTime(2026, 10, 2),
          parentId: 'a',
          rootId: 'a',
          depth: 1,
          path: 'a/b',
        ),
      );
      db.insert(
        entry(
          'c',
          '원래는 나중',
          DateTime(2026, 10, 5),
          parentId: 'a',
          rootId: 'a',
          depth: 1,
          path: 'a/c',
        ),
      );
      // b의 시각을 c보다 나중으로 수정 — 끝은 b가 된다.
      db.updateCreatedAt('b', DateTime(2026, 10, 9));
      expect(db.latestLeafOf('a')!.id, 'b');
    });

    test('없는 로그면 null', () {
      expect(db.latestLeafOf('ghost'), isNull);
    });
  });

  group('settleRepeats — 첫 발화도 사슬의 끝에서', () {
    late Directory tmp;
    late LoopDb db;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('loop_chain_test');
      db = LoopDb(tmp)..open();
    });

    tearDown(() {
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('원본에 이어쓰기가 있으면 발화는 그 끝에 붙는다', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      db.insert(entry('src', '원본', now.subtract(const Duration(days: 3))));
      db.insert(
        entry(
          'cont',
          '어제 이어쓴 것',
          now.subtract(const Duration(days: 1)),
          parentId: 'src',
          rootId: 'src',
          depth: 1,
          path: 'src/cont',
        ),
      );
      db.insertRepeatRule(
        RepeatRule(
          id: 'r1',
          sourceLogId: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          nextFireAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now,
        ),
      );

      expect(db.settleRepeats(), 1);
      final fork = db
          .window(limit: 10)
          .firstWhere((l) => l.repeatRuleId == 'r1');
      // 원본이 아니라 줄기의 끝(cont)에.
      expect(fork.parentId, 'cont');
      expect(fork.rootId, 'src');
      expect(fork.depth, 2);
      expect(fork.path, 'src/cont/${fork.id}');
      // 루프 보기 — 원본 → 이어쓰기 → 발화까지 한 줄.
      expect(db.lineage(fork.id).map((l) => l.id), ['src', 'cont', fork.id]);
    });

    test('이후 정리의 발화도 사슬의 끝(직전 발화)에 이어진다', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      db.insert(entry('src', '원본', now.subtract(const Duration(hours: 1))));
      // 첫 정리 — 발화 1개가 원본에 달린다.
      db.insertRepeatRule(
        RepeatRule(
          id: 'r1',
          sourceLogId: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          nextFireAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now,
        ),
      );
      expect(db.settleRepeats(), 1);
      final f1 = db.window(limit: 10).firstWhere((l) => l.repeatRuleId == 'r1');
      expect(f1.parentId, 'src');

      // 다음 정리(다른 규칙이라도 같은 줄기) — 끝은 이미 f1이므로 거기에.
      db.insertRepeatRule(
        RepeatRule(
          id: 'r2',
          sourceLogId: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          nextFireAt: now.subtract(const Duration(minutes: 2)),
          createdAt: now,
        ),
      );
      expect(db.settleRepeats(), 1);
      final f2 = db.window(limit: 10).firstWhere((l) => l.repeatRuleId == 'r2');
      expect(f2.parentId, f1.id);
      expect(f2.depth, 2);
      expect(f2.path, 'src/${f1.id}/${f2.id}');
      expect(db.lineage(f2.id).map((l) => l.id), ['src', f1.id, f2.id]);
    });

    test('원본과 하위 전부 삭제된 규칙은 조용히 건너뛴다', () {
      final now = DateTime.now();
      db.insert(entry('src', '지워질 것', now));
      db.delete('src');
      // 원본이 사라진 채 남은 규칙(레거리/불완전 삭제)을 흉내 낸다.
      db.insertRepeatRule(
        RepeatRule(
          id: 'r2',
          sourceLogId: 'src',
          kind: RepeatKind.minutes,
          everyN: 10,
          nextFireAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now,
        ),
      );
      expect(db.settleRepeats(), 0); // 고아 발화를 만들지 않는다
    });
  });

  group('LoopSheet — 부착 위치 선택', () {
    // 위젯 테스트의 기본 로케일은 en — 시트 라벨도 en으로 검증한다.
    final en = lookupAppLocalizations(const Locale('en'));
    testWidgets('기본은 사슬의 끝에, "여기서부터"를 고르면 보인 로그에', (tester) async {
      final now = DateTime.now();
      final mid = entry(
        'b',
        '사슬 중간의 오래된 로그',
        now.subtract(const Duration(days: 10)),
        parentId: 'a',
        rootId: 'a',
        depth: 1,
        path: 'a/b',
      );
      final head = entry(
        'c',
        '줄기의 끝',
        now.subtract(const Duration(days: 1)),
        parentId: 'b',
        rootId: 'a',
        depth: 2,
        path: 'a/b/c',
      );

      LoopResult? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await LoopSheet.open(context, log: mid, head: head);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 부착 행 — 기본은 사슬의 끝에서 이어짐을 알려준다.
      expect(find.text(en.loopAttachHeadLabel), findsOneWidget);
      expect(find.text('줄기의 끝'), findsOneWidget); // 끝의 미리보기

      // 그대로 걸기 → 끝(c)에 걸린다. (시트가 길어 버튼까지 스크롤)
      await tester.ensureVisible(find.text(en.loopArm));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.loopArm));
      await tester.pumpAndSettle();
      expect(result, isA<LoopOnce>());
      expect((result as LoopOnce).attachId, 'c');

      // 다시 열어 "여기서부터"로 전환 → 보인 로그(b)에 분기.
      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.loopAttachHereAction));
      await tester.pump();
      expect(find.text(en.loopAttachHereLabel), findsOneWidget);
      await tester.ensureVisible(find.text(en.loopArm));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.loopArm));
      await tester.pumpAndSettle();
      expect((result as LoopOnce).attachId, 'b');
    });

    testWidgets('끝이 곧 보인 로그면 부착 행이 없다', (tester) async {
      final now = DateTime.now();
      final solo = entry('solo', '끝인 로그', now);
      LoopResult? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await LoopSheet.open(context, log: solo);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(en.loopAttachHeadLabel), findsNothing);
      await tester.ensureVisible(find.text(en.loopArm));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.loopArm));
      await tester.pumpAndSettle();
      expect((result as LoopOnce).attachId, 'solo');
    });
  });
}
