import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/loop_db.dart';
import '../l10n/generated/app_localizations.dart';

/// 알림 payload — 탭·액션 처리에 필요한 최소 정보.
/// 알람의 [10분 후 다시]가 앱이 죽어 있어도 동작하려면 DB를 열어야 해서
/// DB 디렉터리 경로를 함께 싣는다. (반복 발화는 규칙 id만 — legacy 형식)
class LoopPayload {
  const LoopPayload({required this.logId, this.dbDir});

  final String logId;
  final String? dbDir;

  /// dbDir가 없으면 legacy/반복 형식 그대로 — decode가 둘 다 읽는다.
  String encode() =>
      dbDir == null ? logId : jsonEncode({'i': logId, 'd': dbDir});

  /// JSON 형식({i,d})과 예전 단일 id 형식을 모두 받는다.
  static LoopPayload decode(String? raw) {
    if (raw == null || raw.isEmpty) return LoopPayload(logId: '');
    if (raw.startsWith('{')) {
      try {
        final m = jsonDecode(raw) as Map<String, Object?>;
        return LoopPayload(
          logId: (m['i'] as String?) ?? '',
          dbDir: m['d'] as String?,
        );
      } catch (_) {
        return LoopPayload(logId: '');
      }
    }
    return LoopPayload(logId: raw);
  }
}

/// 로컬 알림 — "루프가 돌아왔어".
/// - 소리·진동 + 상단 팝업(high)
/// - 알림의 `확인` 액션으로 즉시 종료 (앱이 꺼져 있어도 동작)
/// - 단발 루프는 작성 시점에, 반복은 다가오는 발화를 배치로 건다.
/// - alarm=true면 시계 알람 등급: 무음 무시(ALARM 음원)·꺼야 멈춤(insistent)·
///   잠금화면 전체(fullScreenIntent) + [10분 후 다시] 스누즈. (2026-10-18)
/// 위젯 트리 밖이라 시스템 locale로 직접 문자열을 조회한다.
class LoopNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static AppLocalizations get _l10n =>
      lookupAppLocalizations(PlatformDispatcher.instance.locale);

  /// 스누즈 간격 — 알람의 [10분 후 다시].
  static const snoozeAfter = Duration(minutes: 10);

  /// Android Notification.FLAG_INSISTENT — 알림을 닫을 때까지 소리 반복.
  static const _flagInsistent = 4;

  static AndroidNotificationDetails _androidDetails({required bool alarm}) =>
      AndroidNotificationDetails(
        alarm ? 'loop-alarms' : 'loops',
        alarm ? _l10n.notifAlarmChannelName : _l10n.notifChannelName,
        channelDescription: _l10n.notifChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        // 알람 등급 — 시계 앱의 알람과 같은 부류로 울린다.
        category: alarm ? AndroidNotificationCategory.alarm : null,
        audioAttributesUsage: alarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        fullScreenIntent: alarm,
        additionalFlags: alarm
            ? Int32List.fromList(<int>[_flagInsistent])
            : null,
        actions: [
          if (alarm)
            AndroidNotificationAction(
              'snooze',
              _l10n.snoozeAction,
              showsUserInterface: false,
            ),
          AndroidNotificationAction(
            'confirm',
            _l10n.notifConfirm,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
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
    final payload = LoopPayload.decode(response.payload);
    if (payload.logId.isEmpty) return;
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      if (response.actionId == 'snooze') {
        // [10분 후 다시] — 앱이 죽어도 DB를 열어 예약을 미루고 다시 건다.
        await _snooze(payload);
        return;
      }
      // `확인` — Android가(cancelNotification) 알림을 닫고, 여기선 소화 처리.
      // 반복 알림의 payload는 규칙 id라 markLoopDone이 조용히 무시된다 — 안전.
      onConfirmLog?.call(payload.logId);
    } else {
      // 탭한 알림의 로그를 기억 — 리스너가 없으면(콜드스타트) 나중에 소비.
      pendingOpenLog = payload.logId;
      onOpenLog?.call(payload.logId);
    }
  }

  /// 스누즈 — 루프를 [snoozeAfter] 뒤로 미루고 알람을 다시 건다.
  /// 백그라운드 아이솔레이트에서도 돌 수 있어서 payload의 경로로 DB를 연다.
  static Future<void> _snooze(LoopPayload payload) async {
    final at = DateTime.now().add(snoozeAfter);
    var body = _l10n.notifFallbackBody;
    if (payload.dbDir != null) {
      try {
        final db = LoopDb(Directory(payload.dbDir!))..open();
        try {
          final log = db.byId(payload.logId);
          body = (log?.content.trim().isEmpty ?? true) ? body : log!.content;
          db.updateLoopAt(payload.logId, at, alarm: true);
        } finally {
          db.close();
        }
      } catch (_) {
        // DB를 못 열어도 알람 자체는 다시 걸어준다 — DB는 다음 실행 때 정산.
      }
    }
    await scheduleLoop(
      logId: payload.logId,
      body: body,
      at: at,
      alarm: true,
      dbDir: payload.dbDir,
    );
  }

  /// logId(String) → 알림 id(int). 같은 로그는 항상 같은 알림 id.
  static int idFor(String logId) => logId.hashCode & 0x7fffffff;

  /// 반복 규칙의 알림 id — 규칙당 최대 [_repeatSlots]개 슬롯.
  /// 단발 루프 id와 공간이 겹쳐도 payload로 구별되므로 실질 문제는 없다.
  static const _repeatSlots = 16;

  static int repeatIdFor(String ruleId, int slot) =>
      (ruleId.hashCode & 0x00FFFFFF) * _repeatSlots + (slot & 0x0F);

  static Future<void> scheduleLoop({
    required String logId,
    required String body,
    required DateTime at,
    bool alarm = false,
    String? dbDir,
  }) => _schedule(
    id: idFor(logId),
    title: 'Loop ↩',
    body: body,
    payload: LoopPayload(logId: logId, dbDir: dbDir).encode(),
    at: at,
    alarm: alarm,
  );

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
        alarm: false,
      );
      t = nextAfter(t);
    }
  }

  static Future<void> cancelRepeat(String ruleId) async {
    for (var slot = 0; slot < _repeatSlots; slot++) {
      await _plugin.cancel(id: repeatIdFor(ruleId, slot));
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required String? payload,
    required DateTime at,
    required bool alarm,
  }) async {
    final details = NotificationDetails(
      android: _androidDetails(alarm: alarm),
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

  static Future<void> cancel(String logId) => _plugin.cancel(id: idFor(logId));
}
