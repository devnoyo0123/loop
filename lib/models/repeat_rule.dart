/// 반복 규칙 — "매일 이 시간", "N분/N시간/N개월/N년마다", "매달·매년 이 날",
/// "망각곡선 사다리". 발화(알림 + 빈 포크 로그 생성)는 앱이 켜질 때
/// `LoopDb.settleRepeats()`가 놓친 것까지 몰아서 처리한다. (docs/data-model.md v4)
library;

import '../l10n/generated/app_localizations.dart';
import '../utils/starters.dart';
import '../utils/workday.dart';

/// [weekday]는 "매일(토·일·공휴일 제외)" — 발화 시각(timeOfDay)을
/// 다음 근무일에 같게 유지한다. (공휴일은 utils/workday.dart의 날짜표)
/// [monthly]/[yearly]는 "매달·매년 이 날 이 시간" — timeOfDay에 앵커 날짜를
/// "MM-dd HH:mm"로 함께 담는다. (매일·평일은 "HH:mm"만)
/// [curve]는 망각곡선 사다리 — 발화할 때마다 다음 칸으로 자동 전진하며
/// timeOfDay에 저녁 칸의 앵커 "HH:mm"을 담는다.
enum RepeatKind { minutes, hours, daily, weekday, monthly, yearly, curve }

