import 'dart:math';

/// 타임라인 광고 슬롯 배치기. (2026-10-18 사용자 결정, 2026-11-12 보강)
///
/// 규칙:
/// - 로그 카드 [minGap]~[maxGap]장마다 광고 1개 — 간격은 매번 랜덤
/// - **한 화면에 광고는 많아야 1개** (2026-11-12 사용자 결정) — 광고 사이
///   카드들의 최소 높이 합이 화면 높이 이상이 되도록 [minGap]을 화면 높이에서
///   정한다([configureForViewport]). 카드 수만으로는 한 줄짜리 기록이 몰리거나
///   폴드·태블릿처럼 화면이 클 때 두 광고가 함께 보일 수 있었다.
/// - 간격이 8 이상이라 광고 연속 2개가 나올 수 없다 (구조적 보장)
/// - 맨 위(첫 카드 앞)에는 광고가 오지 않는다 — 첫 광고도 [minGap]장 이후
///
/// 간격 목록([gaps])을 상태로 들고 있어서, 페이징으로 로그가 늘어도
/// 이미 정해진 위치는 흔들리지 않는다. 화면 크기가 바뀌어 최소 간격이
/// 달라질 때만(폴드 펼침·회전) 다시 뽑는다.
class AdSlots {
  AdSlots({Random? random, this.minGap = baseMinGap, int? maxGap})
    : maxGap = maxGap ?? minGap + gapSpread,
      _random = random ?? Random();

  /// 화면이 작아도 지키는 최소 간격 (2026-10-18 결정값).
  static const baseMinGap = 8;

  /// 간격 랜덤 폭 — [minGap]~[minGap]+2.
  static const gapSpread = 2;

  /// 로그 카드 한 장이 차지하는 최소 세로 공간(dp, 위아래 여백 포함).
  /// 위젯 테스트 실측 78dp(한 줄·메타 없음, 2026-11-12) — 폰트 차이를 감안해
  /// 여유를 두고 낮춰 잡는다. 실제 카드가 이보다 크면 광고는 더 드물어질 뿐
  /// "한 화면 1개" 보장은 깨지지 않는다. (test/ad_slots_test.dart가 실측과 대조)
  static const minLogCardPitch = 72.0;

  final Random _random;
  int minGap;
  int maxGap;

  /// 광고 사이의 로그 카드 수 — 필요할 때마다 랜덤으로 늘어난다.
  final List<int> gaps = [];

  /// 화면(리스트 영역) 높이 [viewportHeight]에서 두 광고가 동시에 보이지
  /// 않으려면 광고 사이에 필요한 최소 카드 수.
  ///
  /// 두 광고가 (일부라도) 함께 보이려면 그 사이 카드들의 높이 합이 화면
  /// 높이보다 작아야 한다. 카드 한 장은 최소 [cardPitch]이므로
  /// `gap * cardPitch >= viewportHeight`면 불가능하다.
  static int requiredGap(double viewportHeight, {double cardPitch = minLogCardPitch}) {
    if (!viewportHeight.isFinite || viewportHeight <= 0 || cardPitch <= 0) {
      return baseMinGap;
    }
    return max(baseMinGap, (viewportHeight / cardPitch).ceil());
  }

  /// 화면 높이에 맞춰 최소 간격을 정한다. 바뀌면 자리를 다시 뽑는다.
  /// [textScale]이 1보다 작으면 카드가 작아지므로 그만큼 간격을 늘린다.
  void configureForViewport(double viewportHeight, {double textScale = 1.0}) {
    final pitch = minLogCardPitch * min(1.0, textScale);
    final need = requiredGap(viewportHeight, cardPitch: pitch);
    if (need == minGap) return;
    minGap = need;
    maxGap = need + gapSpread;
    gaps.clear();
  }

  /// [logCount]개의 로그 카드가 있을 때 광고가 들어갈 인덱스들.
  /// 반환값은 로그 리스트에 껴넣을 "광고 앞 카드 수" (0은 없음 — 맨 위 금지).
  List<int> indicesFor(int logCount) {
    if (logCount < minGap) return const [];
    _grow(logCount);
    final result = <int>[];
    var pos = 0;
    for (final gap in gaps) {
      pos += gap;
      if (pos >= logCount) break;
      result.add(pos);
    }
    return result;
  }

  /// [indicesFor]를 "광고까지 포함한 목록"의 위치로 바꾼 것 — ListView에
  /// 광고를 끼워 넣을 때는 이걸 쓴다. k번째 광고 앞에는 이미 광고 k개가
  /// 있으므로 +k. (2026-11-16: 로그 수 기준 값을 그대로 목록 위치로 써서
  /// 두 번째 광고부터 사이 카드가 1장씩 모자랐다 — 한 화면 1개 보장에 구멍)
  List<int> listPositionsFor(int logCount) {
    final idx = indicesFor(logCount);
    return [for (var k = 0; k < idx.length; k++) idx[k] + k];
  }

  /// 목록 위치 [i] 앞에 있는 광고 수 — 로그 인덱스 = i - 이 값.
  static int adsBefore(List<int> listPositions, int i) =>
      listPositions.where((p) => p < i).length;

  void _grow(int logCount) {
    var covered = gaps.fold<int>(0, (a, b) => a + b);
    while (covered < logCount) {
      final gap = minGap + _random.nextInt(maxGap - minGap + 1);
      gaps.add(gap);
      covered += gap;
    }
  }
}
