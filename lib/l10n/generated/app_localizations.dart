import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
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
    Locale('hi'),
    Locale('it'),
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

  /// No description provided for @pastTimeHint.
  ///
  /// In ko, this message translates to:
  /// **'이미 지난 시각이에요 — 다가올 시각으로 다시 골라주세요'**
  String get pastTimeHint;

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

  /// No description provided for @recommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get recommended;

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

  /// No description provided for @presetMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매달'**
  String get presetMonthly;

  /// No description provided for @presetYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년'**
  String get presetYearly;

  /// No description provided for @presetLadder.
  ///
  /// In ko, this message translates to:
  /// **'사다리'**
  String get presetLadder;

  /// No description provided for @ruleLadder.
  ///
  /// In ko, this message translates to:
  /// **'망각곡선 사다리'**
  String get ruleLadder;

  /// No description provided for @curveSteps.
  ///
  /// In ko, this message translates to:
  /// **'10분 → 1시간 → 오늘 저녁 → 내일 → 1주 → 1개월 · 총 6회'**
  String get curveSteps;

  /// No description provided for @fireDate.
  ///
  /// In ko, this message translates to:
  /// **'발화일'**
  String get fireDate;

  /// No description provided for @unitMonths.
  ///
  /// In ko, this message translates to:
  /// **'개월'**
  String get unitMonths;

  /// No description provided for @unitYears.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get unitYears;

  /// No description provided for @ruleMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매달 {day}일 {time}'**
  String ruleMonthly(int day, String time);

  /// No description provided for @ruleEveryMonths.
  ///
  /// In ko, this message translates to:
  /// **'{n}개월마다 {day}일 {time}'**
  String ruleEveryMonths(int n, int day, String time);

  /// No description provided for @ruleYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년 {date} {time}'**
  String ruleYearly(String date, String time);

  /// No description provided for @ruleEveryYears.
  ///
  /// In ko, this message translates to:
  /// **'{n}년마다 {date} {time}'**
  String ruleEveryYears(int n, String date, String time);

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

  /// No description provided for @mineOnlyTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 루프만 보기'**
  String get mineOnlyTitle;

  /// No description provided for @mineOnlyBack.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get mineOnlyBack;

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

  /// No description provided for @testNotifTitle.
  ///
  /// In ko, this message translates to:
  /// **'발화 체험 · 알림'**
  String get testNotifTitle;

  /// No description provided for @overlayPermTitle.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 위에 알람 표시'**
  String get overlayPermTitle;

  /// No description provided for @overlayPermBody.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱을 쓰는 중에도 알람이 전체 화면으로 울리려면 \"다른 앱 위에 그리기\" 권한이 필요해요. 다음 화면에서 허용해 주세요.'**
  String get overlayPermBody;

  /// No description provided for @overlayPermOpen.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get overlayPermOpen;

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

  /// No description provided for @fullScreenHint.
  ///
  /// In ko, this message translates to:
  /// **'알람이 잠금화면 전체로 뜨려면 \'알람 및 리마인더\' 허용이 필요해.'**
  String get fullScreenHint;

  /// No description provided for @openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettings;

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

  /// No description provided for @statsTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 흐름'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'기록이 쌓이면 흐름이 보여요.\n+를 눌러 첫 생각을 남겨보세요.'**
  String get statsEmpty;

  /// No description provided for @statsReturnsLine.
  ///
  /// In ko, this message translates to:
  /// **'생각이 {n}번 다시 돌아왔어요'**
  String statsReturnsLine(int n);

  /// No description provided for @statsReturnsZero.
  ///
  /// In ko, this message translates to:
  /// **'루프를 걸면 생각이 다시 돌아와요'**
  String get statsReturnsZero;

  /// No description provided for @statsTotalLogs.
  ///
  /// In ko, this message translates to:
  /// **'쓴 기록'**
  String get statsTotalLogs;

  /// No description provided for @statsActiveDays.
  ///
  /// In ko, this message translates to:
  /// **'기록한 날'**
  String get statsActiveDays;

  /// No description provided for @statsStreakNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 연속'**
  String get statsStreakNow;

  /// No description provided for @statsStreakBest.
  ///
  /// In ko, this message translates to:
  /// **'최장 연속'**
  String get statsStreakBest;

  /// No description provided for @statsDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String statsDays(int n);

  /// No description provided for @statsHeatmapCaption.
  ///
  /// In ko, this message translates to:
  /// **'최근 15주'**
  String get statsHeatmapCaption;

  /// No description provided for @statsHeatmapLess.
  ///
  /// In ko, this message translates to:
  /// **'적게'**
  String get statsHeatmapLess;

  /// No description provided for @statsHeatmapMore.
  ///
  /// In ko, this message translates to:
  /// **'많이'**
  String get statsHeatmapMore;

  /// No description provided for @statsTopChains.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 이어진 사슬'**
  String get statsTopChains;

  /// No description provided for @statsChainLinkings.
  ///
  /// In ko, this message translates to:
  /// **'{n}번 이어짐'**
  String statsChainLinkings(int n);

  /// No description provided for @starterQuickTitle.
  ///
  /// In ko, this message translates to:
  /// **'10분 루프'**
  String get starterQuickTitle;

  /// No description provided for @starterQuickDesc.
  ///
  /// In ko, this message translates to:
  /// **'지금 쓰면 10분 뒤 다시 돌아와요'**
  String get starterQuickDesc;

  /// No description provided for @starterDailyTitle.
  ///
  /// In ko, this message translates to:
  /// **'매일 밤 한 줄'**
  String get starterDailyTitle;

  /// No description provided for @starterDailyDesc.
  ///
  /// In ko, this message translates to:
  /// **'매일 밤 9시에 오늘이 돌아와요'**
  String get starterDailyDesc;

  /// No description provided for @starterWeekTitle.
  ///
  /// In ko, this message translates to:
  /// **'일주일 루프'**
  String get starterWeekTitle;

  /// No description provided for @starterWeekDesc.
  ///
  /// In ko, this message translates to:
  /// **'지금 쓰고 일주일 뒤에 돌아봐요'**
  String get starterWeekDesc;

  /// No description provided for @starterInMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 뒤'**
  String starterInMinutes(int n);

  /// No description provided for @starterEveryNight.
  ///
  /// In ko, this message translates to:
  /// **'매일 밤 {time}'**
  String starterEveryNight(String time);

  /// No description provided for @starterComposeBanner.
  ///
  /// In ko, this message translates to:
  /// **'↩ {when} 다시 돌아와요'**
  String starterComposeBanner(String when);

  /// No description provided for @onThisDayTitle.
  ///
  /// In ko, this message translates to:
  /// **'그때의 나'**
  String get onThisDayTitle;

  /// No description provided for @onThisDayWeekAgo.
  ///
  /// In ko, this message translates to:
  /// **'1주 전 오늘'**
  String get onThisDayWeekAgo;

  /// No description provided for @onThisDayMonthAgo.
  ///
  /// In ko, this message translates to:
  /// **'1개월 전 오늘'**
  String get onThisDayMonthAgo;

  /// No description provided for @onThisDayYearAgo.
  ///
  /// In ko, this message translates to:
  /// **'1년 전 오늘'**
  String get onThisDayYearAgo;

  /// No description provided for @onThisDayChannelName.
  ///
  /// In ko, this message translates to:
  /// **'그때의 나'**
  String get onThisDayChannelName;

  /// No description provided for @onThisDayChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'과거의 기록을 아침마다 다시 들려줘요'**
  String get onThisDayChannelDesc;

  /// No description provided for @onThisDaySetting.
  ///
  /// In ko, this message translates to:
  /// **'그때의 나 아침 알림'**
  String get onThisDaySetting;

  /// No description provided for @onThisDaySettingDesc.
  ///
  /// In ko, this message translates to:
  /// **'1주·1개월·1년 전 오늘의 기록을 아침 9시에 들려줘요'**
  String get onThisDaySettingDesc;

  /// No description provided for @shareStats.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get shareStats;

  /// No description provided for @shareCardTagline.
  ///
  /// In ko, this message translates to:
  /// **'흘러간 생각이 다시 돌아오는 기록'**
  String get shareCardTagline;

  /// No description provided for @shareFail.
  ///
  /// In ko, this message translates to:
  /// **'공유 카드를 만들지 못했어요'**
  String get shareFail;

  /// No description provided for @loopAttachHeadLabel.
  ///
  /// In ko, this message translates to:
  /// **'↩ 사슬의 마지막 기록에서 이어짐'**
  String get loopAttachHeadLabel;

  /// No description provided for @loopAttachHereLabel.
  ///
  /// In ko, this message translates to:
  /// **'↩ 이 기록에서 분기됨'**
  String get loopAttachHereLabel;

  /// No description provided for @loopAttachHereAction.
  ///
  /// In ko, this message translates to:
  /// **'여기서부터'**
  String get loopAttachHereAction;

  /// No description provided for @loopAttachHeadAction.
  ///
  /// In ko, this message translates to:
  /// **'사슬 끝에서'**
  String get loopAttachHeadAction;

  /// No description provided for @todayEvening.
  ///
  /// In ko, this message translates to:
  /// **'오늘 저녁'**
  String get todayEvening;

  /// No description provided for @dayEndSetting.
  ///
  /// In ko, this message translates to:
  /// **'하루 마무리 시각'**
  String get dayEndSetting;

  /// No description provided for @dayEndSettingDesc.
  ///
  /// In ko, this message translates to:
  /// **'\"오늘 저녁\" 칩과 매일 밤 루프가 이 시각을 써요'**
  String get dayEndSettingDesc;

  /// No description provided for @takePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 촬영'**
  String get takePhoto;

  /// No description provided for @takeVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상 촬영'**
  String get takeVideo;

  /// No description provided for @videoAttached.
  ///
  /// In ko, this message translates to:
  /// **'동영상 첨부됨'**
  String get videoAttached;

  /// No description provided for @videoOpenRow.
  ///
  /// In ko, this message translates to:
  /// **'동영상 · 탭해서 재생'**
  String get videoOpenRow;

  /// No description provided for @videoPlayFail.
  ///
  /// In ko, this message translates to:
  /// **'동영상을 재생할 앱을 찾을 수 없어요'**
  String get videoPlayFail;

  /// No description provided for @videoTooLong.
  ///
  /// In ko, this message translates to:
  /// **'동영상은 1분까지만 첨부할 수 있어요'**
  String get videoTooLong;

  /// No description provided for @shareChainAction.
  ///
  /// In ko, this message translates to:
  /// **'Loop 공유'**
  String get shareChainAction;

  /// No description provided for @shareChainTitle.
  ///
  /// In ko, this message translates to:
  /// **'Loop 공유'**
  String get shareChainTitle;

  /// No description provided for @shareCountLogs.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get shareCountLogs;

  /// No description provided for @shareCountPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get shareCountPhotos;

  /// No description provided for @shareCountVideos.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get shareCountVideos;

  /// No description provided for @shareCountRepeats.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get shareCountRepeats;

  /// No description provided for @shareNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'표시명'**
  String get shareNameLabel;

  /// No description provided for @shareNameHint.
  ///
  /// In ko, this message translates to:
  /// **'상대에게 보이는 이름이에요'**
  String get shareNameHint;

  /// No description provided for @shareStripLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치 정보 빼고 보내기'**
  String get shareStripLocation;

  /// No description provided for @shareStripLocationDesc.
  ///
  /// In ko, this message translates to:
  /// **'기록에 남은 장소·좌표는 빠져요'**
  String get shareStripLocationDesc;

  /// No description provided for @shareStripMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진·동영상 빼고 보내기'**
  String get shareStripMedia;

  /// No description provided for @shareStripMediaDesc.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 기록만 가요'**
  String get shareStripMediaDesc;

  /// No description provided for @shareSendNearby.
  ///
  /// In ko, this message translates to:
  /// **'가까운 기기로 보내기'**
  String get shareSendNearby;

  /// No description provided for @shareExportFile.
  ///
  /// In ko, this message translates to:
  /// **'파일로 내보내기 (.looplog)'**
  String get shareExportFile;

  /// No description provided for @shareSearching.
  ///
  /// In ko, this message translates to:
  /// **'옆 기기를 찾고 있어요…'**
  String get shareSearching;

  /// No description provided for @shareDeviceConnected.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 연결됨'**
  String shareDeviceConnected(String name);

  /// No description provided for @shareSending.
  ///
  /// In ko, this message translates to:
  /// **'전송 중'**
  String get shareSending;

  /// No description provided for @shareHintOffline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷·서버를 전혀 거치지 않아요. 보통 몇십 초 안에 끝나요.'**
  String get shareHintOffline;

  /// No description provided for @shareSent.
  ///
  /// In ko, this message translates to:
  /// **'보냈어요'**
  String get shareSent;

  /// No description provided for @shareSendFail.
  ///
  /// In ko, this message translates to:
  /// **'전송에 실패했어요'**
  String get shareSendFail;

  /// No description provided for @sharePermTitle.
  ///
  /// In ko, this message translates to:
  /// **'가까운 기기 권한'**
  String get sharePermTitle;

  /// No description provided for @sharePermBody.
  ///
  /// In ko, this message translates to:
  /// **'옆 기기를 찾으려면 위치·근거리 기기 권한이 필요해요. 데이터는 기기끼리 직접 주고받고 어디에도 남지 않아요.'**
  String get sharePermBody;

  /// No description provided for @receiveFrom.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 보냈어요'**
  String receiveFrom(String name);

  /// No description provided for @receiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'사슬 가져오기'**
  String get receiveTitle;

  /// No description provided for @receiveBadgeNoLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치 정보 없이 전송됨'**
  String get receiveBadgeNoLocation;

  /// No description provided for @receiveQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 가져올까요?'**
  String get receiveQuestion;

  /// No description provided for @receiveOnly.
  ///
  /// In ko, this message translates to:
  /// **'이 기록만 가져오기'**
  String get receiveOnly;

  /// No description provided for @receiveOnlyDesc.
  ///
  /// In ko, this message translates to:
  /// **'사슬이 통째로 타임라인에 붙어요. 알림은 울리지 않아요.'**
  String get receiveOnlyDesc;

  /// No description provided for @receiveAdopt.
  ///
  /// In ko, this message translates to:
  /// **'살아있는 루프로 이어받기'**
  String get receiveAdopt;

  /// No description provided for @receiveAdoptDesc.
  ///
  /// In ko, this message translates to:
  /// **'반복이 내 알림으로 다시 울려요. 지금부터 내 시간표로 맞춰요.'**
  String get receiveAdoptDesc;

  /// No description provided for @receiveImport.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get receiveImport;

  /// No description provided for @receiveDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get receiveDecline;

  /// No description provided for @receiveDone.
  ///
  /// In ko, this message translates to:
  /// **'가져왔어요'**
  String get receiveDone;

  /// No description provided for @receiveDoneDesc.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록이 내 타임라인에 그대로 붙었어요.'**
  String receiveDoneDesc(int count);

  /// No description provided for @receiveAdoptedTitle.
  ///
  /// In ko, this message translates to:
  /// **'🔁 살아있는 루프로 이어받음'**
  String get receiveAdoptedTitle;

  /// No description provided for @receiveAdoptedDesc.
  ///
  /// In ko, this message translates to:
  /// **'발화 이력은 그대로 남고, 알림은 이제 내 시간표로 울려요.'**
  String get receiveAdoptedDesc;

  /// No description provided for @receiveNextFire.
  ///
  /// In ko, this message translates to:
  /// **'다음 발화 {time}'**
  String receiveNextFire(String time);

  /// No description provided for @viewChainAction.
  ///
  /// In ko, this message translates to:
  /// **'사슬 보기'**
  String get viewChainAction;

  /// No description provided for @laterAction.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get laterAction;

  /// No description provided for @receiveFail.
  ///
  /// In ko, this message translates to:
  /// **'가져오지 못했어요'**
  String get receiveFail;

  /// No description provided for @shareTapToSend.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 보내기'**
  String get shareTapToSend;

  /// No description provided for @shareWaitingReceiver.
  ///
  /// In ko, this message translates to:
  /// **'받는 쪽에서 설정 › 가까운 기기에서 받기를 켜면 여기에 나타나요'**
  String get shareWaitingReceiver;

  /// No description provided for @shareNotFound.
  ///
  /// In ko, this message translates to:
  /// **'옆 기기를 찾지 못했어요'**
  String get shareNotFound;

  /// No description provided for @shareRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 찾기'**
  String get shareRetry;

  /// No description provided for @receiveSetting.
  ///
  /// In ko, this message translates to:
  /// **'가까운 기기에서 받기'**
  String get receiveSetting;

  /// No description provided for @receiveSettingDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱이 켜져 있는 동안 옆 기기에 내 표시명이 보여요'**
  String get receiveSettingDesc;

  /// No description provided for @shareProgressDetail.
  ///
  /// In ko, this message translates to:
  /// **'{sent} / {total} · {speed}/s'**
  String shareProgressDetail(String sent, String total, String speed);

  /// No description provided for @shareEtaSeconds.
  ///
  /// In ko, this message translates to:
  /// **'약 {seconds}초 남음'**
  String shareEtaSeconds(int seconds);

  /// No description provided for @shareEtaMinutes.
  ///
  /// In ko, this message translates to:
  /// **'약 {minutes}분 남음'**
  String shareEtaMinutes(int minutes);

  /// No description provided for @shareSlowHint.
  ///
  /// In ko, this message translates to:
  /// **'블루투스로 느리게 가고 있어요. 취소하고 양쪽 다 Wi-Fi를 켠 뒤 다시 보내면 훨씬 빨라요.'**
  String get shareSlowHint;

  /// No description provided for @shareStalled.
  ///
  /// In ko, this message translates to:
  /// **'한동안 진행이 없어 멈췄어요. 두 기기를 가까이 두고 다시 보내 주세요.'**
  String get shareStalled;

  /// No description provided for @receiveIncoming.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 보내는 중'**
  String receiveIncoming(String name);

  /// No description provided for @receiveIncomingFailed.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 전송이 중단됐어요'**
  String receiveIncomingFailed(String name);

  /// No description provided for @shareCleanTitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 임시 파일 정리'**
  String get shareCleanTitle;

  /// No description provided for @shareCleanDesc.
  ///
  /// In ko, this message translates to:
  /// **'{size} · 받다 만 파일과 전송용 임시 파일'**
  String shareCleanDesc(String size);

  /// No description provided for @shareCleanEmpty.
  ///
  /// In ko, this message translates to:
  /// **'정리할 파일이 없어요'**
  String get shareCleanEmpty;

  /// No description provided for @shareCleanConfirm.
  ///
  /// In ko, this message translates to:
  /// **'지금 주고받는 중인 파일은 남기고 지워요.'**
  String get shareCleanConfirm;

  /// No description provided for @shareCleanAction.
  ///
  /// In ko, this message translates to:
  /// **'정리'**
  String get shareCleanAction;

  /// No description provided for @shareCleanDone.
  ///
  /// In ko, this message translates to:
  /// **'{size} 정리했어요'**
  String shareCleanDone(String size);

  /// No description provided for @alarmPermTitle.
  ///
  /// In ko, this message translates to:
  /// **'알람이 화면에 뜨려면 권한이 필요해요'**
  String get alarmPermTitle;

  /// No description provided for @alarmPermBody.
  ///
  /// In ko, this message translates to:
  /// **'지금은 알람이 울려도 소리만 나고 화면에는 뜨지 않아요. \'전체 화면 알림\'을 허용하면 화면이 꺼져 있어도 잠금 화면 위로 알람이 바로 떠요.'**
  String get alarmPermBody;

  /// No description provided for @settingsAppInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsAppInfo;

  /// No description provided for @guideOpen.
  ///
  /// In ko, this message translates to:
  /// **'Loop 사용법'**
  String get guideOpen;

  /// No description provided for @guideOpenDesc.
  ///
  /// In ko, this message translates to:
  /// **'기능을 그림으로 한눈에'**
  String get guideOpenDesc;

  /// No description provided for @guideTitle.
  ///
  /// In ko, this message translates to:
  /// **'Loop 사용법'**
  String get guideTitle;

  /// No description provided for @guideIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'Loop는 이런 앱이에요'**
  String get guideIntroTitle;

  /// No description provided for @guideIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'지나간 생각을 다시 돌아오게 하는 기록장이에요. 지금 생각을 적고 루프를 걸어 두면, 정한 때에 그 기록이 다시 찾아와요.'**
  String get guideIntroBody;

  /// No description provided for @guideWriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 쓰기'**
  String get guideWriteTitle;

  /// No description provided for @guideWriteBody.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 + 를 눌러 지금 생각을 적어요. 사진과 1분 이내 동영상을 붙일 수 있고, 장소와 날씨는 자동으로 남아요(설정 › 위치 기록에서 끌 수 있어요).'**
  String get guideWriteBody;

  /// No description provided for @guideLoopTitle.
  ///
  /// In ko, this message translates to:
  /// **'루프 걸기 — 다시 돌아오게'**
  String get guideLoopTitle;

  /// No description provided for @guideLoopBody.
  ///
  /// In ko, this message translates to:
  /// **'기록의 ⋯ › ↩ Loop. \'한 번\'은 정한 시각에 한 번 돌아와요(망각곡선에 맞춘 시각을 추천해요). 알림은 조용히 한 번, 알람은 확인할 때까지 울려요.'**
  String get guideLoopBody;

  /// No description provided for @guideRepeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 루프'**
  String get guideRepeatTitle;

  /// No description provided for @guideRepeatBody.
  ///
  /// In ko, this message translates to:
  /// **'루프 시트에서 \'반복\'을 고르면 10분마다·매일·평일·매달처럼 계속 돌아와요. 돌아올 때마다 그 기록에 이어 쓸 자리가 생겨요. 그만두려면 ⋯ › 루프 중지.'**
  String get guideRepeatBody;

  /// No description provided for @guideFlowTitle.
  ///
  /// In ko, this message translates to:
  /// **'이어 쓰기와 루프 보기'**
  String get guideFlowTitle;

  /// No description provided for @guideFlowBody.
  ///
  /// In ko, this message translates to:
  /// **'돌아온 기록에 이어 쓰면 보라색 줄로 이어진 사슬이 돼요. ⋯ › 루프 보기로 처음 기록부터 지금까지 한 줄로 모아 봐요. 위쪽 \'되돌아가기\'를 누르면 전체 타임라인으로 돌아와요.'**
  String get guideFlowBody;

  /// No description provided for @guideUpcomingTitle.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 7일'**
  String get guideUpcomingTitle;

  /// No description provided for @guideUpcomingBody.
  ///
  /// In ko, this message translates to:
  /// **'위쪽 첫 번째 아이콘(다가오는 루프 · 7일)을 누르면 오늘부터 7일 동안 돌아올 루프가 한눈에 보여요.'**
  String get guideUpcomingBody;

  /// No description provided for @guideRhythmTitle.
  ///
  /// In ko, this message translates to:
  /// **'아침·저녁 리듬'**
  String get guideRhythmTitle;

  /// No description provided for @guideRhythmBody.
  ///
  /// In ko, this message translates to:
  /// **'그때의 나 아침 알림: 아침 9시에 1주·1달·1년 전 오늘의 기록을 들려줘요. 하루 마무리 시각: \'오늘 저녁\' 칩과 매일 밤 루프가 이 시각을 써요. 둘 다 설정에서 바꿔요.'**
  String get guideRhythmBody;

  /// No description provided for @guideShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'Loop 공유 — 옆 사람에게'**
  String get guideShareTitle;

  /// No description provided for @guideShareBody.
  ///
  /// In ko, this message translates to:
  /// **'기록의 ⋯ › Loop 공유 › 가까운 기기로 보내기. 인터넷·서버 없이 옆 폰으로 바로 가요. 받는 쪽은 설정 › 가까운 기기에서 받기를 켜 두세요. 위치는 기본으로 빼고 보내요.'**
  String get guideShareBody;

  /// No description provided for @guideBackupTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 — 전체 내보내기·가져오기'**
  String get guideBackupTitle;

  /// No description provided for @guideBackupBody.
  ///
  /// In ko, this message translates to:
  /// **'설정 › 전체 내보내기로 기록·사진·동영상·반복을 .looplog 파일 하나로 저장해요. 새 폰에서는 설정 › 가져오기 — 이미 있는 기록은 건너뛰어요. 가끔씩 내보내 두세요.'**
  String get guideBackupBody;

  /// No description provided for @guideStatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 흐름·검색·날짜 이동'**
  String get guideStatsTitle;

  /// No description provided for @guideStatsBody.
  ///
  /// In ko, this message translates to:
  /// **'위쪽 아이콘으로 찾아봐요. 검색은 내용·장소로, 날짜로 이동은 그날로 바로 가요. 기록 흐름에서는 돌아온 횟수, 연속 기록, 가장 길게 이어진 사슬을 볼 수 있어요.'**
  String get guideStatsBody;

  /// No description provided for @guideAlarmTitle.
  ///
  /// In ko, this message translates to:
  /// **'알람이 화면에 뜨게 하기'**
  String get guideAlarmTitle;

  /// No description provided for @guideAlarmBody.
  ///
  /// In ko, this message translates to:
  /// **'알람이 잠금 화면 위로 뜨려면 \'전체 화면 알림\' 허용이 필요해요. 안내가 뜨면 설정 열기 › Loop 켜기. 꺼져 있으면 소리만 나요. 설정 › 발화 체험으로 미리 확인해 보세요.'**
  String get guideAlarmBody;

  /// No description provided for @coachSkip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get coachSkip;

  /// No description provided for @coachGotIt.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get coachGotIt;

  /// No description provided for @coachWriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금 떠오르는 걸 적어보세요'**
  String get coachWriteTitle;

  /// No description provided for @coachWriteBody.
  ///
  /// In ko, this message translates to:
  /// **'제목도 폴더도 필요 없어요. 머릿속 생각 그대로 남겨보세요.'**
  String get coachWriteBody;

  /// No description provided for @coachReserveTitle.
  ///
  /// In ko, this message translates to:
  /// **'언제 다시 볼지 정해보세요'**
  String get coachReserveTitle;

  /// No description provided for @coachReserveBody.
  ///
  /// In ko, this message translates to:
  /// **'10분 뒤, 오늘 밤, 일주일 뒤… 이 생각이 다시 찾아올 때를 골라보세요.'**
  String get coachReserveBody;

  /// No description provided for @coachSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 루프 완성이에요'**
  String get coachSaveTitle;

  /// No description provided for @coachSaveBody.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간에 이 생각이 다시 돌아와요.'**
  String get coachSaveBody;

  /// No description provided for @coachReturnTitle.
  ///
  /// In ko, this message translates to:
  /// **'돌아오면 이어서 적어보세요'**
  String get coachReturnTitle;

  /// No description provided for @coachReturnBody.
  ///
  /// In ko, this message translates to:
  /// **'알림이 오면 \'지금 이어쓰기\'를 눌러보세요. 생각이 사슬처럼 이어져요.'**
  String get coachReturnBody;

  /// No description provided for @coachArmTitle.
  ///
  /// In ko, this message translates to:
  /// **'이미 쓴 기록에도 루프를 걸 수 있어요'**
  String get coachArmTitle;

  /// No description provided for @coachArmBody.
  ///
  /// In ko, this message translates to:
  /// **'\'Loop 걸기\'를 누르면 이 생각이 다시 돌아와요.'**
  String get coachArmBody;

  /// No description provided for @coachReplay.
  ///
  /// In ko, this message translates to:
  /// **'사용법 다시 보기'**
  String get coachReplay;

  /// No description provided for @coachReplayDesc.
  ///
  /// In ko, this message translates to:
  /// **'첫 루프 만들기 안내를 처음부터 다시 보여줘'**
  String get coachReplayDesc;

  /// No description provided for @pcLinkSettingTitle.
  ///
  /// In ko, this message translates to:
  /// **'PC 연결'**
  String get pcLinkSettingTitle;

  /// No description provided for @pcLinkSettingOff.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get pcLinkSettingOff;

  /// No description provided for @pcLinkSettingConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get pcLinkSettingConnected;

  /// No description provided for @pcLinkTitle.
  ///
  /// In ko, this message translates to:
  /// **'PC 연결'**
  String get pcLinkTitle;

  /// No description provided for @pcLinkIntro.
  ///
  /// In ko, this message translates to:
  /// **'맥의 Claude Code가 내 기록을 검색하게 연결합니다. 연결되면 화면을 끄거나 다른 앱을 써도 마지막 사용 후 1시간 동안 유지돼요.'**
  String get pcLinkIntro;

  /// No description provided for @pcLinkHostLabel.
  ///
  /// In ko, this message translates to:
  /// **'PC 주소(IP)'**
  String get pcLinkHostLabel;

  /// No description provided for @pcLinkHostHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 192.168.0.8'**
  String get pcLinkHostHint;

  /// No description provided for @pcLinkConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get pcLinkConnect;

  /// No description provided for @pcLinkConnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 중…'**
  String get pcLinkConnecting;

  /// No description provided for @pcLinkCodeTitle.
  ///
  /// In ko, this message translates to:
  /// **'페어링 코드'**
  String get pcLinkCodeTitle;

  /// No description provided for @pcLinkCodeBody.
  ///
  /// In ko, this message translates to:
  /// **'PC의 Claude에게 “연결 코드 보여줘”라고 물어본 뒤, 안내받은 8자리를 입력하세요.'**
  String get pcLinkCodeBody;

  /// No description provided for @pcLinkCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'8자리 숫자'**
  String get pcLinkCodeHint;

  /// No description provided for @pcLinkCodeSubmit.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get pcLinkCodeSubmit;

  /// No description provided for @pcLinkConnectedTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get pcLinkConnectedTitle;

  /// No description provided for @pcLinkConnectedBody.
  ///
  /// In ko, this message translates to:
  /// **'Claude가 이제 내 기록을 검색할 수 있어요. 마지막 사용 후 1시간 동안 연결이 유지돼요.'**
  String get pcLinkConnectedBody;

  /// No description provided for @pcLinkQueries.
  ///
  /// In ko, this message translates to:
  /// **'검색 응답'**
  String get pcLinkQueries;

  /// No description provided for @pcLinkDisconnect.
  ///
  /// In ko, this message translates to:
  /// **'연결 끊기'**
  String get pcLinkDisconnect;

  /// No description provided for @pcLinkUnpair.
  ///
  /// In ko, this message translates to:
  /// **'페어링 해제'**
  String get pcLinkUnpair;

  /// No description provided for @pcLinkErrRefused.
  ///
  /// In ko, this message translates to:
  /// **'연결할 수 없어요 — PC 주소를 확인하고 Claude Code가 실행 중인지 보세요.'**
  String get pcLinkErrRefused;

  /// No description provided for @pcLinkErrTimeout.
  ///
  /// In ko, this message translates to:
  /// **'응답이 없어요 — PC와 같은 Wi-Fi인지 확인하세요.'**
  String get pcLinkErrTimeout;

  /// No description provided for @pcLinkErrBadHost.
  ///
  /// In ko, this message translates to:
  /// **'주소 형식이 올바르지 않아요.'**
  String get pcLinkErrBadHost;

  /// No description provided for @pcLinkErrCodeWrong.
  ///
  /// In ko, this message translates to:
  /// **'코드가 맞지 않아요 ({left}회 남음)'**
  String pcLinkErrCodeWrong(int left);

  /// No description provided for @pcLinkErrTooMany.
  ///
  /// In ko, this message translates to:
  /// **'시도 횟수를 초과했어요. 잠시 후 다시 시도하세요.'**
  String get pcLinkErrTooMany;

  /// No description provided for @pcLinkErrBusy.
  ///
  /// In ko, this message translates to:
  /// **'이미 다른 폰이 연결되어 있어요.'**
  String get pcLinkErrBusy;

  /// No description provided for @pcLinkErrCodeExpired.
  ///
  /// In ko, this message translates to:
  /// **'코드가 만료되었어요. Claude에서 새 코드를 받아 다시 연결하세요.'**
  String get pcLinkErrCodeExpired;

  /// No description provided for @pcLinkErrDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊겼어요.'**
  String get pcLinkErrDisconnected;

  /// No description provided for @pcLinkReconnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊겨서 다시 연결하는 중이에요…'**
  String get pcLinkReconnecting;

  /// No description provided for @guidePcTitle.
  ///
  /// In ko, this message translates to:
  /// **'PC에서 Claude로 검색'**
  String get guidePcTitle;

  /// No description provided for @guidePcBody.
  ///
  /// In ko, this message translates to:
  /// **'준비 — 컴퓨터의 Claude Code에 Loop 플러그인을 설치합니다. Claude Code에서 다음 두 줄을 입력하세요: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. 그다음 Claude에게 \"폰 연결해줘\"라고 말하면 연결 주소와 8자리 코드를 알려줍니다. ① 설정 → PC 연결에서 그 주소를 입력하고 연결 ② 코드를 입력하면 연결 완료 — 이후에는 자동으로 다시 연결됩니다. 기록은 폰에 그대로 있고, 검색 질의와 결과만 같은 Wi-Fi 안에서 오갑니다.'**
  String get guidePcBody;
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
    'hi',
    'it',
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
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
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
