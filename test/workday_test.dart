import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/workday.dart';

void main() {
  group('한국 공휴일 날짜표 (utils/workday.dart)', () {
    test('토·일은 근무일이 아니다', () {
      expect(isWorkday(DateTime(2026, 10, 17)), isFalse); // 토
      expect(isWorkday(DateTime(2026, 10, 18)), isFalse); // 일
      expect(isWorkday(DateTime(2026, 10, 19)), isTrue); // 월
    });

    test('2026 — 대체공휴일 포함 판정', () {
      expect(isKoreanHoliday(DateTime(2026, 3, 1)), isTrue); // 삼일절(일)
      expect(isKoreanHoliday(DateTime(2026, 3, 2)), isTrue); // 대체(월)
      expect(isWorkday(DateTime(2026, 3, 3)), isTrue); // 다음 날은 근무일
      expect(isKoreanHoliday(DateTime(2026, 10, 9)), isTrue); // 한글날(금)
      expect(isWorkday(DateTime(2026, 10, 9)), isFalse);
      expect(isKoreanHoliday(DateTime(2026, 10, 13)), isFalse); // 평범한 화요일
    });

    test('2027 — 설 연휴+대체, 한글날+대체', () {
      expect(isKoreanHoliday(DateTime(2027, 2, 6)), isTrue); // 설 전날(토)
      expect(isKoreanHoliday(DateTime(2027, 2, 9)), isTrue); // 대체(화)
      expect(isKoreanHoliday(DateTime(2027, 10, 9)), isTrue); // 한글날(토)
      expect(isKoreanHoliday(DateTime(2027, 10, 11)), isTrue); // 대체(월)
      expect(isWorkday(DateTime(2027, 10, 12)), isTrue);
    });

    test('2028 — 추석이 개천절과 겹치는 해', () {
      expect(isKoreanHoliday(DateTime(2028, 10, 2)), isTrue); // 추석 전날
      expect(isKoreanHoliday(DateTime(2028, 10, 3)), isTrue); // 추석+개천절
      expect(isKoreanHoliday(DateTime(2028, 10, 4)), isTrue); // 추석 다음날
      expect(isKoreanHoliday(DateTime(2028, 10, 5)), isTrue); // 대체(목)
      expect(isWorkday(DateTime(2028, 10, 6)), isTrue); // 금 — 근무일 복귀
    });

    test('표에 없는 해 — 주말만 판정, 평일은 근무일로 둔다', () {
      // 2030-01-01은 화요일 — 표 밖이지만 근무일.
      expect(isWorkday(DateTime(2030, 1, 1)), isTrue);
      expect(isWorkday(DateTime(2030, 1, 5)), isFalse); // 토
    });
  });
}
