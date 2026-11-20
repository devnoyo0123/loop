import 'package:flutter_test/flutter_test.dart';

import 'package:loop/services/review_prompter.dart';

class _FakeApi implements ReviewApi {
  _FakeApi({this.available = true, this.throwOnRequest = false});
  bool available;
  bool throwOnRequest;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requests++;
    if (throwOnRequest) throw Exception('play services down');
  }
}

class _MapStore implements ReviewStore {
  final m = <String, String>{};
  @override
  String? read(String key) => m[key];
  @override
  void write(String key, String value) => m[key] = value;
}

void main() {
  final now = DateTime(2026, 11, 16, 21);
  ({int totalLogs, int activeDays}) seasoned() => (totalLogs: 40, activeDays: 9);

  group('ReviewPolicy — 좋은 순간에만, 너무 자주 묻지 않기', () {
    test('사슬 2회째 + 충분히 쓴 사용자 → 묻는다', () {
      expect(
        ReviewPolicy.shouldAsk(chainReturns: 2, totalLogs: 10, activeDays: 3, now: now),
        isTrue,
      );
    });

    test('사슬 1회째(아직 돌아온 경험이 얕음) → 안 묻는다', () {
      expect(
        ReviewPolicy.shouldAsk(chainReturns: 1, totalLogs: 99, activeDays: 30, now: now),
        isFalse,
      );
    });

    test('갓 설치한 사용자(기록·쓴 날 부족) → 안 묻는다', () {
      expect(ReviewPolicy.shouldAsk(chainReturns: 3, totalLogs: 9, activeDays: 5, now: now), isFalse);
      expect(ReviewPolicy.shouldAsk(chainReturns: 3, totalLogs: 50, activeDays: 2, now: now), isFalse);
    });

    test('물어본 지 120일 안 → 안 묻는다, 지나면 다시', () {
      final asked = now.subtract(const Duration(days: 119));
      expect(
        ReviewPolicy.shouldAsk(chainReturns: 2, totalLogs: 40, activeDays: 9, now: now, lastAskedAt: asked, askCount: 1),
        isFalse,
      );
      expect(
        ReviewPolicy.shouldAsk(chainReturns: 2, totalLogs: 40, activeDays: 9, now: now,
            lastAskedAt: now.subtract(const Duration(days: 121)), askCount: 1),
        isTrue,
      );
    });

    test('평생 3번까지만', () {
      expect(
        ReviewPolicy.shouldAsk(chainReturns: 5, totalLogs: 400, activeDays: 90, now: now, askCount: 3),
        isFalse,
      );
    });
  });

  group('ReviewPrompter', () {
    test('조건 충족 → 요청하고 시도를 기록', () async {
      final api = _FakeApi(); final store = _MapStore();
      final p = ReviewPrompter(api: api, store: store, clock: () => now);
      expect(await p.maybeAsk(chainReturns: 2, usage: seasoned), isTrue);
      expect(api.requests, 1);
      expect(p.askCount, 1);
      expect(p.lastAskedAt, now);
    });

    test('바로 또 이어 써도 쿨다운 동안은 다시 안 묻는다', () async {
      final api = _FakeApi(); final store = _MapStore();
      var t = now;
      final p = ReviewPrompter(api: api, store: store, clock: () => t);
      await p.maybeAsk(chainReturns: 2, usage: seasoned);
      t = now.add(const Duration(days: 3));
      expect(await p.maybeAsk(chainReturns: 3, usage: seasoned), isFalse);
      expect(api.requests, 1);
    });

    test('사슬 조건 미달이면 통계(전체 스캔)를 계산하지 않는다', () async {
      var scanned = false;
      final p = ReviewPrompter(api: _FakeApi(), store: _MapStore(), clock: () => now);
      await p.maybeAsk(chainReturns: 1, usage: () { scanned = true; return seasoned(); });
      expect(scanned, isFalse);
    });

    test('Play 리뷰를 쓸 수 없는 기기 → 요청도 기록도 안 함', () async {
      final api = _FakeApi(available: false); final store = _MapStore();
      final p = ReviewPrompter(api: api, store: store, clock: () => now);
      expect(await p.maybeAsk(chainReturns: 2, usage: seasoned), isFalse);
      expect(api.requests, 0);
      expect(p.askCount, 0);
    });

    test('요청이 실패해도 예외를 밖으로 던지지 않는다(기록 저장 흐름 보호)', () async {
      final api = _FakeApi(throwOnRequest: true);
      final p = ReviewPrompter(api: api, store: _MapStore(), clock: () => now);
      expect(await p.maybeAsk(chainReturns: 2, usage: seasoned), isFalse);
      expect(p.askCount, 1); // 시도는 기록 — 다시 졸라대지 않는다
    });
  });
}
