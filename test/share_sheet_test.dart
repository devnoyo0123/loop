import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/screens/share_sheet.dart';

import 'support/fake_nearby.dart';

/// 사슬 공유 시트 — 요약 카운트·토글·버튼이 그려지는지 스모크.
/// (전송 흐름은 share_transfer_test.dart에서 가짜 전송 계층으로 검증)
void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  late Directory tmp;
  late LoopDb db;
  late FakeSharePlatform platform;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('share_sheet_test');
    db = LoopDb(tmp)..open();
    platform = FakeSharePlatform(name: 'Galaxy S25');
    db.insert(
      LogEntry(
        id: 'R',
        content: '물 하루 8잔 마시기',
        createdAt: DateTime(2026, 10, 12, 8, 30),
        originalCreatedAt: DateTime(2026, 10, 12, 8, 30),
      ),
    );
    db.insert(
      LogEntry(
        id: 'C',
        content: '지금 5잔째',
        createdAt: DateTime(2026, 10, 14, 11, 5),
        originalCreatedAt: DateTime(2026, 10, 14, 11, 5),
        parentId: 'R',
        rootId: 'R',
        depth: 1,
        path: 'R/C',
      ),
    );
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    ShareSheet.open(
                      context,
                      db: db,
                      rootId: 'R',
                      platform: platform,
                    ),
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

  testWidgets('사슬 요약과 토글·보내기 버튼이 나란히 있다', (tester) async {
    await pumpSheet(tester);

    expect(find.text('↩ ${l10n.shareChainTitle}'), findsOneWidget);
    expect(find.text('물 하루 8잔 마시기'), findsOneWidget);
    expect(find.text(l10n.shareCountLogs), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 기록 2개
    expect(find.text(l10n.shareStripLocation), findsOneWidget);
    expect(find.text(l10n.shareStripMedia), findsOneWidget);
    expect(find.text(l10n.shareSendNearby), findsOneWidget);
    expect(find.text(l10n.shareExportFile), findsOneWidget);
    // 위치 제외가 기본 ON
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.first.value, isTrue);
    expect(switches.last.value, isFalse);
  });

  testWidgets('표시명을 저장하면 다음 열 때 유지된다', (tester) async {
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '민수');
    await tester.pump();

    expect(db.shareName(), '민수'); // 입력과 동시에 저장(첫 공유 정체성 준비)
    expect(find.text('민수'), findsOneWidget);
  });

  testWidgets('표시명이 없으면 기기 이름이 기본값으로 채워진다', (tester) async {
    await pumpSheet(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Galaxy S25');
    expect(db.shareName(), isNull); // 저장은 보낼 때 — 열기만 해선 안 남는다
  });

  testWidgets('저장된 표시명이 있으면 기기 이름으로 덮지 않는다', (tester) async {
    db.setShareName('민수');
    await pumpSheet(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '민수');
  });
}
