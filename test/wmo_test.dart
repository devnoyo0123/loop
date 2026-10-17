import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/services/weather_service.dart';

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('Wmo.describe — 종류·아이콘 분기', () {
    test('맑음 계열', () {
      expect(Wmo.describe(0).kind, WmoKind.clear);
      expect(Wmo.describe(1).kind, WmoKind.clear);
      expect(Wmo.describe(0).icon, Icons.wb_sunny);
    });

    test('구름/흐림/안개 계열', () {
      expect(Wmo.describe(2).kind, WmoKind.partly);
      expect(Wmo.describe(3).kind, WmoKind.cloudy);
      expect(Wmo.describe(45).kind, WmoKind.fog);
      expect(Wmo.describe(48).kind, WmoKind.fog);
    });

    test('비 계열 — 이슬비/비/소나기 전부 물 아이콘', () {
      for (final code in [51, 53, 55, 56, 57]) {
        expect(Wmo.describe(code).kind, WmoKind.drizzle);
        expect(Wmo.describe(code).icon, Icons.water_drop);
      }
      for (final code in [61, 63, 65, 66, 67, 80, 81, 82]) {
        expect(Wmo.describe(code).kind, WmoKind.rain);
      }
    });

    test('눈/뇌우', () {
      expect(Wmo.describe(71).kind, WmoKind.snow);
      expect(Wmo.describe(86).kind, WmoKind.snow);
      expect(Wmo.describe(95).kind, WmoKind.thunder);
      expect(Wmo.describe(99).icon, Icons.bolt);
    });

    test('모르는 코드는 알 수 없음', () {
      expect(Wmo.describe(42).kind, WmoKind.unknown);
    });
  });

  group('Wmo.label — locale별 라벨', () {
    test('ko', () {
      expect(Wmo.label(ko, WmoKind.clear), '맑음');
      expect(Wmo.label(ko, WmoKind.partly), '구름 조금');
      expect(Wmo.label(ko, WmoKind.cloudy), '흐림');
      expect(Wmo.label(ko, WmoKind.fog), '안개');
      expect(Wmo.label(ko, WmoKind.drizzle), '이슬비');
      expect(Wmo.label(ko, WmoKind.rain), '비');
      expect(Wmo.label(ko, WmoKind.snow), '눈');
      expect(Wmo.label(ko, WmoKind.thunder), '뇌우');
      expect(Wmo.label(ko, WmoKind.unknown), '알 수 없음');
    });

    test('en', () {
      expect(Wmo.label(en, WmoKind.clear), 'Clear');
      expect(Wmo.label(en, WmoKind.rain), 'Rain');
      expect(Wmo.label(en, WmoKind.thunder), 'Thunderstorm');
    });
  });
}
