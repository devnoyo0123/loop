import '../l10n/generated/app_localizations.dart';

/// Loop 사용법 — 항목(제목·설명·그림) 목록. 화면(GuideScreen)은 그리기만 한다.
///
/// 그림은 실제 앱 화면을 데모 데이터로 캡처한 것(assets/guide/{8개 언어}/).
/// 8개 언어는 각자의 화면, 목록에 없는 언어는 영어 화면을 쓴다. 다시 찍을 땐
/// docs/guide-screenshots.md 절차대로 — 개인 기록이 담기지 않게 에뮬레이터 +
/// 데모 DB(tool/make_demo_db.dart)로만.
class GuideSection {
  const GuideSection({
    required this.id,
    required this.title,
    required this.body,
    required this.images,
  });

  final String id;
  final String title;
  final String body;

  /// 에셋 경로들 — 보통 1장, 알람 항목은 2장(권한 안내 → 알람 화면).
  final List<String> images;
}

/// 그림 이름(확장자 없음) — 순서가 곧 화면 순서. 테스트가 에셋 존재를 검증한다.
const guideImageNames = <String>[
  '00_timeline',
  '01_write',
  '02_loop',
  '03_repeat',
  '04_flow',
  '05_upcoming',
  '06_rhythm',
  '07_share',
  '08_backup',
  '09_stats',
  '10_alarm_permission',
  '11_alarm',
  '12_pc_menu',
  '12_pc',
];

/// 그림이 있는 언어(8개 전부) — 없는 언어는 영어 그림.
const guideImageLanguages = <String>['ko', 'en', 'ja', 'zh', 'es', 'vi', 'it', 'hi'];

String guideImage(String name, String languageCode) {
  final lang = guideImageLanguages.contains(languageCode) ? languageCode : 'en';
  return 'assets/guide/$lang/$name.webp';
}

List<GuideSection> guideSections(AppLocalizations l10n, String languageCode) {
  String img(String name) => guideImage(name, languageCode);
  return [
    GuideSection(
      id: 'intro',
      title: l10n.guideIntroTitle,
      body: l10n.guideIntroBody,
      images: [img('00_timeline')],
    ),
    GuideSection(
      id: 'write',
      title: l10n.guideWriteTitle,
      body: l10n.guideWriteBody,
      images: [img('01_write')],
    ),
    GuideSection(
      id: 'loop',
      title: l10n.guideLoopTitle,
      body: l10n.guideLoopBody,
      images: [img('02_loop')],
    ),
    GuideSection(
      id: 'repeat',
      title: l10n.guideRepeatTitle,
      body: l10n.guideRepeatBody,
      images: [img('03_repeat')],
    ),
    GuideSection(
      id: 'flow',
      title: l10n.guideFlowTitle,
      body: l10n.guideFlowBody,
      images: [img('04_flow')],
    ),
    GuideSection(
      id: 'upcoming',
      title: l10n.guideUpcomingTitle,
      body: l10n.guideUpcomingBody,
      images: [img('05_upcoming')],
    ),
    GuideSection(
      id: 'rhythm',
      title: l10n.guideRhythmTitle,
      body: l10n.guideRhythmBody,
      images: [img('06_rhythm')],
    ),
    GuideSection(
      id: 'share',
      title: l10n.guideShareTitle,
      body: l10n.guideShareBody,
      images: [img('07_share')],
    ),
    GuideSection(
      id: 'backup',
      title: l10n.guideBackupTitle,
      body: l10n.guideBackupBody,
      images: [img('08_backup')],
    ),
    GuideSection(
      id: 'stats',
      title: l10n.guideStatsTitle,
      body: l10n.guideStatsBody,
      images: [img('09_stats')],
    ),
    GuideSection(
      id: 'alarm',
      title: l10n.guideAlarmTitle,
      body: l10n.guideAlarmBody,
      images: [img('10_alarm_permission'), img('11_alarm')],
    ),
    GuideSection(
      id: 'pc',
      title: l10n.guidePcTitle,
      body: l10n.guidePcBody,
      images: [img('12_pc_menu'), img('12_pc')],
    ),
  ];
}
