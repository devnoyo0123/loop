import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/loop_db.dart';
import 'ipv4_input.dart';
import 'mcp/mcp_tools.dart';

/// PC 연결 — 맥의 loop-skill 브리지에 폰이 클라이언트로 붙는다.
/// 프로토콜·페어링 설계: docs/mcp-bridge-design.md (ADR-002).
///
/// 서버(구 MCP 서버)와 방향이 반대다: 이쪽은 접속만 하므로 포트·IP 고지가
/// 없고, Claude 쪽 등록은 플러그인(stdio)이 가져간다. 폰이 할 일은
/// (최초 1회) 맥 주소 + 8자리 코드 입력뿐. 연결 중에는 화면이 꺼져도
/// 링크가 살도록 [PcLinkKeeper]로 60분(유휴) 세션을 붙든다 (ADR-003).

/// 링크 상태.
enum PcLinkStatus {
  /// 미접속. 저장된 host가 있으면 재접속 버튼만으로 붙는다.
  off,

  /// TCP 접속 + hello 전송 중.
  connecting,

  /// 브리지가 코드를 요구 — 화면에서 8자리 입력을 받는다.
  waitingCode,

  /// 코드 전송 후 paired 응답 대기.
  pairing,

  /// 질의 응답 가능. [PcLinkController.host]의 맥과 연결됨.
  connected,
}

/// 실패·단선 사유 — 화면 안내 문구로 매핑.
enum PcLinkError {
  /// TCP 접속 거부 — 주소·포트 확인 (브리지가 안 떠 있음).
  refused,

  /// 시간 초과 — 다른 네트워크일 가능성.
  timeout,

  /// host 형식이 잘못됨.
  badHost,

  /// 코드 불일치. [PcLinkController.attemptsLeft]회 남음.
  codeWrong,

  /// 코드 5회 실패 — 브리지가 접속을 끊었다.
  tooMany,

  /// 이미 다른 폰이 해당 브리지에 연결 중.
  busy,

  /// 코드 만료(5분) — Claude에서 새 코드 요청.
  codeExpired,

  /// 알 수 없는 이유로 끊김.
  disconnected,
}

/// 브리지 접속 실패를 이유와 함께 던지는 예외 (전송 계층 → 컨트롤러).
class PcLinkConnectException implements Exception {
  const PcLinkConnectException(this.reason);
  final PcLinkError reason;
}

/// 한 줄 JSON 통신 추상 — 테스트는 가짜로, 앱은 TCP 소켓으로 구현.
abstract class PcLinkSocket {
  Stream<String> get lines;
  void send(String line);
  void close();
}

abstract class PcLinkTransport {
  Future<PcLinkSocket> connect(String host, int port, {Duration timeout});
}

class TcpPcLinkTransport implements PcLinkTransport {
  const TcpPcLinkTransport();

  @override
  Future<PcLinkSocket> connect(String host, int port, {Duration timeout = const Duration(seconds: 6)}) async {
    final Socket socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
    } on SocketException catch (e) {
      final timedOut = e.message.contains('timed out') ||
          e.osError?.errorCode == 60; // macOS ETIMEDOUT
      throw PcLinkConnectException(timedOut ? PcLinkError.timeout : PcLinkError.refused);
    } on ArgumentError {
      throw const PcLinkConnectException(PcLinkError.badHost);
    }
    return _TcpSocket(socket);
  }
}

class _TcpSocket implements PcLinkSocket {
  _TcpSocket(this._socket) {
    _lines = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }
  final Socket _socket;
  late final Stream<String> _lines;

  @override
  Stream<String> get lines => _lines;

  @override
  void send(String line) => _socket.write('$line\n');

  @override
  void close() => _socket.destroy();
}

/// 네이티브 쪽에서 세션 유지가 끝난 이유.
enum PcLinkKeeperEnd {
  /// 알림의 [연결 끊기].
  user,

  /// 시스템이 포그라운드 서비스를 끝냄 (Android 15+ dataSync 6시간 한도).
  timeout,

  /// 포그라운드 서비스 시작 거부 — 링크는 두고 세션 없이 계속.
  denied,
}

