/// 반복 규칙 — "매일 이 시간", "N분/N시간마다".
/// 발화(알림 + 빈 포크 로그 생성)는 앱이 켜질 때 `LoopDb.settleRepeats()`가
/// 놓친 것까지 몰아서 처리한다. (docs/data-model.md v4)
library;

import '../l10n/generated/app_localizations.dart';
import '../utils/workday.dart';

/// [weekday]는 "매일(토·일·공휴일 제외)" — 발화 시각(timeOfDay)을
/// 다음 근무일에 같게 유지한다. (공휴일은 utils/workday.dart의 날짜표)
enum RepeatKind { minutes, hours, daily, weekday }

class RepeatRule {
  const RepeatRule({
    required this.id,
    required this.sourceLogId,
    required this.kind,
    this.everyN,
    this.timeOfDay,
    required this.nextFireAt,
    required this.createdAt,
    this.fireCount = 0,
    this.active = true,
    this.stoppedAt,
  });

  final String id;

  /// 반복의 원본 로그. 발화마다 이 로그의 포크가 생성된다.
  final String sourceLogId;

  final RepeatKind kind;

  /// minutes/hours 주기값. (10분 → everyN=10)
  final int? everyN;

  /// daily 발화 시각 "HH:mm" (24시간, zero-padded).
  final String? timeOfDay;

  /// 다음 발화 예정 시각.
  final DateTime nextFireAt;

  /// 지금까지 발화(포크 생성) 횟수.
  final int fireCount;

  final bool active;

  /// stop 시각. 살아있는 규칙이면 null.
  final DateTime? stoppedAt;

  final DateTime createdAt;

  /// [t] 바로 다음 발화 시각.
  /// daily는 +1일, weekday는 다음 근무일 — 한국은 DST가 없어 시각이 정확히 유지된다.
  DateTime nextFireAfter(DateTime t) => switch (kind) {
        RepeatKind.minutes => t.add(Duration(minutes: everyN!)),
        RepeatKind.hours => t.add(Duration(hours: everyN!)),
        RepeatKind.daily => t.add(const Duration(days: 1)),
        RepeatKind.weekday => _nextWorkdayAfter(t),
      };

  /// [t] 다음 근무일의 같은 시각 — 토·일·공휴일은 하루씩 건너뛴다.
  static DateTime _nextWorkdayAfter(DateTime t) {
    var d = t.add(const Duration(days: 1));
    while (!isWorkday(d)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// 규칙 생성 시 첫 발화 시각.
  DateTime firstFireFrom(DateTime now) =>
      firstFireOf(kind, everyN: everyN, timeOfDay: timeOfDay, now: now);

  static DateTime firstFireOf(
    RepeatKind kind, {
    int? everyN,
    String? timeOfDay,
    required DateTime now,
  }) =>
      switch (kind) {
        RepeatKind.minutes =>
          now.add(Duration(minutes: everyN ?? 0)),
        RepeatKind.hours => now.add(Duration(hours: everyN ?? 0)),
        RepeatKind.daily => _nextDailyFrom(now, timeOfDay!),
        RepeatKind.weekday => _nextWorkdayFrom(now, timeOfDay!),
      };

  static DateTime _nextDailyFrom(DateTime now, String timeOfDay) {
    final p = timeOfDay.split(':');
    // 분이 없는 레거시 값("09")도 받아준다 — 잘못 저장된 규칙이 있어도 크래시 없이.
    final h = int.tryParse(p.first) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    var t = DateTime(now.year, now.month, now.day, h, m);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  /// daily 첫 발화 후보에서 근무일이 아닌 날을 건너뛴다.
  static DateTime _nextWorkdayFrom(DateTime now, String timeOfDay) {
    var t = _nextDailyFrom(now, timeOfDay);
    while (!isWorkday(t)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// 사람용 라벨 — "10분마다", "3시간마다", "매일 09:00", "평일 09:00". (다국어)
  String label(AppLocalizations l10n) => switch (kind) {
        RepeatKind.minutes => l10n.ruleEveryMinutes(everyN ?? 0),
        RepeatKind.hours => l10n.ruleEveryHours(everyN ?? 0),
        RepeatKind.daily => l10n.ruleDaily(timeOfDay ?? '00:00'),
        RepeatKind.weekday => l10n.ruleWeekday(timeOfDay ?? '00:00'),
      };
}

/// 반복 설정 시트의 결과 — 아직 id/시각이 없는 규칙 초안.
class RepeatDraft {
  const RepeatDraft({required this.kind, this.everyN, this.timeOfDay});

  final RepeatKind kind;
  final int? everyN;
  final String? timeOfDay;

  DateTime firstFireFrom(DateTime now) =>
      RepeatRule.firstFireOf(kind,
          everyN: everyN, timeOfDay: timeOfDay, now: now);

  String label(AppLocalizations l10n) => switch (kind) {
        RepeatKind.minutes => l10n.ruleEveryMinutes(everyN ?? 0),
        RepeatKind.hours => l10n.ruleEveryHours(everyN ?? 0),
        RepeatKind.daily => l10n.ruleDaily(timeOfDay ?? '00:00'),
        RepeatKind.weekday => l10n.ruleWeekday(timeOfDay ?? '00:00'),
      };
}
