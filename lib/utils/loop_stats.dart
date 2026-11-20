/// 기록 흐름 통계의 순수 계산 — DB·위젯 없이 시각 목록만으로 만든다.
/// (기획·스코프: docs/growth-ideas.md "기록 흐름 통계")
///
/// 날짜 버킷은 전부 기기 시간대(로컬 자정)로 계산한다. SQL의 날짜 함수는
/// UTC라 시간대 경계가 어긋나므로, DB는 epoch 밀리초만 주고 여기서 계산한다.
/// (docs/data-model.md "시간 저장 원칙"과 같은 규칙)
class LoopStats {
  const LoopStats({
    required this.totalLogs,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.heatmap,
    required this.heatmapStart,
  });

  /// 쓴 기록 수 — 내용이 있는 로그만 센다(반복으로 생긴 빈 포크 제외).
  final int totalLogs;

  /// 하루라도 쓴 날의 수 (전 기간 중복 없이).
  final int activeDays;

  /// 오늘부터 거꾸로 연속으로 쓴 날 수. 오늘 아직 안 썼으면 어제까지.
  final int currentStreak;

  /// 전 기간 최장 연속 기록 일수.
  final int longestStreak;

  /// 히트맵 셀의 날별 개수 — [주][요일] 순서로 평면화, 요일은 월=0…일=6.
  /// 아직 오지 않은 날은 -1 (화면에서 비활성 셀로 그린다).
  final List<int> heatmap;

  /// 히트맵 첫 칸의 날짜(자정) — 항상 월요일.
  final DateTime heatmapStart;

  /// 마지막 [heatmapWeeks]주의 히트맵을 포함한 통계 전체를 계산한다.
  factory LoopStats.fromTimestamps(
    Iterable<int> epochMs, {
    required DateTime now,
    int heatmapWeeks = 15,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime>{};
    final counts = <DateTime, int>{};
    var total = 0;
    for (final ms in epochMs) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final day = DateTime(dt.year, dt.month, dt.day);
      days.add(day);
      counts[day] = (counts[day] ?? 0) + 1;
      total++;
    }

    // 히트맵 창 — 이번 주(오늘이 속한 주)의 월요일에서 weeks주 전까지.
    final start = _shift(today, -((heatmapWeeks - 1) * 7 + today.weekday - 1));
    final cells = List<int>.filled(heatmapWeeks * 7, 0);
    for (var i = 0; i < cells.length; i++) {
      final d = _shift(start, i);
      cells[i] = d.isAfter(today) ? -1 : (counts[d] ?? 0);
    }

    return LoopStats(
      totalLogs: total,
      activeDays: days.length,
      currentStreak: _currentStreak(days, today),
      longestStreak: _longestStreak(days),
      heatmap: cells,
      heatmapStart: start,
    );
  }

  /// 히트맵 셀 농도 단계 (0~3) — 없음/조금/보통/많음.
  static int levelFor(int count) => switch (count) {
    _ when count <= 0 => 0,
    <= 2 => 1,
    <= 5 => 2,
    _ => 3,
  };

  /// 오늘(또는 어제)까지의 연속 일수 — 오늘 안 썼어도 어제까지 이어졌으면
  /// 스트릭은 살아 있다. GitHub 잔디와 같은 관례.
  static int _currentStreak(Set<DateTime> days, DateTime today) {
    var cursor = days.contains(today) ? today : _shift(today, -1);
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = _shift(cursor, -1);
    }
    return streak;
  }

  static int _longestStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final sorted = days.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      // 연속 판정은 24시간 차가 아니라 달력상 전날 비교 — DST가 있는
      // 시간대에서도 안전하다. (한국은 DST가 없어 어느 쪽이든 같다)
      run = sorted[i] == _shift(sorted[i - 1], 1) ? run + 1 : 1;
      if (run > longest) longest = run;
    }
    return longest;
  }

  /// 달력상 [n]일 앞뒤의 자정 — 생성자가 월/일 범위 초과를 정규화한다
  /// (DateTime(2026, 3, 0) = 2월 말). Duration 더하기와 달리 DST에 안전.
  static DateTime _shift(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);
}