/// monthly/yearly의 발화 앵커 — 앵커 월(null = 매월), 일, 시각, 주기.
typedef _Anchor = (
  int? month,
  int day,
  int hour,
  int minute,
  int stepMonths,
  int stepYears,
);

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

  /// minutes/hours는 주기값(10분 → everyN=10), monthly/yearly는
  /// 개월·연수(2개월 → everyN=2, null=1). daily/weekday는 안 쓴다.
  final int? everyN;

  /// daily/weekday 발화 시각 "HH:mm", monthly/yearly 앵커 "MM-dd HH:mm"
  /// (24시간, zero-padded).
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
  /// daily는 +1일, weekday는 다음 근무일, monthly/yearly는 앵커 '일'을
  /// 유지해 다음 주기 — 그 달에 날이 없으면(31일 → 2월) 말일로 몰아준다.
  /// 한국은 DST가 없어 시각이 정확히 유지된다.
  DateTime nextFireAfter(DateTime t) => switch (kind) {
    RepeatKind.minutes => t.add(Duration(minutes: everyN!)),
    RepeatKind.hours => t.add(Duration(hours: everyN!)),
    RepeatKind.daily => t.add(const Duration(days: 1)),
    RepeatKind.weekday => _nextWorkdayAfter(t),
    RepeatKind.monthly || RepeatKind.yearly => _nextAnchoredAfter(
      t,
      _anchorFor(kind, timeOfDay: timeOfDay, at: t, everyN: everyN),
    ),
    // curve는 칸이 fireCount로 정해진다 — "fireCount번 발화했으니 다음은
    // fireCount칸". 몰아생성(settleRepeats) 중의 연속 전진은 칸 수를 직접
    // 계산해 curveFireAfter로 걷는다 (fireCount가 루프 도중엔 안 늘어나므로).
    RepeatKind.curve => curveFireAfter(t, fireCount, timeOfDay),
  };

  /// curve 사다리 칸 수 — fireCount가 이 값에 도달하면 사다리가 끝난다
  /// (10분 · 1시간 · 저녁 · 내일 · 1주 · 1개월). settleRepeats가 이 순간
  /// 규칙을 스스로 종료(active=0)한다.
  static const curveRungs = 6;

  /// curve 사다리의 [rung]칸이 [t] 뒤로 만드는 다음 발화.
  /// 0=10분, 1=1시간, 2=그날 마무리 시각(timeOfDay "HH:mm", 지났으면 내일),
  /// 3=내일, 4=1주, 5=1개월. [2]는 간격이 아니라 절대 시각을 찍는다 —
  /// "오늘 저녁" 칩(루프 시트)과 같은 기준.
  static DateTime curveFireAfter(DateTime t, int rung, String? timeOfDay) =>
      switch (rung.clamp(0, curveRungs - 1)) {
        0 => t.add(const Duration(minutes: 10)),
        1 => t.add(const Duration(hours: 1)),
        2 => _nextDailyFrom(t, timeOfDay ?? dayEndDefault),
        3 => t.add(const Duration(days: 1)),
        4 => t.add(const Duration(days: 7)),
        _ => t.add(const Duration(days: 30)),
      };

  /// [startRung]칸부터 사다리를 호출마다 한 칸씩 걷는 nextAfter —
  /// 알림 배치 예약(scheduleRepeatFires)용. stateful closure이라
  /// 매 호출마다 다음 칸으로 진행한다.
  static DateTime Function(DateTime) curveWalker({
    required int startRung,
    String? timeOfDay,
  }) {
    var rung = startRung;
    return (t) => curveFireAfter(t, rung++, timeOfDay);
  }

  /// monthly/yearly 발화 앵커 — timeOfDay("MM-dd HH:mm")에서 읽고,
  /// 깨진 값이면 [at]의 날짜·시각을 앵커로 쓴다. 잘못 저장된 규칙이
  /// 있어도 크래시 없이, 멈추지 않이.
  static _Anchor _anchorFor(
    RepeatKind kind, {
    String? timeOfDay,
    required DateTime at,
    int? everyN,
  }) {
    final a = _parseAnchor(timeOfDay);
    return switch (kind) {
      RepeatKind.monthly => (
        null,
        a?.$2 ?? at.day,
        a?.$3 ?? at.hour,
        a?.$4 ?? at.minute,
        everyN ?? 1,
        0,
      ),
      _ => (
        a?.$1 ?? at.month,
        a?.$2 ?? at.day,
        a?.$3 ?? at.hour,
        a?.$4 ?? at.minute,
        0,
        everyN ?? 1,
      ),
    };
  }

  /// 앵커 발화 중 [t]보다 뒤의 첫 발화 — [t]가 속한 달(연도)의 앵커부터
  /// 한 주기씩 민다. 몰아생성(settleRepeats)의 반복에도 그대로 맞는다.
  static DateTime _nextAnchoredAfter(DateTime t, _Anchor anchor) {
    final (month, day, hour, minute, stepMonths, stepYears) = anchor;
    var y = t.year;
    var m = month ?? t.month;
    var cand = _clampDay(y, m, day, hour, minute);
    while (!cand.isAfter(t)) {
      if (month == null) {
        m += stepMonths;
        y += (m - 1) ~/ 12;
        m = (m - 1) % 12 + 1;
      } else {
        y += stepYears;
      }
      cand = _clampDay(y, m, day, hour, minute);
    }
    return cand;
  }

  /// 그 달에 앵커 '일'이 없으면 말일로 — 31일 규칙은 2월엔 28·29일에.
  /// (DateTime(y, m+1, 0) = 그 달의 말일)
  static DateTime _clampDay(int y, int m, int d, int h, int min) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, d > last ? last : d, h, min);
  }

  /// monthly/yearly 앵커 "MM-dd HH:mm" → (월, 일, 시, 분). 형식이 아니면 null.
  static (int, int, int, int)? _parseAnchor(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{1,2})-(\d{1,2}) (\d{1,2}):(\d{2})$')
        .firstMatch(s.trim());
    if (m == null) return null;
    return (
      int.parse(m.group(1)!).clamp(1, 12),
      int.parse(m.group(2)!).clamp(1, 31),
      int.parse(m.group(3)!).clamp(0, 23),
      int.parse(m.group(4)!).clamp(0, 59),
    );
  }

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
  }) => switch (kind) {
    RepeatKind.minutes => now.add(Duration(minutes: everyN ?? 0)),
    RepeatKind.hours => now.add(Duration(hours: everyN ?? 0)),
    RepeatKind.daily => _nextDailyFrom(now, timeOfDay!),
    RepeatKind.weekday => _nextWorkdayFrom(now, timeOfDay!),
    RepeatKind.monthly || RepeatKind.yearly => _nextAnchoredAfter(
      now,
      _anchorFor(kind, timeOfDay: timeOfDay, at: now, everyN: everyN),
    ),
    // 사다리의 첫 칸은 언제나 10분 뒤.
    RepeatKind.curve => curveFireAfter(now, 0, timeOfDay),
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

  /// 사람용 라벨 — "10분마다", "매일 09:00", "매달 24일 09:00". (다국어)
  String label(AppLocalizations l10n) => labelOf(kind, everyN, timeOfDay, l10n);

  static String labelOf(
    RepeatKind kind,
    int? everyN,
    String? timeOfDay,
    AppLocalizations l10n,
  ) => switch (kind) {
    RepeatKind.minutes => l10n.ruleEveryMinutes(everyN ?? 0),
    RepeatKind.hours => l10n.ruleEveryHours(everyN ?? 0),
    RepeatKind.daily => l10n.ruleDaily(timeOfDay ?? '00:00'),
    RepeatKind.weekday => l10n.ruleWeekday(timeOfDay ?? '00:00'),
    RepeatKind.monthly => _monthlyLabel(everyN ?? 1, timeOfDay, l10n),
    RepeatKind.yearly => _yearlyLabel(everyN ?? 1, timeOfDay, l10n),
    RepeatKind.curve => l10n.ruleLadder,
  };

  /// "매달 24일 09:00" · "3개월마다 24일 09:00"
  static String _monthlyLabel(int n, String? timeOfDay, AppLocalizations l10n) {
    final a = _parseAnchor(timeOfDay);
    return n == 1
        ? l10n.ruleMonthly(a?.$2 ?? 1, _clock(a))
        : l10n.ruleEveryMonths(n, a?.$2 ?? 1, _clock(a));
  }

  /// "매년 10.24 09:00" · "2년마다 10.24 09:00"
  static String _yearlyLabel(int n, String? timeOfDay, AppLocalizations l10n) {
    final a = _parseAnchor(timeOfDay);
    final date = '${a?.$1 ?? 1}.${a?.$2 ?? 1}';
    return n == 1
        ? l10n.ruleYearly(date, _clock(a))
        : l10n.ruleEveryYears(n, date, _clock(a));
  }

  static String _clock((int, int, int, int)? a) =>
      '${(a?.$3 ?? 0).toString().padLeft(2, '0')}:'
      '${(a?.$4 ?? 0).toString().padLeft(2, '0')}';
}

/// 반복 설정 시트의 결과 — 아직 id/시각이 없는 규칙 초안.
class RepeatDraft {
  const RepeatDraft({required this.kind, this.everyN, this.timeOfDay});

  final RepeatKind kind;
  final int? everyN;
  final String? timeOfDay;

  DateTime firstFireFrom(DateTime now) => RepeatRule.firstFireOf(
    kind,
    everyN: everyN,
    timeOfDay: timeOfDay,
    now: now,
  );

  String label(AppLocalizations l10n) =>
      RepeatRule.labelOf(kind, everyN, timeOfDay, l10n);
}
