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
  String get testFireDesc => '5秒后通知 · 20秒后闹钟';

  @override
  String get testFireSoon => '即将触发：通知（5秒）· 闹钟（20秒）';

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
}
