import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/loop_db.dart';
import 'native_nearby_transport.dart';
import 'nearby_transport.dart';
import 'share_files.dart';
import 'share_platform.dart';

/// 근거리 사슬 공유의 앱 로직 — 보내기 상태 머신과 받기 대기.
/// (docs/share-design.md §6)
///
/// 이 파일은 [NearbyTransport]·[SharePlatform] 인터페이스에만 의존한다.
/// 플러그인·OS는 [NearbyShareDefaults]에서 한 번 꽂히고, 테스트는 가짜를
/// 생성자로 넘긴다 — 폰 없이 전체 흐름을 검증하기 위한 분리.

/// 앱 기본 구성 — 실제 구현. 전송 계층 인스턴스는 반드시 하나여야 한다
/// (플러그인의 페이로드 콜백이 전역이라 디스패처가 둘이면 서로 덮어쓴다).
/// 둘 다 생성만으로는 플랫폼을 건드리지 않는다(첫 사용 때 연결).
class NearbyShareDefaults {
  NearbyShareDefaults._();

  static final NearbyTransport transport = NativeNearbyTransport();
  static final SharePlatform platform = DeviceSharePlatform();
}

/// 보내기 단계 — 전송 화면(share_sheet)이 그대로 그린다.
enum ShareStage { searching, connecting, sending, done, fail }

/// 실패 이유 — 화면이 사용자에게 다음 행동을 안내하는 데 쓴다.
enum ShareFailure {
  /// 권한 거부 — 설정에서 허용해야 한다.
  permission,

  /// 미지원 플랫폼이거나 탐색 자체를 시작하지 못함.
  unavailable,

  /// 시간 안에 받을 기기를 못 찾음 — 받는 쪽이 받기를 켜야 한다.
  notFound,

  /// 연결 거절·시간 초과.
  connect,

  /// 전송 중 실패·끊김.
  transfer,

  /// 한동안 바이트가 늘지 않음 — 멀어졌거나 연결이 사실상 죽었다.
  stalled,
}

