import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/generated/app_localizations.dart';

/// 로컬 알림·알람 — "루프가 돌아왔어".
///
/// 두 등급이 있다:
/// - 알림(기본): 소리 한 번, 상단 배너. 반복 발화와 일반 단발 루프.
/// - 알람(2026-10-18): 시계 앱과 같은 setAlarmClock 네이티브 예약 —
///   알림 배너를 거치지 않고 전체화면 발화 화면(AlarmActivity)을 띄우고,
///   무음에도 알람음이 [확인]을 누를 때까지 울린다. [10분 후 다시] 스누즈는
///   네이티브가 재예약하고, 기록을 남겨 다음 실행 때 Dart가 DB에 반영한다.
///
/// 위젯 트리 밖이라 시스템 locale로 직접 문자열을 조회한다.
class LoopNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// 네이티브 알람 채널 (MainActivity). 브라우저 설정과 채널을 공유한다.
  static const _nativeCh = MethodChannel('app.loop/browser');

  static AppLocalizations get _l10n =>
      lookupAppLocalizations(PlatformDispatcher.instance.locale);

  /// 다른 앱 위에 알람 UI를 띄우는 특별 권한 — 알람 예약 전에 확인·유도.
  static Future<bool> canDrawOverlays() async {
    try {
      return await _nativeCh.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDrawOverlays() async {
    try {
      await _nativeCh.invokeMethod('requestDrawOverlays');
    } catch (_) {}
  }

  static AndroidNotificationDetails _androidDetails() =>
      AndroidNotificationDetails(
        'loops',
        _l10n.notifChannelName,
        channelDescription: _l10n.notifChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        actions: [
          AndroidNotificationAction(
            'confirm',
            _l10n.notifConfirm,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

  /// 그때의 나 전용 채널 — 조용한 아침 인사라 `확인` 액션 없이 소리만.
  static AndroidNotificationDetails _onThisDayDetails() =>
      AndroidNotificationDetails(
        'onthisday',
        _l10n.onThisDayChannelName,
        channelDescription: _l10n.onThisDayChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      );

  /// 알림 본문을 탭하면 payload와 함께 호출된다.
  /// 단발 루프 = logId, 반복 = 반복 원본 로그 id.
  static void Function(String logId)? onOpenLog;

  /// 아직 소비되지 않은 알림 탭 payload — 콜드스타트(앱이 꺼져 있다가
  /// 알림 탭으로 실행)에선 타임라인이 리스너를 달기 전에 응답이 오므로
  /// 여기에 쌓아두고 타임라인 init에서 소비한다.
  static String? pendingOpenLog;

  /// 알림의 `확인` 액션을 탭하면 payload와 함께 호출된다.
  /// (앱이 켜져 있을 때만 — 꺼져 있으면 다음 실행 때 settleExpiredLoops가 소화)
  static void Function(String logId)? onConfirmLog;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: backgroundActionHandler,
    );

    // 소리·우선순위 등 채널 설정은 Android가 한 번 만들면 고정이라 예전엔
    // 지우고 재생성했지만, 매번 지우면 이미 예약된 알림이 발화 시점에
    // 채널이 없어 조용히 누락된다(특히 재예약되지 않는 단발 루프).
    // 지우지 않는다 — 설정이 바뀌면 채널 id를 올리는 방식으로만 변경.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    // 정확 알람 특수권한 — Android 14+부터 설치 시 기본 거부다. 없으면
    // exactAllowWhileIdle 예약 자체가 실패해 다른 앱 사용 중엔 알림이 안
    // 울리므로 여기서 확인한다. (네이티브가 허용됐으면 화면을 열지 않고
    // 통과, Android 12 미만은 자동 허용)
    await android?.requestExactAlarmsPermission();
  }

  /// 확인 액션 라우팅 — 앱이 살아 있을 때.
  static Future<void> _handleResponse(NotificationResponse response) =>
      _routeResponse(response);

  /// 확인 액션 라우팅 — 앱 프로세스가 죽어 있는 상태.
  /// 백그라운드 아이솔레이트에서 도는 콜백은 반드시 top-level/static이어야 한다.
  @pragma('vm:entry-point')
  static Future<void> backgroundActionHandler(NotificationResponse response) =>
      _routeResponse(response);

  static Future<void> _routeResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      // `확인` — Android가(cancelNotification) 알림을 닫고, 여기선 소화 처리.
      // 반복 알림의 payload는 규칙 id라 markLoopDone이 조용히 무시된다 — 안전.
      onConfirmLog?.call(payload);
    } else {
      // 탭한 알림의 로그를 기억 — 리스너가 없으면(콜드스타트) 나중에 소비.
      pendingOpenLog = payload;
      onOpenLog?.call(payload);
    }
  }

  /// logId(String) → 알림 id(int). 같은 로그는 항상 같은 알림 id.
  static int idFor(String logId) => logId.hashCode & 0x7fffffff;

  /// 반복 규칙의 알림 id — 규칙당 최대 [_repeatSlots]개 슬롯.
  /// 단발 루프 id와 공간이 겹쳐도 payload로 구별되므로 실질 문제는 없다.
  static const _repeatSlots = 16;

  static int repeatIdFor(String ruleId, int slot) =>
      (ruleId.hashCode & 0x00FFFFFF) * _repeatSlots + (slot & 0x0F);

  /// 루프 예약 — [alarm]이면 네이티브 전체화면 알람, 아니면 일반 알림.
  static Future<void> scheduleLoop({
    required String logId,
    required String body,
    required DateTime at,
    bool alarm = false,
    String? title,
  }) async {
    // 과거 시각은 예약하지 않는다 — 과거로 예약하면 즉시 발화한다.
    // 지난 루프는 settleExpiredLoops가 발화 포크로 소화하므로 여기선 침묵.
    if (!at.isAfter(DateTime.now())) return;
    if (alarm) {
      try {
        await _nativeCh.invokeMethod('scheduleNativeAlarm', {
          'logId': logId,
          'atMs': at.millisecondsSinceEpoch,
          'content': body,
        });
        return;
      } catch (_) {
        // 네이티브 경로 실패(안드로이드 외 환경 등) — 알림으로라도 울린다.
      }
    }
    await _schedule(
      id: idFor(logId),
      title: title ?? 'Loop ↩',
      body: body,
      payload: logId,
      at: at,
    );
  }

  /// 반복 규칙의 다가오는 발화를 배치로 예약한다.
  /// 앱을 켤 때마다 [LoopDb.settleRepeats] 후 다시 맞춰준다 —
  /// 안드로이드는 앱이 꺼져 있으면 코드를 못 돌리므로 창을 넉넉히 유지.
  static Future<void> scheduleRepeatFires({
    required String ruleId,
    required String preview,
    required DateTime firstAt,
    required DateTime Function(DateTime) nextAfter,
    int count = 12,
  }) async {
    await cancelRepeat(ruleId);
    var t = firstAt;
    for (var slot = 0; slot < count; slot++) {
      if (!t.isAfter(DateTime.now())) {
        t = nextAfter(t);
        continue;
      }
      await _schedule(
        id: repeatIdFor(ruleId, slot),
        title: _l10n.notifRepeatTitle,
        body: preview,
        payload: ruleId,
        at: t,
      );
      t = nextAfter(t);
    }
  }

  static Future<void> cancelRepeat(String ruleId) async {
    for (var slot = 0; slot < _repeatSlots; slot++) {
      await _plugin.cancel(id: repeatIdFor(ruleId, slot));
    }
  }

  // ── 그때의 나 (docs/growth-ideas.md) ────────────────────────

  /// 그때의 나 알림 슬롯 — 오늘부터 며칠 치를 예약할지.
  static const onThisDaySlots = 8;

  /// 그날의 알림 id — 날짜별로 고정이라 다시 맞출 때 덮어쓴다.
  static int onThisDayIdFor(DateTime day) =>
      (day.year * 10000 + day.month * 100 + day.day) & 0x3FFFFFFF;

  /// 그때의 나 아침 알림 payload — 로그가 아니라 기록 흐름 페이지를 연다.
  static const statsPayload = 'stats';

  /// 그때의 나 아침 알림을 [items]로 다시 맞춘다. 하루에 알림 하나 —
  /// 탭하면 기록 흐름 페이지(그때의 나 섹션 포함)가 열린다.
  /// (2026-11-01: 알림 여러 개 → 하나 + 전체화면 페이지로 전환)
  static Future<void> scheduleOnThisDay(
    List<({DateTime at, String body})> items,
  ) async {
    await cancelOnThisDay();
    for (final item in items) {
      if (!item.at.isAfter(DateTime.now())) continue;
      await _schedule(
        id: onThisDayIdFor(item.at),
        title: '📮 ${_l10n.onThisDayTitle}',
        body: item.body,
        payload: statsPayload,
        at: item.at,
        android: _onThisDayDetails(),
      );
    }
  }

  /// 예약된 그때의 나 전부 취소 — 같은 날짜 id 공간을 다시 맞춘다.
  static Future<void> cancelOnThisDay() async {
    final now = DateTime.now();
    for (var i = 0; i < onThisDaySlots; i++) {
      final d = DateTime(now.year, now.month, now.day + i);
      await _plugin.cancel(id: onThisDayIdFor(d));
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required String? payload,
    required DateTime at,
    AndroidNotificationDetails? android,
  }) async {
    final details = NotificationDetails(
      android: android ?? _androidDetails(),
      macOS: const DarwinNotificationDetails(presentSound: true),
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // 정확 알람 권한이 없으면 예약이 예외로 끝난다 — inexact로라도 걸어서
      // 몇 분 늦더라도 알림은 오도록 보장한다.
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    }
  }

  /// 예약 취소 — 일반 알림과 네이티브 알람을 모두 치운다.
  /// (알림이 없는 id를 cancel해도 조용히 무시된다)
  static Future<void> cancel(String logId) async {
    await _plugin.cancel(id: idFor(logId));
    try {
      await _nativeCh.invokeMethod('cancelNativeAlarm', {'logId': logId});
    } catch (_) {
      // 안드로이드 외 환경 — 무시.
    }
  }

  /// 네이티브 스누즈 기록을 DB에 반영할 수 있게 꺼낸다 (logId → 새 시각 ms).
  /// 꺼내면 네이티브 쪽 기록은 치워진다. 앱 시작 때 한 번 호출.
  static Future<Map<String, int>> consumePendingSnoozes() async {
    try {
      final raw = await _nativeCh.invokeMethod<Map<Object?, Object?>>(
        'consumePendingSnoozes',
      );
      return {
        for (final e in (raw ?? {}).entries)
          e.key as String: (e.value as num).toInt(),
      };
    } catch (_) {
      return const {};
    }
  }

  /// 알람 화면 [확인]로 열어달라는 대상 로그. 없으면 null. (꺼내면 소비됨)
  static Future<String?> consumeAlarmOpen() async {
    try {
      return await _nativeCh.invokeMethod<String?>('consumeAlarmOpen');
    } catch (_) {
      return null;
    }
  }
}
