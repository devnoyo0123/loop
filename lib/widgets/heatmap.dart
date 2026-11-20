import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../utils/loop_stats.dart';

/// 히트맵 격자 — 통계 시트와 공유 카드가 같은 렌더링을 쓴다.
/// [cellSize]/[gap]만 바꿔 크기를 조절한다.
class HeatmapGrid extends StatelessWidget {
  const HeatmapGrid({
    super.key,
    required this.stats,
    required this.today,
    this.cellSize = 13,
    this.gap = 3,
  });

  final LoopStats stats;

  /// 오늘 날짜(자정) — 이 칸에 민트 테두리를 두른다.
  final DateTime today;

  final double cellSize;
  final double gap;

  /// 셀 농도 — 0(없음) → 3(많음). -1(미래)은 투명.
  static const heatColors = <Color>[
    LoopColors.surfaceHi,
    Color(0x4DA78BFA),
    Color(0x99A78BFA),
    LoopColors.lavender,
  ];

  @override
  Widget build(BuildContext context) {
    final weeks = stats.heatmap.length ~/ 7;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var w = 0; w < weeks; w++)
          Column(children: [for (var d = 0; d < 7; d++) _cell(w * 7 + d)]),
      ],
    );
  }

  Widget _cell(int i) {
    final count = stats.heatmap[i];
    final date = DateTime(
      stats.heatmapStart.year,
      stats.heatmapStart.month,
      stats.heatmapStart.day + i,
    );
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.only(right: gap, bottom: gap),
      decoration: BoxDecoration(
        color: count < 0
            ? Colors.transparent
            : heatColors[LoopStats.levelFor(count)],
        borderRadius: BorderRadius.circular(cellSize * 0.23),
        border: isToday ? Border.all(color: LoopColors.mint, width: 1) : null,
      ),
    );
  }
}
