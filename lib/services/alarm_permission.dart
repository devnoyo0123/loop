import 'package:flutter/services.dart';

import '../data/loop_db.dart';

/// 알람이 화면에 뜨는 데 필요한 OS 권한의 경계 — 테스트는 가짜를 꽂는다.
abstract class AlarmPermissionPlatform {
  /// 전체 화면 알림(USE_FULL_SCREEN_INTENT) 허용 여부. Android 13 이하는 항상 true.
  Future<bool> fullScreenAllowed();

  /// 전체 화면 알림 허용 설정 화면으로 보낸다.
  Future<void> openFullScreenSettings();
}

/// 실제 구현 — MainActivity의 `app.loop/browser` 채널.
class ChannelAlarmPermissionPlatform implements AlarmPermissionPlatform {
  const ChannelAlarmPermissionPlatform();

  static const _ch = MethodChannel('app.loop/browser');

  @override
  Future<bool> fullScreenAllowed() async {
    try {
      return await _ch.invokeMethod<bool>('fullScreenAllowed') ?? true;
    } catch (_) {
      return true; // 확인할 수 없으면 묻지 않는다(미지원 플랫폼·테스트)
    }
  }

  @override
  Future<void> openFullScreenSettings() async {
    try {
      await _ch.invokeMethod('openFullScreenSettings');
    } catch (_) {}
  }
}

/// 알람 권한 점검 — "다가오는 알람 루프가 있는데 전체 화면 알림이 막혀
/// 있으면" 사용자에게 알리고 설정으로 보낸다.
///
/// 배경 (2026-11-01 실기기 Fold4): Android 14+에서 전체 화면 알림은 특별
/// 권한이다. Play Console 선언이 '기타'라 설치 때 미리 부여되지 않고,
/// 재설치·백업 복원 뒤엔 사용자가 다시 켜야 한다. 권한이 없으면 알람이
/// 울려도 소리만 나고 화면엔 안 뜬다 — 사용자는 어디서 울리는지도 모른다.
/// 예전엔 루프 시트에서 알람을 새로 걸 때만 확인해서, 가져온 알람은 아무
/// 안내 없이 화면 없는 알람이 됐다.
class AlarmPermissionGuard {
  AlarmPermissionGuard({
    required this.db,
    this.platform = const ChannelAlarmPermissionPlatform(),
    DateTime Function()? clock,
    this.snooze = const Duration(hours: 6),
  }) : _clock = clock ?? DateTime.now;

  final LoopDb db;
  final AlarmPermissionPlatform platform;
  final DateTime Function() _clock;

  /// [나중에]를 누른 뒤 다시 묻기까지.
  final Duration snooze;

  static const dismissedKey = 'fsi_prompt_dismissed_at';

  bool _showing = false;

  /// 아직 울리지 않은 알람 루프가 있는가 (단발 루프 중 알람 등급).
  bool hasPendingAlarms() => db.pendingOneShotLoops().any((l) => l.loopAlarm);

  /// 지금 안내를 띄워야 하는가. [force]는 [나중에] 유예를 무시한다
  /// (알람을 방금 건 경우 등). [requirePending]이 false면 등록된 알람이 없어도
  /// 묻는다 — 곧 알람을 울릴 참일 때(설정의 발화 체험).
  Future<bool> shouldPrompt({
    bool force = false,
    bool requirePending = true,
  }) async {
    if (_showing) return false;
    if (requirePending && !hasPendingAlarms()) return false;
    if (await platform.fullScreenAllowed()) return false;
    if (!force && _snoozed()) return false;
    return true;
  }

  bool _snoozed() {
    final ms = int.tryParse(db.getSetting(dismissedKey) ?? '');
    if (ms == null) return false;
    final at = DateTime.fromMillisecondsSinceEpoch(ms);
    return _clock().difference(at) < snooze;
  }

  /// [나중에] — 유예 시작.
  void dismiss() =>
      db.setSetting(dismissedKey, '${_clock().millisecondsSinceEpoch}');

  /// [설정 열기] — 허용하고 돌아오면 다음 점검에서 조용해진다.
  Future<void> openSettings() async {
    db.setSetting(dismissedKey, '');
    await platform.openFullScreenSettings();
  }

  /// 안내가 떠 있는 동안 중복 표시 방지 (시작·복귀가 겹칠 때).
  void markShowing(bool v) => _showing = v;
}