/// PC 연결 세션 유지 — 연결 중 화면이 꺼지거나 다른 앱을 써도 프로세스가
/// 얼지 않게 붙드는 장치. 안드로이드는 dataSync 포그라운드 서비스
/// (PcLinkService.kt), 그 밖의 플랫폼·테스트는 [NoopPcLinkKeeper]. (ADR-003)
abstract class PcLinkKeeper {
  /// 유지를 시작한다. 실제로 붙들었으면 true. [onEnded]는 네이티브가 먼저
  /// 끝냈을 때(알림 버튼·시스템 타임아웃·거부) 불린다.
  Future<bool> start({required void Function(PcLinkKeeperEnd reason) onEnded});

  Future<void> stop();
}

/// 유지 장치 없음 — 세션 없이 기존 동작(배경에선 재연결 멈춤).
class NoopPcLinkKeeper implements PcLinkKeeper {
  const NoopPcLinkKeeper();

  @override
  Future<bool> start({required void Function(PcLinkKeeperEnd reason) onEnded}) async => false;

  @override
  Future<void> stop() async {}
}

/// 안드로이드 — MainActivity의 app.loop/pclink 채널로 PcLinkService를 켜고 끈다.
class AndroidPcLinkKeeper implements PcLinkKeeper {
  AndroidPcLinkKeeper();

  static const _ch = MethodChannel('app.loop/pclink');
  void Function(PcLinkKeeperEnd reason)? _onEnded;

