import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/time_format.dart';

void main() {
  group('formatMixed', () {
    // 고정된 "지금" 기준: 2026-08-31 (월)
    final now = DateTime(2026, 8, 31, 14, 32);

    test('당일이면 시간만', () {
      expect(formatMixed(DateTime(2026, 8, 31, 9, 5), now), '09:05');
    });

    test('어제면 어제 + 시간', () {
      expect(formatMixed(DateTime(2026, 8, 30, 23, 1), now), '어제 23:01');
    });

    test('올해 과거면 월.일 + 시간', () {
      expect(formatMixed(DateTime(2026, 3, 12, 8, 30), now), '3.12 08:30');
    });

    test('지난해면 년.월.일', () {
      expect(formatMixed(DateTime(2025, 3, 12, 8, 30), now), '2025.3.12');
    });

    test('시각 0 패딩', () {
      expect(formatMixed(DateTime(2026, 8, 31, 3, 7), now), '03:07');
    });
  });

  group('formatCard', () {
    final now = DateTime(2026, 8, 31, 14, 32);

    test('당일이어도 날짜+시간 항상 표기', () {
      expect(formatCard(DateTime(2026, 8, 31, 9, 5), now), '8.31 09:05');
    });

    test('올해 과거', () {
      expect(formatCard(DateTime(2026, 3, 12, 8, 30), now), '3.12 08:30');
    });

    test('지난해면 년까지', () {
      expect(formatCard(DateTime(2025, 3, 12, 8, 30), now), '2025.3.12 08:30');
    });

    test('시각 0 패딩', () {
      expect(formatCard(DateTime(2026, 8, 31, 3, 7), now), '8.31 03:07');
    });
  });
}
