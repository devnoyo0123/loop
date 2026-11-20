import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/services/native_nearby_transport.dart';
import 'package:loop/services/nearby_transport.dart';
import 'package:loop/services/share_files.dart';

/// NativeNearbyTransport — Kotlin 번역층(NearbyBridge) 채널을 목으로 대신해
/// 프로토콜(크기 헤더 + STREAM)·완료 판정·미완성 파일 삭제를 검증한다.
/// 이벤트 형식은 NearbyBridge.kt / NearbyBridgeTest.kt와 같은 계약.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const methods = MethodChannel('app.loop/nearby');
  const events = EventChannel('app.loop/nearby/events');

  late List<MethodCall> calls;
  late Directory root;
  late Directory share;
  MockStreamHandlerEventSink? sink;
  Object? sendBytesReply;
  Object? sendStreamReply;

  setUp(() async {
    calls = [];
    sendBytesReply = 11;
    sendStreamReply = 7;
    root = Directory.systemTemp.createTempSync('native_nearby_test');
    share = await ShareTempFiles.dir(() async => root);
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return switch (call.method) {
        'startDiscovery' ||
        'startAdvertising' ||
        'requestConnection' ||
        'acceptConnection' => true,
        'sendBytes' => sendBytesReply,
        'sendStream' => sendStreamReply,
        _ => null,
      };
    });
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (_, s) => sink = s),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
    root.deleteSync(recursive: true);
  });

  NativeNearbyTransport make() =>
      NativeNearbyTransport(shareDir: () async => share);

  Future<void> flush() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> emit(Map<String, Object?> e) async {
    sink!.success(e);
    await flush();
  }

  Iterable<Object?> argsOf(String method, String key) => calls
      .where((c) => c.method == method)
      .map((c) => (c.arguments as Map)[key]);

  Uint8List header(int size) =>
      utf8.encode(jsonEncode({'loop': 'chain', 'v': 1, 'size': size}));

  /// Kotlin이 STREAM을 .part로 쓰는 것을 흉내 — stream 이벤트 + 파일.
  Future<String> streamStarts(String ep, int pid, String content) async {
    final path = '${share.path}/in-$ep-$pid.part';
    File(path).writeAsStringSync(content);
    await emit({'e': 'stream', 'id': ep, 'pid': pid, 'path': path});
    return path;
  }

  group('받기 — STREAM을 앱 폴더로', () {
    late NativeNearbyTransport t;
    late List<IncomingUpdate> ev;
    late List<String> got;

    setUp(() async {
      t = make();
      ev = [];
      got = [];
      expect(
        await t.startAdvertising('민수', onFile: got.add, onIncoming: ev.add),
        isTrue,
      );
      await flush();
      await emit({'e': 'initiated', 'role': 'ad', 'id': 'E1', 'name': '지민'});
    });

    test('광고는 공유 폴더를 받기 폴더로 넘기고, 들어온 연결을 수락한다', () {
      final adv = calls.lastWhere((c) => c.method == 'startAdvertising');
      expect((adv.arguments as Map)['incomingDir'], share.path);
      expect((adv.arguments as Map)['serviceId'], 'app.loop');
      expect(argsOf('acceptConnection', 'endpointId'), ['E1']);
      expect(ev.single.status, IncomingStatus.started);
      expect(ev.single.senderName, '지민');
    });

    test('정상 — 헤더 크기로 진행률, 다 받으면 .looplog로 넘기고 받는 쪽이 끊는다', () async {
      await emit({'e': 'bytes', 'id': 'E1', 'pid': 1, 'data': header(7)});
      final part = await streamStarts('E1', 42, 'payload');
      expect(ShareTempFiles.isHeld(part), isTrue); // 쓰는 중 — 청소 제외

      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'progress', 'bytes': 3, 'total': -1});
      expect(ev.last.status, IncomingStatus.progress);
      expect(ev.last.fraction, closeTo(3 / 7, 1e-9));

      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'success', 'bytes': 7, 'total': -1});
      expect(got, isEmpty); // 파일 쓰기가 아직 — Nearby 완료만으론 부족
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': true, 'bytes': 7});

      expect(got, ['${share.path}/in-E1-42.looplog']);
      expect(File(got.single).readAsStringSync(), 'payload');
      expect(File(part).existsSync(), isFalse);
      expect(ShareTempFiles.isHeld(part), isFalse);
      expect(ev.last.status, IncomingStatus.completed);
      expect(argsOf('disconnect', 'endpointId'), ['E1']);
    });

    test('파일 쓰기가 Nearby 완료보다 먼저 끝나도 같다 (순서 무관)', () async {
      await emit({'e': 'bytes', 'id': 'E1', 'pid': 1, 'data': header(7)});
      final part = await streamStarts('E1', 42, 'payload');
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': true, 'bytes': 7});
      expect(got, isEmpty);
      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'success', 'bytes': 7, 'total': -1});
      expect(got, hasLength(1));
    });

    test('헤더 크기와 다르면(잘림) 실패 — 미완성 파일 삭제', () async {
      await emit({'e': 'bytes', 'id': 'E1', 'pid': 1, 'data': header(7)});
      final part = await streamStarts('E1', 42, 'payl');
      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'success', 'bytes': 4, 'total': -1});
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': true, 'bytes': 4});
      expect(got, isEmpty);
      expect(File(part).existsSync(), isFalse);
      expect(ev.last.status, IncomingStatus.failed);
    });

    test('파일 쓰기 실패 → 실패, 미완성 삭제', () async {
      final part = await streamStarts('E1', 42, 'pay');
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': false, 'bytes': -1});
      expect(File(part).existsSync(), isFalse);
      expect(ev.last.status, IncomingStatus.failed);
    });

    test('Nearby 실패 → 미완성 삭제, 실패는 한 번만', () async {
      final part = await streamStarts('E1', 42, 'pay');
      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'failure', 'bytes': 3, 'total': -1});
      await emit({'e': 'disconnected', 'role': 'ad', 'id': 'E1'});
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': false, 'bytes': -1});
      expect(File(part).existsSync(), isFalse);
      expect(ev.where((e) => e.status == IncomingStatus.failed), hasLength(1));
      expect(got, isEmpty);
    });

    test('중간에 끊김 → 미완성 삭제 + 실패', () async {
      final part = await streamStarts('E1', 42, 'pay');
      await emit({'e': 'disconnected', 'role': 'ad', 'id': 'E1'});
      expect(File(part).existsSync(), isFalse);
      expect(ev.last.status, IncomingStatus.failed);
    });

    test('받는 쪽이 멈춤을 감지해 끊으면(disconnect) 미완성 삭제', () async {
      final part = await streamStarts('E1', 42, 'pay');
      await t.disconnect('E1');
      expect(File(part).existsSync(), isFalse);
      expect(argsOf('disconnect', 'endpointId'), contains('E1'));
      expect(ev.last.status, IncomingStatus.failed);
    });

    test('받기를 끄면 받던 연결도 끊고 미완성 삭제', () async {
      final part = await streamStarts('E1', 42, 'pay');
      await t.stopAdvertising();
      expect(File(part).existsSync(), isFalse);
      expect(argsOf('disconnect', 'endpointId'), ['E1']);
      expect(calls.last.method, 'stopAdvertising');
    });

    test('헤더가 없어도 받을 수 있다 (크기 확인만 생략)', () async {
      final part = await streamStarts('E1', 42, 'abc');
      await emit({'e': 'update', 'id': 'E1', 'pid': 42, 'status': 'success', 'bytes': 3, 'total': -1});
      await emit({'e': 'streamDone', 'id': 'E1', 'pid': 42, 'path': part, 'ok': true, 'bytes': 3});
      expect(got, hasLength(1));
    });

    test('받기 연결이 아닌 STREAM은 바로 지운다', () async {
      final path = '${share.path}/in-ZZ-9.part';
      File(path).writeAsStringSync('x');
      await emit({'e': 'stream', 'id': 'ZZ', 'pid': 9, 'path': path});
      expect(File(path).existsSync(), isFalse);
    });
  });

  group('보내기 — 크기 헤더 + STREAM', () {
    late File file;

    setUp(() {
      file = File('${share.path}/loop-chain-1.looplog')..writeAsStringSync('0123456789');
    });

    Future<(NativeNearbyTransport, List<TransferUpdate>, Future<bool>)> connected({
      int drops = 0,
    }) async {
      final t = make();
      final updates = <TransferUpdate>[];
      await t.startDiscovery('민수', onFound: (_) {}, onLost: (_) {});
      final c = t.connect('민수', 'B', onUpdate: updates.add, onDisconnected: () {});
      await flush();
      await emit({'e': 'initiated', 'role': 'dis', 'id': 'B', 'name': '서연'});
      await emit({'e': 'result', 'role': 'dis', 'id': 'B', 'ok': true, 'code': 0});
      return (t, updates, c);
    }

    test('탐색 이벤트 → 발견·사라짐', () async {
      final t = make();
      final found = <NearbyDevice>[];
      final lost = <String>[];
      expect(await t.startDiscovery('민수', onFound: found.add, onLost: lost.add), isTrue);
      await emit({'e': 'found', 'id': 'B', 'name': '서연'});
      await emit({'e': 'lost', 'id': 'B'});
      expect(found, [const NearbyDevice(id: 'B', name: '서연')]);
      expect(lost, ['B']);
      expect(argsOf('startDiscovery', 'serviceId'), ['app.loop']);
    });

    test('연결 — 우리가 건 연결만 수락, 결과로 완료', () async {
      final (_, _, c) = await connected();
      expect(await c, isTrue);
      expect(argsOf('acceptConnection', 'endpointId'), ['B']);
    });

    test('크기 헤더를 먼저, 그다음 STREAM — 진행 total은 파일 크기로 채운다', () async {
      final (t, updates, c) = await connected();
      await c;
      expect(await t.sendFile('B', file.path), 7);

      final bytesCall = calls.firstWhere((c) => c.method == 'sendBytes');
      final h = jsonDecode(utf8.decode((bytesCall.arguments as Map)['bytes'] as List<int>));
      expect(h, {'loop': 'chain', 'v': 1, 'size': 10});
      final order = calls.map((c) => c.method).where((m) => m.startsWith('send')).toList();
      expect(order, ['sendBytes', 'sendStream']);
      expect(argsOf('sendStream', 'path'), [file.path]);

      await emit({'e': 'update', 'id': 'B', 'pid': 7, 'status': 'progress', 'bytes': 4, 'total': -1});
      expect(updates.single.totalBytes, 10);
      expect(updates.single.fraction, closeTo(0.4, 1e-9));
    });

    test('페이로드 id가 음수여도 정상 (임의 64비트 값)', () async {
      sendStreamReply = -9876543210;
      final (t, _, c) = await connected();
      await c;
      expect(await t.sendFile('B', file.path), -9876543210);
    });

    test('헤더나 STREAM 전송 실패(null)면 예외 — 컨트롤러가 실패로 정리', () async {
      final (t, _, c) = await connected();
      await c;
      sendBytesReply = null;
      expect(() => t.sendFile('B', file.path), throwsStateError);
      sendBytesReply = 11;
      sendStreamReply = null;
      expect(() => t.sendFile('B', file.path), throwsStateError);
    });

    test('연결 거절 → false', () async {
      final t = make();
      final c = t.connect('민수', 'B', onUpdate: (_) {}, onDisconnected: () {});
      await flush();
      await emit({'e': 'result', 'role': 'dis', 'id': 'B', 'ok': false, 'code': 8004});
      expect(await c, isFalse);
    });

    test('이전 시도의 늦은 결과가 새 시도를 망치지 않는다', () async {
      final t = make();
      t.connect('민수', 'X', onUpdate: (_) {}, onDisconnected: () {}).ignore();
      await flush();
      await t.disconnect('X');
      final y = t.connect('민수', 'Y', onUpdate: (_) {}, onDisconnected: () {});
      await flush();
      await emit({'e': 'result', 'role': 'dis', 'id': 'X', 'ok': false, 'code': 13});
      await emit({'e': 'disconnected', 'role': 'dis', 'id': 'X'});
      await emit({'e': 'result', 'role': 'dis', 'id': 'Y', 'ok': true, 'code': 0});
      expect(await y, isTrue);
    });

    test('포기한 뒤 늦게 붙은 연결은 정리한다', () async {
      final t = make();
      t.connect('민수', 'X', onUpdate: (_) {}, onDisconnected: () {}).ignore();
      await flush();
      await t.disconnect('X');
      calls.clear();
      await emit({'e': 'result', 'role': 'dis', 'id': 'X', 'ok': true, 'code': 0});
      expect(argsOf('disconnect', 'endpointId'), ['X']);
    });

    test('상대가 끊으면 onDisconnected', () async {
      final t = make();
      var dropped = 0;
      final c = t.connect('민수', 'B', onUpdate: (_) {}, onDisconnected: () => dropped++);
      await flush();
      await emit({'e': 'result', 'role': 'dis', 'id': 'B', 'ok': true, 'code': 0});
      await c;
      await emit({'e': 'disconnected', 'role': 'dis', 'id': 'B'});
      expect(dropped, 1);
    });

    test('받기 대기 중에 보내도 보내기·받기 이벤트가 섞이지 않는다', () async {
      final t = make();
      final got = <String>[];
      final ev = <IncomingUpdate>[];
      await t.startAdvertising('민수', onFile: got.add, onIncoming: ev.add);
      await emit({'e': 'initiated', 'role': 'ad', 'id': 'A', 'name': '지민'});

      final updates = <TransferUpdate>[];
      final c = t.connect('민수', 'B', onUpdate: updates.add, onDisconnected: () {});
      await flush();
      await emit({'e': 'result', 'role': 'dis', 'id': 'B', 'ok': true, 'code': 0});
      await c;

      final part = await streamStarts('A', 5, 'x');
      await emit({'e': 'update', 'id': 'A', 'pid': 5, 'status': 'success', 'bytes': 1, 'total': -1});
      await emit({'e': 'streamDone', 'id': 'A', 'pid': 5, 'path': part, 'ok': true, 'bytes': 1});
      expect(updates, isEmpty);
      expect(got, hasLength(1));

      await emit({'e': 'update', 'id': 'B', 'pid': 7, 'status': 'success', 'bytes': 10, 'total': -1});
      expect(updates.single.status, TransferStatus.success);
      expect(got, hasLength(1));
      expect(ev.where((e) => e.endpointId == 'B'), isEmpty);
    });
  });
}
