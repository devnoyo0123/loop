import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/screens/pc_link_screen.dart';
import 'package:loop/services/pc_link.dart';

/// 가짜 소켓 — 보낸 줄 기록, 서버(브리지) 줄은 [server]로 주입.
class FakeSocket implements PcLinkSocket {
  final sent = <String>[];
  final _lines = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _lines.stream;

  @override
  void send(String line) => sent.add(line);

  @override
  void close() => _lines.close();

  /// 브리지 → 폰 메시지 주입.
  void server(Map<String, dynamic> m) => _lines.add(jsonEncode(m));

  /// 브리지 쪽에서 소켓이 닫힘 (브리지 재시작·맥 잠자기·Wi-Fi 단절).
  void drop() => _lines.close();

  Map<String, dynamic> sentJson(int i) => jsonDecode(sent[i]) as Map<String, dynamic>;
}

class FakeTransport implements PcLinkTransport {
  FakeSocket? last;
  String? lastHost;
  PcLinkConnectException? failWith;
  int attempts = 0;

  @override
  Future<PcLinkSocket> connect(String host, int port, {Duration timeout = const Duration(seconds: 6)}) async {
    attempts++;
    lastHost = host;
    if (failWith != null) throw failWith!;
    return last = FakeSocket();
  }
}

/// 가짜 세션 유지 장치 — 시작·정지 횟수 기록, 네이티브 종료는 [end]로 주입.
class FakeKeeper implements PcLinkKeeper {
  bool allow = true;
  int starts = 0;
  int stops = 0;
  bool running = false;
  void Function(PcLinkKeeperEnd reason)? _onEnded;

  @override
  Future<bool> start({required void Function(PcLinkKeeperEnd reason) onEnded}) async {
    starts++;
    _onEnded = onEnded;
    running = allow;
    return allow;
  }

  @override
  Future<void> stop() async {
    stops++;
    running = false;
  }

  /// 네이티브(알림 버튼·onTimeout·시작 거부) → Dart.
  void end(PcLinkKeeperEnd reason) {
    if (reason != PcLinkKeeperEnd.denied) running = false;
    _onEnded?.call(reason);
  }
}

