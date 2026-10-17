import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @emptyTimeline.
  ///
  /// In ko, this message translates to:
  /// **'아직 로그가 없어.\n+ 로 첫 생각을 남겨봐.'**
  String get emptyTimeline;

  /// No description provided for @emptyAtDate.
  ///
  /// In ko, this message translates to:
  /// **'그때는 로그가 없어.\n위에서 날짜를 바꿔보거나 최신으로 돌아가.'**
  String get emptyAtDate;

  /// No description provided for @jumpToDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜로 이동'**
  String get jumpToDate;

  /// No description provided for @backToLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신으로 돌아가'**
  String get backToLatest;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'내용·장소 검색'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어'**
  String get searchEmpty;

  /// No description provided for @sortRelevance.
  ///
  /// In ko, this message translates to:
  /// **'관련도순'**
  String get sortRelevance;

  /// No description provided for @sortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get sortRecent;

  /// No description provided for @editContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 편집'**
  String get editContent;

  /// No description provided for @changeTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 변경'**
  String get changeTime;

  /// No description provided for @deleteAction.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteAction;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @stop.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get stop;

  /// No description provided for @deleteLogTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그 삭제'**
  String get deleteLogTitle;

  /// No description provided for @deleteLogMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 로그를 삭제할까? 이어쓰인 로그는 그대로 남아.'**
  String get deleteLogMessage;

  /// No description provided for @stopRepeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'Loop 중지'**
  String get stopRepeatTitle;

  /// No description provided for @stopRepeatMessage.
  ///
  /// In ko, this message translates to:
  /// **'{rule} 루프를 멈출까?\n다음 발화부터 취소되고, 이미 만들어진 로그는 남아.'**
  String stopRepeatMessage(String rule);

  /// No description provided for @composeHint.
  ///
  /// In ko, this message translates to:
  /// **'지금 생각…'**
  String get composeHint;

  /// No description provided for @forkOf.
  ///
  /// In ko, this message translates to:
  /// **'↩ {time} 로그에 이어쓰기'**
  String forkOf(String time);

  /// No description provided for @saveLog.
  ///
  /// In ko, this message translates to:
  /// **'로그 남기기'**
  String get saveLog;

  /// No description provided for @attachPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 첨부'**
  String get attachPhoto;

  /// No description provided for @reserveAlarm.
  ///
  /// In ko, this message translates to:
  /// **'알림 예약'**
  String get reserveAlarm;

  /// No description provided for @alarmTitle.
  ///
  /// In ko, this message translates to:
  /// **'⏰ 알림 예약'**
  String get alarmTitle;

  /// No description provided for @tapToChangeTime.
  ///
  /// In ko, this message translates to:
  /// **'탭해서 날짜·시각 바꾸기'**
  String get tapToChangeTime;

  /// No description provided for @in10min.
  ///
  /// In ko, this message translates to:
  /// **'10분 후'**
  String get in10min;

  /// No description provided for @in1hour.
  ///
  /// In ko, this message translates to:
  /// **'1시간 후'**
  String get in1hour;

  /// No description provided for @tomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get tomorrow;

  /// No description provided for @nextWeek.
  ///
  /// In ko, this message translates to:
  /// **'다음 주'**
  String get nextWeek;

  /// No description provided for @in1month.
  ///
  /// In ko, this message translates to:
  /// **'1달 후'**
  String get in1month;

  /// No description provided for @loopCurveHint.
  ///
  /// In ko, this message translates to:
  /// **'망각곡선 {n}번째 복습 · 추천 {interval}'**
  String loopCurveHint(int n, String interval);

  /// No description provided for @custom.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get custom;

  /// No description provided for @notifyAtThisTime.
  ///
  /// In ko, this message translates to:
  /// **'이 시각에 알려줘'**
  String get notifyAtThisTime;

  /// No description provided for @repeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'↩ Loop'**
  String get repeatTitle;

  /// No description provided for @repeatDesc.
  ///
  /// In ko, this message translates to:
  /// **'반복을 걸면 발화마다 이 로그의 이어쓰기가 자동으로 생성돼. 언제든 멈출 수 있어.'**
  String get repeatDesc;

  /// No description provided for @preset10min.
  ///
  /// In ko, this message translates to:
  /// **'10분'**
  String get preset10min;

  /// No description provided for @preset30min.
  ///
  /// In ko, this message translates to:
  /// **'30분'**
  String get preset30min;

  /// No description provided for @preset1hour.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get preset1hour;

  /// No description provided for @preset3hours.
  ///
  /// In ko, this message translates to:
  /// **'3시간'**
  String get preset3hours;

  /// No description provided for @preset6hours.
  ///
  /// In ko, this message translates to:
  /// **'6시간'**
  String get preset6hours;

  /// No description provided for @presetDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get presetDaily;

  /// No description provided for @fireTime.
  ///
  /// In ko, this message translates to:
  /// **'발화 시각'**
  String get fireTime;

  /// No description provided for @unitMinutes.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get unitHours;

  /// No description provided for @nextFire.
  ///
  /// In ko, this message translates to:
  /// **'다음 {time} · 이후 {rule}'**
  String nextFire(String time, String rule);

  /// No description provided for @ruleEveryMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분마다'**
  String ruleEveryMinutes(int n);

  /// No description provided for @ruleEveryHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간마다'**
  String ruleEveryHours(int n);

  /// No description provided for @ruleDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일 {time}'**
  String ruleDaily(String time);

  /// No description provided for @ruleWeekday.
  ///
  /// In ko, this message translates to:
  /// **'평일 {time}'**
  String ruleWeekday(String time);

  /// No description provided for @presetWeekday.
  ///
  /// In ko, this message translates to:
  /// **'평일'**
  String get presetWeekday;

  /// No description provided for @upcomingTitle.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 루프 · 7일'**
  String get upcomingTitle;

  /// No description provided for @upcomingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이번 주엔 예정된 루프가 없어'**
  String get upcomingEmpty;

  /// No description provided for @noContent.
  ///
  /// In ko, this message translates to:
  /// **'(내용 없음)'**
  String get noContent;

  /// No description provided for @continuedFrom.
  ///
  /// In ko, this message translates to:
  /// **'↩ {time} 에서 이어짐'**
  String continuedFrom(String time);

  /// No description provided for @locationRecorded.
  ///
  /// In ko, this message translates to:
  /// **'위치 기록됨'**
  String get locationRecorded;

  /// No description provided for @repeatNth.
  ///
  /// In ko, this message translates to:
  /// **'Loop {n}회째'**
  String repeatNth(int n);

  /// No description provided for @repeatEnded.
  ///
  /// In ko, this message translates to:
  /// **'Loop 종료'**
  String get repeatEnded;

  /// No description provided for @loopAction.
  ///
  /// In ko, this message translates to:
  /// **'↩ Loop'**
  String get loopAction;

  /// No description provided for @loopWriteNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 이어쓰기'**
  String get loopWriteNow;

  /// No description provided for @loopAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 알려줘'**
  String get loopAgain;

  /// No description provided for @loopModeOnce.
  ///
  /// In ko, this message translates to:
  /// **'한 번'**
  String get loopModeOnce;

  /// No description provided for @loopModeRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get loopModeRepeat;

  /// No description provided for @loopNextShort.
  ///
  /// In ko, this message translates to:
  /// **'다음 {time}'**
  String loopNextShort(String time);

  /// No description provided for @loopFireCount.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {n}번 돌아왔어'**
  String loopFireCount(int n);

  /// No description provided for @loopJump.
  ///
  /// In ko, this message translates to:
  /// **'원본으로 이동'**
  String get loopJump;

  /// No description provided for @loopStop.
  ///
  /// In ko, this message translates to:
  /// **'루프 중지'**
  String get loopStop;

  /// No description provided for @loopEndedInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 루프는 종료됐어'**
  String get loopEndedInfo;

  /// No description provided for @loopViewAction.
  ///
  /// In ko, this message translates to:
  /// **'루프 보기'**
  String get loopViewAction;

  /// No description provided for @loopWriteAction.
  ///
  /// In ko, this message translates to:
  /// **'작성하기'**
  String get loopWriteAction;

  /// No description provided for @loopViewBack.
  ///
  /// In ko, this message translates to:
  /// **'되돌아가기'**
  String get loopViewBack;

  /// No description provided for @locationCapture.
  ///
  /// In ko, this message translates to:
  /// **'위치 기록'**
  String get locationCapture;

  /// No description provided for @locationCaptureDesc.
  ///
  /// In ko, this message translates to:
  /// **'로그에 장소·날씨를 자동으로 함께 기록'**
  String get locationCaptureDesc;

  /// No description provided for @loopArm.
  ///
  /// In ko, this message translates to:
  /// **'Loop 걸기'**
  String get loopArm;

  /// No description provided for @emptyWriteHint.
  ///
  /// In ko, this message translates to:
  /// **'비어 있음 · 탭해서 작성'**
  String get emptyWriteHint;

  /// No description provided for @openInYoutube.
  ///
  /// In ko, this message translates to:
  /// **'유튜브에서 열기'**
  String get openInYoutube;

  /// No description provided for @openInBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 열기'**
  String get openInBrowser;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @defaultBrowser.
  ///
  /// In ko, this message translates to:
  /// **'기본 브라우저'**
  String get defaultBrowser;

  /// No description provided for @defaultBrowserDesc.
  ///
  /// In ko, this message translates to:
  /// **'웹 링크를 열 때 이 브라우저로 열려'**
  String get defaultBrowserDesc;

  /// No description provided for @systemDefault.
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본값'**
  String get systemDefault;

  /// No description provided for @browserEmpty.
  ///
  /// In ko, this message translates to:
  /// **'설치된 브라우저가 없어'**
  String get browserEmpty;

  /// No description provided for @exportLogs.
  ///
  /// In ko, this message translates to:
  /// **'전체 내보내기'**
  String get exportLogs;

  /// No description provided for @exportAllDesc.
  ///
  /// In ko, this message translates to:
  /// **'로그·사진·반복까지 .looplog 파일 하나로'**
  String get exportAllDesc;

  /// No description provided for @exporting.
  ///
  /// In ko, this message translates to:
  /// **'내보내는 중…'**
  String get exporting;

  /// No description provided for @exportDone.
  ///
  /// In ko, this message translates to:
  /// **'내보냈어'**
  String get exportDone;

  /// No description provided for @exportCancel.
  ///
  /// In ko, this message translates to:
  /// **'저장을 취소했어'**
  String get exportCancel;

  /// No description provided for @exportFail.
  ///
  /// In ko, this message translates to:
  /// **'파일 저장을 못 했어'**
  String get exportFail;

  /// No description provided for @importLogs.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get importLogs;

  /// No description provided for @importAllDesc.
  ///
  /// In ko, this message translates to:
  /// **'.looplog 파일에서 복원 · 이미 있는 로그는 건너뛰어'**
  String get importAllDesc;

  /// No description provided for @importConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'기존 로그는 그대로 두고 파일의 로그를 더해.\n이미 있는 로그는 건너뛰니까 같은 파일을 다시 가져와도 중복이 생기지 않아.'**
  String get importConfirmMessage;

  /// No description provided for @importing.
  ///
  /// In ko, this message translates to:
  /// **'가져오는 중…'**
  String get importing;

  /// No description provided for @importDone.
  ///
  /// In ko, this message translates to:
  /// **'로그 {logs}개 · 반복 {repeats}개를 가져왔어'**
  String importDone(int logs, int repeats);

  /// No description provided for @importCancel.
  ///
  /// In ko, this message translates to:
  /// **'가져오기를 취소했어'**
  String get importCancel;

  /// No description provided for @importEmpty.
  ///
  /// In ko, this message translates to:
  /// **'가져올 내용이 없어'**
  String get importEmpty;

  /// No description provided for @importFail.
  ///
  /// In ko, this message translates to:
  /// **'.looplog 파일을 읽지 못했어'**
  String get importFail;

  /// No description provided for @howNotify.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 알려줄까?'**
  String get howNotify;

  /// No description provided for @modeNotif.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get modeNotif;

  /// No description provided for @modeNotifDesc.
  ///
  /// In ko, this message translates to:
  /// **'한 번 알려주고 끝. 기본 — 조용한 상기'**
  String get modeNotifDesc;

  /// No description provided for @modeAlarm.
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get modeAlarm;

  /// No description provided for @modeAlarmDesc.
  ///
  /// In ko, this message translates to:
  /// **'꺼야 멈춤, 무음에도. 꼭 지켜야 할 루프용'**
  String get modeAlarmDesc;

  /// No description provided for @snoozeAction.
  ///
  /// In ko, this message translates to:
  /// **'10분 후 다시'**
  String get snoozeAction;

  /// No description provided for @notifAlarmChannelName.
  ///
  /// In ko, this message translates to:
  /// **'루프 알람'**
  String get notifAlarmChannelName;

  /// No description provided for @testFire.
  ///
  /// In ko, this message translates to:
  /// **'발화 체험'**
  String get testFire;

  /// No description provided for @testFireDesc.
  ///
  /// In ko, this message translates to:
  /// **'5초 뒤 알림 · 20초 뒤 알람이 울려요'**
  String get testFireDesc;

  /// No description provided for @testFireSoon.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 알림(5초)·알람(20초)이 울려'**
  String get testFireSoon;

  /// No description provided for @detailOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본 기록'**
  String get detailOriginal;

  /// No description provided for @detailPlace.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get detailPlace;

  /// No description provided for @detailWeather.
  ///
  /// In ko, this message translates to:
  /// **'날씨'**
  String get detailWeather;

  /// No description provided for @detailPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get detailPhotos;

  /// No description provided for @photoCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}장'**
  String photoCount(int n);

  /// No description provided for @detailNoContext.
  ///
  /// In ko, this message translates to:
  /// **'위치·날씨·사진 정보 없음'**
  String get detailNoContext;

  /// No description provided for @detailRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get detailRecord;

  /// No description provided for @unknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get unknown;

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @wmoClear.
  ///
  /// In ko, this message translates to:
  /// **'맑음'**
  String get wmoClear;

  /// No description provided for @wmoPartly.
  ///
  /// In ko, this message translates to:
  /// **'구름 조금'**
  String get wmoPartly;

  /// No description provided for @wmoCloudy.
  ///
  /// In ko, this message translates to:
  /// **'흐림'**
  String get wmoCloudy;

  /// No description provided for @wmoFog.
  ///
  /// In ko, this message translates to:
  /// **'안개'**
  String get wmoFog;

  /// No description provided for @wmoDrizzle.
  ///
  /// In ko, this message translates to:
  /// **'이슬비'**
  String get wmoDrizzle;

  /// No description provided for @wmoRain.
  ///
  /// In ko, this message translates to:
  /// **'비'**
  String get wmoRain;

  /// No description provided for @wmoSnow.
  ///
  /// In ko, this message translates to:
  /// **'눈'**
  String get wmoSnow;

  /// No description provided for @wmoThunder.
  ///
  /// In ko, this message translates to:
  /// **'뇌우'**
  String get wmoThunder;

  /// No description provided for @wmoUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get wmoUnknown;

  /// No description provided for @notifRepeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'↩ Loop'**
  String get notifRepeatTitle;

  /// No description provided for @notifFallbackBody.
  ///
  /// In ko, this message translates to:
  /// **'루프 돌아올 시간'**
  String get notifFallbackBody;

  /// No description provided for @notifConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get notifConfirm;

  /// No description provided for @notifChannelName.
  ///
  /// In ko, this message translates to:
  /// **'루프'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'돌아온 루프를 알려준다'**
  String get notifChannelDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'ja',
    'ko',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
