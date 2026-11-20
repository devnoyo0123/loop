import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'nearby_transport.dart';
import 'share_files.dart';

/// [NearbyTransport]의 실제 구현 — 앱 Kotlin 번역층(NearbyBridge.kt)을 통해
/// Google Nearby Connections를 직접 쓴다. (docs/share-design.md §6.6)
///
/// 왜 플러그인이 아닌가: FILE 페이로드는 Play 서비스가 공용 Downloads에
/// 쓰고 앱이 위치를 정할 수 없다(일기 내용이 공용 폴더에 놓이고, 미완성
/// 파일은 회수가 어렵다). STREAM으로 보내면 받는 쪽이 앱 폴더(share/)에
/// 직접 쓰고, 미완성은 그 폴더의 `.part`로만 남는다 — 청소·수동 정리 가능.
///
/// 프로토콜 (보내는 쪽 → 받는 쪽, 같은 연결에서 순서대로):
///  1. BYTES 헤더 `{"loop":"chain","v":1,"size":N}` — STREAM은 전체 크기를
///     알려주지 않아(total=-1) 진행률과 무결성 확인에 쓴다.
///  2. STREAM 본문 — Kotlin이 받는 즉시 `share/in-<ep>-<pid>.part`로 흘려 쓴다.
///
/// 완료 판정(받는 쪽): Nearby SUCCESS **그리고** 파일 쓰기 성공 **그리고**
/// 바이트 수 = 헤더 크기. 그때 `.part` → `.looplog`로 바꿔 넘기고 연결을 끊는다.
/// 판단은 전부 여기(Dart)서 — Kotlin은 옮기기만 한다.
class NativeNearbyTransport implements NearbyTransport {
  NativeNearbyTransport({
    MethodChannel methods = const MethodChannel('app.loop/nearby'),
    EventChannel eventChannel = const EventChannel('app.loop/nearby/events'),
    Future<Directory> Function()? shareDir,
  }) : _m = methods,
       _events = eventChannel,
       _shareDir = shareDir ?? ShareTempFiles.dir;

  /// 상호 발견의 열쇠 — 같은 serviceId끼리만 서로 보인다.
  static const serviceId = 'app.loop';

  final MethodChannel _m;
  final EventChannel _events;
  final Future<Directory> Function() _shareDir;

  StreamSubscription<Object?>? _sub;

  // 보내기
  void Function(NearbyDevice)? _onFound;
  void Function(String)? _onLost;
  final _connecting = <String, Completer<bool>>{};
  final _outUpdate = <String, void Function(TransferUpdate)>{};
  final _outDisconnect = <String, void Function()>{};
  final _outSize = <String, int>{};

  // 받기
  final _inbound = <String, _Inbound>{};
  void Function(String path)? _onFile;
  void Function(IncomingUpdate)? _onIncoming;

  /// 이벤트 채널은 첫 사용 때 구독한다(테스트·미지원 플랫폼에서 안전).
  void _listen() {
    _sub ??= _events.receiveBroadcastStream().listen(
      (e) => _dispatch((e as Map).cast<String, Object?>()),
      onError: (_) {},
    );
  }

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _m.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // ── 이벤트 라우팅 ───────────────────────────────────────────

  void _dispatch(Map<String, Object?> e) {
    final id = e['id'] as String? ?? '';
    switch (e['e']) {
      case 'found':
        _onFound?.call(NearbyDevice(id: id, name: e['name'] as String? ?? ''));
      case 'lost':
        _onLost?.call(id);
      case 'initiated':
        if (e['role'] == 'ad') {
          final b = _inbound[id] = _Inbound(e['name'] as String? ?? '');
          _emit(id, b, IncomingStatus.started);
        } else if (!_connecting.containsKey(id)) {
          return; // 우리가 건 연결이 아니다
        }
        unawaited(_call<bool>('acceptConnection', {'endpointId': id}));
      case 'result':
        final ok = e['ok'] == true;
        if (e['role'] == 'ad') {
          if (!ok) _dropInbound(id);
        } else {
          final c = _connecting.remove(id);
          if (c != null && !c.isCompleted) {
            c.complete(ok);
          } else if (ok && !_outUpdate.containsKey(id)) {
            unawaited(disconnect(id)); // 포기한 뒤 늦게 붙음 — 정리
          }
        }
      case 'disconnected':
        if (e['role'] == 'ad') {
          _dropInbound(id);
        } else {
          final c = _connecting.remove(id);
          if (c != null && !c.isCompleted) c.complete(false);
          _outUpdate.remove(id);
          _outSize.remove(id);
          _outDisconnect.remove(id)?.call();
        }
      case 'bytes':
        _onHeader(id, e['data']);
      case 'stream':
        final b = _inbound[id];
        final path = e['path'] as String;
        ShareTempFiles.hold(path); // 쓰는 중 — 청소 제외
        if (b == null) {
          _deleteQuietly(path); // 받기 연결이 아니다
          return;
        }
        b.parts[_pid(e)] = _Part(path);
      case 'streamDone':
        final b = _inbound[id];
        final part = b?.parts[_pid(e)];
        if (b == null || part == null) {
          _deleteQuietly(e['path'] as String);
          return;
        }
        part
          ..written = true
          ..writeOk = e['ok'] == true
          ..bytes = (e['bytes'] as num?)?.toInt() ?? -1;
        _settle(id, b, _pid(e), part);
      case 'update':
        _onUpdate(id, e);
    }
  }

