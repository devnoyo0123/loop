/// 하나의 로그. 스키마 v2는 docs/data-model.md 참고.
class LogEntry {
  const LogEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.originalCreatedAt,
    this.parentId,
    this.rootId,
    this.depth = 0,
    this.path,
    this.loopAt,
    this.loopDone = false,
    this.loopAlarm = false,
    this.latitude,
    this.longitude,
    this.place,
    this.weatherCode,
    this.temperatureC,
    this.repeatRuleId,
    this.loopCount = 0,
  });

  final String id;

  /// 로그 본문.
  final String content;

  /// 표시·정렬 기준 시각. 사용자가 수정 가능. (로컬 시간대)
  final DateTime createdAt;

  /// 최초 생성 시각. 불변 — 시간을 수정해도 보존된다.
  final DateTime originalCreatedAt;

  /// 포크(이어쓰기) 부모 로그. 원본이면 null.
  final String? parentId;

  /// 계보의 시작점(최초 원본) id. 원본이면 null.
  final String? rootId;

  /// 포크 깊이. 원본 = 0.
  final int depth;

  /// Materialized Path — "원본id/자식id/손자id". 원본이면 null.
  final String? path;

  /// 예약된 루프(알림) 시각.
  final DateTime? loopAt;

  /// 루프 소화 여부.
  final bool loopDone;

  /// 이 루프를 알람처럼(무음 무시·꺼야 멈춤·전체화면) 울릴지. (2026-10-18)
  final bool loopAlarm;

  /// 저장 순간의 위치. (자동 캡처, 권한 거부/실패 시 null)
  final double? latitude;
  final double? longitude;

  /// 역지오코딩한 장소명. (예: "서울특별시 성동구")
  final String? place;

  /// WMO 날씨 코드. (0=맑음, 61=비, 95=뇌우…)
  final int? weatherCode;

  /// 기온 ℃.
  final double? temperatureC;

  /// 이 로그를 생성한 반복 규칙. (반복 발화로 자동 생성된 포크만 값이 있다)
  final String? repeatRuleId;

  /// 이 체인에서 지금까지 루프(한 번 알림)로 돌아온 횟수.
  /// 망각곡선 다음 간격을 고르는 기준 — 원본과 발화 포크가 함께 올라간다.
  final int loopCount;

  bool get isFork => parentId != null;

  bool get isRepeatFork => repeatRuleId != null;

  bool get hasPendingLoop => loopAt != null && !loopDone;

  bool get hasLocation => latitude != null && longitude != null;

  LogEntry copyWith({
    String? content,
    DateTime? createdAt,
    DateTime? loopAt,
    bool? loopDone,
    bool? loopAlarm,
  }) => LogEntry(
    id: id,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    originalCreatedAt: originalCreatedAt,
    parentId: parentId,
    rootId: rootId,
    depth: depth,
    path: path,
    loopAt: loopAt ?? this.loopAt,
    loopDone: loopDone ?? this.loopDone,
    loopAlarm: loopAlarm ?? this.loopAlarm,
    latitude: latitude,
    longitude: longitude,
    place: place,
    weatherCode: weatherCode,
    temperatureC: temperatureC,
    repeatRuleId: repeatRuleId,
    loopCount: loopCount,
  );
}

/// 타임라인 카드용 이미지 요약 — 장수와 첫 이미지(base64)만.
/// 이미지 본문은 log_images 테이블에서 필요할 때 읽는다. (docs/data-model.md v3)
class LogImageSummary {
  const LogImageSummary({required this.count, this.firstBase64});

  final int count;

  /// position 0 이미지의 base64. 이미지 전용 로그의 썸네일 표시용.
  final String? firstBase64;
}
