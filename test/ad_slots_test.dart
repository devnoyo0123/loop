import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/ad_slots.dart';

void main() {
  group('AdSlots — 8~10장마다 1개, 인접 금지, 맨 위 금지', () {
    test('첫 광고는 최소 8장 이후 — 맨 위 금지', () {
      final s = AdSlots(random: Random(1));
      final idx = s.indicesFor(100);
      expect(idx.first, greaterThanOrEqualTo(8));
      expect(idx.contains(0), isFalse);
    });

    test('간격은 항상 8~10 — 광고 연속 2개가 나올 수 없다', () {
      final s = AdSlots(random: Random(42));
      final idx = s.indicesFor(300);
      expect(idx, isNotEmpty);
      for (final gap in s.gaps) {
        expect(gap, inInclusiveRange(8, 10));
      }
      // 인접 광고 간 카드 수도 같은 범위 — 연속 광고 구조적으로 불가능.
      for (var i = 1; i < idx.length; i++) {
        expect(idx[i] - idx[i - 1], inInclusiveRange(8, 10));
      }
    });

    test('로그가 부족하면 광고 없음', () {
      final s = AdSlots(random: Random(1));
      expect(s.indicesFor(5), isEmpty); // 첫 간격(8+) 미만
      expect(s.indicesFor(0), isEmpty);
    });

    test('페이징으로 로그가 늘어도 이미 정해진 자리는 흔들리지 않는다', () {
      final s = AdSlots(random: Random(7));
      final before = s.indicesFor(30);
      final after = s.indicesFor(100);
      expect(after.take(before.length), equals(before));
      expect(after.length, greaterThan(before.length));
    });

    test('로그 수가 광고 자리 사이면 자리가 생기지 않는다', () {
      final s = AdSlots(random: Random(1));
      final idx = s.indicesFor(100);
      final last = idx.last;
      expect(s.indicesFor(last), hasLength(idx.length - 1));
    });
  });

  group('AdSlots — 한 화면에 광고 최대 1개 (2026-11-12)', () {
    test('화면 높이로 최소 간격을 정한다 — 작은 화면은 기본 8장', () {
      expect(AdSlots.requiredGap(400), 8);
      expect(AdSlots.requiredGap(800), 12); // 800/72 = 11.1 → 12
      expect(AdSlots.requiredGap(1200), 17); // 태블릿 세로
    });

    test('높이를 모르면(무한·0) 기본 간격 — 크래시 없음', () {
      expect(AdSlots.requiredGap(double.infinity), 8);
      expect(AdSlots.requiredGap(0), 8);
    });

    test('글자 크기가 작으면 카드가 작아지니 간격을 늘린다', () {
      final normal = AdSlots(random: Random(1))..configureForViewport(800);
      final small = AdSlots(random: Random(1))
        ..configureForViewport(800, textScale: 0.85);
      expect(small.minGap, greaterThan(normal.minGap));
    });

    test('화면이 바뀔 때만 자리를 다시 뽑는다 — 같은 화면이면 그대로', () {
      final s = AdSlots(random: Random(3))..configureForViewport(800);
      final before = s.indicesFor(100);
      s.configureForViewport(800);
      expect(s.indicesFor(100), equals(before));
      s.configureForViewport(1200); // 폴드 펼침
      expect(s.minGap, AdSlots.requiredGap(1200));
      for (final g in s.gaps) {
        expect(g, inInclusiveRange(s.minGap, s.minGap + AdSlots.gapSpread));
      }
    });

    test('보장: 카드가 모두 최소 높이여도 어떤 스크롤 위치에서든 광고 2개가 함께 보이지 않는다', () {
      for (final viewport in [640.0, 800.0, 915.0, 1200.0]) {
        final s = AdSlots(random: Random(viewport.toInt()))
          ..configureForViewport(viewport);
        const logs = 300;
        final ads = s.indicesFor(logs).toSet();
        // 최악: 모든 로그 카드가 최소 높이. 광고 카드는 140dp.
        final tops = <double>[];
        final isAd = <bool>[];
        var y = 0.0;
        var logIdx = 0;
        while (logIdx < logs) {
          if (ads.contains(logIdx) && (isAd.isEmpty || !isAd.last)) {
            tops.add(y);
            isAd.add(true);
            y += 140;
            continue;
          }
          tops.add(y);
          isAd.add(false);
          y += AdSlots.minLogCardPitch;
          logIdx++;
        }
        final adSpans = [
          for (var i = 0; i < tops.length; i++)
            if (isAd[i]) (tops[i], tops[i] + 140),
        ];
        expect(adSpans.length, greaterThan(1));
        for (var i = 1; i < adSpans.length; i++) {
          final gapBetween = adSpans[i].$1 - adSpans[i - 1].$2;
          // 두 광고 사이 빈 구간이 화면 높이 이상 → 한 화면에 동시에 못 들어온다.
          expect(gapBetween, greaterThanOrEqualTo(viewport),
              reason: 'viewport=$viewport ad#$i');
        }
      }
    });
  });

  group('AdSlots.listPositionsFor — 광고를 끼운 목록 위치 (2026-11-16 버그 회귀)', () {
    test('광고 사이 기록 수 = 간격 그대로 (두 번째 광고부터 1장씩 모자라던 버그)', () {
      final s = AdSlots(random: Random(9))..configureForViewport(800);
      final pos = s.listPositionsFor(400);
      expect(pos.length, greaterThan(3));
      // 목록을 실제로 펼쳐 광고 사이 기록 수를 센다.
      final total = 400 + pos.length;
      final set = pos.toSet();
      final between = <int>[];
      var run = 0;
      var seenAd = false;
      for (var i = 0; i < total; i++) {
        if (set.contains(i)) {
          if (seenAd) between.add(run);
          seenAd = true;
          run = 0;
        } else {
          run++;
        }
      }
      for (var k = 0; k < between.length; k++) {
        expect(between[k], s.gaps[k + 1], reason: 'ad#${k + 1}');
        expect(between[k], greaterThanOrEqualTo(s.minGap));
      }
    });

    test('adsBefore로 되짚은 기록 인덱스가 0..n-1을 빠짐없이 한 번씩', () {
      final s = AdSlots(random: Random(4))..configureForViewport(640);
      const n = 120;
      final pos = s.listPositionsFor(n);
      final set = pos.toSet();
      final seen = <int>[];
      for (var i = 0; i < n + pos.length; i++) {
        if (!set.contains(i)) seen.add(i - AdSlots.adsBefore(pos, i));
      }
      expect(seen, List.generate(n, (i) => i));
    });
  });
}
