import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/l10n/generated/app_localizations.dart';
import 'package:loop/screens/guide_screen.dart';
import 'package:loop/screens/settings_sheet.dart';
import 'package:loop/services/image_store.dart';
import 'package:loop/services/nearby_share.dart';
import 'package:loop/services/video_store.dart';
import 'package:loop/utils/coach_tour.dart';
import 'package:loop/utils/guide_content.dart';

import 'support/fake_nearby.dart';

/// Loop 사용법 — 그림 안내 (2026-11-01 사용자 요청: 글만 말고 그림으로).
void main() {
  group('guide_content', () {
    test('모든 언어 — 항목마다 제목·설명이 있고 그림이 1장 이상', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        final sections = guideSections(l10n, locale.languageCode);
        expect(sections, hasLength(12), reason: '$locale');
        for (final s in sections) {
          expect(s.title.trim(), isNotEmpty, reason: '$locale ${s.id}');
          expect(s.body.trim(), isNotEmpty, reason: '$locale ${s.id}');
          expect(s.images, isNotEmpty, reason: '$locale ${s.id}');
        }
        expect(sections.map((s) => s.id).toSet(), hasLength(sections.length));
      }
    });

    test('그림 파일이 한국어·영어 세트 모두 실제로 있다', () {
      for (final lang in guideImageLanguages) {
        for (final name in guideImageNames) {
          final path = guideImage(name, lang);
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }
    });

    test('항목이 쓰는 그림은 모두 목록에 있는 그림', () {
      final l10n = lookupAppLocalizations(const Locale('ko'));
      final used = guideSections(l10n, 'ko').expand((s) => s.images).toSet();
      final known = guideImageNames.map((n) => guideImage(n, 'ko')).toSet();
      expect(used.difference(known), isEmpty);
      expect(known.difference(used), isEmpty, reason: '쓰이지 않는 그림이 번들에 있다');
    });

    test('한국어는 한국어 그림, 그 밖의 언어는 영어 그림', () {
      expect(guideImage('01_write', 'ko'), 'assets/guide/ko/01_write.webp');
      expect(guideImage('01_write', 'en'), 'assets/guide/en/01_write.webp');
      // 8개 언어 전부 네이티브 그림 세트가 있다 (14개국 출시)
      for (final lang in ['ja', 'zh', 'es', 'vi', 'hi', 'it']) {
        expect(guideImage('01_write', lang), 'assets/guide/$lang/01_write.webp');
      }
      // 목록에 없는 언어는 영어로 폴백
      expect(guideImage('01_write', 'fr'), 'assets/guide/en/01_write.webp');
    });
  });

  group('GuideScreen', () {
    Widget app(Widget home, {Locale locale = const Locale('ko')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

    testWidgets('제목·첫 항목·그림이 보이고, 끝까지 스크롤된다', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ko'));
      await tester.pumpWidget(app(const GuideScreen()));
      await tester.pumpAndSettle();
      expect(find.text(l10n.guideTitle), findsOneWidget);
      expect(find.text(l10n.guideIntroTitle), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('guide-alarm')),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.guideAlarmTitle), findsOneWidget);
      // 알람 항목은 그림 2장(권한 안내 → 알람 화면)
      final alarmImages = find.descendant(
        of: find.byKey(const ValueKey('guide-alarm')),
        matching: find.byType(Image),
      );
      expect(alarmImages, findsNWidgets(2));
    });

    testWidgets('그림을 탭하면 크게 보고, 다시 탭하면 닫힌다', (tester) async {
      await tester.pumpWidget(app(const GuideScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('일본어 화면 — 일본어 글 + 일본어 그림', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ja'));
      await tester.pumpWidget(app(const GuideScreen(), locale: const Locale('ja')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.guideIntroTitle), findsOneWidget);
      final img = tester.widget<Image>(find.byType(Image).first);
      expect((img.image as AssetImage).assetName, 'assets/guide/ja/00_timeline.webp');
    });

    testWidgets('설정 › 앱 정보 › Loop 사용법으로 열린다', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ko'));
      final tmp = Directory.systemTemp.createTempSync('guide_settings_test');
      final db = LoopDb(tmp)..open();
      addTearDown(() {
        db.close();
        tmp.deleteSync(recursive: true);
      });
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: SettingsSheet(
                db: db,
                videos: VideoStore(tmp),
                images: ImageStore(tmp),
                receiver: ShareReceiver(
                  transport: FakeTransport(),
                  platform: FakeSharePlatform(),
                ),
                shareDir: () async => tmp,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final row = find.byKey(const ValueKey('guide-row'));
      await tester.ensureVisible(row);
      expect(find.text(l10n.settingsAppInfo), findsOneWidget);
      expect(find.text(l10n.guideOpen), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(GuideScreen), findsOneWidget);
    });

    testWidgets('설정 › 사용법 다시 보기 — 투어를 ①로 되감고 ⑤ 안내도 다시', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ko'));
      final tmp = Directory.systemTemp.createTempSync('tour_replay_test');
      final db = LoopDb(tmp)..open();
      addTearDown(() {
        db.close();
        tmp.deleteSync(recursive: true);
      });
      db.setSetting(CoachTour.storeKey, CoachStep.done.name);
      db.setSetting(CoachTour.armHintKey, '1');
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: SettingsSheet(
                db: db,
                videos: VideoStore(tmp),
                images: ImageStore(tmp),
                receiver: ShareReceiver(
                  transport: FakeTransport(),
                  platform: FakeSharePlatform(),
                ),
                shareDir: () async => tmp,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final row = find.byKey(const ValueKey('tour-replay-row'));
      await tester.ensureVisible(row);
      expect(find.text(l10n.coachReplay), findsOneWidget);
      await tester.tap(row);
      await tester.pump();
      expect(CoachTour.decode(db.getSetting(CoachTour.storeKey)).step, CoachStep.write);
      expect(db.getSetting(CoachTour.armHintKey), isNull);
    });
  });
}
