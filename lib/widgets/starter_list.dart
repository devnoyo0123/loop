import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/starters.dart';

/// 첫 루프 스타터 3장 — 텅 빈 최신 타임라인에 뜨는 시작 안내.
/// 탭하면 [onPick]으로 스타터가 전달되고, 타임라인이 작성 시트를 열어
/// 저장하면 그 스타터의 루프/반복이 첫 기록에 자동으로 걸린다.
/// (기획: docs/growth-ideas.md "첫 루프 스타터 팩")
///
/// 스타터의 뜻: 핵심 사이클(쓰기 → 돌아옴 → 이어쓰기)을 첫 세션 안에
/// 체감시켜 D1 이탈을 줄인다. 10분 루프는 망각곡선의 첫 단계를 그대로
/// 체험하는 가장 빠른 시작. 매일 밤은 [dayEnd]의 마무리 시각(설정값)을 따른다.
class StarterList extends StatelessWidget {
  const StarterList({
    super.key,
    required this.onPick,
    this.dayEnd = dayEndDefault,
  });

  final ValueChanged<Starter> onPick;

  /// 하루 마무리 시각 ("HH:mm") — 설정에서 온 값.
  final String dayEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final starters = [starterQuick, dayEndStarter(dayEnd), starterWeek];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: LoopSpacing.l),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: LoopSpacing.m),
              child: Text(
                l10n.emptyTimeline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: LoopColors.textDim, height: 1.6),
              ),
            ),
            for (final s in starters) _card(l10n, s),
          ],
        ),
      ),
    );
  }

  Widget _card(AppLocalizations l10n, Starter s) {
    final icon = s.isDaily
        ? Icons.repeat
        : s.kind == StarterKind.once && s.everyN == starterQuick.everyN
        ? Icons.bolt
        : Icons.event_outlined;
    return GestureDetector(
      onTap: () => onPick(s),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: LoopSpacing.s),
        padding: const EdgeInsets.all(LoopSpacing.m),
        decoration: BoxDecoration(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoopColors.line),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: s.isDaily ? LoopColors.mint : LoopColors.lavender,
            ),
            const SizedBox(width: LoopSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.label(l10n),
                    style: const TextStyle(
                      color: LoopColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.desc(l10n),
                    style: const TextStyle(
                      color: LoopColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: LoopColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}
