import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/loop_stats.dart';
import 'heatmap.dart';

/// 공유 카드 시각물 — 논리 크기 540×675(4:5)를 pixelRatio 2로 찍어
/// 1080×1350 PNG가 된다. 통계 시트와 같은 색·요소를 쓴다(히트맵 격자 공유).
class ShareCardView extends StatelessWidget {
  const ShareCardView({
    super.key,
    required this.stats,
    required this.returns,
    required this.l10n,
    required this.today,
  });

  final LoopStats stats;
  final int returns;
  final AppLocalizations l10n;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      height: 675,
      color: LoopColors.bg,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Loop ↩',
                style: TextStyle(
                  color: LoopColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                l10n.statsTitle,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            l10n.statsReturnsLine(returns),
            style: const TextStyle(
              color: LoopColors.mint,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 34),
          Row(
            children: [
              _number(stats.totalLogs.toString(), l10n.statsTotalLogs),
              _number(stats.activeDays.toString(), l10n.statsActiveDays),
              _number(l10n.statsDays(stats.currentStreak), l10n.statsStreakNow),
              _number(
                l10n.statsDays(stats.longestStreak),
                l10n.statsStreakBest,
              ),
            ],
          ),
          const SizedBox(height: 34),
          HeatmapGrid(stats: stats, today: today, cellSize: 16, gap: 4),
          const Spacer(),
          Text(
            l10n.shareCardTagline,
            style: const TextStyle(
              color: LoopColors.textDim,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _number(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: LoopColors.text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
        ),
      ],
    ),
  );
}
