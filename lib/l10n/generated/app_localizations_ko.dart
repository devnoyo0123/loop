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
  String get testFireDesc => '5초 뒤 알림 · 20초 뒤 알람이 울려요';

  @override
  String get testFireSoon => '잠시 후 알림(5초)·알람(20초)이 울려';

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
}
