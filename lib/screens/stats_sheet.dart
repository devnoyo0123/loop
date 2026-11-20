import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../utils/loop_stats.dart';
import '../utils/on_this_day.dart';
import '../widgets/heatmap.dart';

/// 기록 흐름 페이지 (docs/growth-ideas.md v1 → 2026-11-01 전체화면 전환).
///
/// 핵심 숫자 4개 · "생각이 N번 다시 돌아왔어요" · 최근 15주 히트맵 ·
/// 가장 많이 이어진 사슬 TOP 3 · **그때의 나**(1년·1개월·1주 전 오늘의
/// 기록 — 스크롤로 훑는다). 아침 9시 알림 하나가 이 페이지를 바로 연다.
///
/// 페이지를 닫을 때 [StatsPick]을 돌려준다 — 사슬을 고르면 루프 보기로,
/// 그때의 나 기록을 고르면 그날 타임라인으로 이동한다.
class StatsPick {
  const StatsPick({this.chainLogId, this.jumpLogId});

  final String? chainLogId;
  final String? jumpLogId;
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.db});

  final LoopDb db;

  /// 히트맵 주 수 — 캡션 문구("최근 15주")와 값을 하나로 유지한다.
  static const weeks = 15;

  static Future<StatsPick?> show(
    BuildContext context, {
    required LoopDb db,
  }) => Navigator.push<StatsPick>(
    context,
    MaterialPageRoute<StatsPick>(builder: (_) => StatsPage(db: db)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final stats = LoopStats.fromTimestamps(
      db.writtenLogTimestamps(),
      now: now,
      heatmapWeeks: weeks,
    );
    final returns = db.loopReturnCount();
    final chains = db.topChains();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.statsTitle,
          style: const TextStyle(
            color: LoopColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: stats.totalLogs == 0
          ? Padding(
              padding: const EdgeInsets.all(LoopSpacing.l),
              child: Text(
                l10n.statsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LoopColors.textDim,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: LoopSpacing.s,
                bottom: LoopSpacing.xl,
              ),
              children: [
                if (returns > 0)
                  _returnsLine(l10n, returns)
                else
                  _returnsZero(l10n),
                _numbers(l10n, stats),
                _heatmap(context, l10n, stats, now),
                if (chains.isNotEmpty) ...[
                  _sectionHeader(l10n.statsTopChains),
                  for (final c in chains) _chainTile(context, l10n, db, c),
                ],
                ..._onThisDaySection(context, l10n, now),
              ],
            ),
    );
  }

  /// 그때의 나 — 1년·1개월·1주 전 "오늘"의 기록을 거리 순으로. 스크롤로
  /// 훑게 하려는 게 이 페이지 전환의 목적이다. (2026-11-01 사용자 요청)
  List<Widget> _onThisDaySection(
    BuildContext context,
    AppLocalizations l10n,
    DateTime now,
  ) {
    final d = onThisDayDatesFor(now);
    final groups = [
      (l10n.onThisDayYearAgo, db.logsOnDay(d.year)),
      (l10n.onThisDayMonthAgo, db.logsOnDay(d.month)),
      (l10n.onThisDayWeekAgo, db.logsOnDay(d.week)),
    ];
    return [
      _sectionHeader(l10n.onThisDayTitle),
      for (final (label, logs) in groups) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LoopSpacing.m,
            LoopSpacing.xs,
            LoopSpacing.m,
            LoopSpacing.xs,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: LoopColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              LoopSpacing.m,
              0,
              LoopSpacing.m,
              LoopSpacing.xs,
            ),
            child: Text(
              '—',
              style: TextStyle(color: LoopColors.textDim, fontSize: 12),
            ),
          )
        else
          for (final log in logs) _pastMeTile(context, l10n, log),
      ],
    ];
  }

  /// 그때의 나 한 줄 — 시간 + 내용 미리보기. 탭하면 그날 타임라인으로.
  Widget _pastMeTile(
    BuildContext context,
    AppLocalizations l10n,
    LogEntry log,
  ) {
    final preview = OnThisDayPick.previewOf(log.content);
    final empty = preview.trim().isEmpty;
    final time = TimeOfDay.fromDateTime(log.createdAt);
    return GestureDetector(
      onTap: () => Navigator.pop(context, StatsPick(jumpLogId: log.id)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: LoopSpacing.m,
          vertical: LoopSpacing.xs,
        ),
        padding: const EdgeInsets.all(LoopSpacing.m),
        decoration: BoxDecoration(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              time.format(context),
              style: const TextStyle(
                color: LoopColors.textDim,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: Text(
                empty ? l10n.noContent : preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: empty ? LoopColors.textDim : LoopColors.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: LoopSpacing.s),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: LoopColors.textDim,
            ),
          ],
        ),
      ),
    );
  }

  /// "생각이 N번 다시 돌아왔어요" — 이 앱의 차별점을 숫자로 보여주는 라인.
  static Widget _returnsLine(AppLocalizations l10n, int returns) => Container(
    margin: const EdgeInsets.fromLTRB(
      LoopSpacing.m,
      0,
      LoopSpacing.m,
      LoopSpacing.s,
    ),
    padding: const EdgeInsets.all(LoopSpacing.m),
    decoration: BoxDecoration(
      color: LoopColors.surfaceHi,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: LoopColors.line),
    ),
    child: Row(
      children: [
        const Icon(Icons.replay, size: 16, color: LoopColors.mint),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: Text(
            l10n.statsReturnsLine(returns),
            style: const TextStyle(
              color: LoopColors.text,
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  /// 아직 돌아온 루프가 없을 때 — 루프 기능으로 가는 부드러운 안내.
  static Widget _returnsZero(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.fromLTRB(
      LoopSpacing.m,
      0,
      LoopSpacing.m,
      LoopSpacing.s,
    ),
    child: Text(
      l10n.statsReturnsZero,
      style: const TextStyle(color: LoopColors.textDim, fontSize: 12.5),
    ),
  );

  /// 핵심 숫자 4개 — 쓴 기록 / 기록한 날 / 지금 연속 / 최장 연속.
  static Widget _numbers(AppLocalizations l10n, LoopStats stats) => Padding(
    padding: const EdgeInsets.fromLTRB(
      LoopSpacing.m,
      LoopSpacing.s,
      LoopSpacing.m,
      LoopSpacing.m,
    ),
    child: Row(
      children: [
        _tile(l10n.statsTotalLogs, stats.totalLogs.toString()),
        _tile(l10n.statsActiveDays, stats.activeDays.toString()),
        _tile(l10n.statsStreakNow, l10n.statsDays(stats.currentStreak)),
        _tile(
          l10n.statsStreakBest,
          l10n.statsDays(stats.longestStreak),
          last: true,
        ),
      ],
    ),
  );

  static Widget _tile(String label, String value, {bool last = false}) =>
      Expanded(
        child: Container(
          margin: EdgeInsets.only(right: last ? 0 : LoopSpacing.s),
          padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s + 4),
          decoration: BoxDecoration(
            color: LoopColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoopColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoopColors.textDim,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      );

  /// 최근 [weeks]주 히트맵 — 캡션·범례·요일 라벨(월·수·금)과 함께.
  /// 격자 자체는 HeatmapGrid(공유 카드와 공유).
  static Widget _heatmap(
    BuildContext pageContext,
    AppLocalizations l10n,
    LoopStats stats,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    // narrowWeekdays는 일요일 시작 — 행 순서(월=0…일=6)에 맞게 다시 배열.
    final weekdays = MaterialLocalizations.of(pageContext).narrowWeekdays;
    final dayLabel = [for (var d = 1; d <= 7; d++) weekdays[d % 7]];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LoopSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.statsHeatmapCaption,
                style: const TextStyle(
                  color: LoopColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                l10n.statsHeatmapLess,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 10),
              ),
              const SizedBox(width: 4),
              for (final c in HeatmapGrid.heatColors) _legendCell(c),
              const SizedBox(width: 4),
              Text(
                l10n.statsHeatmapMore,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: LoopSpacing.s),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요일 라벨 — 월·수·금만. 셀(13+3 리듬)과 세로로 맞춘다.
                Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Container(
                        width: 16,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 3),
                        alignment: Alignment.centerLeft,
                        child: d % 2 == 0
                            ? Text(
                                dayLabel[d],
                                style: const TextStyle(
                                  color: LoopColors.textDim,
                                  fontSize: 8,
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                HeatmapGrid(stats: stats, today: today),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendCell(Color c) => Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.only(right: 2),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
  );

  static Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      LoopSpacing.m,
      LoopSpacing.m,
      LoopSpacing.m,
      LoopSpacing.xs,
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: LoopColors.textDim,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );

  /// 사슬 타일 — 미리보기 시트의 행과 같은 문법. 탭하면 루프 보기로.
  Widget _chainTile(
    BuildContext pageContext,
    AppLocalizations l10n,
    LoopDb db,
    ({String chainId, int count, String logId}) chain,
  ) {
    final preview = db.byId(chain.logId)?.content.trim() ?? '';
    return GestureDetector(
      onTap: () => Navigator.pop(pageContext, StatsPick(chainLogId: chain.logId)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: LoopSpacing.m,
          vertical: LoopSpacing.xs,
        ),
        padding: const EdgeInsets.all(LoopSpacing.m),
        decoration: BoxDecoration(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_tree,
              size: 14,
              color: LoopColors.lavender,
            ),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: Text(
                preview.isEmpty ? l10n.noContent : preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoopColors.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: LoopSpacing.s),
            Text(
              l10n.statsChainLinkings(chain.count),
              style: const TextStyle(
                color: LoopColors.mint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
