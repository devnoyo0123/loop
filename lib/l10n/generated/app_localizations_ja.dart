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
  String get pastTimeHint => 'すでに過ぎた時刻です — 未来の時刻を選び直してください';

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
  String get recommended => 'おすすめ';

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
  String get presetMonthly => '毎月';

  @override
  String get presetYearly => '毎年';

  @override
  String get presetLadder => 'ラダー';

  @override
  String get ruleLadder => '忘却曲線ラダー';

  @override
  String get curveSteps => '10分 → 1時間 → 今夜 → 明日 → 1週 → 1か月 · 計6回';

  @override
  String get fireDate => '発火日';

  @override
  String get unitMonths => 'か月';

  @override
  String get unitYears => '年';

  @override
  String ruleMonthly(int day, String time) {
    return '毎月$day日 $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return '$nか月ごとに$day日 $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return '毎年$date $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return '$n年ごとに$date $time';
  }

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
  String get mineOnlyTitle => '自分のループだけ';

  @override
  String get mineOnlyBack => 'すべて表示';

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
  String get testNotifTitle => '発火テスト · 通知';

  @override
  String get overlayPermTitle => '他のアプリの上にアラームを表示';

  @override
  String get overlayPermBody =>
      '他のアプリ使用中でもアラームを全画面で鳴らすには「他のアプリの上に重ねて表示」権限が必要です。次の画面で許可してください。';

  @override
  String get overlayPermOpen => '設定を開く';

  @override
  String get testFireDesc => '5秒後に通知 · 20秒後にアラーム';

  @override
  String get testFireSoon => 'まもなく発火：通知（5秒）· アラーム（20秒）';

  @override
  String get fullScreenHint => 'アラームを全画面で出すには「アラームとリマインダー」を許可してね。';

  @override
  String get openSettings => '設定を開く';

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

  @override
  String get statsTitle => '記録の流れ';

  @override
  String get statsEmpty => '記録が積もると流れが見えてきます。\n+で最初の思考を残してみよう。';

  @override
  String statsReturnsLine(int n) {
    return '思考が$n回、また戻ってきました';
  }

  @override
  String get statsReturnsZero => 'ループを設定すると、思考がまた戻ってきます';

  @override
  String get statsTotalLogs => '書いた記録';

  @override
  String get statsActiveDays => '記録した日';

  @override
  String get statsStreakNow => '今の連続';

  @override
  String get statsStreakBest => '最長連続';

  @override
  String statsDays(int n) {
    return '$n日';
  }

  @override
  String get statsHeatmapCaption => '直近15週';

  @override
  String get statsHeatmapLess => '少ない';

  @override
  String get statsHeatmapMore => '多い';

  @override
  String get statsTopChains => 'いちばんつながった鎖';

  @override
  String statsChainLinkings(int n) {
    return '$n回つながり';
  }

  @override
  String get starterQuickTitle => '10分ループ';

  @override
  String get starterQuickDesc => '今書くと10分後にまた戻ってきます';

  @override
  String get starterDailyTitle => '毎晩ひとこと';

  @override
  String get starterDailyDesc => '毎晩9時に今日が戻ってきます';

  @override
  String get starterWeekTitle => '1週間ループ';

  @override
  String get starterWeekDesc => '今書いて1週間後に振り返ります';

  @override
  String starterInMinutes(int n) {
    return '$n分後';
  }

  @override
  String starterEveryNight(String time) {
    return '毎晩$time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ $whenまた戻ってきます';
  }

  @override
  String get onThisDayTitle => 'あの日の自分';

  @override
  String get onThisDayWeekAgo => '1週間前の今日';

  @override
  String get onThisDayMonthAgo => '1か月前の今日';

  @override
  String get onThisDayYearAgo => '1年前の今日';

  @override
  String get onThisDayChannelName => 'あの日の自分';

  @override
  String get onThisDayChannelDesc => '過去の記録を毎朝もう一度聞かせます';

  @override
  String get onThisDaySetting => 'あの日の自分 朝の通知';

  @override
  String get onThisDaySettingDesc => '1週間・1か月・1年前の今日の記録を朝9時に届けます';

  @override
  String get shareStats => '共有';

  @override
  String get shareCardTagline => '流れた思考がまた戻ってくる記録';

  @override
  String get shareFail => '共有カードを作成できませんでした';

  @override
  String get loopAttachHeadLabel => '↩ 鎖の最後の記録からつながります';

  @override
  String get loopAttachHereLabel => '↩ この記録から分岐します';

  @override
  String get loopAttachHereAction => 'ここから';

  @override
  String get loopAttachHeadAction => '鎖の終点から';

  @override
  String get todayEvening => '今夜';

  @override
  String get dayEndSetting => '一日の締め時刻';

  @override
  String get dayEndSettingDesc => '\"今夜\"チップと毎晩ループがこの時刻を使います';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get takeVideo => '動画を撮る';

  @override
  String get videoAttached => '動画を添付した';

  @override
  String get videoOpenRow => '動画 · タップで再生';

  @override
  String get videoPlayFail => '再生できるアプリが見つかりません';

  @override
  String get videoTooLong => '動画は1分以内で録画してください';

  @override
  String get shareChainAction => 'ループを共有';

  @override
  String get shareChainTitle => 'ループを共有';

  @override
  String get shareCountLogs => '記録';

  @override
  String get shareCountPhotos => '写真';

  @override
  String get shareCountVideos => '動画';

  @override
  String get shareCountRepeats => '繰り返し';

  @override
  String get shareNameLabel => '表示名';

  @override
  String get shareNameHint => '相手に見える名前です';

  @override
  String get shareStripLocation => '位置情報を抜いて送る';

  @override
  String get shareStripLocationDesc => '記録に残った場所・座標は除かれます';

  @override
  String get shareStripMedia => '写真・動画を抜いて送る';

  @override
  String get shareStripMediaDesc => 'テキスト記録だけ送ります';

  @override
  String get shareSendNearby => '近くのデバイスに送る';

  @override
  String get shareExportFile => 'ファイルに書き出す (.looplog)';

  @override
  String get shareSearching => '近くのデバイスを探しています…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · 接続済み';
  }

  @override
  String get shareSending => '送信中';

  @override
  String get shareHintOffline => 'インターネットもサーバーも使いません。ふつうは数十秒で終わります。';

  @override
  String get shareSent => '送りました';

  @override
  String get shareSendFail => '送れませんでした';

  @override
  String get sharePermTitle => '近くのデバイスの権限';

  @override
  String get sharePermBody =>
      '近くのデバイスを探すには位置情報・近くのデバイスの権限が必要です。データはデバイス間で直接やり取りされ、どこにも残りません。';

  @override
  String receiveFrom(String name) {
    return '$nameさんから届きました';
  }

  @override
  String get receiveTitle => 'チェーンを取り込む';

  @override
  String get receiveBadgeNoLocation => '位置情報なしで送信されました';

  @override
  String get receiveQuestion => 'どう取り込みますか？';

  @override
  String get receiveOnly => '記録だけ取り込む';

  @override
  String get receiveOnlyDesc => 'チェーンがそのままタイムラインに付きます。通知は鳴りません。';

  @override
  String get receiveAdopt => '生きたループとして引き継ぐ';

  @override
  String get receiveAdoptDesc => '繰り返しはこれから私のスケジュールで通知されます。';

  @override
  String get receiveImport => '取り込む';

  @override
  String get receiveDecline => '断る';

  @override
  String get receiveDone => '取り込みました';

  @override
  String receiveDoneDesc(int count) {
    return '$count件の記録がタイムラインにそのまま付きました。';
  }

  @override
  String get receiveAdoptedTitle => '🔁 生きたループとして引き継ぎ';

  @override
  String get receiveAdoptedDesc => '発火の履歴はそのまま、通知はこれから私のスケジュールで鳴ります。';

  @override
  String receiveNextFire(String time) {
    return '次の発火 $time';
  }

  @override
  String get viewChainAction => 'チェーンを見る';

  @override
  String get laterAction => 'あとで';

  @override
  String get receiveFail => '取り込めませんでした';

  @override
  String get shareTapToSend => 'タップして送る';

  @override
  String get shareWaitingReceiver =>
      '相手の端末で 設定 › 近くのデバイスから受け取る をオンにするとここに表示されます';

  @override
  String get shareNotFound => '近くのデバイスが見つかりませんでした';

  @override
  String get shareRetry => 'もう一度探す';

  @override
  String get receiveSetting => '近くのデバイスから受け取る';

  @override
  String get receiveSettingDesc => 'アプリを開いている間、近くのデバイスにあなたの表示名が見えます';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return '残り約$seconds秒';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return '残り約$minutes分';
  }

  @override
  String get shareSlowHint =>
      'Bluetoothでゆっくり送信中です。キャンセルして両方の端末でWi-Fiをオンにしてから送り直すと、ずっと速くなります。';

  @override
  String get shareStalled => 'しばらく進まなかったため停止しました。端末を近づけてもう一度送ってください。';

  @override
  String receiveIncoming(String name) {
    return '$nameさんが送信中…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return '$nameさんからの送信が中断されました';
  }

  @override
  String get shareCleanTitle => '共有の一時ファイルを削除';

  @override
  String shareCleanDesc(String size) {
    return '$size · 受信途中のファイルと送信用の一時ファイル';
  }

  @override
  String get shareCleanEmpty => '削除するファイルはありません';

  @override
  String get shareCleanConfirm => '送受信中のファイルは残します。';

  @override
  String get shareCleanAction => '削除';

  @override
  String shareCleanDone(String size) {
    return '$size を削除しました';
  }

  @override
  String get alarmPermTitle => 'アラームを画面に表示するには許可が必要です';

  @override
  String get alarmPermBody =>
      '今はアラームが鳴っても音だけで画面に表示されません。「全画面通知」を許可すると、画面が消えていてもロック画面の上にアラームが表示されます。';

  @override
  String get settingsAppInfo => 'アプリ情報';

  @override
  String get guideOpen => 'Loopの使い方';

  @override
  String get guideOpenDesc => 'すべての機能を画像で';

  @override
  String get guideTitle => 'Loopの使い方';

  @override
  String get guideIntroTitle => 'Loopとは';

  @override
  String get guideIntroBody =>
      '過ぎた考えをもう一度呼び戻す記録帳です。今の考えを書いてループをかけておくと、決めたときにその記録が戻ってきます。';

  @override
  String get guideWriteTitle => '記録を書く';

  @override
  String get guideWriteBody =>
      '右下の + をタップして今の考えを書きます。写真や1分以内の動画を添付でき、場所と天気は自動で残ります（設定 › 位置の記録でオフにできます）。';

  @override
  String get guideLoopTitle => 'ループをかける — もう一度戻す';

  @override
  String get guideLoopBody =>
      '記録の ⋯ › ↩ ループ。「1回」は決めた時刻に一度戻ってきます（忘却曲線に合わせた時刻をおすすめします）。通知は静かに一度、アラームは確認するまで鳴ります。';

  @override
  String get guideRepeatTitle => '繰り返しループ';

  @override
  String get guideRepeatBody =>
      'ループシートで「繰り返し」を選ぶと、10分ごと・毎日・平日・毎月などで戻り続けます。戻るたびに続きを書く場所ができます。やめるには ⋯ › ループを止める。';

  @override
  String get guideFlowTitle => '続きを書く・ループを見る';

  @override
  String get guideFlowBody =>
      '戻ってきた記録に続きを書くと、紫の線でつながったチェーンになります。⋯ › ループを見る で最初の記録から一列で見られます。上のボタンで全体に戻ります。';

  @override
  String get guideUpcomingTitle => '今後の7日間';

  @override
  String get guideUpcomingBody =>
      '上部の最初のアイコン（今後のループ · 7日）をタップすると、今日から7日間に戻ってくるループが一目でわかります。';

  @override
  String get guideRhythmTitle => '朝と夜のリズム';

  @override
  String get guideRhythmBody =>
      'あの日の自分 朝の通知：朝9時に1週間・1か月・1年前の今日の記録を届けます。一日の締め時刻：「今夜」チップと毎晩のループがこの時刻を使います。どちらも設定で変更できます。';

  @override
  String get guideShareTitle => 'ループを共有 — 隣の人へ';

  @override
  String get guideShareBody =>
      '記録の ⋯ › ループを共有 › 近くのデバイスに送る。インターネットやサーバーを通さず隣のスマホへ直接届きます。受け取る側は 設定 › 近くのデバイスから受け取る をオンに。位置は初期設定で除いて送ります。';

  @override
  String get guideBackupTitle => 'バックアップ — エクスポートと読み込み';

  @override
  String get guideBackupBody =>
      '設定 › すべてエクスポート で記録・写真・動画・繰り返しを .looplog ファイル1つに保存します。新しいスマホでは 設定 › 読み込む。すでにある記録はスキップされます。ときどきエクスポートしておきましょう。';

  @override
  String get guideStatsTitle => '記録の流れ・検索・日付へ移動';

  @override
  String get guideStatsBody =>
      '上部のアイコンで探せます。検索は内容・場所で、日付へ移動はその日へ。記録の流れでは戻ってきた回数、連続記録、いちばん長いチェーンが見られます。';

  @override
  String get guideAlarmTitle => 'アラームを画面に表示する';

  @override
  String get guideAlarmBody =>
      'アラームをロック画面の上に表示するには「全画面通知」の許可が必要です。案内が出たら 設定を開く › Loop をオン。オフのままだと音だけ鳴ります。設定 › 発火テスト で試せます。';

  @override
  String get coachSkip => 'スキップ';

  @override
  String get coachGotIt => 'OK';

  @override
  String get coachWriteTitle => 'いま頭に浮かんでいることを書いてみてください';

  @override
  String get coachWriteBody => 'タイトルもフォルダもいりません。思ったことをそのまま残してみてください。';

  @override
  String get coachReserveTitle => 'いつまた見るか決めてみてください';

  @override
  String get coachReserveBody => '10分後、今夜、1週間後…この思考がまた戻ってくる時を選んでください。';

  @override
  String get coachSaveTitle => '保存すればループ完成です';

  @override
  String get coachSaveBody => '決めた時間に、この思考がまた戻ってきます。';

  @override
  String get coachReturnTitle => '戻ってきたら、続きを書いてみてください';

  @override
  String get coachReturnBody =>
      '通知が来たら「今つづきを書く」をタップしてみてください。思考がチェーンのようにつながります。';

  @override
  String get coachArmTitle => '書いたログにもループをかけられます';

  @override
  String get coachArmBody => '「ループをかける」をタップすると、この思考がまた戻ってきます。';

  @override
  String get coachReplay => '使い方をもう一度';

  @override
  String get coachReplayDesc => '最初のループ作りの案内をもう一度表示';

  @override
  String get pcLinkSettingTitle => 'PC接続';

  @override
  String get pcLinkSettingOff => '未接続';

  @override
  String get pcLinkSettingConnected => '接続済み';

  @override
  String get pcLinkTitle => 'PC接続';

  @override
  String get pcLinkIntro =>
      'MacのClaude Codeが自分の記録を検索できるよう接続します。接続後は画面を消したり他のアプリを使っても、最後の利用から1時間つながったままです。';

  @override
  String get pcLinkHostLabel => 'PCのアドレス(IP)';

  @override
  String get pcLinkHostHint => '例: 192.168.0.8';

  @override
  String get pcLinkConnect => '接続';

  @override
  String get pcLinkConnecting => '接続中…';

  @override
  String get pcLinkCodeTitle => 'ペアリングコード';

  @override
  String get pcLinkCodeBody => 'PCのClaudeに「接続コードを見せて」と尋ね、表示された8桁を入力してください。';

  @override
  String get pcLinkCodeHint => '8桁の数字';

  @override
  String get pcLinkCodeSubmit => '確認';

  @override
  String get pcLinkConnectedTitle => '接続済み';

  @override
  String get pcLinkConnectedBody =>
      'Claudeが自分の記録を検索できるようになりました。最後の利用から1時間つながったままです。';

  @override
  String get pcLinkQueries => '応答した検索';

  @override
  String get pcLinkDisconnect => '切断';

  @override
  String get pcLinkUnpair => 'ペアリング解除';

  @override
  String get pcLinkErrRefused => '接続できません — PCのアドレスとClaude Codeの実行状態を確認してください。';

  @override
  String get pcLinkErrTimeout => '応答がありません — PCと同じWi-Fiか確認してください。';

  @override
  String get pcLinkErrBadHost => 'アドレスの形式が正しくありません。';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'コードが違います（あと$left回）';
  }

  @override
  String get pcLinkErrTooMany => '試行回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get pcLinkErrBusy => 'すでに別のスマホが接続されています。';

  @override
  String get pcLinkErrCodeExpired =>
      'コードの期限が切れました。Claudeで新しいコードを受け取り再接続してください。';

  @override
  String get pcLinkErrDisconnected => '接続が切れました。';

  @override
  String get pcLinkReconnecting => '接続が切れました。再接続しています…';

  @override
  String get guidePcTitle => 'PCのClaudeで検索';

  @override
  String get guidePcBody =>
      '準備 — パソコンのClaude CodeにLoopプラグインをインストールします。Claude Codeで次の2行を入力: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop。あとはClaudeに「スマホを接続して」と言えば、接続アドレスと8桁のコードを教えてくれます。① 設定 → PC接続 でそのアドレスを入力して接続 ② コードを入力すれば接続完了 — 以後は自動で再接続されます。記録はスマホに残ったまま、検索だけが同じWi-Fi内で行われます。';
}
