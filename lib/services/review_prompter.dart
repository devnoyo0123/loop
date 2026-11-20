import 'package:in_app_review/in_app_review.dart';

/// 앱 안 별점 요청(Google Play In-App Review) — ASO 4번 (2026-11-16).
///
/// "좋은 순간"에만 묻는다: 루프로 돌아온 생각을 이어 써서 사슬이
/// [ReviewPolicy.minChainReturns]회째가 됐을 때. 앱의 핵심 경험(생각이 다시
/// 돌아온다)을 방금 체감한 순간이라 별점이 가장 정직하게 나온다.
///
/// Play는 자체 할당량으로 실제 표시 여부를 정하고(호출해도 안 뜰 수 있음),
/// 결과를 앱에 알려주지 않는다. 그래서 우리는 "물어본 시도"만 기록하고
/// 간격·횟수 상한으로 사용자를 귀찮게 하지 않는다.

/// 별점 창을 띄우는 플랫폼 경계 — 테스트에서는 가짜로 바꾼다.
abstract interface class ReviewApi {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

/// 실제 Google Play In-App Review.
class PlayReviewApi implements ReviewApi {
  const PlayReviewApi();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// "언제 몇 번 물었나"를 저장하는 곳 — 앱에서는 LoopDb 설정 테이블.
abstract interface class ReviewStore {
  String? read(String key);
  void write(String key, String value);
}

/// 물어볼지 판단 — 순수 함수(시계·저장소 없음).
abstract final class ReviewPolicy {
  /// 사슬이 이만큼 돌아왔을 때(“Loop N회째”) 묻는다.
  static const minChainReturns = 2;

  /// 앱을 충분히 써 본 사람에게만 — 기록 수와 쓴 날 수.
  static const minLogs = 10;
  static const minActiveDays = 3;

  /// 한 번 물으면 이만큼은 다시 묻지 않는다.
  static const cooldown = Duration(days: 120);

  /// 평생 최대 시도 횟수.
  static const maxAsks = 3;

  static bool shouldAsk({
    required int chainReturns,
    required int totalLogs,
    required int activeDays,
    required DateTime now,
    DateTime? lastAskedAt,
    int askCount = 0,
  }) {
    if (chainReturns < minChainReturns) return false;
    if (totalLogs < minLogs || activeDays < minActiveDays) return false;
    if (askCount >= maxAsks) return false;
    if (lastAskedAt != null && now.difference(lastAskedAt) < cooldown) {
      return false;
    }
    return true;
  }
}

class ReviewPrompter {
  ReviewPrompter({
    required this.api,
    required this.store,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final ReviewApi api;
  final ReviewStore store;
  final DateTime Function() _now;

  static const lastAskedKey = 'review_last_asked_ms';
  static const askCountKey = 'review_ask_count';

  int get askCount => int.tryParse(store.read(askCountKey) ?? '') ?? 0;

  DateTime? get lastAskedAt {
    final ms = int.tryParse(store.read(lastAskedKey) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 사슬이 [chainReturns]회째가 된 직후 호출한다. 통계(전체 스캔)는
  /// 사슬 조건을 넘었을 때만 계산하도록 콜백으로 받는다.
  /// 실제로 요청을 보냈으면 true.
  Future<bool> maybeAsk({
    required int chainReturns,
    required ({int totalLogs, int activeDays}) Function() usage,
  }) async {
    if (chainReturns < ReviewPolicy.minChainReturns) return false;
    final u = usage();
    final now = _now();
    if (!ReviewPolicy.shouldAsk(
      chainReturns: chainReturns,
      totalLogs: u.totalLogs,
      activeDays: u.activeDays,
      now: now,
      lastAskedAt: lastAskedAt,
      askCount: askCount,
    )) {
      return false;
    }
    try {
      if (!await api.isAvailable()) return false;
      // 시도를 먼저 기록 — 요청 중 앱이 죽어도 다시 졸라대지 않는다.
      store.write(lastAskedKey, now.millisecondsSinceEpoch.toString());
      store.write(askCountKey, (askCount + 1).toString());
      await api.requestReview();
      return true;
    } catch (_) {
      return false; // 별점 창 실패가 기록 저장 흐름을 깨면 안 된다.
    }
  }
}
