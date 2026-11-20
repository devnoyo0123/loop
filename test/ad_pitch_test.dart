import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/utils/ad_slots.dart';
import 'package:loop/widgets/log_card.dart';

/// "한 화면에 광고 최대 1개" 보장(2026-11-12)은 로그 카드가 최소
/// AdSlots.minLogCardPitch 이상이라는 가정에 기댄다. 카드 디자인이 줄어들면
/// 이 테스트가 먼저 깨져서 상수를 함께 낮추게 한다.
void main() {
  for (final content in ['', 'a', '밥먹자']) {
    testWidgets('가장 작은 로그 카드("$content")도 최소 피치 이상', (tester) async {
      final at = DateTime(2026, 11, 12, 9);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                LogCard(
                  log: LogEntry(
                    id: 'a',
                    content: content,
                    createdAt: at,
                    originalCreatedAt: at,
                  ),
                  onAction: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final h = tester.getSize(find.byType(LogCard)).height;
      expect(h, greaterThanOrEqualTo(AdSlots.minLogCardPitch));
    });
  }
}
