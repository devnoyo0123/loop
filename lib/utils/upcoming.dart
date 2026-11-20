import '../data/loop_db.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';

/// 앞으로 돌아올 것 하나 — 단발 루프 또는 반복 알림의 한 회차.
///
/// "다가오는 루프" 시트와 MCP `upcoming_loops`가 같은 계산을 쓰도록 화면과
/// 분리했다. 둘이 다르게 보이면 안 된다. (2026-11-18, 반복 알림이 브리지에서
/// 안 보이던 문제)
class UpcomingFire {
  const UpcomingFire.once(this.at, LogEntry this.log) : rule = null;

  const UpcomingFire.repeat(this.at, RepeatRule this.rule) : log = null;

  /// 발화(도래) 예정 시각.
  final DateTime at;

  /// 단발 루프면 루프가 걸린 로그.
  final LogEntry? log;

  /// 반복 알림 회차면 그 규칙.
  final RepeatRule? rule;

  bool get repeated => rule != null;

  /// 돌아올 원본 로그 id — 단발은 그 로그, 반복은 규칙의 원본.
  String get logId => rule?.sourceLogId ?? log!.id;

  /// 전체 화면 알람이면 true. 반복 알림은 지금 항상 일반 알림이다.
  bool get alarm => log?.loopAlarm ?? false;
}

/// (from, to] 사이에 올 단발 루프와 반복 알림 회차를 시간순으로 모은다.
///
/// - 단발 루프: 예약 시각이 창 안에 있는 것 전부
/// - 매일·평일·매달·매년 반복: 창 안의 매 회차 (하루 한 줄 이하)
/// - 분·시간·망각곡선 반복: 다음 회차 하나만 — 7일치를 늘어놓으면 수백 줄이
///   되고, 망각곡선은 다음 칸 계산이 fireCount에 달려 있다
List<UpcomingFire> upcomingFires(
  LoopDb db, {
  required DateTime from,
  required DateTime to,
}) {
  final fires = <UpcomingFire>[
    for (final log in db.pendingLoopsBetween(from, to))
      UpcomingFire.once(log.loopAt!, log),
  ];

  for (final rule in db.activeRepeatRules()) {
    switch (rule.kind) {
      case RepeatKind.daily:
      case RepeatKind.weekday:
      case RepeatKind.monthly:
      case RepeatKind.yearly:
        var t = rule.nextFireAt;
        while (!t.isAfter(to)) {
          fires.add(UpcomingFire.repeat(t, rule));
          t = rule.nextFireAfter(t);
        }
      case RepeatKind.minutes:
      case RepeatKind.hours:
      case RepeatKind.curve:
        if (!rule.nextFireAt.isAfter(to)) {
          fires.add(UpcomingFire.repeat(rule.nextFireAt, rule));
        }
    }
  }

  fires.sort((a, b) => a.at.compareTo(b.at));
  return fires;
}