/// 보내기 상태 머신 — 권한 → 탐색(발견 목록) → 사용자가 기기 선택 →
/// 연결 → 파일 전송 → 받는 쪽이 끊으면(=다 받음) 완료.
///
/// 처음 발견한 기기로 자동 연결하지 않는다 — 근처에 Loop 기기가 여럿이면
/// 엉뚱한 사람에게 갈 수 있어서, 항상 목록에서 탭해 고른다.
class ShareSendController extends ChangeNotifier {
  ShareSendController({
    required this.file,
    required this.myName,
    NearbyTransport? transport,
    SharePlatform? platform,
    this.searchTimeout = const Duration(seconds: 60),
    this.connectTimeout = const Duration(seconds: 30),
    this.stallTimeout = const Duration(seconds: 60),
    this.drainTimeout = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _transport = transport ?? NearbyShareDefaults.transport,
       _platform = platform ?? NearbyShareDefaults.platform,
       _clock = clock ?? DateTime.now;

  final File file;

  /// 보내는 쪽 표시명 — 비었으면 기기 이름으로 대신한다.
  final String myName;

  /// 기기가 하나도 안 보일 때 포기하기까지. 목록에 기기가 있으면
  /// 사용자가 고를 때까지 기다린다.
  final Duration searchTimeout;
  final Duration connectTimeout;

  /// 전송 중 이 시간 동안 바이트가 늘지 않으면 실패. 전체 시간 상한은
  /// 두지 않는다 — 블루투스로 느리게라도 계속 가고 있으면 끝까지 보낸다.
  final Duration stallTimeout;

  /// 내 쪽 전송 완료(SUCCESS) 뒤 받는 쪽이 파일을 옮기고 연결을 끊을
  /// 때까지 기다리는 상한. 바로 끊으면 상대의 마지막 바이트가 잘릴 수 있다.
  final Duration drainTimeout;

  final NearbyTransport _transport;
  final SharePlatform _platform;
  final DateTime Function() _clock;

  /// 속도 계산 창 — 최근 이만큼의 진행으로 순간 속도를 잰다.
  static const _rateWindow = Duration(seconds: 3);

  /// 이보다 느리면 블루투스 경로로 본다(Wi-Fi Direct는 수 MB/s 이상).
  static const slowBytesPerSecond = 1024 * 1024;

  /// 느림 판정 전 최소 관찰 시간 / 남은 시간이 이보다 짧으면 안내 안 함.
  static const _slowAfter = Duration(seconds: 4);
  static const _slowMinEta = Duration(seconds: 20);

  ShareStage _stage = ShareStage.searching;
  ShareFailure? _failure;
  final _devices = <String, NearbyDevice>{};
  NearbyDevice? _device;
  double _progress = 0;

  String _name = '';
  int? _payloadId;
  final _early = <int, TransferUpdate>{};
  bool _sentAll = false;
  bool _closed = false;
  bool _disposed = false;
  Timer? _searchTimer;
  Timer? _stallTimer;
  Timer? _drainTimer;

  int _sentBytes = 0;
  int _totalBytes = 0;
  DateTime? _sendStart;
  final _samples = <({DateTime at, int bytes})>[];

  ShareStage get stage => _stage;
  ShareFailure? get failure => _failure;

  /// 발견 순서대로 — 사라진 기기는 빠진다.
  List<NearbyDevice> get devices => List.unmodifiable(_devices.values);

  /// 고른 기기 (탐색 중엔 null).
  NearbyDevice? get device => _device;

  /// 0..1
  double get progress => _progress;

  bool get finished => _stage == ShareStage.done || _stage == ShareStage.fail;

  /// 보낸 바이트 / 전체 바이트 (전체를 모르면 0).
  int get sentBytes => _sentBytes;
  int get totalBytes => _totalBytes;

  /// 최근 [_rateWindow] 기준 속도. 관찰이 1초 미만이면 null.
  double? get bytesPerSecond {
    if (_samples.length < 2) return null;
    final a = _samples.first, b = _samples.last;
    final ms = b.at.difference(a.at).inMilliseconds;
    if (ms < 1000) return null;
    return (b.bytes - a.bytes) * 1000 / ms;
  }

  /// 남은 시간 추정 — 속도나 전체 크기를 모르면 null.
  Duration? get eta {
    final r = bytesPerSecond;
    if (r == null || r <= 0 || _totalBytes <= 0) return null;
    final left = (_totalBytes - _sentBytes).clamp(0, _totalBytes);
    return Duration(milliseconds: (left * 1000 / r).round());
  }

  /// 느린 경로(블루투스)로 가는 중 — "Wi-Fi를 켜고 다시" 안내를 띄울 때.
  /// 잠깐 관찰한 뒤에만, 그리고 곧 끝날 전송이면 굳이 띄우지 않는다.
  bool get slow {
    if (_stage != ShareStage.sending || _sentAll) return false;
    final start = _sendStart, r = bytesPerSecond;
    if (start == null || r == null) return false;
    if (_clock().difference(start) < _slowAfter) return false;
    if (r >= slowBytesPerSecond) return false;
    final left = eta;
    return left == null || left > _slowMinEta;
  }
  /// 권한 → 탐색 시작. 화면이 뜨자마자 한 번 부른다.
  Future<void> start() async {
    if (!_platform.supported) return _fail(ShareFailure.unavailable);
    if (!await _platform.requestPermissions()) {
      return _fail(ShareFailure.permission);
    }
    if (_closed) return;
    final typed = myName.trim();
    _name = typed.isEmpty ? await _platform.deviceName() : typed;
    if (_closed) return;
    final ok = await _transport.startDiscovery(
      _name,
      onFound: _onFound,
      onLost: _onLost,
    );
    if (_closed) {
      if (ok) await _transport.stopDiscovery();
      return;
    }
    if (!ok) return _fail(ShareFailure.unavailable);
    _armSearchTimer();
  }

  /// 실패 뒤 "다시 찾기" — 받는 쪽이 받기를 켠 다음 등.
  Future<void> retry() async {
    if (_stage != ShareStage.fail || _disposed) return;
    _cancelTimers();
    _closed = false;
    _stage = ShareStage.searching;
    _failure = null;
    _devices.clear();
    _device = null;
    _progress = 0;
    _payloadId = null;
    _early.clear();
    _sentAll = false;
    _sentBytes = 0;
    _totalBytes = 0;
    _sendStart = null;
    _samples.clear();
    _notify();
    await start();
  }

  void _onFound(NearbyDevice d) {
    if (_closed || _stage != ShareStage.searching) return;
    _devices[d.id] = d;
    _notify();
  }

  void _onLost(String id) {
    if (_closed || _stage != ShareStage.searching) return;
    if (_devices.remove(id) == null) return;
    if (_devices.isEmpty) _armSearchTimer();
    _notify();
  }

  void _armSearchTimer() {
    if (_searchTimer?.isActive ?? false) return;
    _searchTimer = Timer(searchTimeout, () {
      if (_closed || _stage != ShareStage.searching || _devices.isNotEmpty) {
        return;
      }
      unawaited(_transport.stopDiscovery());
      _fail(ShareFailure.notFound);
    });
  }

  /// 사용자가 목록에서 기기를 골랐다 → 연결 → 전송.
  Future<void> select(NearbyDevice d) async {
    if (_closed || _stage != ShareStage.searching) return;
    _searchTimer?.cancel();
    _device = d;
    _stage = ShareStage.connecting;
    _notify();
    await _transport.stopDiscovery();

    bool connected;
    try {
      connected = await _transport
          .connect(
            _name,
            d.id,
            onUpdate: _onUpdate,
            onDisconnected: _onDisconnected,
          )
          .timeout(connectTimeout);
    } on TimeoutException {
      connected = false;
    } catch (_) {
      connected = false;
    }
    if (_closed || _stage != ShareStage.connecting) return;
    if (!connected) return _endFail(ShareFailure.connect);

    _stage = ShareStage.sending;
    _progress = 0;
    _notify();
    final int id;
    try {
      id = await _transport.sendFile(d.id, file.path);
    } catch (_) {
      if (!_closed) _endFail(ShareFailure.transfer);
      return;
    }
    if (_closed || _stage != ShareStage.sending) return;
    _payloadId = id;
    _sendStart = _clock();
    _samples
      ..clear()
      ..add((at: _sendStart!, bytes: 0));
    _armStall();
    // sendFile 결과보다 먼저 도착한 진행 이벤트가 있으면 이제 반영.
    final early = _early.remove(id);
    _early.clear();
    if (early != null) _onUpdate(early);
  }

  /// 바이트가 늘 때마다 다시 건다 — [stallTimeout] 동안 그대로면 실패.
  void _armStall() {
    _stallTimer?.cancel();
    _stallTimer = Timer(stallTimeout, () {
      if (!_closed && _stage == ShareStage.sending && !_sentAll) {
        _endFail(ShareFailure.stalled);
      }
    });
  }

  void _record(int bytes, int total) {
    if (total > 0) _totalBytes = total;
    if (bytes <= _sentBytes) return;
    _sentBytes = bytes;
    final now = _clock();
    _samples.add((at: now, bytes: bytes));
    // 창 밖 표본은 버리되, 기준점 하나는 창 경계 바깥에 남긴다.
    while (_samples.length > 2 &&
        now.difference(_samples[1].at) >= _rateWindow) {
      _samples.removeAt(0);
    }
    _armStall();
  }

  void _onUpdate(TransferUpdate u) {
    if (_closed || _stage != ShareStage.sending) return;
    final id = _payloadId;
    if (id == null) {
      _early[u.payloadId] = u; // 아직 내 페이로드 id를 모른다 — 보류
      return;
    }
    if (u.payloadId != id || _sentAll) return;
    switch (u.status) {
      case TransferStatus.inProgress:
        _record(u.bytesTransferred, u.totalBytes);
        final f = u.fraction;
        if (f != null && f > _progress) _progress = f;
        _notify();
      case TransferStatus.success:
        _sentAll = true;
        _progress = 1;
        if (u.totalBytes > 0) {
          _totalBytes = u.totalBytes;
          _sentBytes = u.totalBytes;
        }
        _stallTimer?.cancel();
        _notify();
        // 받는 쪽이 파일을 옮기고 끊으면 완료. 안 끊으면 상한 뒤 내가 끊는다.
        _drainTimer = Timer(drainTimeout, _complete);
      case TransferStatus.failure:
      case TransferStatus.canceled:
        _endFail(ShareFailure.transfer);
    }
  }

  void _onDisconnected() {
    if (_closed) return;
    // 받는 쪽이 다 받고 끊었다. 내 SUCCESS보다 상대의 끊김이 먼저 올 수도
    // 있어서, 바이트를 전부 보낸 게 확인됐으면(진행률 100%) 완료로 본다.
    if (!_sentAll && _stage == ShareStage.sending && _progress >= 1) {
      _sentAll = true;
    }
    if (_sentAll) return _complete();
    if (_stage == ShareStage.connecting || _stage == ShareStage.sending) {
      _endFail(ShareFailure.transfer);
    }
  }

  void _complete() {
    if (_stage != ShareStage.sending || !_sentAll) return;
    _cancelTimers();
    _stage = ShareStage.done;
    _notify();
    final d = _device;
    if (d != null) unawaited(_transport.disconnect(d.id));
  }

  /// 연결이 있었으면 그 기기만 끊고 실패로.
  void _endFail(ShareFailure f) {
    final d = _device;
    if (d != null) unawaited(_transport.disconnect(d.id));
    _fail(f);
  }

  void _fail(ShareFailure f) {
    if (finished) return;
    _cancelTimers();
    _failure = f;
    _stage = ShareStage.fail;
    _notify();
  }

  /// 사용자가 취소 — 탐색·연결을 정리하고 이후 이벤트는 무시한다.
  Future<void> cancel() async {
    if (_closed) return;
    _closed = true;
    _cancelTimers();
    final searching = _stage == ShareStage.searching;
    final d = _device;
    if (searching) await _transport.stopDiscovery();
    if (d != null && !finished) await _transport.disconnect(d.id);
  }

  void _cancelTimers() {
    _searchTimer?.cancel();
    _stallTimer?.cancel();
    _drainTimer?.cancel();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (!_closed) unawaited(cancel());
    _disposed = true;
    super.dispose();
  }
}

/// 받는 중 표시 상태.
enum IncomingShareStatus { receiving, completed, failed }

/// 지금 받고 있는(또는 방금 끝난) 전송 — 받는 쪽 알림이 그린다.
class IncomingShare {
  const IncomingShare({
    required this.endpointId,
    required this.senderName,
    required this.status,
    this.bytes = 0,
    this.total = 0,
  });

  final String endpointId;
  final String senderName;
  final IncomingShareStatus status;
  final int bytes;
  final int total;

  /// 0..1, 크기를 아직 모르면 null.
  double? get fraction => total > 0 ? (bytes / total).clamp(0.0, 1.0) : null;

  IncomingShare copyWith({IncomingShareStatus? status, int? bytes, int? total}) =>
      IncomingShare(
        endpointId: endpointId,
        senderName: senderName,
        status: status ?? this.status,
        bytes: bytes ?? this.bytes,
        total: total ?? this.total,
      );
}

/// 받기 대기 — 앱이 켜져 있는 동안만 옆 기기에 보인다.
///
/// 권한 정책 (docs/share-design.md §6):
///  - 앱 시작: 권한이 **이미** 있고 사용자가 끄지 않았으면 조용히 대기.
///    권한 팝업은 띄우지 않는다(공유를 안 쓰는 사람까지 묻지 않게).
///  - 설정 › "가까운 기기에서 받기"를 켜면 그때 권한을 요청하고 대기.
///  - 끄면 저장해 두고 다음 실행에도 자동 대기하지 않는다.
class ShareReceiver extends ChangeNotifier {
  ShareReceiver({
    NearbyTransport? transport,
    SharePlatform? platform,
    this.stallTimeout = const Duration(seconds: 60),
  }) : _transport = transport ?? NearbyShareDefaults.transport,
       _platform = platform ?? NearbyShareDefaults.platform;

  /// 받는 중 이 시간 동안 바이트가 늘지 않으면 이쪽에서 끊고 실패로
  /// 정리한다(미완성 파일 삭제 포함). 보내는 쪽 [ShareSendController]와 같은 값.
  final Duration stallTimeout;

  static ShareReceiver? _instance;

  /// 앱 전역 받기 대기 (실제 구현). 테스트는 생성자로 따로 만든다.
  static ShareReceiver get instance => _instance ??= ShareReceiver();

  /// 설정 키 — '0' = 사용자가 끔, 그 외/없음 = 권한만 있으면 자동 대기.
  static const prefKey = 'share_receive';

  final NearbyTransport _transport;
  final SharePlatform _platform;

  bool _active = false;
  IncomingShare? _incoming;
  Timer? _stallTimer;

  /// 파일이 온전히 도착했을 때 — 앱이 받기 시트를 띄운다.
  void Function(File file)? onReceived;

  /// 받는 중·방금 끝난 전송 (없으면 null). 알림이 이걸 보고 그린다.
  IncomingShare? get incoming => _incoming;

  /// 알림이 실패·완료를 보여준 뒤 치운다.
  void clearIncoming() {
    if (_incoming == null) return;
    if (_incoming!.status == IncomingShareStatus.receiving) return;
    _incoming = null;
    notifyListeners();
  }

  void _onIncoming(IncomingUpdate u) {
    final cur = _incoming;
    // 다른 상대의 늦은 이벤트는 지금 표시 중인 것을 덮지 않는다.
    if (u.status != IncomingStatus.started &&
        cur != null &&
        cur.endpointId != u.endpointId) {
      return;
    }
    switch (u.status) {
      case IncomingStatus.started:
        _incoming = IncomingShare(
          endpointId: u.endpointId,
          senderName: u.senderName,
          status: IncomingShareStatus.receiving,
        );
        _armStall(u.endpointId);
      case IncomingStatus.progress:
        if (cur == null || cur.status != IncomingShareStatus.receiving) return;
        if (u.bytesTransferred > cur.bytes) _armStall(u.endpointId);
        _incoming = cur.copyWith(bytes: u.bytesTransferred, total: u.totalBytes);
      case IncomingStatus.completed:
        _stallTimer?.cancel();
        if (cur == null) return;
        _incoming = cur.copyWith(
          status: IncomingShareStatus.completed,
          bytes: u.totalBytes,
          total: u.totalBytes,
        );
      case IncomingStatus.failed:
        _stallTimer?.cancel();
        if (cur == null || cur.status == IncomingShareStatus.failed) return;
        _incoming = cur.copyWith(status: IncomingShareStatus.failed);
        unawaited(ShareJanitor.instance?.sweep());
    }
    notifyListeners();
  }

  void _armStall(String endpointId) {
    _stallTimer?.cancel();
    _stallTimer = Timer(stallTimeout, () {
      final cur = _incoming;
      if (cur == null ||
          cur.endpointId != endpointId ||
          cur.status != IncomingShareStatus.receiving) {
        return;
      }
      _incoming = cur.copyWith(status: IncomingShareStatus.failed);
      notifyListeners();
      // 끊으면 전송 계층이 미완성 파일을 지운다.
      unawaited(_transport.disconnect(endpointId));
    });
  }

  bool get supported => _platform.supported;

  /// 지금 옆 기기에 보이는 중인가.
  bool get active => _active;

  /// 사용자가 설정에서 꺼 둔 상태인가.
  static bool userDisabled(LoopDb db) => db.getSetting(prefKey) == '0';

  /// 앱 시작 때 — 조건이 맞으면 팝업 없이 대기 시작.
  Future<bool> startIfAllowed(LoopDb db) async {
    if (!_platform.supported || userDisabled(db)) return false;
    if (!await _platform.hasPermissions()) return false;
    return _start(db);
  }

  /// 설정 스위치. 켜기는 권한 요청 → 대기, 끄기는 저장 후 중지.
  /// 결과 상태(active)를 돌려준다 — 권한 거부면 false이고 설정은 그대로.
  Future<bool> setEnabled(LoopDb db, bool on) async {
    if (!on) {
      db.setSetting(prefKey, '0');
      _stallTimer?.cancel();
      if (_active) await _transport.stopAdvertising();
      _set(false);
      return false;
    }
    if (!_platform.supported) return false;
    if (!await _platform.requestPermissions()) return false;
    db.setSetting(prefKey, '');
    return _start(db);
  }

  /// 표시명이 바뀌었을 때 — 대기 중이면 새 이름으로 다시 광고.
  Future<void> refreshName(LoopDb db) async {
    if (_active) await _start(db);
  }

  Future<bool> _start(LoopDb db) async {
    final saved = db.shareName()?.trim();
    final name = saved == null || saved.isEmpty
        ? await _platform.deviceName()
        : saved;
    final ok = await _transport.startAdvertising(
      name,
      onFile: (path) => onReceived?.call(File(path)),
      onIncoming: _onIncoming,
    );
    _set(ok);
    return ok;
  }

  void _set(bool v) {
    if (_active == v) return;
    _active = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    super.dispose();
  }
}
