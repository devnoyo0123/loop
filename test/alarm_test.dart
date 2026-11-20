import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/design/tokens.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/screens/loop_sheet.dart';
import 'package:loop/services/loop_notifications.dart';

void main() {
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
      final t = DateTime.now();
      db.insert(entry('soft', t));
      db.insert(entry('hard', t, loopAlarm: true));

      expect(db.byId('soft')!.loopAlarm, isFalse);
      expect(db.byId('hard')!.loopAlarm, isTrue);
    });

    test('재예약 시 alarm 지정/미지정 — null이면 기존 플래그 유지', () {
      final t = DateTime.now();
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
      final t = DateTime.now();
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
      final t = DateTime.now();
      db.insert(entry('hard', t, loopAlarm: true));
      final pending = db.pendingOneShotLoops();
      expect(pending.single.id, 'hard');
      expect(pending.single.loopAlarm, isTrue);
    });

    test('스누즈 반영 — 네이티브가 기록한 새 시각을 updateLoopAt(alarm: true)으로', () {
      // 실제 스누즈는 네이티브 AlarmActivity가 AlarmManager로 다시 걸고,
      // 기록은 앱 시작 때 consumePendingSnoozes로 여기에 반영된다.
      final t = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch); // DB는 밀리초까지 저장
      db.insert(entry('x', t, loopAlarm: true));
      final snoozedAt = t.add(const Duration(minutes: 10));
      db.updateLoopAt('x', snoozedAt, alarm: true);

      final log = db.byId('x')!;
      expect(log.loopAt, snoozedAt);
      expect(log.loopAlarm, isTrue);
      expect(db.pendingOneShotLoops().single.id, 'x');
    });
  });

  // 과거 시각 예약 → 즉시 발화 사고의 재발 방지 (2026-10-24 수정).
  // 여기선 Dart 논리만 보증한다 — 네이티브 발화 타이밍(setAlarmClock이 실제로
  // 그 시각에 울리는지)은 실기기 릴리스 빌드로 확인해야 한다.
  group('scheduleLoop — 과거 시각 차단·네이티브 계약', () {
    late List<MethodCall> nativeCalls;
    late List<MethodCall> notifCalls;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      nativeCalls = [];
      notifCalls = [];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('app.loop/browser'),
        (call) async {
          nativeCalls.add(call);
          return true;
        },
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          notifCalls.add(call);
          return null;
        },
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('app.loop/browser'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null,
        );
      });
    });

    test('과거 시각은 알림·알람 어느 경로로도 예약하지 않는다', () async {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      await LoopNotifications.scheduleLoop(
          logId: 'past-alarm', body: 'b', at: past, alarm: true);
      await LoopNotifications.scheduleLoop(
          logId: 'past-notif', body: 'b', at: past, alarm: false);
      expect(nativeCalls, isEmpty);
      expect(notifCalls, isEmpty);
    });

    test('미래 알람은 네이티브에 epoch 밀리초로 건넨다 — 코틀린은 Long으로 읽는다', () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      await LoopNotifications.scheduleLoop(
          logId: 'future', body: 'b', at: at, alarm: true);
      expect(nativeCalls, hasLength(1));
      expect(nativeCalls.single.method, 'scheduleNativeAlarm');
      final args = nativeCalls.single.arguments as Map<Object?, Object?>;
      expect(args['logId'], 'future');
      // 이 값은 int64로 직렬화된다 — 코틀린이 argument<Int>로 읽으면
      // ClassCastException으로 예약이 전부 실패했었다. 계약을 고정한다.
      expect(args['atMs'], at.millisecondsSinceEpoch);
      expect(notifCalls, isEmpty); // 네이티브 성공 → 알림 폴백 없음
    });
  });

  group('LoopOncePicker — 과거 시각 안내·잠금', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      DateTime initial, {
      void Function(({DateTime at, bool asAlarm})? result)? onDone,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final f = LoopOncePicker.show(context, initial: initial);
                  if (onDone != null) f.then(onDone);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // 과거 시각 안내 문구 — 이 시트에서 유일하게 danger 색을 쓰는 텍스트.
    final dangerTexts = find.byWidgetPredicate(
      (w) => w is Text && w.style?.color == LoopColors.danger,
    );

    testWidgets('과거 시각이면 안내가 뜨고 적용 버튼이 잠긴다', (tester) async {
      await pumpSheet(
          tester, DateTime.now().subtract(const Duration(hours: 1)));
      expect(dangerTexts, findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('미래 시각이면 잠금 없이 그 시각 그대로 적용된다', (tester) async {
      final at = DateTime.now().add(const Duration(hours: 1));
      ({DateTime at, bool asAlarm})? result;
      await pumpSheet(tester, at, onDone: (r) => result = r);
      expect(dangerTexts, findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.at, at);
      expect(result!.asAlarm, isFalse);
    });
  });
}
