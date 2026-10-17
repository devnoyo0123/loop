// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get emptyTimeline => 'まだログがありません。\n+ で最初のひとことを残そう。';

  @override
  String get emptyAtDate => 'この日はログがありません。\n上で日付を変えるか、最新に戻ろう。';

  @override
  String get jumpToDate => '日付へ移動';

  @override
  String get backToLatest => '最新に戻る';

  @override
  String get searchHint => '内容・場所を検索';

  @override
  String get searchEmpty => '検索結果がありません';

  @override
  String get sortRelevance => '関連度順';

  @override
  String get sortRecent => '新着順';

  @override
  String get editContent => '内容を編集';

  @override
  String get changeTime => '時刻を変更';

  @override
  String get deleteAction => '削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get stop => '停止';

  @override
  String get deleteLogTitle => 'ログを削除';

  @override
  String get deleteLogMessage => 'このログを削除する？続き書きのログはそのまま残るよ。';

  @override
  String get stopRepeatTitle => 'ループを止める';

  @override
  String stopRepeatMessage(String rule) {
    return '$rule ループを止める?\n次の発火からは取り消されて、もう作られた記録は残るよ。';
  }

  @override
  String get composeHint => 'いまの思考…';

  @override
  String forkOf(String time) {
    return '↩ $time のログに続きを書く';
  }

  @override
  String get saveLog => 'ログを残す';

  @override
  String get attachPhoto => '写真を添付';

  @override
  String get reserveAlarm => 'リマインダー予約';

  @override
  String get alarmTitle => '⏰ リマインダー';

  @override
  String get tapToChangeTime => 'タップして日時を変更';

  @override
  String get in10min => '10分後';

  @override
  String get in1hour => '1時間後';

  @override
  String get tomorrow => '明日';

  @override
  String get nextWeek => '来週';

  @override
  String get in1month => '1か月後';

  @override
  String loopCurveHint(int n, String interval) {
    return '忘却曲線 $n回目の復習 · おすすめ $interval';
  }

  @override
  String get custom => '直接指定';

  @override
  String get notifyAtThisTime => 'この時刻に知らせて';

  @override
  String get repeatTitle => '↩ ループ';

  @override
  String get repeatDesc => '繰り返しをかける発火のたびに、この記録の続きが自動で作られるよ。いつでも止められる。';

  @override
  String get preset10min => '10分';

  @override
  String get preset30min => '30分';

  @override
  String get preset1hour => '1時間';

  @override
  String get preset3hours => '3時間';

  @override
  String get preset6hours => '6時間';

  @override
  String get presetDaily => '毎日';

  @override
  String get fireTime => '発火時刻';

  @override
  String get unitMinutes => '分';

  @override
  String get unitHours => '時間';

  @override
  String nextFire(String time, String rule) {
    return '次は $time · 以降 $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return '$n分ごと';
  }

  @override
  String ruleEveryHours(int n) {
    return '$n時間ごと';
  }

  @override
  String ruleDaily(String time) {
    return '毎日 $time';
  }

  @override
  String ruleWeekday(String time) {
    return '平日 $time';
  }

  @override
  String get presetWeekday => '平日';

  @override
  String get upcomingTitle => '今後のループ · 7日';

  @override
  String get upcomingEmpty => '今週の予定されたループはないよ';

  @override
  String get noContent => '(内容なし)';

  @override
  String continuedFrom(String time) {
    return '↩ $time からの続き';
  }

  @override
  String get locationRecorded => '位置を記録済み';

  @override
  String repeatNth(int n) {
    return 'ループ$n回目';
  }

  @override
  String get repeatEnded => 'ループ終了';

  @override
  String get loopAction => '↩ ループ';

  @override
  String get loopWriteNow => '今つづきを書く';

  @override
  String get loopAgain => 'また知らせる';

  @override
  String get loopModeOnce => '1回';

  @override
  String get loopModeRepeat => '繰り返し';

  @override
  String loopNextShort(String time) {
    return '次は $time';
  }

  @override
  String loopFireCount(int n) {
    return 'これまでに$n回';
  }

  @override
  String get loopJump => '元の記録へ';

  @override
  String get loopStop => 'ループを止める';

  @override
  String get loopEndedInfo => 'このループは終了したよ';

  @override
  String get loopViewAction => 'ループを見る';

  @override
  String get loopWriteAction => '書く';

  @override
  String get loopViewBack => 'タイムラインに戻る';

  @override
  String get locationCapture => '位置情報';

  @override
  String get locationCaptureDesc => '場所・天気を自動でいっしょに記録';

  @override
  String get loopArm => 'ループをかける';

  @override
  String get emptyWriteHint => '空欄 · タップして記入';

  @override
  String get openInYoutube => 'YouTubeで開く';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsData => 'データ';

  @override
  String get defaultBrowser => '既定のブラウザ';

  @override
  String get defaultBrowserDesc => 'Webリンクはこのブラウザで開くよ';

  @override
  String get systemDefault => 'システム既定';

  @override
  String get browserEmpty => 'インストール済みのブラウザがありません';

  @override
  String get exportLogs => 'すべてエクスポート';

  @override
  String get exportAllDesc => 'ログ・写真・繰り返しを .looplog ファイル 1つに';

  @override
  String get exporting => 'エクスポート中…';

  @override
  String get exportDone => 'エクスポートしたよ';

  @override
  String get exportCancel => '保存をキャンセルしたよ';

  @override
  String get exportFail => 'ファイルを保存できなかった';

  @override
  String get importLogs => '読み込む';

  @override
  String get importAllDesc => '.looplogファイルから復元 · あるログはスキップ';

  @override
  String get importConfirmMessage =>
      '今のログはそのままに、ファイルのログを追加するよ。\n同じログはスキップするから、同じファイルをもう一度読み込んでも重複しない。';

  @override
  String get importing => '読み込み中…';

  @override
  String importDone(int logs, int repeats) {
    return 'ログ$logs件 · 繰り返し$repeats件を読み込んだよ';
  }

  @override
  String get importCancel => '読み込みをキャンセルした';

  @override
  String get importEmpty => '読み込む内容がない';

  @override
  String get importFail => '.looplogファイルを読めなかった';

  @override
  String get howNotify => 'どう知らせる？';

  @override
  String get modeNotif => '通知';

  @override
  String get modeNotifDesc => '一度だけ知らせる。基本 — 静かな促し';

  @override
  String get modeAlarm => 'アラーム';

  @override
  String get modeAlarmDesc => '止めるまで鳴る、マナーモードでも。絶対守るループ用';

  @override
  String get snoozeAction => '10分後にまた';

  @override
  String get notifAlarmChannelName => 'ループアラーム';

  @override
  String get testFire => '発火テスト';

  @override
  String get testFireDesc => '5秒後に通知 · 20秒後にアラーム';

  @override
  String get testFireSoon => 'まもなく発火：通知（5秒）· アラーム（20秒）';

  @override
  String get detailOriginal => '元の記録';

  @override
  String get detailPlace => '場所';

  @override
  String get detailWeather => '天気';

  @override
  String get detailPhotos => '写真';

  @override
  String photoCount(int n) {
    return '$n枚';
  }

  @override
  String get detailNoContext => '位置・天気・写真の情報なし';

  @override
  String get detailRecord => '記録';

  @override
  String get unknown => '不明';

  @override
  String get yesterday => '昨日';

  @override
  String get wmoClear => '晴れ';

  @override
  String get wmoPartly => '一部曇り';

  @override
  String get wmoCloudy => '曇り';

  @override
  String get wmoFog => '霧';

  @override
  String get wmoDrizzle => '霧雨';

  @override
  String get wmoRain => '雨';

  @override
  String get wmoSnow => '雪';

  @override
  String get wmoThunder => '雷雨';

  @override
  String get wmoUnknown => '不明';

  @override
  String get notifRepeatTitle => '↩ ループ';

  @override
  String get notifFallbackBody => 'ループが戻る時間です';

  @override
  String get notifConfirm => '確認';

  @override
  String get notifChannelName => 'ループ';

  @override
  String get notifChannelDesc => '戻ってきたループを知らせるよ';
}
