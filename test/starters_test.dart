import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/utils/starters.dart';

void main() {
  group('Starter — 첫 루프 프리셋', () {
    final l10n = lookupAppLocalizations(const Locale('ko'));

    test('3종 구성 — 10분 단발 · 매일 밤(마무리 시각) · 일주일 단발', () {
      expect(starterList.length, 2); // 매일 밤은 dayEndStarter로 조립
      expect(starterList[0].kind, StarterKind.once);
      expect(starterList[0].everyN, 10);
      expect(starterList[1].everyN, 60 * 24 * 7);
      expect(dayEndStarter('21:00').kind, StarterKind.daily);
      expect(dayEndStarter('21:00').timeOfDay, '21:00');
    });

    test('라벨 — 프리셋별로 제목·설명·시점 라벨이 다르다', () {
      expect(starterQuick.label(l10n), l10n.starterQuickTitle);
      expect(dayEndStarter('21:00').label(l10n), l10n.starterDailyTitle);
      expect(starterWeek.label(l10n), l10n.starterWeekTitle);
      expect(starterQuick.desc(l10n), isNot(equals(starterWeek.desc(l10n))));
      expect(starterQuick.whenLabel(l10n), contains('10'));
      expect(dayEndStarter('21:00').whenLabel(l10n), contains('21:00'));
    });
  });

  group('nextDailyFire — 매일 반복의 다음 발화', () {
    test('오늘 21:00이 남았으면 오늘', () {
      final now = DateTime(2026, 10, 25, 15);
      expect(nextDailyFire('21:00', now), DateTime(2026, 10, 25, 21));
    });

    test('오늘 21:00이 지났으면 내일', () {
      final now = DateTime(2026, 10, 25, 21, 30);
      expect(nextDailyFire('21:00', now), DateTime(2026, 10, 26, 21));
    });

    test('정각 경계 — 21:00 딱이면 내일 (isAfter)', () {
      final now = DateTime(2026, 10, 25, 21);
      expect(nextDailyFire('21:00', now), DateTime(2026, 10, 26, 21));
    });

    test('nextDayEnd — "오늘 저녁"은 마무리 시각의 절대 시각', () {
      // 15시 기준: 오늘 21:00
      expect(
        nextDayEnd('21:00', DateTime(2026, 10, 30, 15)),
        DateTime(2026, 10, 30, 21),
      );
      // 22시 기준: 내일 21:00
      expect(
        nextDayEnd('21:00', DateTime(2026, 10, 30, 22)),
        DateTime(2026, 10, 31, 21),
      );
    });

    test('월말 경계 — 10/31 23시면 11/1', () {
      final now = DateTime(2026, 10, 31, 23);
      expect(nextDailyFire('21:00', now), DateTime(2026, 11, 1, 21));
    });
  });
}
