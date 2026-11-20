import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/utils/loop_stats.dart';
import 'package:loop/widgets/heatmap.dart';
import 'package:loop/widgets/share_card_view.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  LoopStats dummyStats() => LoopStats.fromTimestamps(
    List.generate(
      40,
      (i) => DateTime.now()
          .subtract(Duration(days: i % 20, hours: i))
          .millisecondsSinceEpoch,
    ),
    now: DateTime.now(),
  );

  group('HeatmapGrid', () {
    testWidgets('주 수 × 7칸이 그려진다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeatmapGrid(stats: dummyStats(), today: DateTime.now()),
          ),
        ),
      );
      // 셀 Container 105개 + 부모 Container들 — 최소 105개는 확실히.
      final cells = find.byType(Container);
      expect(cells.evaluate().length, greaterThanOrEqualTo(105));
    });
  });

  group('ShareCardView', () {
    testWidgets('브랜드·하이라이트·숫자·태그라인이 다 그려진다', (tester) async {
      final stats = dummyStats();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShareCardView(
                stats: stats,
                returns: 42,
                l10n: l10n,
                today: DateTime.now(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Loop ↩'), findsOneWidget);
      expect(find.text(l10n.statsReturnsLine(42)), findsOneWidget);
      expect(find.text(l10n.statsTotalLogs), findsOneWidget);
      expect(find.text(l10n.shareCardTagline), findsOneWidget);
      expect(find.byType(HeatmapGrid), findsOneWidget);
    });
  });
}
