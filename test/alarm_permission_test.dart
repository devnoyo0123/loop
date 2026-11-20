import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/services/alarm_permission.dart';
import 'package:loop/widgets/alarm_permission_prompt.dart';

class FakeAlarmPlatform implements AlarmPermissionPlatform {
  bool allowed = false;
  int opened = 0;
  int checks = 0;

  @override
  Future<bool> fullScreenAllowed() async {
    checks++;
    return allowed;
  }

  @override
  Future<void> openFullScreenSettings() async => opened++;
}

/// 알람 권한 점검 — 전체 화면 알림이 막혀 있으면 알람이 소리만 나고 화면엔
/// 안 뜬다(2026-11-01 실기기). 다가오는 알람이 있을 때만, 유예를 지켜 묻는다.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  late Directory tmp;
  late LoopDb db;
  late FakeAlarmPlatform platform;
  late DateTime now;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('alarm_permission_test');
    db = LoopDb(tmp)..open();
    platform = FakeAlarmPlatform();
    now = DateTime.now();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  AlarmPermissionGuard guard() => AlarmPermissionGuard(
    db: db,
    platform: platform,
    clock: () => now,
  );

  void addLoop({required bool alarm, Duration inFuture = const Duration(hours: 1)}) {
    final id = db.newId();
    final at = DateTime.now();
    db.insert(
      LogEntry(
        id: id,
        content: '물 마시기',
        createdAt: at,
        originalCreatedAt: at,
        loopAt: at.add(inFuture),
        loopAlarm: alarm,
      ),
    );
  }

  group('AlarmPermissionGuard', () {
    test('다가오는 알람이 없으면 묻지 않는다 (권한도 확인 안 함)', () async {
      addLoop(alarm: false); // 일반 알림 루프
      expect(await guard().shouldPrompt(), isFalse);
      expect(platform.checks, 0);
    });

    test('지난 알람만 있으면 묻지 않는다', () async {
      addLoop(alarm: true, inFuture: const Duration(hours: -1));
      expect(await guard().shouldPrompt(), isFalse);
    });

    test('다가오는 알람 + 권한 없음 → 묻는다', () async {
      addLoop(alarm: true);
      expect(await guard().shouldPrompt(), isTrue);
    });

    test('권한이 있으면 묻지 않는다', () async {
      addLoop(alarm: true);
      platform.allowed = true;
      expect(await guard().shouldPrompt(), isFalse);
    });

    test('[나중에] 뒤엔 6시간 동안 조용 — 지나면 다시', () async {
      addLoop(alarm: true);
      final g = guard()..dismiss();
      now = now.add(const Duration(hours: 5));
      expect(await g.shouldPrompt(), isFalse);
      now = now.add(const Duration(hours: 2));
      expect(await g.shouldPrompt(), isTrue);
    });

    test('알람을 방금 걸었으면(force) 유예를 무시한다', () async {
      addLoop(alarm: true);
      final g = guard()..dismiss();
      expect(await g.shouldPrompt(force: true), isTrue);
    });

    test('[설정 열기]는 유예를 지우고 설정으로 보낸다', () async {
      addLoop(alarm: true);
      final g = guard()..dismiss();
      await g.openSettings();
      expect(platform.opened, 1);
      expect(await g.shouldPrompt(), isTrue); // 아직 허용 안 했으면 다음 점검에서 다시
    });

    test('곧 울릴 참(발화 체험)이면 등록된 알람이 없어도 묻는다', () async {
      final g = guard();
      expect(await g.shouldPrompt(force: true), isFalse); // 기본은 알람이 있어야
      expect(await g.shouldPrompt(force: true, requirePending: false), isTrue);
      platform.allowed = true;
      expect(await g.shouldPrompt(force: true, requirePending: false), isFalse);
    });

    test('안내가 떠 있는 동안엔 겹쳐 묻지 않는다 (시작·복귀 동시)', () async {
      addLoop(alarm: true);
      final g = guard()..markShowing(true);
      expect(await g.shouldPrompt(), isFalse);
    });
  });

  group('AlarmPermissionPrompt', () {
    Future<void> pump(WidgetTester tester, AlarmPermissionGuard g, {bool force = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => AlarmPermissionPrompt.maybeShow(context, g, force: force),
              child: const Text('check'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();
    }

    testWidgets('조건이 맞으면 안내 → [설정 열기]면 설정으로', (tester) async {
      addLoop(alarm: true);
      final g = guard();
      await pump(tester, g);
      expect(find.text(l10n.alarmPermTitle), findsOneWidget);
      expect(find.text(l10n.alarmPermBody), findsOneWidget);
      await tester.tap(find.text(l10n.openSettings));
      await tester.pumpAndSettle();
      expect(platform.opened, 1);
      expect(find.text(l10n.alarmPermTitle), findsNothing);
    });

    testWidgets('[나중에]면 유예가 시작된다', (tester) async {
      addLoop(alarm: true);
      final g = guard();
      await pump(tester, g);
      await tester.tap(find.text(l10n.laterAction));
      await tester.pumpAndSettle();
      expect(platform.opened, 0);
      expect(db.getSetting(AlarmPermissionGuard.dismissedKey), isNotEmpty);
      expect(await g.shouldPrompt(), isFalse);
    });

    testWidgets('권한이 있으면 아무것도 안 뜬다', (tester) async {
      addLoop(alarm: true);
      platform.allowed = true;
      await pump(tester, guard());
      expect(find.text(l10n.alarmPermTitle), findsNothing);
    });
  });
}
