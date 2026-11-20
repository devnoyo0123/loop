import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/services/nearby_share.dart';
import 'package:loop/services/nearby_transport.dart';
import 'package:loop/services/share_platform.dart';

import 'support/fake_nearby.dart';

/// 근거리 공유 상태 머신 — 폰 없이 가짜 전송 계층으로 전체 흐름을 검증.
/// (docs/share-design.md §6 — 실기기 테스트 전 단계)
void main() {
  // 이벤트 루프를 한 바퀴 돌려 비동기 체인(await 연쇄)을 흘려보낸다.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('requiredSharePermissions — API 레벨별 권한 조합', () {
    test('33+ : 블루투스 3종 + 근처 Wi-Fi 기기, 위치는 요청하지 않는다', () {
      for (final sdk in [33, 34, 36]) {
        final ps = requiredSharePermissions(sdk);
        expect(ps, contains(Permission.nearbyWifiDevices), reason: 'sdk $sdk');
        expect(ps, contains(Permission.bluetoothScan));
        expect(ps, contains(Permission.bluetoothAdvertise));
        expect(ps, contains(Permission.bluetoothConnect));
        expect(ps, isNot(contains(Permission.locationWhenInUse)));
      }
    });

    test('31~32 : 블루투스 3종 + 위치, 근처 Wi-Fi 기기는 없다(요청 시 denied라 공유가 막힌다)', () {
      for (final sdk in [31, 32]) {
        final ps = requiredSharePermissions(sdk);
        expect(ps, isNot(contains(Permission.nearbyWifiDevices)), reason: 'sdk $sdk');
        expect(ps, contains(Permission.locationWhenInUse));
        expect(ps, contains(Permission.bluetoothScan));
      }
    });

    test('30 이하 : 위치만', () {
      for (final sdk in [24, 29, 30]) {
        expect(requiredSharePermissions(sdk), [Permission.locationWhenInUse]);
      }
    });
  });

  group('ShareSendController — 보내기', () {
    late Directory tmp;
    late File file;
    late FakeTransport t;
    late FakeSharePlatform p;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('nearby_share_test');
      file = File('${tmp.path}/chain.looplog')..writeAsStringSync('{}\n');
      t = FakeTransport();
      p = FakeSharePlatform(granted: true);
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    ShareSendController make({
      String name = '민수',
      Duration searchTimeout = const Duration(seconds: 60),
      Duration connectTimeout = const Duration(seconds: 30),
      Duration stallTimeout = const Duration(seconds: 60),
      Duration drainTimeout = const Duration(seconds: 5),
      DateTime Function()? clock,
    }) => ShareSendController(
      file: file,
      myName: name,
      transport: t,
      platform: p,
      searchTimeout: searchTimeout,
      connectTimeout: connectTimeout,
      stallTimeout: stallTimeout,
      drainTimeout: drainTimeout,
      clock: clock,
    );

    /// 연결까지 마친 컨트롤러 (전송 시작 상태).
    Future<ShareSendController> sending({
      Duration stallTimeout = const Duration(seconds: 60),
      DateTime Function()? clock,
    }) async {
      final c = make(stallTimeout: stallTimeout, clock: clock);
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      expect(c.stage, ShareStage.sending);
      return c;
    }

    group('A — 멈춤 감지 (전체 시간 상한 없음)', () {
      test('바이트가 안 늘면 stallTimeout 뒤 stalled 실패, 그 기기만 끊는다', () async {
        final c = await sending(stallTimeout: const Duration(milliseconds: 40));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(c.stage, ShareStage.fail);
        expect(c.failure, ShareFailure.stalled);
        expect(t.disconnected, ['e1']);
        c.dispose();
      });

      test('조금씩이라도 계속 가면 오래 걸려도 실패하지 않는다', () async {
        final c = await sending(stallTimeout: const Duration(milliseconds: 60));
        for (var i = 1; i <= 8; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          t.progress(7, i * 10, 1000); // 총 200ms > stallTimeout
        }
        expect(c.stage, ShareStage.sending);
        c.dispose();
      });

      test('같은 바이트가 반복되면 진행이 아니다', () async {
        final c = await sending(stallTimeout: const Duration(milliseconds: 60));
        t.progress(7, 10, 1000);
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          t.progress(7, 10, 1000);
        }
        expect(c.failure, ShareFailure.stalled);
        c.dispose();
      });

      test('내 쪽 SUCCESS 뒤엔 멈춤 감지를 하지 않는다(받는 쪽 정리 대기)', () async {
        final c = await sending(stallTimeout: const Duration(milliseconds: 30));
        t.succeed(7);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(c.failure, isNull);
        t.peerDisconnects();
        expect(c.stage, ShareStage.done);
        c.dispose();
      });
    });

    group('B — 속도·남은 시간·느림 안내', () {
      late DateTime now;
      DateTime clock() => now;
      const mb = 1024 * 1024;

      setUp(() => now = DateTime(2026, 11, 1, 12));

      void at(int ms, int bytes, int total) {
        now = DateTime(2026, 11, 1, 12).add(Duration(milliseconds: ms));
        t.progress(7, bytes, total);
      }

      test('1초 미만 관찰이면 속도를 모른다', () async {
        final c = await sending(clock: clock);
        at(500, 100 * 1024, 10 * mb);
        expect(c.bytesPerSecond, isNull);
        expect(c.eta, isNull);
        expect(c.slow, isFalse);
        c.dispose();
      });

      test('보낸/전체 바이트와 속도·남은 시간', () async {
        final c = await sending(clock: clock);
        at(1000, 2 * mb, 10 * mb);
        at(2000, 4 * mb, 10 * mb);
        expect(c.sentBytes, 4 * mb);
        expect(c.totalBytes, 10 * mb);
        expect(c.bytesPerSecond, closeTo(2 * mb, 1)); // 4MB / 2s
        expect(c.eta, const Duration(seconds: 3)); // 남은 6MB / 2MB/s
        c.dispose();
      });

      test('속도는 최근 3초 창 기준 — 처음엔 빨랐다가 느려지면 느린 값', () async {
        final c = await sending(clock: clock);
        at(1000, 5 * mb, 100 * mb); // 처음 1초 5MB/s
        for (var sec = 2; sec <= 8; sec++) {
          at(sec * 1000, 5 * mb + (sec - 1) * 100 * 1024, 100 * mb); // 이후 100KB/s
        }
        expect(c.bytesPerSecond!, lessThan(200 * 1024));
        c.dispose();
      });

      test('블루투스 속도로 4초 넘게 가고 한참 남았으면 slow', () async {
        final c = await sending(clock: clock);
        for (var sec = 1; sec <= 5; sec++) {
          at(sec * 1000, sec * 200 * 1024, 50 * mb); // 200KB/s, 수 분 남음
        }
        expect(c.slow, isTrue);
        c.dispose();
      });

      test('4초 전에는 느려도 안내하지 않는다', () async {
        final c = await sending(clock: clock);
        at(1000, 200 * 1024, 50 * mb);
        at(3000, 600 * 1024, 50 * mb);
        expect(c.slow, isFalse);
        c.dispose();
      });

      test('Wi-Fi 속도면 slow 아님', () async {
        final c = await sending(clock: clock);
        for (var sec = 1; sec <= 5; sec++) {
          at(sec * 1000, sec * 8 * mb, 400 * mb);
        }
        expect(c.slow, isFalse);
        c.dispose();
      });

      test('느려도 곧 끝나면(20초 이내) 안내하지 않는다', () async {
        final c = await sending(clock: clock);
        for (var sec = 1; sec <= 5; sec++) {
          at(sec * 1000, sec * 200 * 1024, 1200 * 1024); // 남은 200KB
        }
        expect(c.slow, isFalse);
        c.dispose();
      });
    });

    test('권한 거부 → 탐색을 시작하지 않고 permission 실패', () async {
      p.grantOnRequest = false;
      p.granted = false;
      final c = make();
      await c.start();
      expect(c.stage, ShareStage.fail);
      expect(c.failure, ShareFailure.permission);
      expect(t.calls, isNot(contains('startDiscovery')));
      c.dispose();
    });

    test('미지원 플랫폼 → unavailable, 권한도 묻지 않는다', () async {
      p.supported = false;
      final c = make();
      await c.start();
      expect(c.failure, ShareFailure.unavailable);
      expect(p.requestCount, 0);
      c.dispose();
    });

    test('탐색 시작 실패 → unavailable', () async {
      t.discoveryOk = false;
      final c = make();
      await c.start();
      expect(c.failure, ShareFailure.unavailable);
      c.dispose();
    });

    test('표시명이 비었으면 기기 이름으로 탐색·연결한다', () async {
      final c = make(name: '  ');
      await c.start();
      expect(t.discoveryName, 'Pixel 9');
      t.find('e1', '지민');
      await c.select(c.devices.single);
      expect(t.connectName, 'Pixel 9');
      c.dispose();
    });

    test('발견한 기기는 목록에만 쌓이고 자동으로 연결하지 않는다', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      t.find('e2', '서연');
      await settle();
      expect(c.stage, ShareStage.searching);
      expect(c.devices.map((d) => d.name), ['지민', '서연']);
      expect(t.calls.where((s) => s.startsWith('connect')), isEmpty);

      t.lose('e1');
      expect(c.devices.map((d) => d.name), ['서연']);
      c.dispose();
    });

    test('같은 기기가 다시 발견되면 한 줄로 — 이름은 최신으로', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      t.find('e1', '지민폰');
      expect(c.devices, [const NearbyDevice(id: 'e1', name: '지민폰')]);
      c.dispose();
    });

    test('정상 경로 — 고른 기기로 연결 → 진행률 → 상대가 끊으면 완료', () async {
      final c = make();
      final stages = <ShareStage>[];
      c.addListener(() {
        if (stages.isEmpty || stages.last != c.stage) stages.add(c.stage);
      });
      await c.start();
      t.find('e1', '지민');
      t.find('e2', '서연');
      await c.select(c.devices.last); // 두 번째 기기를 고른다

      expect(t.calls, containsAllInOrder(['stopDiscovery', 'connect:e2', 'sendFile:e2']));
      expect(t.sent.single.path, file.path);
      expect(c.stage, ShareStage.sending);
      expect(c.device!.name, '서연');

      t.progress(7, 25, 100);
      expect(c.progress, closeTo(0.25, 1e-9));
      t.progress(7, 60, 100);
      expect(c.progress, closeTo(0.6, 1e-9));

      t.succeed(7);
      // 내 쪽 전송 완료 — 상대가 파일을 옮기고 끊을 때까지는 아직 완료 아님
      expect(c.stage, ShareStage.sending);
      expect(c.progress, 1);

      t.peerDisconnects();
      expect(c.stage, ShareStage.done);
      expect(c.failure, isNull);
      expect(stages, [
        ShareStage.searching, // 발견 알림
        ShareStage.connecting,
        ShareStage.sending,
        ShareStage.done,
      ]);
      c.dispose();
    });

    test('상대가 끊지 않아도 drain 상한 뒤 완료하고 그 기기만 끊는다', () async {
      final c = make(drainTimeout: const Duration(milliseconds: 20));
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.succeed(7);
      expect(c.stage, ShareStage.sending);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.stage, ShareStage.done);
      expect(t.disconnected, ['e1']);
      c.dispose();
    });

    test('보내기가 끝나도 받기 대기(광고)는 그대로 — 전체 끊기를 쓰지 않는다', () async {
      final receiver = ShareReceiver(transport: t, platform: p);
      final dbDir = Directory('${tmp.path}/db')..createSync();
      final db = LoopDb(dbDir)..open();
      await receiver.startIfAllowed(db);
      expect(t.advertising, isTrue);

      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.succeed(7);
      t.peerDisconnects();
      expect(c.stage, ShareStage.done);
      expect(t.advertising, isTrue);
      expect(t.calls, isNot(contains('stopAdvertising')));
      c.dispose();
      db.close();
    });

    test('연결 거절 → connect 실패, 그 기기 연결 정리', () async {
      t.connectOk = false;
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      expect(c.stage, ShareStage.fail);
      expect(c.failure, ShareFailure.connect);
      expect(t.disconnected, ['e1']);
      expect(t.sent, isEmpty);
      c.dispose();
    });

    test('연결 응답이 없으면 시간 초과로 connect 실패', () async {
      t.connectCompleter = Completer<bool>();
      final c = make(connectTimeout: const Duration(milliseconds: 20));
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      expect(c.failure, ShareFailure.connect);
      c.dispose();
    });

    test('전송 실패 이벤트 → transfer 실패', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.failTransfer(7);
      expect(c.failure, ShareFailure.transfer);
      expect(t.disconnected, ['e1']);
      c.dispose();
    });

    test('전송 도중 끊김(성공 전) → transfer 실패', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.progress(7, 10, 100);
      t.peerDisconnects();
      expect(c.stage, ShareStage.fail);
      expect(c.failure, ShareFailure.transfer);
      c.dispose();
    });

    test('100% 보낸 뒤 내 SUCCESS보다 상대 끊김이 먼저 와도 완료', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.progress(7, 100, 100);
      t.peerDisconnects();
      expect(c.stage, ShareStage.done);
      c.dispose();
    });

    test('페이로드 id를 받기 전에 온 진행 이벤트도 놓치지 않는다', () async {
      t.beforeSendReturns = (id) => t.succeed(id); // 아주 작은 파일
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      expect(c.progress, 1);
      t.peerDisconnects();
      expect(c.stage, ShareStage.done);
      c.dispose();
    });

    test('다른 페이로드의 이벤트는 무시한다', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.succeed(99);
      t.failTransfer(99);
      expect(c.stage, ShareStage.sending);
      expect(c.progress, 0);
      c.dispose();
    });

    test('아무 기기도 없이 시간이 지나면 notFound — 탐색도 멈춘다', () async {
      final c = make(searchTimeout: const Duration(milliseconds: 20));
      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.failure, ShareFailure.notFound);
      expect(t.discovering, isFalse);
      c.dispose();
    });

    test('목록에 기기가 있으면 시간이 지나도 사용자가 고를 때까지 기다린다', () async {
      final c = make(searchTimeout: const Duration(milliseconds: 20));
      await c.start();
      t.find('e1', '지민');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.stage, ShareStage.searching);
      c.dispose();
    });

    test('취소하면 탐색을 멈추고 이후 이벤트는 무시한다', () async {
      final c = make();
      await c.start();
      await c.cancel();
      expect(t.discovering, isFalse);
      t.find('e1', '지민'); // 콜백이 남아 있었더라도
      expect(c.devices, isEmpty);
      c.dispose();
    });

    test('전송 중 취소하면 그 기기만 끊는다', () async {
      final c = make();
      await c.start();
      t.find('e1', '지민');
      await c.select(c.devices.single);
      await c.cancel();
      expect(t.disconnected, ['e1']);
      t.succeed(7);
      expect(c.stage, ShareStage.sending); // 닫힌 뒤 이벤트는 반영 안 됨
      c.dispose();
    });

    test('dispose가 진행 중인 탐색을 정리한다', () async {
      final c = make();
      await c.start();
      c.dispose();
      await settle();
      expect(t.discovering, isFalse);
    });

    test('실패 뒤 다시 찾기 — 상태를 비우고 탐색부터 다시', () async {
      final c = make(searchTimeout: const Duration(milliseconds: 20));
      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.failure, ShareFailure.notFound);

      await c.retry();
      expect(c.stage, ShareStage.searching);
      expect(c.failure, isNull);
      expect(t.discovering, isTrue);
      t.find('e1', '지민');
      await c.select(c.devices.single);
      t.succeed(7);
      t.peerDisconnects();
      expect(c.stage, ShareStage.done);
      c.dispose();
    });
  });

  group('ShareReceiver — 받기 대기', () {
    late Directory tmp;
    late LoopDb db;
    late FakeTransport t;
    late FakeSharePlatform p;
    late ShareReceiver r;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('share_receiver_test');
      db = LoopDb(tmp)..open();
      t = FakeTransport();
      p = FakeSharePlatform();
      r = ShareReceiver(transport: t, platform: p);
    });

    tearDown(() {
      r.dispose();
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('앱 시작 — 권한이 없으면 팝업 없이 대기하지 않는다', () async {
      expect(await r.startIfAllowed(db), isFalse);
      expect(p.requestCount, 0);
      expect(r.active, isFalse);
      expect(t.advertising, isFalse);
    });

    test('앱 시작 — 권한이 이미 있으면 조용히 대기, 표시명으로 광고', () async {
      p.granted = true;
      db.setShareName('민수');
      expect(await r.startIfAllowed(db), isTrue);
      expect(p.requestCount, 0);
      expect(r.active, isTrue);
      expect(t.advertisedName, '민수');
    });

    test('표시명이 없으면 기기 이름으로 광고', () async {
      p.granted = true;
      await r.startIfAllowed(db);
      expect(t.advertisedName, 'Pixel 9');
    });

    test('사용자가 꺼 두었으면 권한이 있어도 자동 대기하지 않는다', () async {
      p.granted = true;
      db.setSetting(ShareReceiver.prefKey, '0');
      expect(await r.startIfAllowed(db), isFalse);
      expect(t.advertising, isFalse);
    });

    test('미지원 플랫폼이면 아무것도 하지 않는다', () async {
      p
        ..supported = false
        ..granted = true;
      expect(await r.startIfAllowed(db), isFalse);
      expect(await r.setEnabled(db, true), isFalse);
      expect(p.requestCount, 0);
    });

    test('설정에서 켜기 — 그때 권한을 요청하고 대기 시작', () async {
      db.setSetting(ShareReceiver.prefKey, '0');
      var notified = 0;
      r.addListener(() => notified++);
      expect(await r.setEnabled(db, true), isTrue);
      expect(p.requestCount, 1);
      expect(r.active, isTrue);
      expect(notified, 1);
      expect(ShareReceiver.userDisabled(db), isFalse);
    });

    test('설정에서 켜기 — 권한 거부면 꺼진 채로, 설정값도 그대로', () async {
      p.grantOnRequest = false;
      db.setSetting(ShareReceiver.prefKey, '0');
      expect(await r.setEnabled(db, true), isFalse);
      expect(r.active, isFalse);
      expect(t.advertising, isFalse);
      expect(ShareReceiver.userDisabled(db), isTrue);
    });

    test('설정에서 끄기 — 광고 중지, 다음 실행에도 자동 대기 안 함', () async {
      p.granted = true;
      await r.startIfAllowed(db);
      expect(await r.setEnabled(db, false), isFalse);
      expect(r.active, isFalse);
      expect(t.advertising, isFalse);
      expect(ShareReceiver.userDisabled(db), isTrue);

      final next = ShareReceiver(transport: t, platform: p);
      expect(await next.startIfAllowed(db), isFalse);
      next.dispose();
    });

    test('파일이 도착하면 onReceived로 넘긴다', () async {
      p.granted = true;
      File? got;
      r.onReceived = (f) => got = f;
      await r.startIfAllowed(db);
      t.deliver('/tmp/shared-1.looplog');
      expect(got?.path, '/tmp/shared-1.looplog');
    });

    test('표시명이 바뀌면 대기 중일 때만 새 이름으로 다시 광고', () async {
      await r.refreshName(db); // 대기 전 — 아무 일 없음
      expect(t.calls.where((c) => c.startsWith('startAdvertising')), isEmpty);

      p.granted = true;
      db.setShareName('민수');
      await r.startIfAllowed(db);
      db.setShareName('민수폰');
      await r.refreshName(db);
      expect(t.advertisedName, '민수폰');
    });

    test('광고 시작 실패 → 대기 아님', () async {
      p.granted = true;
      t.advertiseOk = false;
      expect(await r.startIfAllowed(db), isFalse);
      expect(r.active, isFalse);
    });
  });

  group('ShareReceiver — 받는 중 상태 (C)', () {
    late Directory tmp;
    late LoopDb db;
    late FakeTransport t;
    late FakeSharePlatform p;
    late ShareReceiver r;

    Future<void> setup({Duration stall = const Duration(seconds: 60)}) async {
      r = ShareReceiver(transport: t, platform: p, stallTimeout: stall);
      await r.startIfAllowed(db);
    }

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('share_incoming_test');
      db = LoopDb(tmp)..open();
      t = FakeTransport();
      p = FakeSharePlatform(granted: true);
    });

    tearDown(() {
      r.dispose();
      db.close();
      tmp.deleteSync(recursive: true);
    });

    test('연결 → 진행 → 완료', () async {
      await setup();
      t.incoming('A', IncomingStatus.started, name: '지민');
      expect(r.incoming!.senderName, '지민');
      expect(r.incoming!.status, IncomingShareStatus.receiving);
      expect(r.incoming!.fraction, isNull);

      t.incoming('A', IncomingStatus.progress, bytes: 30, total: 100);
      expect(r.incoming!.fraction, closeTo(0.3, 1e-9));

      t.incoming('A', IncomingStatus.completed, total: 100);
      expect(r.incoming!.status, IncomingShareStatus.completed);
      expect(r.incoming!.fraction, 1);

      r.clearIncoming();
      expect(r.incoming, isNull);
    });

    test('중단 → failed', () async {
      await setup();
      t.incoming('A', IncomingStatus.started);
      t.incoming('A', IncomingStatus.progress, bytes: 30, total: 100);
      t.incoming('A', IncomingStatus.failed);
      expect(r.incoming!.status, IncomingShareStatus.failed);
    });

    test('받는 중에는 clearIncoming이 지우지 않는다', () async {
      await setup();
      t.incoming('A', IncomingStatus.started);
      r.clearIncoming();
      expect(r.incoming, isNotNull);
    });

    test('다른 상대의 늦은 이벤트는 지금 표시를 덮지 않는다', () async {
      await setup();
      t.incoming('A', IncomingStatus.started, name: '지민');
      t.incoming('B', IncomingStatus.failed, name: '서연');
      expect(r.incoming!.senderName, '지민');
      expect(r.incoming!.status, IncomingShareStatus.receiving);
    });

    test('받는 쪽도 멈춤 감지 — 바이트가 안 늘면 이쪽에서 끊고 failed', () async {
      await setup(stall: const Duration(milliseconds: 40));
      t.incoming('A', IncomingStatus.started);
      t.incoming('A', IncomingStatus.progress, bytes: 10, total: 100);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(r.incoming!.status, IncomingShareStatus.failed);
      expect(t.disconnected, ['A']); // 끊으면 전송 계층이 미완성 파일을 지운다
    });

    test('진행 중이면 멈춤 감지가 다시 걸린다', () async {
      await setup(stall: const Duration(milliseconds: 60));
      t.incoming('A', IncomingStatus.started);
      for (var i = 1; i <= 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        t.incoming('A', IncomingStatus.progress, bytes: i * 10, total: 100);
      }
      expect(r.incoming!.status, IncomingShareStatus.receiving);
      expect(t.disconnected, isEmpty);
    });

    test('완료 뒤엔 멈춤 감지가 꺼진다', () async {
      await setup(stall: const Duration(milliseconds: 30));
      t.incoming('A', IncomingStatus.started);
      t.incoming('A', IncomingStatus.completed, total: 100);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(r.incoming!.status, IncomingShareStatus.completed);
      expect(t.disconnected, isEmpty);
    });
  });
}
