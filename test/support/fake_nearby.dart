import 'dart:async';

import 'package:loop/services/nearby_transport.dart';
import 'package:loop/services/share_platform.dart';

/// 메모리 전송 계층 — 테스트가 상대 기기 역할(발견·수락·진행·끊김)을
/// 직접 일으킨다. 실제 Nearby 플러그인 없이 상태 머신 전체를 돌린다.
class FakeTransport implements NearbyTransport {
  /// 호출 기록 — 순서 검증용 ('startDiscovery', 'stopDiscovery', ...).
  final calls = <String>[];

  bool discoveryOk = true;
  bool advertiseOk = true;

  /// connect 결과. [connectCompleter]가 있으면 그것을 기다린다(시간 초과 검증).
  bool connectOk = true;
  Completer<bool>? connectCompleter;

  int nextPayloadId = 7;

  /// sendFile이 id를 돌려주기 *전에* 진행 이벤트를 흘려보낼 때.
  void Function(int payloadId)? beforeSendReturns;

  bool discovering = false;
  bool advertising = false;
  String? discoveryName;
  String? advertisedName;
  String? connectName;
  String? connectedTo;
  final sent = <({String deviceId, String path})>[];
  final disconnected = <String>[];

  void Function(NearbyDevice)? _onFound;
  void Function(String)? _onLost;
  void Function(TransferUpdate)? _onUpdate;
  void Function()? _onDisconnected;
  void Function(String path)? _onFile;
  void Function(IncomingUpdate)? _onIncoming;

  // ── 상대 기기 역할 ─────────────────────────────────────────
  void find(String id, String name) =>
      _onFound?.call(NearbyDevice(id: id, name: name));

  void lose(String id) => _onLost?.call(id);

  void progress(int payloadId, int bytes, int total) => _onUpdate?.call(
    TransferUpdate(
      payloadId: payloadId,
      status: TransferStatus.inProgress,
      bytesTransferred: bytes,
      totalBytes: total,
    ),
  );

  void succeed(int payloadId) => _onUpdate?.call(
    TransferUpdate(
      payloadId: payloadId,
      status: TransferStatus.success,
      bytesTransferred: 100,
      totalBytes: 100,
    ),
  );

  void failTransfer(int payloadId) => _onUpdate?.call(
    TransferUpdate(payloadId: payloadId, status: TransferStatus.failure),
  );

  /// 상대가 연결을 끊음 (받는 쪽이 다 받고 끊는 정상 경로 포함).
  void peerDisconnects() {
    connectedTo = null;
    final d = _onDisconnected;
    _onUpdate = null;
    _onDisconnected = null;
    d?.call();
  }

  /// 받기 대기 중 파일이 도착함.
  void deliver(String path) => _onFile?.call(path);

  // ── 받는 쪽 진행 (보내는 상대 역할) ─────────────────────────
  void incoming(
    String id,
    IncomingStatus status, {
    String name = '지민',
    int bytes = 0,
    int total = 0,
  }) => _onIncoming?.call(
    IncomingUpdate(
      endpointId: id,
      senderName: name,
      status: status,
      bytesTransferred: bytes,
      totalBytes: total,
    ),
  );

  // ── NearbyTransport ────────────────────────────────────────
  @override
  Future<bool> startDiscovery(
    String myName, {
    required void Function(NearbyDevice device) onFound,
    required void Function(String deviceId) onLost,
  }) async {
    calls.add('startDiscovery');
    discoveryName = myName;
    if (!discoveryOk) return false;
    _onFound = onFound;
    _onLost = onLost;
    discovering = true;
    return true;
  }

  @override
  Future<void> stopDiscovery() async {
    calls.add('stopDiscovery');
    discovering = false;
    _onFound = null;
    _onLost = null;
  }

  @override
  Future<bool> connect(
    String myName,
    String deviceId, {
    required void Function(TransferUpdate update) onUpdate,
    required void Function() onDisconnected,
  }) async {
    calls.add('connect:$deviceId');
    connectName = myName;
    _onUpdate = onUpdate;
    _onDisconnected = onDisconnected;
    final ok = connectCompleter != null
        ? await connectCompleter!.future
        : connectOk;
    if (ok) connectedTo = deviceId;
    return ok;
  }

  @override
  Future<int> sendFile(String deviceId, String path) async {
    calls.add('sendFile:$deviceId');
    sent.add((deviceId: deviceId, path: path));
    final id = nextPayloadId;
    beforeSendReturns?.call(id);
    return id;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    calls.add('disconnect:$deviceId');
    disconnected.add(deviceId);
    if (connectedTo == deviceId) connectedTo = null;
    _onUpdate = null;
    _onDisconnected = null;
  }

  @override
  Future<bool> startAdvertising(
    String myName, {
    required void Function(String path) onFile,
    void Function(IncomingUpdate update)? onIncoming,
  }) async {
    calls.add('startAdvertising:$myName');
    if (!advertiseOk) return false;
    advertisedName = myName;
    _onFile = onFile;
    _onIncoming = onIncoming;
    advertising = true;
    return true;
  }

  @override
  Future<void> stopAdvertising() async {
    calls.add('stopAdvertising');
    advertising = false;
    _onFile = null;
    _onIncoming = null;
  }

}

/// 권한·기기 이름 가짜 — 허용 여부와 팝업 횟수를 테스트가 정한다/센다.
class FakeSharePlatform implements SharePlatform {
  FakeSharePlatform({
    this.supported = true,
    this.granted = false,
    this.grantOnRequest = true,
    this.name = 'Pixel 9',
  });

  @override
  bool supported;

  /// 이미 허용된 상태인가.
  bool granted;

  /// 요청 팝업에서 사용자가 허용하는가.
  bool grantOnRequest;

  String name;
  int requestCount = 0;

  @override
  Future<bool> hasPermissions() async => granted;

  @override
  Future<bool> requestPermissions() async {
    requestCount++;
    if (grantOnRequest) granted = true;
    return granted;
  }

  @override
  Future<String> deviceName() async => name;
}

