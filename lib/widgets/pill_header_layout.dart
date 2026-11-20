import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// 상태 알약(날짜 이동 중 · 루프 보기 중) + 그 아래 본문.
///
/// 알약은 본문 위에 **자기 줄을 차지한다** — 본문 위에 띄우면(Stack +
/// Positioned) 맨 위 카드의 날짜·장소를 가린다 (2026-11-01 실기기 Fold4).
/// 알약은 고정이라 스크롤해도 계속 보이고, 본문은 그 아래에서 시작한다.
class PillHeaderLayout extends StatelessWidget {
  const PillHeaderLayout({super.key, required this.pills, required this.child});

  /// 보여줄 알약들(없으면 본문이 맨 위부터).
  final List<Widget> pills;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final pill in pills)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s),
          child: Center(child: pill),
        ),
      Expanded(child: child),
    ],
  );
}