  @override
  Future<bool> start({required void Function(PcLinkKeeperEnd reason) onEnded}) async {
    _onEnded = onEnded;
    _ch.setMethodCallHandler((call) async {
      if (call.method != 'ended') return;
      final reason = switch ((call.arguments as Map?)?['reason']) {
        'timeout' => PcLinkKeeperEnd.timeout,
        'denied' => PcLinkKeeperEnd.denied,
        _ => PcLinkKeeperEnd.user,
      };
      _onEnded?.call(reason);
    });
    try {
      return await _ch.invokeMethod<bool>('start') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _onEnded = null;
    try {
      await _ch.invokeMethod<void>('stop');
    } catch (_) {}
  }
}

/// 링크 생명주기·페어링·도구 중계. UI가 구독한다.
class PcLinkController extends ChangeNotifier {
  PcLinkController({
    required this.db,
    PcLinkTransport? transport,
    McpTools? tools,
    this.connectTimeout = const Duration(seconds: 8),
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 30),
    ],
    this.maxRetries = 10,
    PcLinkKeeper? keeper,
    this.sessionIdle = const Duration(minutes: 60),
    Timer Function(Duration, void Function())? idleTimer,
  }) : _transport = transport ?? const TcpPcLinkTransport(),
       _tools = tools ?? McpTools(db),
       _keeper = keeper ?? const NoopPcLinkKeeper(),
       _idleTimerFactory = idleTimer ?? Timer.new;

  static const port = 8766;
  static const _keyHost = 'pclink_host';
  static const _keyDeviceId = 'pclink_device_id';
  static const _keySecret = 'pclink_secret';
  static const _codeMaxAttempts = 5;

  final LoopDb db;
  final PcLinkTransport _transport;
  final McpTools _tools;
  /// TCP 접속·hello 응답 대기 기본 시간.
  final Duration connectTimeout;

  /// 자동 재연결 간격 — n번째 재시도는 [n], 끝을 넘으면 마지막 값 반복.
  /// 기본 1·2·5·10·30초 → 이후 30초. 10회면 약 3분 시도 후 멈춘다.
  final List<Duration> retryDelays;

  /// 한 번 끊긴 뒤 연달아 시도할 최대 횟수. 넘으면 멈추고 끊김을 표시하며,
  /// 앱으로 돌아올 때([setForeground]) 다시 처음부터 시도한다.
  final int maxRetries;

  /// 세션 길이 — 연결 또는 마지막 질의 후 이만큼 조용하면 끊고 유지를 멈춘다.
  final Duration sessionIdle;

  final PcLinkKeeper _keeper;
  final Timer Function(Duration, void Function()) _idleTimerFactory;
  Timer? _idleTimer;

  /// 유지 시작을 요청함(응답 대기 포함) / 실제로 붙들고 있음.
  /// 세션 중에는 배경에서도 재연결이 돈다 — 프로세스가 얼지 않으므로.
  bool _sessionWanted = false;
  bool _session = false;

  PcLinkSocket? _socket;
  StreamSubscription<String>? _sub;
  Timer? _ping;
  int _nextPingMisses = 0;

  /// 연결을 유지하려는 의사 — 페어링된 링크가 붙으면 켜지고, 사용자가
  /// 끊거나 브리지가 재시도 불가 사유로 거절하면 꺼진다. 켜져 있는 동안
  /// 예기치 않은 단선은 자동 재연결한다. (브리지 재시작·업그레이드,
  /// 맥 잠자기, Wi-Fi 순단)
  bool _keepAlive = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _foreground = true;

  /// 단선 후 재연결 사이클 진행 중 — 대기·시도 중 모두 true라 화면 안내가
  /// 시도마다 깜빡이지 않는다. 붙거나, 포기하거나, 사용자가 끊으면 false.
  bool _retrying = false;

  PcLinkStatus _status = PcLinkStatus.off;
  PcLinkError? _lastError;
  int _attemptsLeft = _codeMaxAttempts;
  int _queries = 0;

  PcLinkStatus get status => _status;
  PcLinkError? get lastError => _lastError;
  int get attemptsLeft => _attemptsLeft;
  bool get paired {
    final s = db.getSetting(_keySecret);
    return s != null && s.isNotEmpty;
  }

  /// 저장된 맥 주소 — 마지막 연결 성공 호스트.
  String get host => db.getSetting(_keyHost) ?? '';

  /// 이번 연결에서 처리한 도구 호출 수 (화면 상태 표시용).
  int get queryCount => _queries;

  /// 끊겨서 자동 재연결 중(다음 시도 대기 또는 시도 중) — 화면은 오류 대신
  /// "다시 연결하는 중"을 보여준다.
  bool get reconnecting => _retrying;

  /// 폰을 식별하는 안정 id — 설치마다 1회 발급.
  String get deviceId {
    final existing = db.getSetting(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final id = List<int>.generate(16, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    db.setSetting(_keyDeviceId, id);
    return id;
  }

  // ── 연결 ──────────────────────────────────────────────────────

  /// [host]로 붙는다. null이면 저장된 호스트. 페어링된 경우 secret으로
  /// 즉시 연결되고, 아니면 코드 입력([waitingCode])으로 간다.
  /// 사용자가 직접 누르면 대기 중인 자동 재연결 타이머는 취소된다.
  Future<void> connect({String? host}) {
    _cancelRetryTimer();
    _retryAttempt = 0;
    return _connect(host);
  }

  Future<void> _connect(String? host) async {
    // 포트는 고정 — 붙여넣은 `http://…:8766/`도 호스트만 남긴다.
    final h = sanitizeHost(host ?? this.host);
    if (h.isEmpty) {
      _fail(PcLinkError.badHost);
      return;
    }
    await _teardown();
    _status = PcLinkStatus.connecting;
    _lastError = null;
    _attemptsLeft = _codeMaxAttempts;
    notifyListeners();

    final PcLinkSocket socket;
    try {
      socket = await _transport.connect(h, port, timeout: connectTimeout);
    } on PcLinkConnectException catch (e) {
      _fail(e.reason);
      return;
    }
    _socket = socket;
    _sub = socket.lines.listen(
      _onLine,
      onError: (_) => _fail(PcLinkError.disconnected),
      onDone: () => _fail(PcLinkError.disconnected),
    );
    socket.send(jsonEncode({
      't': 'hello',
      'id': deviceId,
      'proto': 1,
      // 폰이 가진 도구 목록 — 브리지가 이걸 Claude에 그대로 노출한다.
      // 새 도구는 앱 업데이트만으로 추가된다. 구 브리지는 무시.
      'tools': _tools.definitions,
      if (paired) 'secret': db.getSetting(_keySecret),
    }));
    db.setSetting(_keyHost, h);
  }

  /// [waitingCode]에서 사용자가 입력한 8자리를 보낸다.
  void submitCode(String code) {
    final s = _socket;
    if (_status != PcLinkStatus.waitingCode || s == null) return;
    _status = PcLinkStatus.pairing;
    notifyListeners();
    s.send(jsonEncode({'t': 'pair', 'code': code.trim()}));
  }

  /// 사용자가 끊거나 화면을 닫을 때. 페어링 정보는 유지. 자동 재연결도 멈춘다.
  Future<void> disconnect() async {
    _stopKeepAlive();
    _socket?.send(jsonEncode({'t': 'bye'}));
    await _teardown();
    _status = PcLinkStatus.off;
    _lastError = null;
    notifyListeners();
  }

  /// 페어링 해제 — secret을 지운다(맥 쪽 state.json은 맥에서 삭제).
  Future<void> unpair() async {
    await disconnect();
    db.setSetting(_keySecret, '');
    notifyListeners();
  }

  // ── 수신 ──────────────────────────────────────────────────────

  void _onLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> m;
    try {
      m = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (m['t']) {
      case 'need_code':
        // pairing 중에 왔으면 코드 불일치 — 코드 화면 유지 + 오류 표시.
        if (_status == PcLinkStatus.pairing) _lastError = PcLinkError.codeWrong;
        // 코드는 사람이 넣어야 한다 — 자동 재연결 대상이 아니다.
        _stopKeepAlive();
        _attemptsLeft = (m['attemptsLeft'] as num?)?.toInt() ?? _codeMaxAttempts;
        _status = PcLinkStatus.waitingCode;
        notifyListeners();
      case 'paired':
        final secret = m['secret'];
        if (secret is String && secret.isNotEmpty) {
          db.setSetting(_keySecret, secret);
        }
        _status = PcLinkStatus.connected;
        _lastError = null;
        _keepAlive = true;
        _retrying = false;
        _retryAttempt = 0;
        _cancelRetryTimer();
        _startPing();
        if (_foreground) _startSession();
        notifyListeners();
      case 'invoke':
        _onInvoke(m);
      case 'pong':
        _nextPingMisses = 0;
      case 'busy':
        _fail(PcLinkError.busy);
      case 'bye':
        switch (m['reason']) {
          case 'too_many':
            _fail(PcLinkError.tooMany);
          case 'code_expired':
            _fail(PcLinkError.codeExpired);
          case 'secret':
            // 맥이 재페어링된 경우 — secret 폐기 후 코드 절차로.
            db.setSetting(_keySecret, '');
            _fail(PcLinkError.codeExpired);
          default:
            _fail(PcLinkError.disconnected);
        }
    }
  }

  /// 브리지가 온 도구 호출 — 기존 MCP 도구 구현을 그대로 재사용.
  void _onInvoke(Map<String, dynamic> m) {
    final rid = m['rid'];
    final name = m['tool'];
    final args = (m['args'] as Map?)?.cast<String, Object?>() ?? {};
    final result = name is String
        ? _tools.call(name, args)
        : {'isError': true, 'content': [
            {'type': 'text', 'text': 'Unknown tool: $name'},
          ]};
    final isError = result['isError'] == true;
    final text = ((result['content'] as List?)?.first as Map?)?['text'];
    final reply = <String, Object?>{
      't': 'result',
      'rid': rid,
      'ok': !isError,
    };
    if (isError) {
      reply['error'] = text ?? 'error';
    } else {
      reply['text'] = text ?? '';
    }
    _socket?.send(jsonEncode(reply));
    _queries++;
    if (_session) _resetIdle();
    notifyListeners();
  }

  // ── 유지 ──────────────────────────────────────────────────────

  void _startPing() {
    _ping?.cancel();
    _nextPingMisses = 0;
    _ping = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_status != PcLinkStatus.connected) return;
      _socket?.send(jsonEncode({'t': 'ping'}));
      // pong 없이 3회(90초) 지나면 죽은 링크로 본다.
      if (++_nextPingMisses >= 3) _fail(PcLinkError.disconnected);
    });
  }

  Future<void> _teardown() async {
    _ping?.cancel();
    _ping = null;
    await _sub?.cancel();
    _sub = null;
    _socket?.close();
    _socket = null;
  }

  void _fail(PcLinkError reason) {
    _teardown();
    _status = PcLinkStatus.off;
    _lastError = reason;
    if (_keepAlive && paired && _retryable(reason)) {
      _scheduleRetry();
    } else {
      _stopKeepAlive();
    }
    notifyListeners();
  }

  // ── 자동 재연결 ────────────────────────────────────────────────

  /// 다시 시도하면 붙을 수 있는 단선 — 브리지가 잠시 내려갔거나 네트워크가
  /// 끊긴 경우. busy·tooMany·codeExpired(secret 무효 포함)·badHost는
  /// 사람이 손대야 하므로 멈춘다.
  static bool _retryable(PcLinkError e) =>
      e == PcLinkError.disconnected ||
      e == PcLinkError.refused ||
      e == PcLinkError.timeout;

  void _scheduleRetry() {
    _cancelRetryTimer();
    // 포기 — 끊김을 보여주고, 앱으로 돌아올 때 처음부터 다시. 세션도 끝.
    if (_retryAttempt >= maxRetries) {
      _retrying = false;
      _endSession();
      return;
    }
    _retrying = true;
    // 세션 없는 백그라운드 — 안드로이드가 프로세스를 얼리고 배터리도 쓴다.
    // 복귀 때 시도. 세션 중엔 유지 장치가 붙들고 있으니 계속 시도.
    if (!_foreground && !_session) return;
    final delay = retryDelays[min(_retryAttempt, retryDelays.length - 1)];
    _retryAttempt++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _connect(null);
    });
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _stopKeepAlive() {
    _keepAlive = false;
    _retrying = false;
    _retryAttempt = 0;
    _cancelRetryTimer();
    _endSession();
  }

  // ── 세션 유지 (ADR-003) ─────────────────────────────────────────

  /// 연결되면(전경에서만) 유지 장치를 켜고 [sessionIdle] 타이머를 건다.
  /// 이미 세션 중이면(자동 재연결) 타이머는 그대로 — 질의만 연장한다.
  Future<void> _startSession() async {
    if (_sessionWanted) return;
    _sessionWanted = true;
    bool ok;
    try {
      ok = await _keeper.start(onEnded: _onKeeperEnded);
    } catch (_) {
      ok = false;
    }
    if (!_sessionWanted) {
      // 기다리는 사이 링크가 끝났다.
      if (ok) _keeper.stop();
      return;
    }
    if (!ok) {
      _sessionWanted = false;
      return;
    }
    _session = true;
    _resetIdle();
  }

  void _resetIdle() {
    _idleTimer?.cancel();
    _idleTimer = _idleTimerFactory(sessionIdle, () {
      _idleTimer = null;
      disconnect();
    });
  }

  void _endSession() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (!_sessionWanted) return;
    final wasRunning = _session;
    _sessionWanted = false;
    _session = false;
    // 시작 응답 대기 중이면 [_startSession]이 받은 뒤 정리한다.
    if (wasRunning) _keeper.stop();
  }

  void _onKeeperEnded(PcLinkKeeperEnd reason) {
    if (reason == PcLinkKeeperEnd.denied) {
      // 서비스만 못 띄움 — 링크는 두고 기존 동작으로.
      _idleTimer?.cancel();
      _idleTimer = null;
      _sessionWanted = false;
      _session = false;
      if (!_foreground) _cancelRetryTimer();
      return;
    }
    disconnect();
  }

  /// 앱 전경/배경 전환 (main의 AppLifecycleListener가 부른다).
  /// 배경이면 재연결을 멈추고(세션 중이면 계속), 전경으로 돌아오면 끊겨
  /// 있던 링크를 바로 다시 붙인다 — 재시도를 다 써서 포기한 경우도 포함.
  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (!foreground) {
      if (!_session) _cancelRetryTimer();
      notifyListeners();
      return;
    }
    // 배경에서 붙었던 링크 — 이제 유지를 켤 수 있다.
    if (_status == PcLinkStatus.connected) _startSession();
    if (_keepAlive && _status == PcLinkStatus.off) {
      _retryAttempt = 0;
      _retrying = true;
      _connect(null);
    }
  }

  @override
  void dispose() {
    _cancelRetryTimer();
    _endSession();
    _teardown();
    super.dispose();
  }
}
