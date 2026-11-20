import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';

/// "그때의 나" — 같은 날짜의 과거 기록(1주·1개월·1년 전 오늘)을 골라
/// 아침 알림으로 다시 들려준다. (기획: docs/growth-ideas.md "그때의 나")
///
/// 순수 로직만 — DB 조회는 호출자가 하고, 날짜 계산은 전부 기기
/// 시간대의 달력 산술(생성자 정규화)로 한다.
enum OnThisDayDistance { week, month, year }

class OnThisDayPick {
  const OnThisDayPick({required this.log, required this.distance});

  final LogEntry log;
  final OnThisDayDistance distance;

  String distanceLabel(AppLocalizations l10n) => switch (distance) {
    OnThisDayDistance.week => l10n.onThisDayWeekAgo,
    OnThisDayDistance.month => l10n.onThisDayMonthAgo,
    OnThisDayDistance.year => l10n.onThisDayYearAgo,
  };

  /// 알림 본문 — "원문 미리보기 · 1년 전 오늘".
  String notificationBody(AppLocalizations l10n) =>
      '${previewOf(log.content)} · ${distanceLabel(l10n)}';

  /// 알림 본문에 실을 미리보기 — 앞 48자(rune) + …. 이모지 안전.
  static String previewOf(String content, {int max = 48}) {
    final runes = content.trim().runes.toList();
    if (runes.length <= max) return String.fromCharCodes(runes);
    return '${String.fromCharCodes(runes.sublist(0, max))}…';
  }
}

/// [date]의 1주·1개월·1년 전 날짜. 월·년은 말일로 클램프한다 —
/// 3월 31일의 한 달 전은 2월 28일, 2월 29일의 1년 전은 2월 28일.
/// (Dart 생성자는 넘치는 날짜를 다음 달로 굴리므로 직접 계산해야 한다)
({DateTime week, DateTime month, DateTime year}) onThisDayDatesFor(
  DateTime date,
) => (
  week: DateTime(date.year, date.month, date.day - 7),
  month: _sameDayPreviousMonth(date),
  year: _sameDayPreviousYear(date),
);

int _lastDayOf(int year, int month) =>
    DateTime(year, month + 1, 0).day; // 다음 달 0일 = 이번 달 말일

DateTime _sameDayPreviousMonth(DateTime date) {
  final first = DateTime(date.year, date.month - 1, 1);
  final last = _lastDayOf(first.year, first.month);
  return DateTime(first.year, first.month, date.day < last ? date.day : last);
}

DateTime _sameDayPreviousYear(DateTime date) {
  final last = _lastDayOf(date.year - 1, date.month);
  return DateTime(date.year - 1, date.month, date.day < last ? date.day : last);
}

/// 후보 중 고른다 — 1년 → 1개월 → 1주 순(가장 먼 재회 우선). 각 거리에서는
/// 그날의 첫 기록: `db.logsOnDay`가 시간 순으로 주는 목록에서 내용 있는
/// 첫 로그(반복 발화의 빈 포크는 건너뛴다).
OnThisDayPick? selectOnThisDay({
  List<LogEntry> weekAgo = const [],
  List<LogEntry> monthAgo = const [],
  List<LogEntry> yearAgo = const [],
}) {
  final byDistance = [
    (OnThisDayDistance.year, yearAgo),
    (OnThisDayDistance.month, monthAgo),
    (OnThisDayDistance.week, weekAgo),
  ];
  for (final (distance, logs) in byDistance) {
    for (final log in logs) {
      if (log.content.trim().isNotEmpty) {
        return OnThisDayPick(log: log, distance: distance);
      }
    }
  }
  return null;
}
