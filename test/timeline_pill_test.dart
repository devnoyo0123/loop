import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/widgets/pill_header_layout.dart';

/// 상태 알약(루프 보기 · 되돌아가기 / 날짜 이동)이 맨 위 카드를 가리지
/// 않는다 — 예전엔 리스트 위에 떠서(Positioned) 원본 카드의 날짜·장소를
/// 덮었다 (2026-11-01 실기기 Fold4). 타임라인은 PillHeaderLayout을 쓴다.
void main() {
  Widget host({required List<Widget> pills, ScrollController? scroll}) => MaterialApp(
    home: Scaffold(
      body: PillHeaderLayout(
        pills: pills,
        child: ListView(
          controller: scroll,
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(key: ValueKey('card$i'), height: 80, child: Text('카드 $i')),
          ],
        ),
      ),
    ),
  );

  const pill = SizedBox(key: ValueKey('pill'), width: 200, height: 36);

  testWidgets('알약 아래에서 첫 카드가 시작한다 — 겹치지 않음', (tester) async {
    await tester.pumpWidget(host(pills: const [pill]));
    final pillRect = tester.getRect(find.byKey(const ValueKey('pill')));
    final cardRect = tester.getRect(find.byKey(const ValueKey('card0')));
    expect(pillRect.bottom, lessThanOrEqualTo(cardRect.top));
    expect(pillRect.overlaps(cardRect), isFalse);
  });

  testWidgets('스크롤해도 알약은 그 자리에 있고, 카드는 알약 밑으로 지나가지 않는다', (tester) async {
    final scroll = ScrollController();
    await tester.pumpWidget(host(pills: const [pill], scroll: scroll));
    final before = tester.getRect(find.byKey(const ValueKey('pill')));
    scroll.jumpTo(400);
    await tester.pump();
    expect(tester.getRect(find.byKey(const ValueKey('pill'))), before);
    final listTop = tester.getRect(find.byType(ListView)).top;
    expect(listTop, greaterThanOrEqualTo(before.bottom));
  });

  testWidgets('알약 두 개(날짜 이동 + 루프 보기)도 차례로 자리를 잡는다', (tester) async {
    await tester.pumpWidget(
      host(
        pills: const [
          SizedBox(key: ValueKey('a'), width: 100, height: 30),
          SizedBox(key: ValueKey('b'), width: 100, height: 30),
        ],
      ),
    );
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    final card = tester.getRect(find.byKey(const ValueKey('card0')));
    expect(a.bottom, lessThanOrEqualTo(b.top));
    expect(b.bottom, lessThanOrEqualTo(card.top));
  });

  testWidgets('알약이 없으면 리스트가 맨 위부터', (tester) async {
    await tester.pumpWidget(host(pills: const []));
    expect(tester.getRect(find.byType(ListView)).top, 0);
  });
}
