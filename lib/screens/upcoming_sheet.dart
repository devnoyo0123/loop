import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/repeat_rule.dart';
import '../utils/time_format.dart';

/// 다가오는 루프 미리보기 항목 하나.
class UpcomingLoopItem {
  const UpcomingLoopItem({
    required this.at,
    required this.logId,
    required this.title,
    required this.ruleLabel,
    required this.repeated,
  });

  /// 발화(도래) 예정 시각.
  final DateTime at;

  /// 점프 대상 로그 — 루프를 건 원본.
  final String logId;

  /// 원본 내용. 비어 있으면 화면이 l10n 폴백 문구로 표시한다.
  final String title;

  /// "한 번" / "매일 09:00" / "평일 09:00" / "10분마다" 등.
  final String ruleLabel;

  /// 반복 규칙 발화면 true — 아이콘 구분용.
  final bool repeated;
}

/// 오늘부터 7일 안에 올 루프를 한 장에 보여주는 시트. (사용자 요청)
///
/// - 단발 루프: 예약 시각이 창 안에 있는 것 전부
/// - 매일/평일 반복: 창 안의 매 발화 (하루 한 줄)
/// - 분/시간 반복: 다음 발화 하나만 — 7일치를 늘어놓으면 수백 줄이 된다
///
/// 항목을 탭하면 [show]가 그 루프의 원본 로그 id를 돌려주고,
/// 타임라인이 그 로그가 있는 날로 이동한다. (검색 점프와 같은 패턴)
class UpcomingSheet {
  static const window = Duration(days: 7);

  static Future<String?> show(BuildContext context, {required LoopDb db}) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext);
          final items = itemsFor(db, l10n);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(LoopSpacing.m,
                        LoopSpacing.l, LoopSpacing.m, LoopSpacing.s),
                    child: Text(
                      l10n.upcomingTitle,
                      style: const TextStyle(
                          color: LoopColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(LoopSpacing.l),
                            child: Text(
                              l10n.upcomingEmpty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: LoopColors.textDim,
                                  fontSize: 14,
                                  height: 1.6),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(
                                bottom: LoopSpacing.m),
                            itemCount: items.length,
                            itemBuilder: (context, i) => _tile(
                              sheetContext,
                              items[i],
                              l10n,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  /// [now]부터 7일 창의 발화를 시간순으로 모은다. (테스트를 위해 now 주입)
  static List<UpcomingLoopItem> itemsFor(
    LoopDb db,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final to = n.add(window);
    final items = <UpcomingLoopItem>[];

    for (final log in db.pendingLoopsBetween(n, to)) {
      items.add(UpcomingLoopItem(
        at: log.loopAt!,
        logId: log.id,
        title: log.content.trim(),
        ruleLabel: l10n.loopModeOnce,
        repeated: false,
      ));
    }

    for (final rule in db.activeRepeatRules()) {
      final title = db.byId(rule.sourceLogId)?.content.trim() ?? '';
      final label = rule.label(l10n);
      switch (rule.kind) {
        case RepeatKind.daily:
        case RepeatKind.weekday:
          // 하루 한 번 규칙 — 창 안의 매 발화가 각각 한 줄.
          var t = rule.nextFireAt;
          while (!t.isAfter(to)) {
            items.add(UpcomingLoopItem(
              at: t,
              logId: rule.sourceLogId,
              title: title,
              ruleLabel: label,
              repeated: true,
            ));
            t = rule.nextFireAfter(t);
          }
        case RepeatKind.minutes:
        case RepeatKind.hours:
          // 고빈도 반복 — 다음 발화만. 창 안이 아니면 아예 안 보인다.
          if (!rule.nextFireAt.isAfter(to)) {
            items.add(UpcomingLoopItem(
              at: rule.nextFireAt,
              logId: rule.sourceLogId,
              title: title,
              ruleLabel: label,
              repeated: true,
            ));
          }
      }
    }

    items.sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  /// 검색 결과 타일과 같은 문법의 행 — 시각+요일 / 원본 내용 / 규칙 라벨.
  static Widget _tile(
    BuildContext sheetContext,
    UpcomingLoopItem item,
    AppLocalizations l10n,
  ) {
    // narrowWeekdays는 일요일 시작 — DateTime.weekday(월=1…일=7)를 맞춘다.
    final weekday =
        MaterialLocalizations.of(sheetContext).narrowWeekdays[item.at.weekday % 7];
    return GestureDetector(
      onTap: () => Navigator.pop(sheetContext, item.logId),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: LoopSpacing.m, vertical: LoopSpacing.xs),
        padding: const EdgeInsets.all(LoopSpacing.m),
        decoration: BoxDecoration(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.repeated ? Icons.repeat : Icons.alarm,
                  size: 12,
                  color: item.repeated ? LoopColors.mint : LoopColors.lavender,
                ),
                const SizedBox(width: 4),
                Text(
                  '${formatCard(item.at)} $weekday',
                  style: const TextStyle(
                    color: LoopColors.textDim,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  item.ruleLabel,
                  style: const TextStyle(
                      color: LoopColors.mint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.title.isEmpty ? l10n.noContent : item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: LoopColors.text, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