  static int _pid(Map<String, Object?> e) => (e['pid'] as num).toInt();

  void _onUpdate(String id, Map<String, Object?> e) {
    final status = switch (e['status']) {
      'success' => TransferStatus.success,
      'failure' => TransferStatus.failure,
      'canceled' => TransferStatus.canceled,
      _ => TransferStatus.inProgress,
    };
    final bytes = (e['bytes'] as num?)?.toInt() ?? 0;
    final out = _outUpdate[id];
    if (out != null) {
      // STREAM은 total=-1 — 보낸 파일 크기로 채운다.
      out(
        TransferUpdate(
          payloadId: _pid(e),
          status: status,
          bytesTransferred: bytes,
          totalBytes: _outSize[id] ?? 0,
        ),
      );
      return;
    }
    final b = _inbound[id];
    final part = b?.parts[_pid(e)];
    if (b == null || part == null) return; // 헤더(BYTES) 진행 등
    switch (status) {
      case TransferStatus.inProgress:
        _emit(
          id,
          b,
          IncomingStatus.progress,
          bytes: bytes,
          total: b.expected ?? 0,
        );
      case TransferStatus.success:
        part.nearbyOk = true;
        _settle(id, b, _pid(e), part);
      case TransferStatus.failure:
      case TransferStatus.canceled:
        _failInbound(id, b);
    }
  }

  void _onHeader(String id, Object? data) {
    final b = _inbound[id];
    if (b == null || data is! List<int>) return;
    try {
      final h = jsonDecode(utf8.decode(data));
      if (h is Map && h['loop'] == 'chain') {
        b.expected = (h['size'] as num?)?.toInt();
      }
    } catch (_) {
      // 모르는 바이트 — 무시
    }
  }

  /// Nearby 완료와 파일 쓰기 완료가 둘 다 와야 판정한다(순서 무관).
  void _settle(String id, _Inbound b, int pid, _Part part) {
    if (!part.written) return;
    if (!part.writeOk) return _failInbound(id, b);
    if (!part.nearbyOk) return;
    final expected = b.expected;
    if (expected != null && part.bytes != expected) {
      return _failInbound(id, b); // 잘린 파일
    }
    b.parts.remove(pid);
    b.delivering = true;
    _emit(id, b, IncomingStatus.completed, bytes: part.bytes, total: part.bytes);
    unawaited(_deliver(id, b, part));
  }

  Future<void> _deliver(String id, _Inbound b, _Part part) async {
    final dest = part.path.replaceFirst(RegExp(r'\.part$'), '.looplog');
    try {
      await File(part.path).rename(dest);
      ShareTempFiles.release(part.path);
      final cb = _onFile;
      if (cb != null) {
        cb(dest);
      } else {
        _deleteQuietly(dest); // 받기를 끈 사이 도착
      }
    } catch (_) {
      ShareTempFiles.release(part.path);
      _deleteQuietly(part.path);
      _deleteQuietly(dest);
      b.failed = true;
      _emit(id, b, IncomingStatus.failed);
    } finally {
      _inbound.remove(id);
      // 받는 쪽이 끊는다 — 보내는 쪽은 이 끊김을 "다 받았다"로 읽는다.
      await _call<void>('disconnect', {'endpointId': id});
    }
  }

  void _failInbound(String id, _Inbound b) {
    _discardParts(b);
    if (!b.failed) {
      b.failed = true;
      _emit(id, b, IncomingStatus.failed);
    }
  }

