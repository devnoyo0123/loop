import '../l10n/generated/app_localizations.dart';

/// 첫 루프 스타터 — 빈 타임라인에서 첫 기록과 함께 자동으로 걸리는 예약.
/// (기획: docs/growth-ideas.md "첫 루프 스타터 팩")
///
/// 핵심 사이클(쓰기 → 돌아옴 → 이어쓰기)을 첫 세션 안에 체감시켜
/// D1 이탈을 줄이는 장치다. 스타터는 예약 "방식"만 정의하고 내용은
/// 사용자가 작성 시트에 직접 쓴다 — 사용자가 예약(⏰)을 직접 골랐다면
/// 그 선택이 우선한다.
enum StarterKind {
  /// N분 뒤 도는 한 번 루프 — 망각곡선의 첫 단계(10분)를 그대로 체험.
  once,

  /// 매일 같은 시각에 도는 반복 규칙.
  daily,
}

class Starter {
  const Starter({required this.kind, this.everyN, this.timeOfDay});

  final StarterKind kind;

  /// [StarterKind.once] — N분 후.
  final int? everyN;

  /// [StarterKind.daily] — 발화 시각 "HH:mm".
  final String? timeOfDay;

  /// 매일 밤 스타터인지 — 아이콘·색 결정에 쓴다.
  bool get isDaily => kind == StarterKind.daily;

  /// 카드 제목.
  String label(AppLocalizations l10n) => switch (kind) {
    StarterKind.daily => l10n.starterDailyTitle,
    StarterKind.once when everyN == starterQuick.everyN =>
      l10n.starterQuickTitle,
    _ => l10n.starterWeekTitle,
  };

  /// 카드 한 줄 설명.
  String desc(AppLocalizations l10n) => switch (kind) {
    StarterKind.daily => l10n.starterDailyDesc,
    StarterKind.once when everyN == starterQuick.everyN =>
      l10n.starterQuickDesc,
    _ => l10n.starterWeekDesc,
  };

  /// 작성 시트 상단 배너 — "10분 뒤 다시 돌아와요"에 쓸 시점 라벨.
  String whenLabel(AppLocalizations l10n) => switch (kind) {
    StarterKind.once => l10n.starterInMinutes(everyN!),
    StarterKind.daily => l10n.starterEveryNight(timeOfDay!),
  };
}

/// 10분 루프 — 앱을 닫기도 전에 돌아오는 가장 빠른 첫 체험.
const starterQuick = Starter(kind: StarterKind.once, everyN: 10);

/// 일주일 루프 — 한 주 뒤의 회고.
const starterWeek = Starter(kind: StarterKind.once, everyN: 60 * 24 * 7);

/// 스타터 3종 — 순서가 노출 순서. 매일 밤은 [dayEndStarter]로 만든다 —
/// 하루 마무리 시각(설정, 기본 21:00)을 따라야 하기 때문.
const starterList = [starterQuick, starterWeek]; // + dayEndStarter(dayEnd)

/// 매일 밤 스타터 — [hhmm]은 하루 마무리 시각(설정값).
Starter dayEndStarter(String hhmm) =>
    Starter(kind: StarterKind.daily, timeOfDay: hhmm);

/// 매일 반복의 다음 발화 시각 — 오늘 [hhmm]이 아직 남았으면 오늘,
/// 지났으면 내일. (한국은 DST가 없어 시각이 그대로 유지된다)
DateTime nextDailyFire(String hhmm, DateTime now) {
  final parts = hhmm.split(':');
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
  if (today.isAfter(now)) return today;
  return DateTime(
    today.year,
    today.month,
    today.day + 1,
    today.hour,
    today.minute,
  );
}

/// 하루 마무리 시각 — "오늘 저녁"의 기준. (기본 21:00, 설정에서 변경)
/// 스타터의 매일 밤, 루프 칩의 "오늘 저녁", 그때의 나의 저녁 짝이 모두
/// 이 하나의 값으로 일관된다. "HH:mm".
const dayEndDefault = '21:00';

/// [now] 기준 다음 마무리 시각 — 오늘 아직 안 지났으면 오늘, 지났으면 내일.
/// 곡선 칩처럼 상대 시간을 더하지 않고 절대 시각을 찍는 "하루 마무리" 전용.
DateTime nextDayEnd(String hhmm, DateTime now) => nextDailyFire(hhmm, now);
