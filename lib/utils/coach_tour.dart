/// 첫 루프 투어(코치 마크 ①~④) 진행 상태 — 위젯·저장소 없는 순수 상태 기계.
/// (2026-11-16 사용자 결정: 빈 타임라인에서 시작해 첫 루프를 끝까지 만들게 안내)
///
/// ① write   타임라인 + 버튼 — "지금 떠오르는 걸 적어보세요"
/// ② reserve 작성 시트 🔔+ 예약 버튼 — "언제 다시 볼지 정해보세요"
/// ③ save    작성 시트 저장 버튼 — "저장하면 루프 완성이에요"
/// ④ returns 방금 저장한 카드 — "돌아오면 이어서 적어보세요" (확인으로 종료)
///
/// ①~③은 사용자가 실제 버튼을 눌러야 다음으로 넘어간다 — 직접 해봐야 첫
/// 루프가 진짜로 만들어진다. 어느 단계에서든 건너뛰면 끝(done).
enum CoachStep { write, reserve, save, returns, done }

class CoachTour {
  CoachTour([this.step = CoachStep.write]);

  CoachStep step;

  bool get isDone => step == CoachStep.done;

  /// 진행 표시용 번호(1~4). 끝났으면 0.
  int get number => switch (step) {
    CoachStep.write => 1,
    CoachStep.reserve => 2,
    CoachStep.save => 3,
    CoachStep.returns => 4,
    CoachStep.done => 0,
  };

  static const total = 4;

  /// 이미 기록이 있는 사용자(업데이트로 들어온 기존 사용자)는 투어 대상이 아니다.
  void existingUser() {
    if (step == CoachStep.write) step = CoachStep.done;
  }

  /// 작성 시트가 열렸다. 스타터 카드로 열었으면 루프가 이미 정해져 있으니
  /// ②를 건너뛰고 바로 ③.
  void composeOpened({required bool loopPreset}) {
    if (step == CoachStep.write) {
      step = loopPreset ? CoachStep.save : CoachStep.reserve;
    }
  }

  /// 작성 시트에서 루프 시간을 골랐다 / 지웠다.
  void loopReserved() {
    if (step == CoachStep.reserve) step = CoachStep.save;
  }

  void loopCleared() {
    if (step == CoachStep.save) step = CoachStep.reserve;
  }

  /// 작성 시트가 닫혔다. 루프 있는 저장 → ④, 루프 없이 저장 → 투어 종료
  /// (기록이 생겼으니 빈 화면의 ①은 더 나올 수 없다), 취소 → 다시 ①.
  void composeClosed({required bool saved, required bool hasLoop}) {
    if (step != CoachStep.reserve && step != CoachStep.save) return;
    if (!saved) {
      step = CoachStep.write;
    } else {
      step = hasLoop ? CoachStep.returns : CoachStep.done;
    }
  }

  /// ④에서 [확인].
  void acknowledge() {
    if (step == CoachStep.returns) step = CoachStep.done;
  }

  /// 아무 단계에서나 [건너뛰기].
  void skip() => step = CoachStep.done;

  // ── 저장(설정 테이블의 문자열 하나) ─────────────────────────

  static const storeKey = 'coach_tour_step';

  /// 카드 [Loop 걸기] 한 번짜리 안내(⑤)를 봤는지.
  static const armHintKey = 'coach_arm_hint_seen';

  String encode() => step.name;

  static CoachTour decode(String? raw) => CoachTour(
    CoachStep.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => CoachStep.write,
    ),
  );
}