  /// 받기 연결 정리 — 미완성 파일은 지우고, 넘기는 중이 아니면 실패로.
  void _dropInbound(String id) {
    final b = _inbound.remove(id);
    if (b == null) return;
    _discardParts(b);
    if (!b.failed && !b.delivering) {
      b.failed = true;
      _emit(id, b, IncomingStatus.failed);
    }
  }

  void _discardParts(_Inbound b) {
    for (final p in b.parts.values) {
      ShareTempFiles.release(p.path);
      _deleteQuietly(p.path);
    }
    b.parts.clear();
  }

  static void _deleteQuietly(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void _emit(
    String id,
    _Inbound b,
    IncomingStatus status, {
    int bytes = 0,
    int total = 0,
  }) => _onIncoming?.call(
    IncomingUpdate(
      endpointId: id,
      senderName: b.name,
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
    _listen();
    // 이전 세션이 남아 있으면 ALREADY_DISCOVERING으로 실패한다.
    await _call<void>('stopDiscovery');
    _onFound = onFound;
    _onLost = onLost;
    return await _call<bool>('startDiscovery', {
          'name': myName,
          'serviceId': serviceId,
        }) ??
        false;
  }

  @override
  Future<void> stopDiscovery() async {
    _onFound = null;
    _onLost = null;
    await _call<void>('stopDiscovery');
  }

  @override
  Future<bool> connect(
    String myName,
    String deviceId, {
    required void Function(TransferUpdate update) onUpdate,
    required void Function() onDisconnected,
  }) async {
    _listen();
    final result = _connecting[deviceId] = Completer<bool>();
    _outUpdate[deviceId] = onUpdate;
    _outDisconnect[deviceId] = onDisconnected;
    final requested = await _call<bool>('requestConnection', {
      'name': myName,
      'endpointId': deviceId,
    });
    if (requested != true) {
      _forgetOut(deviceId);
      return false;
    }
    final ok = await result.future;
    if (!ok) _forgetOut(deviceId);
    return ok;
  }

  void _forgetOut(String id) {
    _connecting.remove(id);
    _outUpdate.remove(id);
    _outDisconnect.remove(id);
    _outSize.remove(id);
  }

  @override
  Future<int> sendFile(String deviceId, String path) async {
    final size = await File(path).length();
    _outSize[deviceId] = size;
    final header = utf8.encode(
      jsonEncode({'loop': 'chain', 'v': 1, 'size': size}),
    );
    final h = await _call<int>('sendBytes', {
      'endpointId': deviceId,
      'bytes': Uint8List.fromList(header),
    });
    // 실패는 null — 페이로드 id는 음수일 수도 있어 부호로 판단하지 않는다.
    if (h == null) throw StateError('header send failed');
    final id = await _call<int>('sendStream', {
      'endpointId': deviceId,
      'path': path,
    });
    if (id == null) throw StateError('stream send failed');
    return id;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _forgetOut(deviceId);
    _dropInbound(deviceId); // 받던 연결이면 미완성 파일 정리
    await _call<void>('disconnect', {'endpointId': deviceId});
  }

  @override
  Future<bool> startAdvertising(
    String myName, {
    required void Function(String path) onFile,
    void Function(IncomingUpdate update)? onIncoming,
  }) async {
    _listen();
    _onFile = onFile;
    _onIncoming = onIncoming;
    final dir = await _shareDir();
    // 이름이 바뀌었을 수 있다 — 기존 광고를 내리고 새 이름으로.
    await _call<void>('stopAdvertising');
    return await _call<bool>('startAdvertising', {
          'name': myName,
          'serviceId': serviceId,
          'incomingDir': dir.path,
        }) ??
        false;
  }

  @override
  Future<void> stopAdvertising() async {
    // 광고만 내려선 이미 붙은 받기 연결이 남는다 — 그것까지 끊고 정리.
    for (final id in _inbound.keys.toList()) {
      _dropInbound(id);
      await _call<void>('disconnect', {'endpointId': id});
    }
    _onFile = null;
    _onIncoming = null;
    await _call<void>('stopAdvertising');
  }
}

class _Inbound {
  _Inbound(this.name);

  final String name;

  /// 헤더가 알려준 전체 크기 (아직 모르면 null).
  int? expected;

  /// 받는 중인 STREAM — payloadId → `.part`.
  final parts = <int, _Part>{};

  /// 다 받아 넘기는 중 — 이때의 끊김은 실패가 아니다.
  bool delivering = false;

  /// 실패를 이미 알렸다(중복 방지).
  bool failed = false;
}

class _Part {
  _Part(this.path);

  final String path;
  bool nearbyOk = false;
  bool written = false;
  bool writeOk = false;
  int bytes = -1;
}
