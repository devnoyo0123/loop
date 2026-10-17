/// 혼합 시각 표기 (docs/ui-design.md #6)
/// 당일 `14:32` / 어제 `어제 14:32` / 올해 `3.12 14:32` / 지난해 `2025.3.12`
/// [yesterdayLabel]은 다국어용 — 위젯에서 l10n.yesterday를 넘긴다.
String formatMixed(DateTime t, [DateTime? now, String yesterdayLabel = '어제']) {
  final n = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final hm = '${two(t.hour)}:${two(t.minute)}';
  if (t.year == n.year && t.month == n.month && t.day == n.day) return hm;
  final yesterday = DateTime(n.year, n.month, n.day - 1);
  if (t.year == yesterday.year &&
      t.month == yesterday.month &&
      t.day == yesterday.day) {
    return '$yesterdayLabel $hm';
  }
  if (t.year == n.year) return '${t.month}.${t.day} $hm';
  return '${t.year}.${t.month}.${t.day}';
}

/// 카드 헤더용 — 날짜+시간 항상 표기. (docs/ui-design.md #16)
/// 올해 `8.31 14:32` / 지난해 `2025.3.12 08:30`
String formatCard(DateTime t, [DateTime? now]) {
  final n = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final hm = '${two(t.hour)}:${two(t.minute)}';
  final md = '${t.month}.${t.day} $hm';
  return t.year == n.year ? md : '${t.year}.$md';
}
