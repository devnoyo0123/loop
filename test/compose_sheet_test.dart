import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/screens/compose_sheet.dart';

/// 작성 시트 첨부 행 — 갤러리·촬영 버튼이 나란히 있고, 플러그인이 없는
/// 테스트 환경에서 눌러도 조용히 무시된다(크래시 없음).
void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'), // 테스트 기본 로케일은 en — ko 고정
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => ComposeSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('첨부 행에 갤러리·촬영·루프 버튼이 나란히 있다', (tester) async {
    await pumpSheet(tester);
    expect(find.byTooltip(l10n.attachPhoto), findsOneWidget);
    expect(find.byTooltip(l10n.takePhoto), findsOneWidget);
    expect(find.byTooltip(l10n.reserveAlarm), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
  });

  testWidgets('촬영 버튼을 눌러도 테스트 환경(플러그인 없음)에서 크래시 없이 넘어간다', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byTooltip(l10n.takePhoto));
    // 플러그인 응답이 오지 않는 환경이라 pumpAndSettle은 시간 초과 —
    // 유한 pump로 예외 없이 대기 상태에 들어가는지만 확인한다.
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('로그 남기기'), findsOneWidget); // 시트 유지
  });
}
