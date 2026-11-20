import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/widgets/coach_mark.dart';

void main() {
  Widget host({required CoachSpec? spec, required VoidCallback onTarget, required GlobalKey key}) =>
      MaterialApp(
        home: CoachMarkLayer(
          spec: spec,
          child: Scaffold(
            body: Center(
              child: ElevatedButton(key: key, onPressed: onTarget, child: const Text('target')),
            ),
          ),
        ),
      );

  testWidgets('말풍선(진행·제목·본문)을 띄우고, 비춘 버튼은 그대로 눌린다', (tester) async {
    final key = GlobalKey();
    var tapped = 0;
    var skipped = 0;
    await tester.pumpWidget(host(
      key: key,
      onTarget: () => tapped++,
      spec: CoachSpec(
        target: key,
        number: 1,
        total: 4,
        title: '지금 떠오르는 걸 적어보세요',
        body: '제목도 폴더도 필요 없어요.',
        skipLabel: '건너뛰기',
        onSkip: () => skipped++,
      ),
    ));
    await tester.pumpAndSettle(); // 대상 위치가 잡히면 추적 티커가 멈춰 정착한다

    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('지금 떠오르는 걸 적어보세요'), findsOneWidget);
    expect(find.text('제목도 폴더도 필요 없어요.'), findsOneWidget);

    // 어두운 막은 터치를 막지 않는다 — 실제 버튼을 눌러 다음 단계로 간다.
    await tester.tap(find.text('target'));
    expect(tapped, 1);

    await tester.tap(find.text('건너뛰기'));
    expect(skipped, 1);
  });

  testWidgets('확인 버튼이 있으면 눌러서 넘긴다', (tester) async {
    final key = GlobalKey();
    var acked = 0;
    await tester.pumpWidget(host(
      key: key,
      onTarget: () {},
      spec: CoachSpec(
        target: key,
        title: 't',
        body: 'b',
        skipLabel: 'skip',
        onSkip: () {},
        actionLabel: '확인',
        onAction: () => acked++,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsNothing); // 단발 안내(⑤)는 진행 표시 없음
    await tester.tap(find.text('확인'));
    expect(acked, 1);
  });

  testWidgets('spec이 없으면 아무것도 안 그린다', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(host(key: key, onTarget: () {}, spec: null));
    await tester.pumpAndSettle();
    expect(find.byType(CoachMarkOverlay), findsNothing);
  });
}
