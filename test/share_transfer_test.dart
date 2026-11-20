import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/screens/incoming_share_notice.dart';
import 'package:loop/screens/settings_sheet.dart';
import 'package:loop/screens/share_sheet.dart';
import 'package:loop/services/image_store.dart';
import 'package:loop/services/nearby_share.dart';
import 'package:loop/services/nearby_transport.dart';
import 'package:loop/services/share_files.dart';
import 'package:loop/services/video_store.dart';

import 'support/fake_nearby.dart';

/// 전송 화면·받기 스위치 — 가짜 전송 계층으로 화면 흐름을 검증.
/// 실제 BLE/Wi-Fi Direct는 실기기 2대 단계에서.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  late Directory tmp;
  late FakeTransport t;
  late FakeSharePlatform p;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('share_transfer_test');
    t = FakeTransport();
    p = FakeSharePlatform(granted: true);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Widget app(Widget home) => MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  group('ShareTransferScreen', () {
    late File file;

    setUp(() {
      file = File('${tmp.path}/chain.looplog')..writeAsStringSync('{}\n');
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ShareTransferScreen(
            file: file,
            myName: '민수',
            stats: ShareChainStats(2, 0, 0, 1),
            transport: t,
            platform: p,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('기기가 없을 땐 받는 쪽 안내를 보여준다', (tester) async {
      await pumpScreen(tester);
      expect(find.text(l10n.shareSearching), findsOneWidget);
      expect(find.text(l10n.shareWaitingReceiver), findsOneWidget);
      expect(t.discovering, isTrue);
    });

    testWidgets('여러 대가 보이면 목록으로 — 탭한 기기로만 보낸다', (tester) async {
      await pumpScreen(tester);
      t.find('e1', '지민');
      t.find('e2', '서연');
      await tester.pump();

      expect(find.text('지민'), findsOneWidget);
      expect(find.text('서연'), findsOneWidget);
      expect(find.text(l10n.shareTapToSend), findsNWidgets(2));
      expect(t.calls.where((c) => c.startsWith('connect')), isEmpty);

      await tester.tap(find.text('서연'));
      await tester.pump();
      expect(t.calls, contains('connect:e2'));
      expect(t.calls, isNot(contains('connect:e1')));
      expect(find.text(l10n.shareDeviceConnected('서연')), findsWidgets);

      t.progress(7, 50, 100);
      await tester.pump();
      expect(find.text('50%'), findsOneWidget);

      t.succeed(7);
      t.peerDisconnects();
      await tester.pump();
      expect(find.text(l10n.shareSent), findsWidgets);
    });

    testWidgets('한 대만 보여도 자동 연결하지 않는다', (tester) async {
      await pumpScreen(tester);
      t.find('e1', '지민');
      await tester.pump();
      expect(find.text('지민'), findsOneWidget);
      expect(t.calls.where((c) => c.startsWith('connect')), isEmpty);
    });

    testWidgets('권한 거부 → 이유 안내 + 다시 찾기', (tester) async {
      p
        ..granted = false
        ..grantOnRequest = false;
      await pumpScreen(tester);
      expect(find.text(l10n.shareSendFail), findsOneWidget);
      expect(find.text(l10n.sharePermBody), findsOneWidget);
      expect(find.text(l10n.shareRetry), findsOneWidget);

      p.grantOnRequest = true;
      await tester.tap(find.text(l10n.shareRetry));
      await tester.pump();
      expect(find.text(l10n.shareSearching), findsOneWidget);
    });

    testWidgets('취소하면 탐색을 멈추고 화면을 닫는다, 임시 파일도 지운다', (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ShareTransferScreen(
                    file: file,
                    myName: '민수',
                    stats: ShareChainStats(1, 0, 0, 0),
                    transport: t,
                    platform: p,
                  ),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      // 탐색 중엔 진행 표시가 계속 돈다 — pumpAndSettle은 가짜 시간을 10분까지
      // 흘려 탐색 시간 초과를 일으키므로 전환 시간만큼만 민다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(t.discovering, isTrue);

      await tester.tap(find.text(l10n.cancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(t.discovering, isFalse);
      expect(find.text('go'), findsOneWidget);
      expect(file.existsSync(), isFalse);
    });
  });

  group('설정 › 가까운 기기에서 받기', () {
    late LoopDb db;

    setUp(() {
      db = LoopDb(tmp)..open();
    });

    tearDown(() => db.close());

    Future<ShareReceiver> pumpSettings(WidgetTester tester) async {
      final receiver = ShareReceiver(transport: t, platform: p);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: SettingsSheet(
                db: db,
                videos: VideoStore(tmp),
                images: ImageStore(tmp),
                receiver: receiver,
                shareDir: () async => tmp,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return receiver;
    }

    /// 실제 파일 IO는 가짜 시간 영역에서 await 한 단계씩만 나아간다 —
    /// 실제 IO와 pump를 번갈아 여러 번 흘린다.
    Future<void> settleIo(WidgetTester tester) async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump();
      }
    }

    Switch receiveSwitch(WidgetTester tester) =>
        tester.widget<Switch>(find.byKey(const ValueKey('share-receive-switch')));

    testWidgets('켜면 그때 권한을 요청하고 대기 시작', (tester) async {
      p.granted = false;
      final r = await pumpSettings(tester);
      expect(find.text(l10n.receiveSetting), findsOneWidget);
      expect(receiveSwitch(tester).value, isFalse);
      expect(p.requestCount, 0); // 시트를 연 것만으로는 묻지 않는다

      final sw = find.byKey(const ValueKey('share-receive-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pump();
      expect(p.requestCount, 1);
      expect(r.active, isTrue);
      expect(t.advertising, isTrue);
      expect(receiveSwitch(tester).value, isTrue);
    });

    testWidgets('권한 거부면 꺼진 채로 이유를 알린다', (tester) async {
      p
        ..granted = false
        ..grantOnRequest = false;
      await pumpSettings(tester);
      final sw = find.byKey(const ValueKey('share-receive-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pump();
      expect(receiveSwitch(tester).value, isFalse);
      expect(find.text(l10n.sharePermBody), findsOneWidget);
    });

    testWidgets('끄면 광고를 멈추고 꺼짐을 기억한다', (tester) async {
      final r = await pumpSettings(tester);
      await r.startIfAllowed(db);
      await tester.pump();
      expect(receiveSwitch(tester).value, isTrue);

      final sw = find.byKey(const ValueKey('share-receive-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pump();
      expect(t.advertising, isFalse);
      expect(ShareReceiver.userDisabled(db), isTrue);
    });

    testWidgets('공유 임시 파일 정리 — 크기를 보여주고, 확인하면 쓰는 중만 남기고 지운다', (tester) async {
      final share = Directory('${tmp.path}/share')..createSync();
      final partial = File('${share.path}/in-E1-1.part')
        ..writeAsBytesSync(List.filled(300 * 1024, 1));
      final busy = File('${share.path}/in-E2-2.part')..writeAsBytesSync([1]);
      ShareTempFiles.hold(busy.path);
      addTearDown(() => ShareTempFiles.release(busy.path));

      await pumpSettings(tester);
      await settleIo(tester);
      expect(find.text(l10n.shareCleanDesc('300 KB')), findsOneWidget);

      final row = find.byKey(const ValueKey('share-clean-row'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text(l10n.shareCleanConfirm), findsOneWidget);
      await tester.tap(find.text(l10n.shareCleanAction));
      await settleIo(tester);

      expect(partial.existsSync(), isFalse);
      expect(busy.existsSync(), isTrue);
      expect(find.text(l10n.shareCleanDone('300 KB')), findsOneWidget);
      expect(find.text(l10n.shareCleanEmpty), findsOneWidget);
    });

    testWidgets('정리할 게 없으면 행이 비활성', (tester) async {
      await pumpSettings(tester);
      await settleIo(tester);
      expect(find.text(l10n.shareCleanEmpty), findsOneWidget);
      final row = find.byKey(const ValueKey('share-clean-row'));
      expect(tester.widget<GestureDetector>(row).onTap, isNull);
    });

    testWidgets('미지원 플랫폼이면 행 자체가 없다', (tester) async {
      p.supported = false;
      await pumpSettings(tester);
      expect(find.text(l10n.receiveSetting), findsNothing);
    });
  });

  group('전송 화면 — 속도·느림 안내·멈춤 (A·B)', () {
    late File file;
    late DateTime now;
    const mb = 1024 * 1024;

    setUp(() {
      file = File('${tmp.path}/chain.looplog')..writeAsStringSync('{}\n');
      now = DateTime(2026, 11, 1, 12);
    });

    Future<void> pumpSending(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          ShareTransferScreen(
            file: file,
            myName: '민수',
            stats: ShareChainStats(1, 0, 1, 0),
            transport: t,
            platform: p,
            clock: () => now,
          ),
        ),
      );
      await tester.pump();
      t.find('e1', '지민');
      await tester.pump();
      await tester.tap(find.text('지민'));
      await tester.pump();
    }

    Future<void> at(WidgetTester tester, int sec, int bytes, int total) async {
      now = DateTime(2026, 11, 1, 12).add(Duration(seconds: sec));
      t.progress(7, bytes, total);
      await tester.pump();
    }

    testWidgets('보낸 양·속도·남은 시간을 보여준다', (tester) async {
      await pumpSending(tester);
      await at(tester, 1, 2 * mb, 10 * mb);
      await at(tester, 2, 4 * mb, 10 * mb);
      expect(
        find.text(
          '${l10n.shareProgressDetail('4.0 MB', '10.0 MB', '2.0 MB')} · '
          '${l10n.shareEtaSeconds(5)}',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('share-slow-hint')), findsNothing);
    });

    testWidgets('블루투스 속도면 Wi-Fi 안내를 띄운다', (tester) async {
      await pumpSending(tester);
      for (var sec = 1; sec <= 5; sec++) {
        await at(tester, sec, sec * 200 * 1024, 50 * mb);
      }
      expect(find.byKey(const ValueKey('share-slow-hint')), findsOneWidget);
      expect(find.text(l10n.shareSlowHint), findsOneWidget);
    });

    testWidgets('진행이 60초 멈추면 실패 + 이유 안내 + 다시 찾기', (tester) async {
      await pumpSending(tester);
      await at(tester, 1, 1 * mb, 10 * mb);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text(l10n.shareSendFail), findsWidgets);
      expect(find.text(l10n.shareStalled), findsOneWidget);
      expect(find.text(l10n.shareRetry), findsOneWidget);
      expect(t.disconnected, ['e1']);
    });
  });

  group('남은 시간 표기', () {
    test('1분 미만은 5초 단위 올림, 이상은 분 올림', () {
      expect(formatShareEta(l10n, const Duration(seconds: 1)), l10n.shareEtaSeconds(5));
      expect(formatShareEta(l10n, const Duration(seconds: 42)), l10n.shareEtaSeconds(45));
      expect(formatShareEta(l10n, const Duration(seconds: 60)), l10n.shareEtaMinutes(1));
      expect(formatShareEta(l10n, const Duration(seconds: 61)), l10n.shareEtaMinutes(2));
    });

    test('바이트 표기', () {
      expect(formatShareBytes(500), '1 KB');
      expect(formatShareBytes(300 * 1024), '300 KB');
      expect(formatShareBytes(5 * 1024 * 1024 + 1), '5.0 MB');
    });
  });

  group('받기 시트 — 임시 파일 정리 (D)', () {
    late LoopDb db;

    setUp(() => db = LoopDb(tmp)..open());
    tearDown(() => db.close());

    testWidgets('거절로 닫아도 받은 임시 파일을 지운다', (tester) async {
      final file = File('${tmp.path}/shared-1.looplog')..writeAsStringSync('{}\n');
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ReceiveSheet(db: db, file: file, videos: VideoStore(tmp)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(file.existsSync(), isTrue);

      await tester.tap(find.text(l10n.receiveDecline));
      await tester.pumpAndSettle();
      expect(file.existsSync(), isFalse);
    });

    testWidgets('바깥을 탭해 닫아도 지운다', (tester) async {
      final file = File('${tmp.path}/shared-2.looplog')..writeAsStringSync('{}\n');
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ReceiveSheet(db: db, file: file, videos: VideoStore(tmp)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // 시트 바깥(장벽)
      await tester.pumpAndSettle();
      expect(file.existsSync(), isFalse);
    });
  });

  group('받는 쪽 알림 (C)', () {
    late LoopDb db;
    late ShareReceiver r;
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    setUp(() => db = LoopDb(tmp)..open());
    tearDown(() => db.close());

    Future<void> pumpApp(WidgetTester tester) async {
      r = ShareReceiver(transport: t, platform: p);
      await r.startIfAllowed(db);
      IncomingShareNotice(
        receiver: r,
        messenger: () => messengerKey.currentState,
      ).attach();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
    }

    testWidgets('보내는 중 진행률을 보여주고 완료되면 치운다', (tester) async {
      await pumpApp(tester);
      t.incoming('A', IncomingStatus.started, name: '지민');
      // 크기를 모르는 동안 진행 막대가 계속 돈다 — pumpAndSettle은 가짜 시간을
      // 흘려 받는 쪽 멈춤 감지(60초)를 터뜨리므로 전환 시간만큼만 민다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.receiveIncoming('지민')), findsOneWidget);

      t.incoming('A', IncomingStatus.progress, name: '지민', bytes: 50, total: 100);
      await tester.pump();
      expect(find.text('${l10n.receiveIncoming('지민')} · 50%'), findsOneWidget);

      t.incoming('A', IncomingStatus.completed, name: '지민', total: 100);
      await tester.pumpAndSettle();
      expect(find.textContaining(l10n.receiveIncoming('지민')), findsNothing);
      expect(r.incoming, isNull);
    });

    testWidgets('중단되면 알린다', (tester) async {
      await pumpApp(tester);
      t.incoming('A', IncomingStatus.started, name: '지민');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      t.incoming('A', IncomingStatus.failed, name: '지민');
      await tester.pumpAndSettle();
      expect(find.text(l10n.receiveIncomingFailed('지민')), findsOneWidget);
      expect(find.textContaining(l10n.receiveIncoming('지민')), findsNothing);
      await tester.pump(const Duration(seconds: 5)); // 스낵바 자동 닫힘
      await tester.pumpAndSettle();
      expect(find.text(l10n.receiveIncomingFailed('지민')), findsNothing);
    });
  });
}
