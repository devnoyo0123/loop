// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get emptyTimeline => '还没有记录。\n用 + 写下第一个想法吧。';

  @override
  String get emptyAtDate => '那天没有记录。\n在上方换一天，或回到最新。';

  @override
  String get jumpToDate => '跳转到日期';

  @override
  String get backToLatest => '回到最新';

  @override
  String get searchHint => '搜索内容、地点';

  @override
  String get searchEmpty => '没有搜索结果';

  @override
  String get sortRelevance => '按相关度';

  @override
  String get sortRecent => '按最新';

  @override
  String get editContent => '编辑内容';

  @override
  String get changeTime => '更改时间';

  @override
  String get deleteAction => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get stop => '停止';

  @override
  String get deleteLogTitle => '删除记录';

  @override
  String get deleteLogMessage => '要删除这条记录吗？续写的记录会保留。';

  @override
  String get stopRepeatTitle => '停止循环';

  @override
  String stopRepeatMessage(String rule) {
    return '要停止$rule的循环吗？\n之后的触发会取消，已创建的记录会保留。';
  }

  @override
  String get composeHint => '此刻的想法…';

  @override
  String forkOf(String time) {
    return '↩ 续写 $time 的记录';
  }

  @override
  String get saveLog => '留下记录';

  @override
  String get attachPhoto => '添加照片';

  @override
  String get reserveAlarm => '预约提醒';

  @override
  String get alarmTitle => '⏰ 预约提醒';

  @override
  String get tapToChangeTime => '点按更改日期时间';

  @override
  String get pastTimeHint => '该时间已经过去——请重新选择未来的时间';

  @override
  String get in10min => '10分钟后';

  @override
  String get in1hour => '1小时后';

  @override
  String get tomorrow => '明天';

  @override
  String get nextWeek => '下周';

  @override
  String get in1month => '1个月后';

  @override
  String loopCurveHint(int n, String interval) {
    return '遗忘曲线第 $n 次复习 · 推荐 $interval';
  }

  @override
  String get recommended => '推荐';

  @override
  String get custom => '自定义';

  @override
  String get notifyAtThisTime => '在这个时间提醒我';

  @override
  String get repeatTitle => '↩ 循环';

  @override
  String get repeatDesc => '开启重复后，每次触发都会自动创建这条记录的续写。随时可以停止。';

  @override
  String get preset10min => '10分';

  @override
  String get preset30min => '30分';

  @override
  String get preset1hour => '1小时';

  @override
  String get preset3hours => '3小时';

  @override
  String get preset6hours => '6小时';

  @override
  String get presetDaily => '每天';

  @override
  String get fireTime => '触发时间';

  @override
  String get unitMinutes => '分';

  @override
  String get unitHours => '小时';

  @override
  String nextFire(String time, String rule) {
    return '下次 $time · 之后 $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return '每$n分钟';
  }

  @override
  String ruleEveryHours(int n) {
    return '每$n小时';
  }

  @override
  String ruleDaily(String time) {
    return '每天 $time';
  }

  @override
  String ruleWeekday(String time) {
    return '工作日 $time';
  }

  @override
  String get presetWeekday => '工作日';

  @override
  String get presetMonthly => '每月';

  @override
  String get presetYearly => '每年';

  @override
  String get presetLadder => '阶梯';

  @override
  String get ruleLadder => '遗忘曲线阶梯';

  @override
  String get curveSteps => '10分钟 → 1小时 → 今晚 → 明天 → 1周 → 1个月 · 共6次';

  @override
  String get fireDate => '触发日期';

  @override
  String get unitMonths => '个月';

  @override
  String get unitYears => '年';

  @override
  String ruleMonthly(int day, String time) {
    return '每月$day日 $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return '每$n个月的$day日 $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return '每年$date $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return '每$n年的$date $time';
  }

  @override
  String get upcomingTitle => '即将到来的循环 · 7天';

  @override
  String get upcomingEmpty => '本周没有安排的循环';

  @override
  String get noContent => '(无内容)';

  @override
  String continuedFrom(String time) {
    return '↩ 接续自 $time';
  }

  @override
  String get locationRecorded => '已记录位置';

  @override
  String repeatNth(int n) {
    return '循环第$n次';
  }

  @override
  String get repeatEnded => '循环已结束';

  @override
  String get loopAction => '↩ 循环';

  @override
  String get loopWriteNow => '现在续写';

  @override
  String get loopAgain => '再次提醒我';

  @override
  String get loopModeOnce => '一次';

  @override
  String get loopModeRepeat => '重复';

  @override
  String loopNextShort(String time) {
    return '下次 $time';
  }

  @override
  String loopFireCount(int n) {
    return '到目前为止已循环$n次';
  }

  @override
  String get loopJump => '转到原记录';

  @override
  String get loopStop => '停止循环';

  @override
  String get loopEndedInfo => '这个循环已结束';

  @override
  String get loopViewAction => '查看循环';

  @override
  String get loopWriteAction => '写内容';

  @override
  String get loopViewBack => '返回时间线';

  @override
  String get mineOnlyTitle => '只看我的循环';

  @override
  String get mineOnlyBack => '查看全部';

  @override
  String get locationCapture => '位置记录';

  @override
  String get locationCaptureDesc => '自动在日志中记录地点和天气';

  @override
  String get loopArm => '设定循环';

  @override
  String get emptyWriteHint => '空白 · 点按填写';

  @override
  String get openInYoutube => '在 YouTube 打开';

  @override
  String get openInBrowser => '在浏览器打开';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsData => '数据';

  @override
  String get defaultBrowser => '默认浏览器';

  @override
  String get defaultBrowserDesc => '打开网页链接时使用此浏览器';

  @override
  String get systemDefault => '系统默认';

  @override
  String get browserEmpty => '没有已安装的浏览器';

  @override
  String get exportLogs => '全部导出';

  @override
  String get exportAllDesc => '记录、照片、重复规则打包成一个 .looplog 文件';

  @override
  String get exporting => '导出中…';

  @override
  String get exportDone => '导出完成';

  @override
  String get exportCancel => '已取消保存';

  @override
  String get exportFail => '无法保存文件';

  @override
  String get importLogs => '导入';

  @override
  String get importAllDesc => '从.looplog文件恢复 · 已有的日志会跳过';

  @override
  String get importConfirmMessage =>
      '保留现有日志，把文件中的日志加进来。\n相同ID的日志会跳过，所以重复导入同一个文件也不会产生重复。';

  @override
  String get importing => '导入中…';

  @override
  String importDone(int logs, int repeats) {
    return '已导入$logs条日志 · $repeats个重复';
  }

  @override
  String get importCancel => '已取消导入';

  @override
  String get importEmpty => '没有可导入的内容';

  @override
  String get importFail => '无法读取.looplog文件';

  @override
  String get howNotify => '怎么提醒你？';

  @override
  String get modeNotif => '通知';

  @override
  String get modeNotifDesc => '提醒一次就结束。默认 — 轻声提示';

  @override
  String get modeAlarm => '闹钟';

  @override
  String get modeAlarmDesc => '不关就一直响，静音也响。给必须守住的循环';

  @override
  String get snoozeAction => '10分钟后再响';

  @override
  String get notifAlarmChannelName => '循环闹钟';

  @override
  String get testFire => '触发体验';

  @override
  String get testNotifTitle => '触发测试 · 通知';

  @override
  String get overlayPermTitle => '在其他应用上层显示闹钟';

  @override
  String get overlayPermBody =>
      '要在使用其他应用时也以全屏响铃，Loop 需要\"显示在其他应用上层\"权限。请在下一个页面允许。';

  @override
  String get overlayPermOpen => '打开设置';

  @override
  String get testFireDesc => '5秒后通知 · 20秒后闹钟';

  @override
  String get testFireSoon => '即将触发：通知（5秒）· 闹钟（20秒）';

  @override
  String get fullScreenHint => '闹钟要全屏显示，需要允许\"闹钟和提醒\"。';

  @override
  String get openSettings => '打开设置';

  @override
  String get detailOriginal => '原始记录';

  @override
  String get detailPlace => '地点';

  @override
  String get detailWeather => '天气';

  @override
  String get detailPhotos => '照片';

  @override
  String photoCount(int n) {
    return '$n张';
  }

  @override
  String get detailNoContext => '无位置、天气、照片信息';

  @override
  String get detailRecord => '记录';

  @override
  String get unknown => '未知';

  @override
  String get yesterday => '昨天';

  @override
  String get wmoClear => '晴';

  @override
  String get wmoPartly => '少云';

  @override
  String get wmoCloudy => '阴';

  @override
  String get wmoFog => '雾';

  @override
  String get wmoDrizzle => '毛毛雨';

  @override
  String get wmoRain => '雨';

  @override
  String get wmoSnow => '雪';

  @override
  String get wmoThunder => '雷雨';

  @override
  String get wmoUnknown => '未知';

  @override
  String get notifRepeatTitle => '↩ 循环';

  @override
  String get notifFallbackBody => '到回到循环的时间了';

  @override
  String get notifConfirm => '知道了';

  @override
  String get notifChannelName => '循环';

  @override
  String get notifChannelDesc => '提醒你回来的循环';

  @override
  String get statsTitle => '记录轨迹';

  @override
  String get statsEmpty => '记录积累后，轨迹会在这里显现。\n点 + 留下你的第一个想法吧。';

  @override
  String statsReturnsLine(int n) {
    return '你的想法已经回来了$n次';
  }

  @override
  String get statsReturnsZero => '设置循环，想法就会回到你身边';

  @override
  String get statsTotalLogs => '写下的记录';

  @override
  String get statsActiveDays => '记录的天数';

  @override
  String get statsStreakNow => '当前连续';

  @override
  String get statsStreakBest => '最长连续';

  @override
  String statsDays(int n) {
    return '$n天';
  }

  @override
  String get statsHeatmapCaption => '最近15周';

  @override
  String get statsHeatmapLess => '少';

  @override
  String get statsHeatmapMore => '多';

  @override
  String get statsTopChains => '延续最多的链';

  @override
  String statsChainLinkings(int n) {
    return '延续$n次';
  }

  @override
  String get starterQuickTitle => '10分钟循环';

  @override
  String get starterQuickDesc => '现在写下，10分钟后它会回来';

  @override
  String get starterDailyTitle => '每晚一句';

  @override
  String get starterDailyDesc => '每晚9点，今天会回来';

  @override
  String get starterWeekTitle => '一周循环';

  @override
  String get starterWeekDesc => '现在写下，一周后回顾';

  @override
  String starterInMinutes(int n) {
    return '$n分钟后';
  }

  @override
  String starterEveryNight(String time) {
    return '每晚$time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ $when会再回来';
  }

  @override
  String get onThisDayTitle => '那时的你';

  @override
  String get onThisDayWeekAgo => '一周前的今天';

  @override
  String get onThisDayMonthAgo => '一个月前的今天';

  @override
  String get onThisDayYearAgo => '一年前的今天';

  @override
  String get onThisDayChannelName => '那时的你';

  @override
  String get onThisDayChannelDesc => '每天早上把过去的记录再读给你听';

  @override
  String get onThisDaySetting => '那时的你 早间提醒';

  @override
  String get onThisDaySettingDesc => '一周、一个月、一年前的今天，早上9点回来找你';

  @override
  String get shareStats => '分享';

  @override
  String get shareCardTagline => '让流逝的想法回来的记录';

  @override
  String get shareFail => '无法创建分享卡片';

  @override
  String get loopAttachHeadLabel => '↩ 从这条链的最新记录延续';

  @override
  String get loopAttachHereLabel => '↩ 从这条记录分叉';

  @override
  String get loopAttachHereAction => '从这里开始';

  @override
  String get loopAttachHeadAction => '回到链尾';

  @override
  String get todayEvening => '今晚';

  @override
  String get dayEndSetting => '一天收尾时间';

  @override
  String get dayEndSettingDesc => '\"今晚\"选项和每晚循环都会使用这个时间';

  @override
  String get takePhoto => '拍摄照片';

  @override
  String get takeVideo => '录制视频';

  @override
  String get videoAttached => '已附加视频';

  @override
  String get videoOpenRow => '视频 · 点按播放';

  @override
  String get videoPlayFail => '找不到可以播放视频的应用';

  @override
  String get videoTooLong => '视频最长只能录制 1 分钟';

  @override
  String get shareChainAction => '分享循环';

  @override
  String get shareChainTitle => '分享循环';

  @override
  String get shareCountLogs => '记录';

  @override
  String get shareCountPhotos => '照片';

  @override
  String get shareCountVideos => '视频';

  @override
  String get shareCountRepeats => '循环';

  @override
  String get shareNameLabel => '显示名称';

  @override
  String get shareNameHint => '对方看到的名字';

  @override
  String get shareStripLocation => '不含位置信息发送';

  @override
  String get shareStripLocationDesc => '记录中的地点和坐标不会发送';

  @override
  String get shareStripMedia => '不含照片·视频发送';

  @override
  String get shareStripMediaDesc => '只发送文字记录';

  @override
  String get shareSendNearby => '发送到附近设备';

  @override
  String get shareExportFile => '导出为文件 (.looplog)';

  @override
  String get shareSearching => '正在查找附近设备…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · 已连接';
  }

  @override
  String get shareSending => '发送中';

  @override
  String get shareHintOffline => '完全不经过互联网和服务器，通常几十秒完成。';

  @override
  String get shareSent => '已发送';

  @override
  String get shareSendFail => '发送失败';

  @override
  String get sharePermTitle => '附近设备权限';

  @override
  String get sharePermBody => '查找附近设备需要位置和附近设备权限。数据在设备之间直接传输，不会保存到任何地方。';

  @override
  String receiveFrom(String name) {
    return '$name 发来了一个链';
  }

  @override
  String get receiveTitle => '导入链';

  @override
  String get receiveBadgeNoLocation => '未包含位置信息';

  @override
  String get receiveQuestion => '要如何导入？';

  @override
  String get receiveOnly => '仅导入记录';

  @override
  String get receiveOnlyDesc => '链会原样贴到时间线上，不会提醒。';

  @override
  String get receiveAdopt => '作为活跃循环接续';

  @override
  String get receiveAdoptDesc => '循环从现在起按我的时间表提醒。';

  @override
  String get receiveImport => '导入';

  @override
  String get receiveDecline => '拒绝';

  @override
  String get receiveDone => '已导入';

  @override
  String receiveDoneDesc(int count) {
    return '$count 条记录已原样贴到时间线。';
  }

  @override
  String get receiveAdoptedTitle => '🔁 已作为活跃循环接续';

  @override
  String get receiveAdoptedDesc => '触发历史保持不变，提醒从现在起按我的时间表。';

  @override
  String receiveNextFire(String time) {
    return '下次触发 $time';
  }

  @override
  String get viewChainAction => '查看链';

  @override
  String get laterAction => '稍后';

  @override
  String get receiveFail => '导入失败';

  @override
  String get shareTapToSend => '点按发送';

  @override
  String get shareWaitingReceiver => '在对方手机上打开 设置 › 从附近设备接收，就会显示在这里';

  @override
  String get shareNotFound => '未找到附近设备';

  @override
  String get shareRetry => '重新搜索';

  @override
  String get receiveSetting => '从附近设备接收';

  @override
  String get receiveSettingDesc => '应用打开期间，附近设备可以看到你的显示名称';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return '约剩 $seconds 秒';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return '约剩 $minutes 分钟';
  }

  @override
  String get shareSlowHint => '正在通过蓝牙缓慢发送。取消后在两台手机上打开 Wi-Fi 再重新发送，会快很多。';

  @override
  String get shareStalled => '一段时间没有进展，已停止。请把两台手机靠近后重新发送。';

  @override
  String receiveIncoming(String name) {
    return '$name 正在发送…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return '来自 $name 的传输已中断';
  }

  @override
  String get shareCleanTitle => '清理分享临时文件';

  @override
  String shareCleanDesc(String size) {
    return '$size · 未完成的接收文件和传输临时文件';
  }

  @override
  String get shareCleanEmpty => '没有可清理的文件';

  @override
  String get shareCleanConfirm => '正在传输的文件会保留。';

  @override
  String get shareCleanAction => '清理';

  @override
  String shareCleanDone(String size) {
    return '已清理 $size';
  }

  @override
  String get alarmPermTitle => '需要权限才能在屏幕上显示闹钟';

  @override
  String get alarmPermBody =>
      '目前闹钟响起时只有声音，屏幕上不会显示。允许“全屏通知”后，即使屏幕关闭，闹钟也会直接显示在锁屏上。';

  @override
  String get settingsAppInfo => '应用信息';

  @override
  String get guideOpen => 'Loop 使用指南';

  @override
  String get guideOpenDesc => '用图片看懂所有功能';

  @override
  String get guideTitle => 'Loop 使用指南';

  @override
  String get guideIntroTitle => 'Loop 是什么';

  @override
  String get guideIntroBody =>
      '一本让过去的想法重新回来的记录本。写下此刻的想法并设置循环，到了你定的时间，这条记录会再次出现。';

  @override
  String get guideWriteTitle => '写记录';

  @override
  String get guideWriteBody =>
      '点按右下角的 + 写下此刻的想法。可以附上照片或 1 分钟以内的视频，地点和天气会自动保存（可在 设置 › 位置记录 中关闭）。';

  @override
  String get guideLoopTitle => '设置循环 — 让它回来';

  @override
  String get guideLoopBody =>
      '记录的 ⋯ › ↩ 循环。“一次”会在指定时间回来一次（会按遗忘曲线推荐时间）。通知安静地提醒一次，闹钟会一直响到你确认。';

  @override
  String get guideRepeatTitle => '重复循环';

  @override
  String get guideRepeatBody =>
      '在循环面板中选择“重复”，就会每 10 分钟、每天、工作日、每月等持续回来。每次回来都会留出续写的位置。要停止：⋯ › 停止循环。';

  @override
  String get guideFlowTitle => '续写与查看循环';

  @override
  String get guideFlowBody =>
      '在回来的记录上续写，会形成用紫色线连接的链。⋯ › 查看循环 可把从第一条到现在的记录排成一行。点按顶部按钮返回全部时间线。';

  @override
  String get guideUpcomingTitle => '未来 7 天';

  @override
  String get guideUpcomingBody =>
      '点按顶部第一个图标（即将到来的循环 · 7天），即可一眼看到今天起 7 天内会回来的循环。';

  @override
  String get guideRhythmTitle => '早晚节奏';

  @override
  String get guideRhythmBody =>
      '那时的你 早间提醒：早上 9 点带来 1 周、1 个月、1 年前今天的记录。一天收尾时间：“今晚”标签和每晚的循环都使用这个时间。两者都可在设置中修改。';

  @override
  String get guideShareTitle => '分享循环 — 给身边的人';

  @override
  String get guideShareBody =>
      '记录的 ⋯ › 分享循环 › 发送到附近设备。无需互联网和服务器，直接送到身边的手机。接收方请打开 设置 › 从附近设备接收。默认不发送位置。';

  @override
  String get guideBackupTitle => '备份 — 全部导出与导入';

  @override
  String get guideBackupBody =>
      '设置 › 全部导出 会把记录、照片、视频和重复设置保存成一个 .looplog 文件。在新手机上用 设置 › 导入，已有的记录会被跳过。记得不时导出一次。';

  @override
  String get guideStatsTitle => '记录轨迹 · 搜索 · 跳转到日期';

  @override
  String get guideStatsBody =>
      '用顶部图标查找：搜索按内容和地点查找，跳转到日期直接到那一天，记录轨迹显示想法回来的次数、连续记录和最长的链。';

  @override
  String get guideAlarmTitle => '让闹钟显示在屏幕上';

  @override
  String get guideAlarmBody =>
      '要让闹钟显示在锁屏之上，需要允许“全屏通知”。出现提示时点按 打开设置 › 开启 Loop。关闭时闹钟只会响铃。可以用 设置 › 触发体验 试一试。';

  @override
  String get coachSkip => '跳过';

  @override
  String get coachGotIt => '知道了';

  @override
  String get coachWriteTitle => '写下此刻脑海里浮现的想法';

  @override
  String get coachWriteBody => '不需要标题，也不需要文件夹。把脑中的想法原样记下来吧。';

  @override
  String get coachReserveTitle => '选择什么时候再看一次';

  @override
  String get coachReserveBody => '10 分钟后、今晚、一周后……选一个让这个想法再回来的时间吧。';

  @override
  String get coachSaveTitle => '保存后，循环就设好了';

  @override
  String get coachSaveBody => '到了你选的时间，这个想法会再回来。';

  @override
  String get coachReturnTitle => '想法回来时，接着写下去吧';

  @override
  String get coachReturnBody => '收到提醒后，点「现在续写」试试。想法会像链条一样连起来。';

  @override
  String get coachArmTitle => '已写的记录也能设定循环';

  @override
  String get coachArmBody => '点「设定循环」，这个想法就会再回来。';

  @override
  String get coachReplay => '重新查看教程';

  @override
  String get coachReplayDesc => '从头再看一遍创建第一个循环的引导';

  @override
  String get pcLinkSettingTitle => 'PC 连接';

  @override
  String get pcLinkSettingOff => '未连接';

  @override
  String get pcLinkSettingConnected => '已连接';

  @override
  String get pcLinkTitle => 'PC 连接';

  @override
  String get pcLinkIntro =>
      '连接后，Mac 上的 Claude Code 可以搜索你的记录。即使关闭屏幕或使用其他应用，最后一次使用后也会保持连接 1 小时。';

  @override
  String get pcLinkHostLabel => 'PC 地址(IP)';

  @override
  String get pcLinkHostHint => '例如：192.168.0.8';

  @override
  String get pcLinkConnect => '连接';

  @override
  String get pcLinkConnecting => '连接中…';

  @override
  String get pcLinkCodeTitle => '配对码';

  @override
  String get pcLinkCodeBody => '向 PC 上的 Claude 询问“显示连接代码”，然后输入显示的 8 位数字。';

  @override
  String get pcLinkCodeHint => '8 位数字';

  @override
  String get pcLinkCodeSubmit => '确认';

  @override
  String get pcLinkConnectedTitle => '已连接';

  @override
  String get pcLinkConnectedBody => 'Claude 现在可以搜索你的记录了。最后一次使用后会保持连接 1 小时。';

  @override
  String get pcLinkQueries => '已响应查询';

  @override
  String get pcLinkDisconnect => '断开';

  @override
  String get pcLinkUnpair => '取消配对';

  @override
  String get pcLinkErrRefused => '无法连接 — 请检查 PC 地址，并确认 Claude Code 正在运行。';

  @override
  String get pcLinkErrTimeout => '没有响应 — 请确认与 PC 在同一 Wi-Fi。';

  @override
  String get pcLinkErrBadHost => '地址格式不正确。';

  @override
  String pcLinkErrCodeWrong(int left) {
    return '代码不正确（还剩 $left 次）';
  }

  @override
  String get pcLinkErrTooMany => '尝试次数过多，请稍后再试。';

  @override
  String get pcLinkErrBusy => '已有其他手机连接。';

  @override
  String get pcLinkErrCodeExpired => '代码已过期 — 请从 Claude 获取新代码后重新连接。';

  @override
  String get pcLinkErrDisconnected => '连接已断开。';

  @override
  String get pcLinkReconnecting => '连接已断开，正在重新连接…';

  @override
  String get guidePcTitle => '在电脑上用 Claude 搜索';

  @override
  String get guidePcBody =>
      '准备 — 在电脑的 Claude Code 中安装 Loop 插件。在 Claude Code 中输入这两行：/plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop。然后只需对 Claude 说“连接我的手机”，它就会给你连接地址和 8 位配对码。① 在 设置 → PC连接 中输入该地址并连接 ② 输入配对码即完成连接 — 之后会自动重连。记录仍保存在手机上，只有查询和结果在局域网内传输。';
}
