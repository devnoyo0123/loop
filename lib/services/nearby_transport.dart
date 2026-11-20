/// 근거리 전송의 경계 — 앱 로직(nearby_share.dart)은 이 인터페이스만 안다.
///
/// 실제 구현은 앱 Kotlin 번역층(NearbyBridge.kt)을 쓰는
/// `NativeNearbyTransport`(native_nearby_transport.dart), 테스트는 메모리 가짜
/// 구현을 꽂는다. 플랫폼 타입은 이 파일에 새어 나오지 않는다 — 상태 머신을
/// 폰 없이 단위 테스트하기 위한 분리. (docs/share-design.md §6)
library;

/// 탐색으로 발견한 상대 기기. [name]은 상대가 광고한 표시명.
class NearbyDevice {
  const NearbyDevice({required this.id, required this.name});

  /// Nearby 엔드포인트 id — 세션 한정, 기기 정체성(peers.id)과 무관.
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is NearbyDevice && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'NearbyDevice($id, $name)';
}

/// 페이로드 전송 상태 — 플러그인의 PayloadStatus를 앱 어휘로.
enum TransferStatus { inProgress, success, failure, canceled }

/// 페이로드 진행 이벤트.
class TransferUpdate {
  const TransferUpdate({
    required this.payloadId,
    required this.status,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
  });

  final int payloadId;
  final TransferStatus status;
  final int bytesTransferred;
  final int totalBytes;

  /// 0..1, 전체 크기를 아직 모르면 null.
  double? get fraction =>
      totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : null;
}

/// 받는 쪽 진행 단계 — 상대가 붙은 순간부터 파일이 넘어갈 때까지.
enum IncomingStatus {
  /// 상대가 연결됨 (아직 바이트 없음).
  started,

  /// 파일 수신 중.
  progress,

  /// 바이트를 다 받음 — 곧 onFile로 파일이 넘어간다(복사 실패면 failed).
  completed,

  /// 실패·취소·중간 끊김. 미완성 파일은 이미 지워졌다.
  failed,
}

/// 받는 쪽 진행 이벤트 — 받기 화면(알림)이 그린다.
class IncomingUpdate {
  const IncomingUpdate({
    required this.endpointId,
    required this.senderName,
    required this.status,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
  });

  final String endpointId;

  /// 상대가 광고한 표시명.
  final String senderName;
  final IncomingStatus status;
  final int bytesTransferred;
  final int totalBytes;

  /// 0..1, 전체 크기를 아직 모르면 null.
  double? get fraction =>
      totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : null;
}

/// 근거리 전송 계층. 한 번에 하나의 보내기 세션과 하나의 받기 대기를
/// 가정한다(앱이 그 이상을 만들지 않는다).
abstract class NearbyTransport {
  /// 탐색 시작 — 같은 서비스로 광고 중인 기기가 [onFound]로, 사라지면
  /// [onLost]로 온다. 시작 자체가 실패하면 false.
  Future<bool> startDiscovery(
    String myName, {
    required void Function(NearbyDevice device) onFound,
    required void Function(String deviceId) onLost,
  });

  Future<void> stopDiscovery();

  /// [deviceId]에 연결 요청 → 이쪽도 수락 → 양쪽 수락 결과를 돌려준다.
  /// 연결 후 이 연결의 페이로드 진행은 [onUpdate], 끊기면 [onDisconnected].
  Future<bool> connect(
    String myName,
    String deviceId, {
    required void Function(TransferUpdate update) onUpdate,
    required void Function() onDisconnected,
  });

  /// 파일 페이로드 전송 시작 — 페이로드 id를 돌려준다.
  /// 진행은 [connect]의 onUpdate로 온다.
  Future<int> sendFile(String deviceId, String path);

  /// 이 기기와의 연결만 끊는다(보내기 정리·취소, 받기 멈춤 감지). 전체
  /// 끊기를 쓰지 않는 이유: Nearby의 stopAllEndpoints는 받기 대기(광고)까지
  /// 멈춘다. 받던 연결이면 미완성 파일도 지운다.
  Future<void> disconnect(String deviceId);

  /// 받기 대기 — 들어오는 연결을 자동 수락하고, 파일이 온전히 도착해
  /// 앱이 읽을 수 있는 경로로 옮겨지면 [onFile]로 그 경로를 넘긴다.
  /// 진행·실패는 [onIncoming]으로 — 실패하면 미완성 파일은 구현이 지운다.
  Future<bool> startAdvertising(
    String myName, {
    required void Function(String path) onFile,
    void Function(IncomingUpdate update)? onIncoming,
  });

  Future<void> stopAdvertising();
}
