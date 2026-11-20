// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get emptyTimeline => '아직 로그가 없어.\n+ 로 첫 생각을 남겨봐.';

  @override
  String get emptyAtDate => '그때는 로그가 없어.\n위에서 날짜를 바꿔보거나 최신으로 돌아가.';

  @override
  String get jumpToDate => '날짜로 이동';

  @override
  String get backToLatest => '최신으로 돌아가';

  @override
  String get searchHint => '내용·장소 검색';

  @override
  String get searchEmpty => '검색 결과가 없어';

  @override
  String get sortRelevance => '관련도순';

  @override
  String get sortRecent => '최신순';

  @override
  String get editContent => '내용 편집';

  @override
  String get changeTime => '시간 변경';

  @override
  String get deleteAction => '삭제';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get stop => '중지';

  @override
  String get deleteLogTitle => '로그 삭제';

  @override
  String get deleteLogMessage => '이 로그를 삭제할까? 이어쓰인 로그는 그대로 남아.';

  @override
  String get stopRepeatTitle => 'Loop 중지';

  @override
  String stopRepeatMessage(String rule) {
    return '$rule 루프를 멈출까?\n다음 발화부터 취소되고, 이미 만들어진 로그는 남아.';
  }

  @override
  String get composeHint => '지금 생각…';

  @override
  String forkOf(String time) {
    return '↩ $time 로그에 이어쓰기';
  }

  @override
  String get saveLog => '로그 남기기';

  @override
  String get attachPhoto => '사진 첨부';

  @override
  String get reserveAlarm => '알림 예약';

  @override
  String get alarmTitle => '⏰ 알림 예약';

  @override
  String get tapToChangeTime => '탭해서 날짜·시각 바꾸기';

  @override
  String get pastTimeHint => '이미 지난 시각이에요 — 다가올 시각으로 다시 골라주세요';

  @override
  String get in10min => '10분 후';

  @override
  String get in1hour => '1시간 후';

  @override
  String get tomorrow => '내일';

  @override
  String get nextWeek => '다음 주';

  @override
  String get in1month => '1달 후';

  @override
  String loopCurveHint(int n, String interval) {
    return '망각곡선 $n번째 복습 · 추천 $interval';
  }

  @override
  String get recommended => '추천';

  @override
  String get custom => '직접';

  @override
  String get notifyAtThisTime => '이 시각에 알려줘';

  @override
  String get repeatTitle => '↩ Loop';

  @override
  String get repeatDesc => '반복을 걸면 발화마다 이 로그의 이어쓰기가 자동으로 생성돼. 언제든 멈출 수 있어.';

  @override
  String get preset10min => '10분';

  @override
  String get preset30min => '30분';

  @override
  String get preset1hour => '1시간';

  @override
  String get preset3hours => '3시간';

  @override
  String get preset6hours => '6시간';

  @override
  String get presetDaily => '매일';

  @override
  String get fireTime => '발화 시각';

  @override
  String get unitMinutes => '분';

  @override
  String get unitHours => '시간';

  @override
  String nextFire(String time, String rule) {
    return '다음 $time · 이후 $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return '$n분마다';
  }

  @override
  String ruleEveryHours(int n) {
    return '$n시간마다';
  }

  @override
  String ruleDaily(String time) {
    return '매일 $time';
  }

  @override
  String ruleWeekday(String time) {
    return '평일 $time';
  }

  @override
  String get presetWeekday => '평일';

  @override
  String get presetMonthly => '매달';

  @override
  String get presetYearly => '매년';

  @override
  String get presetLadder => '사다리';

  @override
  String get ruleLadder => '망각곡선 사다리';

  @override
  String get curveSteps => '10분 → 1시간 → 오늘 저녁 → 내일 → 1주 → 1개월 · 총 6회';

  @override
  String get fireDate => '발화일';

  @override
  String get unitMonths => '개월';

  @override
  String get unitYears => '년';

  @override
  String ruleMonthly(int day, String time) {
    return '매달 $day일 $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return '$n개월마다 $day일 $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return '매년 $date $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return '$n년마다 $date $time';
  }

  @override
  String get upcomingTitle => '다가오는 루프 · 7일';

  @override
  String get upcomingEmpty => '이번 주엔 예정된 루프가 없어';

  @override
  String get noContent => '(내용 없음)';

  @override
  String continuedFrom(String time) {
    return '↩ $time 에서 이어짐';
  }

  @override
  String get locationRecorded => '위치 기록됨';

  @override
  String repeatNth(int n) {
    return 'Loop $n회째';
  }

  @override
  String get repeatEnded => 'Loop 종료';

  @override
  String get loopAction => '↩ Loop';

  @override
  String get loopWriteNow => '지금 이어쓰기';

  @override
  String get loopAgain => '다시 알려줘';

  @override
  String get loopModeOnce => '한 번';

  @override
  String get loopModeRepeat => '반복';

  @override
  String loopNextShort(String time) {
    return '다음 $time';
  }

  @override
  String loopFireCount(int n) {
    return '지금까지 $n번 돌아왔어';
  }

  @override
  String get loopJump => '원본으로 이동';

  @override
  String get loopStop => '루프 중지';

  @override
  String get loopEndedInfo => '이 루프는 종료됐어';

  @override
  String get loopViewAction => '루프 보기';

  @override
  String get loopWriteAction => '작성하기';

  @override
  String get loopViewBack => '되돌아가기';

  @override
  String get mineOnlyTitle => '내 루프만 보기';

  @override
  String get mineOnlyBack => '전체 보기';

  @override
  String get locationCapture => '위치 기록';

  @override
  String get locationCaptureDesc => '로그에 장소·날씨를 자동으로 함께 기록';

  @override
  String get loopArm => 'Loop 걸기';

  @override
  String get emptyWriteHint => '비어 있음 · 탭해서 작성';

  @override
  String get openInYoutube => '유튜브에서 열기';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsData => '데이터';

  @override
  String get defaultBrowser => '기본 브라우저';

  @override
  String get defaultBrowserDesc => '웹 링크를 열 때 이 브라우저로 열려';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get browserEmpty => '설치된 브라우저가 없어';

  @override
  String get exportLogs => '전체 내보내기';

  @override
  String get exportAllDesc => '로그·사진·반복까지 .looplog 파일 하나로';

  @override
  String get exporting => '내보내는 중…';

  @override
  String get exportDone => '내보냈어';

  @override
  String get exportCancel => '저장을 취소했어';

  @override
  String get exportFail => '파일 저장을 못 했어';

  @override
  String get importLogs => '가져오기';

  @override
  String get importAllDesc => '.looplog 파일에서 복원 · 이미 있는 로그는 건너뛰어';

  @override
  String get importConfirmMessage =>
      '기존 로그는 그대로 두고 파일의 로그를 더해.\n이미 있는 로그는 건너뛰니까 같은 파일을 다시 가져와도 중복이 생기지 않아.';

  @override
  String get importing => '가져오는 중…';

  @override
  String importDone(int logs, int repeats) {
    return '로그 $logs개 · 반복 $repeats개를 가져왔어';
  }

  @override
  String get importCancel => '가져오기를 취소했어';

  @override
  String get importEmpty => '가져올 내용이 없어';

  @override
  String get importFail => '.looplog 파일을 읽지 못했어';

  @override
  String get howNotify => '어떻게 알려줄까?';

  @override
  String get modeNotif => '알림';

  @override
  String get modeNotifDesc => '한 번 알려주고 끝. 기본 — 조용한 상기';

  @override
  String get modeAlarm => '알람';

  @override
  String get modeAlarmDesc => '꺼야 멈춤, 무음에도. 꼭 지켜야 할 루프용';

  @override
  String get snoozeAction => '10분 후 다시';

  @override
  String get notifAlarmChannelName => '루프 알람';

  @override
  String get testFire => '발화 체험';

  @override
  String get testNotifTitle => '발화 체험 · 알림';

  @override
  String get overlayPermTitle => '다른 앱 위에 알람 표시';

  @override
  String get overlayPermBody =>
      '다른 앱을 쓰는 중에도 알람이 전체 화면으로 울리려면 \"다른 앱 위에 그리기\" 권한이 필요해요. 다음 화면에서 허용해 주세요.';

  @override
  String get overlayPermOpen => '설정 열기';

  @override
  String get testFireDesc => '5초 뒤 알림 · 20초 뒤 알람이 울려요';

  @override
  String get testFireSoon => '잠시 후 알림(5초)·알람(20초)이 울려';

  @override
  String get fullScreenHint => '알람이 잠금화면 전체로 뜨려면 \'알람 및 리마인더\' 허용이 필요해.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get detailOriginal => '원본 기록';

  @override
  String get detailPlace => '장소';

  @override
  String get detailWeather => '날씨';

  @override
  String get detailPhotos => '사진';

  @override
  String photoCount(int n) {
    return '$n장';
  }

  @override
  String get detailNoContext => '위치·날씨·사진 정보 없음';

  @override
  String get detailRecord => '기록';

  @override
  String get unknown => '알 수 없음';

  @override
  String get yesterday => '어제';

  @override
  String get wmoClear => '맑음';

  @override
  String get wmoPartly => '구름 조금';

  @override
  String get wmoCloudy => '흐림';

  @override
  String get wmoFog => '안개';

  @override
  String get wmoDrizzle => '이슬비';

  @override
  String get wmoRain => '비';

  @override
  String get wmoSnow => '눈';

  @override
  String get wmoThunder => '뇌우';

  @override
  String get wmoUnknown => '알 수 없음';

  @override
  String get notifRepeatTitle => '↩ Loop';

  @override
  String get notifFallbackBody => '루프 돌아올 시간';

  @override
  String get notifConfirm => '확인';

  @override
  String get notifChannelName => '루프';

  @override
  String get notifChannelDesc => '돌아온 루프를 알려준다';

  @override
  String get statsTitle => '기록 흐름';

  @override
  String get statsEmpty => '기록이 쌓이면 흐름이 보여요.\n+를 눌러 첫 생각을 남겨보세요.';

  @override
  String statsReturnsLine(int n) {
    return '생각이 $n번 다시 돌아왔어요';
  }

  @override
  String get statsReturnsZero => '루프를 걸면 생각이 다시 돌아와요';

  @override
  String get statsTotalLogs => '쓴 기록';

  @override
  String get statsActiveDays => '기록한 날';

  @override
  String get statsStreakNow => '지금 연속';

  @override
  String get statsStreakBest => '최장 연속';

  @override
  String statsDays(int n) {
    return '$n일';
  }

  @override
  String get statsHeatmapCaption => '최근 15주';

  @override
  String get statsHeatmapLess => '적게';

  @override
  String get statsHeatmapMore => '많이';

  @override
  String get statsTopChains => '가장 많이 이어진 사슬';

  @override
  String statsChainLinkings(int n) {
    return '$n번 이어짐';
  }

  @override
  String get starterQuickTitle => '10분 루프';

  @override
  String get starterQuickDesc => '지금 쓰면 10분 뒤 다시 돌아와요';

  @override
  String get starterDailyTitle => '매일 밤 한 줄';

  @override
  String get starterDailyDesc => '매일 밤 9시에 오늘이 돌아와요';

  @override
  String get starterWeekTitle => '일주일 루프';

  @override
  String get starterWeekDesc => '지금 쓰고 일주일 뒤에 돌아봐요';

  @override
  String starterInMinutes(int n) {
    return '$n분 뒤';
  }

  @override
  String starterEveryNight(String time) {
    return '매일 밤 $time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ $when 다시 돌아와요';
  }

  @override
  String get onThisDayTitle => '그때의 나';

  @override
  String get onThisDayWeekAgo => '1주 전 오늘';

  @override
  String get onThisDayMonthAgo => '1개월 전 오늘';

  @override
  String get onThisDayYearAgo => '1년 전 오늘';

  @override
  String get onThisDayChannelName => '그때의 나';

  @override
  String get onThisDayChannelDesc => '과거의 기록을 아침마다 다시 들려줘요';

  @override
  String get onThisDaySetting => '그때의 나 아침 알림';

  @override
  String get onThisDaySettingDesc => '1주·1개월·1년 전 오늘의 기록을 아침 9시에 들려줘요';

  @override
  String get shareStats => '공유';

  @override
  String get shareCardTagline => '흘러간 생각이 다시 돌아오는 기록';

  @override
  String get shareFail => '공유 카드를 만들지 못했어요';

  @override
  String get loopAttachHeadLabel => '↩ 사슬의 마지막 기록에서 이어짐';

  @override
  String get loopAttachHereLabel => '↩ 이 기록에서 분기됨';

  @override
  String get loopAttachHereAction => '여기서부터';

  @override
  String get loopAttachHeadAction => '사슬 끝에서';

  @override
  String get todayEvening => '오늘 저녁';

  @override
  String get dayEndSetting => '하루 마무리 시각';

  @override
  String get dayEndSettingDesc => '\"오늘 저녁\" 칩과 매일 밤 루프가 이 시각을 써요';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get takeVideo => '동영상 촬영';

  @override
  String get videoAttached => '동영상 첨부됨';

  @override
  String get videoOpenRow => '동영상 · 탭해서 재생';

  @override
  String get videoPlayFail => '동영상을 재생할 앱을 찾을 수 없어요';

  @override
  String get videoTooLong => '동영상은 1분까지만 첨부할 수 있어요';

  @override
  String get shareChainAction => 'Loop 공유';

  @override
  String get shareChainTitle => 'Loop 공유';

  @override
  String get shareCountLogs => '기록';

  @override
  String get shareCountPhotos => '사진';

  @override
  String get shareCountVideos => '동영상';

  @override
  String get shareCountRepeats => '반복';

  @override
  String get shareNameLabel => '표시명';

  @override
  String get shareNameHint => '상대에게 보이는 이름이에요';

  @override
  String get shareStripLocation => '위치 정보 빼고 보내기';

  @override
  String get shareStripLocationDesc => '기록에 남은 장소·좌표는 빠져요';

  @override
  String get shareStripMedia => '사진·동영상 빼고 보내기';

  @override
  String get shareStripMediaDesc => '텍스트 기록만 가요';

  @override
  String get shareSendNearby => '가까운 기기로 보내기';

  @override
  String get shareExportFile => '파일로 내보내기 (.looplog)';

  @override
  String get shareSearching => '옆 기기를 찾고 있어요…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · 연결됨';
  }

  @override
  String get shareSending => '전송 중';

  @override
  String get shareHintOffline => '인터넷·서버를 전혀 거치지 않아요. 보통 몇십 초 안에 끝나요.';

  @override
  String get shareSent => '보냈어요';

  @override
  String get shareSendFail => '전송에 실패했어요';

  @override
  String get sharePermTitle => '가까운 기기 권한';

  @override
  String get sharePermBody =>
      '옆 기기를 찾으려면 위치·근거리 기기 권한이 필요해요. 데이터는 기기끼리 직접 주고받고 어디에도 남지 않아요.';

  @override
  String receiveFrom(String name) {
    return '$name님이 보냈어요';
  }

  @override
  String get receiveTitle => '사슬 가져오기';

  @override
  String get receiveBadgeNoLocation => '위치 정보 없이 전송됨';

  @override
  String get receiveQuestion => '어떻게 가져올까요?';

  @override
  String get receiveOnly => '이 기록만 가져오기';

  @override
  String get receiveOnlyDesc => '사슬이 통째로 타임라인에 붙어요. 알림은 울리지 않아요.';

  @override
  String get receiveAdopt => '살아있는 루프로 이어받기';

  @override
  String get receiveAdoptDesc => '반복이 내 알림으로 다시 울려요. 지금부터 내 시간표로 맞춰요.';

  @override
  String get receiveImport => '가져오기';

  @override
  String get receiveDecline => '거절';

  @override
  String get receiveDone => '가져왔어요';

  @override
  String receiveDoneDesc(int count) {
    return '$count개 기록이 내 타임라인에 그대로 붙었어요.';
  }

  @override
  String get receiveAdoptedTitle => '🔁 살아있는 루프로 이어받음';

  @override
  String get receiveAdoptedDesc => '발화 이력은 그대로 남고, 알림은 이제 내 시간표로 울려요.';

  @override
  String receiveNextFire(String time) {
    return '다음 발화 $time';
  }

  @override
  String get viewChainAction => '사슬 보기';

  @override
  String get laterAction => '나중에';

  @override
  String get receiveFail => '가져오지 못했어요';

  @override
  String get shareTapToSend => '눌러서 보내기';

  @override
  String get shareWaitingReceiver => '받는 쪽에서 설정 › 가까운 기기에서 받기를 켜면 여기에 나타나요';

  @override
  String get shareNotFound => '옆 기기를 찾지 못했어요';

  @override
  String get shareRetry => '다시 찾기';

  @override
  String get receiveSetting => '가까운 기기에서 받기';

  @override
  String get receiveSettingDesc => '앱이 켜져 있는 동안 옆 기기에 내 표시명이 보여요';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return '약 $seconds초 남음';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return '약 $minutes분 남음';
  }

  @override
  String get shareSlowHint =>
      '블루투스로 느리게 가고 있어요. 취소하고 양쪽 다 Wi-Fi를 켠 뒤 다시 보내면 훨씬 빨라요.';

  @override
  String get shareStalled => '한동안 진행이 없어 멈췄어요. 두 기기를 가까이 두고 다시 보내 주세요.';

  @override
  String receiveIncoming(String name) {
    return '$name님이 보내는 중';
  }

  @override
  String receiveIncomingFailed(String name) {
    return '$name님의 전송이 중단됐어요';
  }

  @override
  String get shareCleanTitle => '공유 임시 파일 정리';

  @override
  String shareCleanDesc(String size) {
    return '$size · 받다 만 파일과 전송용 임시 파일';
  }

  @override
  String get shareCleanEmpty => '정리할 파일이 없어요';

  @override
  String get shareCleanConfirm => '지금 주고받는 중인 파일은 남기고 지워요.';

  @override
  String get shareCleanAction => '정리';

  @override
  String shareCleanDone(String size) {
    return '$size 정리했어요';
  }

  @override
  String get alarmPermTitle => '알람이 화면에 뜨려면 권한이 필요해요';

  @override
  String get alarmPermBody =>
      '지금은 알람이 울려도 소리만 나고 화면에는 뜨지 않아요. \'전체 화면 알림\'을 허용하면 화면이 꺼져 있어도 잠금 화면 위로 알람이 바로 떠요.';

  @override
  String get settingsAppInfo => '앱 정보';

  @override
  String get guideOpen => 'Loop 사용법';

  @override
  String get guideOpenDesc => '기능을 그림으로 한눈에';

  @override
  String get guideTitle => 'Loop 사용법';

  @override
  String get guideIntroTitle => 'Loop는 이런 앱이에요';

  @override
  String get guideIntroBody =>
      '지나간 생각을 다시 돌아오게 하는 기록장이에요. 지금 생각을 적고 루프를 걸어 두면, 정한 때에 그 기록이 다시 찾아와요.';

  @override
  String get guideWriteTitle => '기록 쓰기';

  @override
  String get guideWriteBody =>
      '오른쪽 아래 + 를 눌러 지금 생각을 적어요. 사진과 1분 이내 동영상을 붙일 수 있고, 장소와 날씨는 자동으로 남아요(설정 › 위치 기록에서 끌 수 있어요).';

  @override
  String get guideLoopTitle => '루프 걸기 — 다시 돌아오게';

  @override
  String get guideLoopBody =>
      '기록의 ⋯ › ↩ Loop. \'한 번\'은 정한 시각에 한 번 돌아와요(망각곡선에 맞춘 시각을 추천해요). 알림은 조용히 한 번, 알람은 확인할 때까지 울려요.';

  @override
  String get guideRepeatTitle => '반복 루프';

  @override
  String get guideRepeatBody =>
      '루프 시트에서 \'반복\'을 고르면 10분마다·매일·평일·매달처럼 계속 돌아와요. 돌아올 때마다 그 기록에 이어 쓸 자리가 생겨요. 그만두려면 ⋯ › 루프 중지.';

  @override
  String get guideFlowTitle => '이어 쓰기와 루프 보기';

  @override
  String get guideFlowBody =>
      '돌아온 기록에 이어 쓰면 보라색 줄로 이어진 사슬이 돼요. ⋯ › 루프 보기로 처음 기록부터 지금까지 한 줄로 모아 봐요. 위쪽 \'되돌아가기\'를 누르면 전체 타임라인으로 돌아와요.';

  @override
  String get guideUpcomingTitle => '다가오는 7일';

  @override
  String get guideUpcomingBody =>
      '위쪽 첫 번째 아이콘(다가오는 루프 · 7일)을 누르면 오늘부터 7일 동안 돌아올 루프가 한눈에 보여요.';

  @override
  String get guideRhythmTitle => '아침·저녁 리듬';

  @override
  String get guideRhythmBody =>
      '그때의 나 아침 알림: 아침 9시에 1주·1달·1년 전 오늘의 기록을 들려줘요. 하루 마무리 시각: \'오늘 저녁\' 칩과 매일 밤 루프가 이 시각을 써요. 둘 다 설정에서 바꿔요.';

  @override
  String get guideShareTitle => 'Loop 공유 — 옆 사람에게';

  @override
  String get guideShareBody =>
      '기록의 ⋯ › Loop 공유 › 가까운 기기로 보내기. 인터넷·서버 없이 옆 폰으로 바로 가요. 받는 쪽은 설정 › 가까운 기기에서 받기를 켜 두세요. 위치는 기본으로 빼고 보내요.';

  @override
  String get guideBackupTitle => '백업 — 전체 내보내기·가져오기';

  @override
  String get guideBackupBody =>
      '설정 › 전체 내보내기로 기록·사진·동영상·반복을 .looplog 파일 하나로 저장해요. 새 폰에서는 설정 › 가져오기 — 이미 있는 기록은 건너뛰어요. 가끔씩 내보내 두세요.';

  @override
  String get guideStatsTitle => '기록 흐름·검색·날짜 이동';

  @override
  String get guideStatsBody =>
      '위쪽 아이콘으로 찾아봐요. 검색은 내용·장소로, 날짜로 이동은 그날로 바로 가요. 기록 흐름에서는 돌아온 횟수, 연속 기록, 가장 길게 이어진 사슬을 볼 수 있어요.';

  @override
  String get guideAlarmTitle => '알람이 화면에 뜨게 하기';

  @override
  String get guideAlarmBody =>
      '알람이 잠금 화면 위로 뜨려면 \'전체 화면 알림\' 허용이 필요해요. 안내가 뜨면 설정 열기 › Loop 켜기. 꺼져 있으면 소리만 나요. 설정 › 발화 체험으로 미리 확인해 보세요.';

  @override
  String get coachSkip => '건너뛰기';

  @override
  String get coachGotIt => '확인';

  @override
  String get coachWriteTitle => '지금 떠오르는 걸 적어보세요';

  @override
  String get coachWriteBody => '제목도 폴더도 필요 없어요. 머릿속 생각 그대로 남겨보세요.';

  @override
  String get coachReserveTitle => '언제 다시 볼지 정해보세요';

  @override
  String get coachReserveBody => '10분 뒤, 오늘 밤, 일주일 뒤… 이 생각이 다시 찾아올 때를 골라보세요.';

  @override
  String get coachSaveTitle => '저장하면 루프 완성이에요';

  @override
  String get coachSaveBody => '정한 시간에 이 생각이 다시 돌아와요.';

  @override
  String get coachReturnTitle => '돌아오면 이어서 적어보세요';

  @override
  String get coachReturnBody => '알림이 오면 \'지금 이어쓰기\'를 눌러보세요. 생각이 사슬처럼 이어져요.';

  @override
  String get coachArmTitle => '이미 쓴 기록에도 루프를 걸 수 있어요';

  @override
  String get coachArmBody => '\'Loop 걸기\'를 누르면 이 생각이 다시 돌아와요.';

  @override
  String get coachReplay => '사용법 다시 보기';

  @override
  String get coachReplayDesc => '첫 루프 만들기 안내를 처음부터 다시 보여줘';

  @override
  String get pcLinkSettingTitle => 'PC 연결';

  @override
  String get pcLinkSettingOff => '연결 안 됨';

  @override
  String get pcLinkSettingConnected => '연결됨';

  @override
  String get pcLinkTitle => 'PC 연결';

  @override
  String get pcLinkIntro =>
      '맥의 Claude Code가 내 기록을 검색하게 연결합니다. 연결되면 화면을 끄거나 다른 앱을 써도 마지막 사용 후 1시간 동안 유지돼요.';

  @override
  String get pcLinkHostLabel => 'PC 주소(IP)';

  @override
  String get pcLinkHostHint => '예: 192.168.0.8';

  @override
  String get pcLinkConnect => '연결';

  @override
  String get pcLinkConnecting => '연결 중…';

  @override
  String get pcLinkCodeTitle => '페어링 코드';

  @override
  String get pcLinkCodeBody =>
      'PC의 Claude에게 “연결 코드 보여줘”라고 물어본 뒤, 안내받은 8자리를 입력하세요.';

  @override
  String get pcLinkCodeHint => '8자리 숫자';

  @override
  String get pcLinkCodeSubmit => '확인';

  @override
  String get pcLinkConnectedTitle => '연결됨';

  @override
  String get pcLinkConnectedBody =>
      'Claude가 이제 내 기록을 검색할 수 있어요. 마지막 사용 후 1시간 동안 연결이 유지돼요.';

  @override
  String get pcLinkQueries => '검색 응답';

  @override
  String get pcLinkDisconnect => '연결 끊기';

  @override
  String get pcLinkUnpair => '페어링 해제';

  @override
  String get pcLinkErrRefused =>
      '연결할 수 없어요 — PC 주소를 확인하고 Claude Code가 실행 중인지 보세요.';

  @override
  String get pcLinkErrTimeout => '응답이 없어요 — PC와 같은 Wi-Fi인지 확인하세요.';

  @override
  String get pcLinkErrBadHost => '주소 형식이 올바르지 않아요.';

  @override
  String pcLinkErrCodeWrong(int left) {
    return '코드가 맞지 않아요 ($left회 남음)';
  }

  @override
  String get pcLinkErrTooMany => '시도 횟수를 초과했어요. 잠시 후 다시 시도하세요.';

  @override
  String get pcLinkErrBusy => '이미 다른 폰이 연결되어 있어요.';

  @override
  String get pcLinkErrCodeExpired => '코드가 만료되었어요. Claude에서 새 코드를 받아 다시 연결하세요.';

  @override
  String get pcLinkErrDisconnected => '연결이 끊겼어요.';

  @override
  String get pcLinkReconnecting => '연결이 끊겨서 다시 연결하는 중이에요…';

  @override
  String get guidePcTitle => 'PC에서 Claude로 검색';

  @override
  String get guidePcBody =>
      '준비 — 컴퓨터의 Claude Code에 Loop 플러그인을 설치합니다. Claude Code에서 다음 두 줄을 입력하세요: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. 그다음 Claude에게 \"폰 연결해줘\"라고 말하면 연결 주소와 8자리 코드를 알려줍니다. ① 설정 → PC 연결에서 그 주소를 입력하고 연결 ② 코드를 입력하면 연결 완료 — 이후에는 자동으로 다시 연결됩니다. 기록은 폰에 그대로 있고, 검색 질의와 결과만 같은 Wi-Fi 안에서 오갑니다.';
}
