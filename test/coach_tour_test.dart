import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/coach_tour.dart';

void main() {
  group('CoachTour — 첫 루프 투어 ①~④', () {
    test('정석 흐름: + → 예약 → 저장 → 카드 확인', () {
      final t = CoachTour();
      expect(t.step, CoachStep.write);
      expect(t.number, 1);
      t.composeOpened(loopPreset: false);
      expect(t.step, CoachStep.reserve);
      t.loopReserved();
      expect(t.step, CoachStep.save);
      t.composeClosed(saved: true, hasLoop: true);
      expect(t.step, CoachStep.returns);
      expect(t.number, 4);
      t.acknowledge();
      expect(t.isDone, isTrue);
    });

    test('스타터 카드로 열면 루프가 이미 있으니 ②를 건너뛰고 ③', () {
      final t = CoachTour()..composeOpened(loopPreset: true);
      expect(t.step, CoachStep.save);
    });

    test('작성 시트를 취소하면 다시 ①', () {
      final t = CoachTour()
        ..composeOpened(loopPreset: false)
        ..composeClosed(saved: false, hasLoop: false);
      expect(t.step, CoachStep.write);
    });

    test('루프 없이 저장하면 투어 종료(기록이 생겨 빈 화면 ①이 다시 못 나온다)', () {
      final t = CoachTour()
        ..composeOpened(loopPreset: false)
        ..composeClosed(saved: true, hasLoop: false);
      expect(t.isDone, isTrue);
    });

    test('예약한 루프를 지우면 ③에서 ②로 돌아간다', () {
      final t = CoachTour()
        ..composeOpened(loopPreset: false)
        ..loopReserved()
        ..loopCleared();
      expect(t.step, CoachStep.reserve);
    });

    test('어느 단계에서든 건너뛰면 끝', () {
      for (final s in [CoachStep.write, CoachStep.reserve, CoachStep.save, CoachStep.returns]) {
        expect((CoachTour(s)..skip()).isDone, isTrue);
      }
    });

    test('기존 사용자(기록 있음)는 투어 대상 아님 — 진행 중이면 건드리지 않음', () {
      expect((CoachTour()..existingUser()).isDone, isTrue);
      expect((CoachTour(CoachStep.returns)..existingUser()).step, CoachStep.returns);
    });

    test('엉뚱한 순서의 이벤트는 무시', () {
      final t = CoachTour()
        ..loopReserved()
        ..acknowledge()
        ..composeClosed(saved: true, hasLoop: true);
      expect(t.step, CoachStep.write);
    });

    test('저장 문자열 왕복, 모르는 값은 처음부터', () {
      expect(CoachTour.decode(CoachTour(CoachStep.save).encode()).step, CoachStep.save);
      expect(CoachTour.decode(null).step, CoachStep.write);
      expect(CoachTour.decode('garbage').step, CoachStep.write);
    });
  });
}