/// 손으로 울리는 타이머 — 세션 유휴 시간을 실제로 기다리지 않는다.
class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);
  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  late Directory tmp;
  late LoopDb db;
  late FakeTransport transport;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_pc_link_test');
    db = LoopDb(tmp)..open();
    transport = FakeTransport();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  PcLinkController newController() =>
      PcLinkController(db: db, transport: transport);

  // ── 자동 재연결 ──────────────────────────────────────────────

  const tick = Duration(milliseconds: 5);
  PcLinkController retryController({int maxRetries = 10}) => PcLinkController(
    db: db,
    transport: transport,
    retryDelays: const [tick],
    maxRetries: maxRetries,
  );
  /// "일어나지 않음" 확인용 고정 대기 — 느린 환경에서도 실패로 뒤집히지 않는다.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

  /// "일어남" 확인은 고정 대기 대신 조건이 될 때까지 기다린다 — 부하에도 안정.
  Future<void> until(bool Function() cond, {Duration timeout = const Duration(seconds: 5)}) async {
    final sw = Stopwatch()..start();
    while (!cond()) {
      if (sw.elapsed > timeout) fail('조건이 ${timeout.inSeconds}초 안에 충족되지 않음');
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  /// 페어링까지 끝난 연결 상태로 만든다.
  Future<PcLinkController> connected(PcLinkController c) async {
    await c.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c.submitCode('12345678');
    transport.last!.server({'t': 'paired', 'secret': 'SECR'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.connected);
    return c;
  }

  test('자동 재연결 — 브리지가 끊으면 secret으로 다시 붙는다', () async {
    final c = await connected(retryController());
    final first = transport.last!;

    first.drop();
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.off);
    expect(c.reconnecting, isTrue);

    await until(() => transport.last != first && transport.last!.sent.isNotEmpty);
    expect(c.reconnecting, isTrue); // 시도 중에도 안내 유지 (깜빡임 없음)
    final hello = transport.last!.sentJson(0);
    expect(hello['t'], 'hello');
    expect(hello['secret'], 'SECR');

    transport.last!.server({'t': 'paired'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.connected);
    expect(c.reconnecting, isFalse);
    expect(c.lastError, isNull);
  });

  test('자동 재연결 — 브리지가 잠시 안 떠 있어도(refused) 계속 시도', () async {
    final c = await connected(retryController(maxRetries: 1000));
    transport.failWith = const PcLinkConnectException(PcLinkError.refused);
    final first = transport.last!;
    first.drop();
    await until(() => transport.attempts > 2); // 첫 연결 + 실패한 재시도들
    expect(c.reconnecting, isTrue);

    transport.failWith = null; // 브리지가 다시 떴다
    await until(() => transport.last != first && transport.last!.sent.isNotEmpty);
    transport.last!.server({'t': 'paired'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.connected);
  });

  test('자동 재연결 — maxRetries 넘으면 멈추고 끊김 표시', () async {
    final c = await connected(retryController(maxRetries: 3));
    transport.failWith = const PcLinkConnectException(PcLinkError.refused);
    transport.last!.drop();
    await until(() => transport.attempts == 1 + 3 && !c.reconnecting);
    await settle(); // 포기 후 추가 시도가 없는지
    expect(transport.attempts, 1 + 3);
    expect(c.reconnecting, isFalse);
    expect(c.status, PcLinkStatus.off);
    expect(c.lastError, isNotNull);
  });

  test('자동 재연결 — 사용자가 끊으면 다시 붙지 않는다', () async {
    final c = await connected(retryController());
    await c.disconnect();
    await settle();
    expect(transport.attempts, 1);
    expect(c.reconnecting, isFalse);
  });

  test('자동 재연결 — secret 무효(bye secret)면 코드 절차로, 재시도 없음', () async {
    final c = await connected(retryController());
    transport.last!.server({'t': 'bye', 'reason': 'secret'});
    await settle();
    expect(transport.attempts, 1);
    expect(c.reconnecting, isFalse);
    expect(c.paired, isFalse);
  });

  test('자동 재연결 — 처음 연결 실패는 재시도하지 않는다', () async {
    transport.failWith = const PcLinkConnectException(PcLinkError.refused);
    final c = retryController();
    await c.connect(host: '10.0.0.9');
    await settle();
    expect(transport.attempts, 1);
    expect(c.reconnecting, isFalse);
  });

  test('자동 재연결 — 백그라운드에선 멈추고, 앱으로 돌아오면 바로 시도', () async {
    final c = await connected(retryController());
    c.setForeground(false);
    transport.last!.drop();
    await settle();
    expect(transport.attempts, 1); // 백그라운드 — 시도 안 함

    c.setForeground(true);
    await pumpEventQueue();
    expect(transport.attempts, 2);
    transport.last!.server({'t': 'paired'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.connected);
  });

  test('자동 재연결 — 포기한 뒤에도 앱으로 돌아오면 다시 시도', () async {
    final c = await connected(retryController(maxRetries: 1));
    transport.failWith = const PcLinkConnectException(PcLinkError.refused);
    transport.last!.drop();
    await until(() => transport.attempts == 1 + 1 && !c.reconnecting);
    final before = transport.attempts;

    transport.failWith = null;
    c.setForeground(false);
    c.setForeground(true);
    await pumpEventQueue();
    expect(transport.attempts, before + 1);
  });

  // ── 세션 유지 (ADR-003) ──────────────────────────────────────

  group('세션 유지', () {
    late FakeKeeper keeper;
    late List<FakeTimer> timers;

    setUp(() {
      keeper = FakeKeeper();
      timers = [];
    });

    PcLinkController sessionController({int maxRetries = 10}) => PcLinkController(
      db: db,
      transport: transport,
      retryDelays: const [tick],
      maxRetries: maxRetries,
      keeper: keeper,
      idleTimer: (d, cb) {
        final t = FakeTimer(d, cb);
        timers.add(t);
        return t;
      },
    );

    FakeTimer? activeIdle() => timers.where((t) => t.isActive).lastOrNull;

    test('연결되면 유지 시작 + 60분 유휴 타이머', () async {
      await connected(sessionController());
      await pumpEventQueue();
      expect(keeper.starts, 1);
      expect(keeper.running, isTrue);
      expect(activeIdle()?.duration, const Duration(minutes: 60));
    });

    test('질의가 오면 유휴 타이머를 새로 건다', () async {
      final c = await connected(sessionController());
      await pumpEventQueue();
      final first = activeIdle()!;

      transport.last!.server({'t': 'invoke', 'rid': 1, 'tool': 'no_such_tool', 'args': {}});
      await pumpEventQueue();
      expect(c.queryCount, 1);
      expect(first.isActive, isFalse);
      expect(activeIdle(), isNot(same(first)));
      expect(timers.where((t) => t.isActive), hasLength(1));
    });

    test('유휴 만료 — 끊고(bye) 유지 정지, 재연결 없음', () async {
      final c = await connected(sessionController());
      await pumpEventQueue();
      final socket = transport.last!;

      activeIdle()!.fire();
      await settle();
      expect(c.status, PcLinkStatus.off);
      expect(c.reconnecting, isFalse);
      expect(socket.sent.map(jsonDecode).any((m) => (m as Map)['t'] == 'bye'), isTrue);
      expect(keeper.stops, 1);
      expect(keeper.running, isFalse);
      expect(transport.attempts, 1);
    });

    test('사용자가 끊으면 유지 정지 + 유휴 타이머 해제', () async {
      final c = await connected(sessionController());
      await pumpEventQueue();
      await c.disconnect();
      expect(keeper.stops, 1);
      expect(activeIdle(), isNull);
    });

    test('세션 중 백그라운드 — 끊겨도 재연결 계속', () async {
      final c = await connected(sessionController());
      await pumpEventQueue();
      c.setForeground(false);
      final first = transport.last!;
      first.drop();

      await until(() => transport.last != first && transport.last!.sent.isNotEmpty);
      transport.last!.server({'t': 'paired'});
      await pumpEventQueue();
      expect(c.status, PcLinkStatus.connected);
      expect(keeper.starts, 1); // 같은 세션 — 다시 켜지 않는다
      expect(keeper.running, isTrue);
    });

    test('세션 없음(유지 불가) — 백그라운드에선 기존처럼 재연결 멈춤', () async {
      keeper.allow = false;
      final c = await connected(sessionController());
      await pumpEventQueue();
      expect(activeIdle(), isNull); // 세션 없으면 유휴 끊김도 없음
      c.setForeground(false);
      transport.last!.drop();
      await settle();
      expect(transport.attempts, 1);
    });

    test('네이티브 종료(알림 버튼·onTimeout) — 끊고 재연결 없음', () async {
      for (final reason in [PcLinkKeeperEnd.user, PcLinkKeeperEnd.timeout]) {
        final c = await connected(sessionController());
        await pumpEventQueue();
        final before = transport.attempts;
        keeper.end(reason);
        await settle();
        expect(c.status, PcLinkStatus.off, reason: '$reason');
        expect(c.reconnecting, isFalse, reason: '$reason');
        expect(transport.attempts, before, reason: '$reason');
        expect(activeIdle(), isNull, reason: '$reason');
      }
    });

    test('서비스 시작 거부(denied) — 링크는 유지, 세션 없이 기존 동작', () async {
      final c = await connected(sessionController());
      await pumpEventQueue();
      keeper.end(PcLinkKeeperEnd.denied);
      expect(c.status, PcLinkStatus.connected);
      expect(activeIdle(), isNull);

      c.setForeground(false);
      transport.last!.drop();
      await settle();
      expect(transport.attempts, 1); // 백그라운드 재연결 멈춤
    });

    test('재시도 소진 — 유지 정지', () async {
      final c = await connected(sessionController(maxRetries: 2));
      await pumpEventQueue();
      transport.failWith = const PcLinkConnectException(PcLinkError.refused);
      transport.last!.drop();
      await until(() => transport.attempts == 1 + 2 && !c.reconnecting);
      expect(keeper.stops, 1);
      expect(activeIdle(), isNull);
    });

    test('재연결 불가 사유(secret 무효) — 유지 정지', () async {
      await connected(sessionController());
      await pumpEventQueue();
      transport.last!.server({'t': 'bye', 'reason': 'secret'});
      await settle();
      expect(keeper.stops, 1);
    });
  });

  test('최초 연결 — hello(코드 요구) → 8자리 → paired + secret 저장', () async {
    final c = newController();
    await c.connect(host: '192.168.0.8');

    final hello = transport.last!.sentJson(0);
    expect(hello['t'], 'hello');
    expect(hello['proto'], 1);
    expect(hello['id'], isNotEmpty);
    expect(hello.containsKey('secret'), isFalse); // 미페어링 — secret 없음
    final tools = (hello['tools'] as List).map((t) => (t as Map)['name']);
    expect(tools, contains('search_logs')); // 폰이 도구 목록을 광고

    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.waitingCode);

    c.submitCode('12345678');
    expect(c.status, PcLinkStatus.pairing);
    final pair = transport.last!.sentJson(1);
    expect(pair['t'], 'pair');
    expect(pair['code'], '12345678');

    transport.last!.server({'t': 'paired', 'secret': 'SECR32BXXXXXXXXXXXXXXXXXXXXX'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.connected);
    expect(c.paired, isTrue);
    expect(db.getSetting('pclink_secret'), 'SECR32BXXXXXXXXXXXXXXXXXXXXX');
    expect(c.host, '192.168.0.8'); // 호스트 저장
  });

  test('코드 불일치 — attemptsLeft 반영 + codeWrong 오류', () async {
    final c = newController();
    await c.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c.submitCode('00000000');

    transport.last!.server({'t': 'need_code', 'attemptsLeft': 4});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.waitingCode);
    expect(c.lastError, PcLinkError.codeWrong);
    expect(c.attemptsLeft, 4);
  });

  test('too_many — 브리지가 끊으면 오류로', () async {
    final c = newController();
    await c.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c.submitCode('00000000');
    transport.last!.server({'t': 'bye', 'reason': 'too_many'});
    await pumpEventQueue();
    expect(c.status, PcLinkStatus.off);
    expect(c.lastError, PcLinkError.tooMany);
  });

  test('재접속 — 저장된 secret으로 hello → 즉시 connected', () async {
    final c1 = newController();
    await c1.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c1.submitCode('12345678');
    transport.last!.server({'t': 'paired', 'secret': 'SECR'});
    await pumpEventQueue();
    final deviceId = transport.last!.sentJson(0)['id'] as String;
    await c1.disconnect();

    // 새 컨트롤러(앱 재시작) — 같은 db에서 secret·host·deviceId 복원.
    final c2 = newController();
    await c2.connect(); // host 생략 → 저장된 값
    final hello = transport.last!.sentJson(0);
    expect(hello['id'], deviceId);
    expect(hello['secret'], 'SECR');
    expect(c2.host, '192.168.0.8');

    transport.last!.server({'t': 'paired'});
    await pumpEventQueue();
    expect(c2.status, PcLinkStatus.connected);
  });

  test('도구 중계 — invoke → 기존 McpTools 결과를 result로 응답', () async {
    final c = newController();
    await c.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c.submitCode('12345678');
    transport.last!.server({'t': 'paired', 'secret': 'S'});
    await pumpEventQueue();

    transport.last!.server({
      't': 'invoke',
      'rid': 7,
      'tool': 'no_such_tool',
      'args': {},
    });
    await pumpEventQueue();
    final result = transport.last!.sentJson(2);
    expect(result['t'], 'result');
    expect(result['rid'], 7);
    expect(result['ok'], isFalse);
    expect(result['error'], contains('Unknown tool'));
    expect(c.queryCount, 1);
  });

  test('접속 실패 — refused 반영', () async {
    transport.failWith = const PcLinkConnectException(PcLinkError.refused);
    final c = newController();
    await c.connect(host: '10.0.0.9');
    expect(c.status, PcLinkStatus.off);
    expect(c.lastError, PcLinkError.refused);
  });

  test('페어링 해제 — secret 폐기', () async {
    final c = newController();
    await c.connect(host: '192.168.0.8');
    transport.last!.server({'t': 'need_code'});
    await pumpEventQueue();
    c.submitCode('12345678');
    transport.last!.server({'t': 'paired', 'secret': 'SECR'});
    await pumpEventQueue();
    expect(c.paired, isTrue);

    await c.unpair();
    expect(c.paired, isFalse);
    expect(c.status, PcLinkStatus.off);
  });

  test('주소 정리 — 붙여넣은 스킴·포트·경로를 떼고 접속·저장', () async {
    final c = newController();
    await c.connect(host: ' http://192.168.35.8:8766/ ');
    expect(transport.lastHost, '192.168.35.8');
    expect(c.host, '192.168.35.8');
  });

  test('주소 정리 — 예전에 저장된 "IP:포트"도 접속된다', () async {
    db.setSetting('pclink_host', '192.168.35.8:8766');
    await newController().connect();
    expect(transport.lastHost, '192.168.35.8');
  });

  group('PcLinkScreen 주소 칸', () {
    Future<void> pump(WidgetTester tester, {String? prefix}) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PcLinkScreen(
          controller: newController(),
          subnetLookup: () async => prefix,
        ),
      ));
      await tester.pump();
    }

    TextField field(WidgetTester tester) =>
        tester.widget<TextField>(find.byKey(const ValueKey('pclink-host-field')));

    testWidgets('빈 칸이면 폰 Wi-Fi 서브넷으로 미리 채우고 커서는 끝', (tester) async {
      await pump(tester, prefix: '192.168.35.');
      final ctl = field(tester).controller!;
      expect(ctl.text, '192.168.35.');
      expect(ctl.selection, const TextSelection.collapsed(offset: 11));
    });

    testWidgets('저장된 주소가 있으면 미리 채우지 않는다', (tester) async {
      db.setSetting('pclink_host', '10.0.0.9');
      await pump(tester, prefix: '192.168.35.');
      expect(field(tester).controller!.text, '10.0.0.9');
    });

    testWidgets('서브넷을 못 찾으면 비워 둔다', (tester) async {
      await pump(tester);
      expect(field(tester).controller!.text, '');
    });

    testWidgets('숫자 키패드(점 포함) + 붙여넣은 포트 제거', (tester) async {
      await pump(tester);
      expect(
        field(tester).keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      await tester.enterText(
        find.byKey(const ValueKey('pclink-host-field')),
        '192.168.35.8:8766',
      );
      expect(field(tester).controller!.text, '192.168.35.8');
    });
  });
}
