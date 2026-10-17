// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get emptyTimeline =>
      'No logs yet.\nTap + to write your first thought.';

  @override
  String get emptyAtDate =>
      'No logs around that time.\nPick another date above, or go back to latest.';

  @override
  String get jumpToDate => 'Jump to date';

  @override
  String get backToLatest => 'Back to latest';

  @override
  String get searchHint => 'Search content & places';

  @override
  String get searchEmpty => 'No results';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortRecent => 'Newest';

  @override
  String get editContent => 'Edit';

  @override
  String get changeTime => 'Change time';

  @override
  String get deleteAction => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get stop => 'Stop';

  @override
  String get deleteLogTitle => 'Delete log';

  @override
  String get deleteLogMessage => 'Delete this log? Forked logs will stay.';

  @override
  String get stopRepeatTitle => 'Stop loop';

  @override
  String stopRepeatMessage(String rule) {
    return 'Stop the $rule loop?\nUpcoming fires are cancelled — logs already created stay.';
  }

  @override
  String get composeHint => 'On your mind…';

  @override
  String forkOf(String time) {
    return '↩ Continuing from $time';
  }

  @override
  String get saveLog => 'Save log';

  @override
  String get attachPhoto => 'Attach photos';

  @override
  String get reserveAlarm => 'Set reminder';

  @override
  String get alarmTitle => '⏰ Reminder';

  @override
  String get tapToChangeTime => 'Tap to change date & time';

  @override
  String get in10min => 'In 10 min';

  @override
  String get in1hour => 'In 1 hour';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get nextWeek => 'Next week';

  @override
  String get in1month => 'In a month';

  @override
  String loopCurveHint(int n, String interval) {
    return 'Forgetting-curve review #$n · suggested $interval';
  }

  @override
  String get custom => 'Custom';

  @override
  String get notifyAtThisTime => 'Notify me at this time';

  @override
  String get repeatTitle => '↩ Loop';

  @override
  String get repeatDesc =>
      'With repeat on, a continuation of this log is created automatically on every fire. Stop anytime.';

  @override
  String get preset10min => '10 min';

  @override
  String get preset30min => '30 min';

  @override
  String get preset1hour => '1 hour';

  @override
  String get preset3hours => '3 hours';

  @override
  String get preset6hours => '6 hours';

  @override
  String get presetDaily => 'Daily';

  @override
  String get fireTime => 'Fire time';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitHours => 'hr';

  @override
  String nextFire(String time, String rule) {
    return 'Next $time · then $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return 'Every $n min';
  }

  @override
  String ruleEveryHours(int n) {
    return 'Every $n hr';
  }

  @override
  String ruleDaily(String time) {
    return 'Daily at $time';
  }

  @override
  String ruleWeekday(String time) {
    return 'Weekdays at $time';
  }

  @override
  String get presetWeekday => 'Weekdays';

  @override
  String get upcomingTitle => 'Upcoming · 7 days';

  @override
  String get upcomingEmpty => 'No loops scheduled this week';

  @override
  String get noContent => '(no content)';

  @override
  String continuedFrom(String time) {
    return '↩ Continued from $time';
  }

  @override
  String get locationRecorded => 'Location saved';

  @override
  String repeatNth(int n) {
    return 'Loop #$n';
  }

  @override
  String get repeatEnded => 'Loop ended';

  @override
  String get loopAction => '↩ Loop';

  @override
  String get loopWriteNow => 'Write now';

  @override
  String get loopAgain => 'Remind me';

  @override
  String get loopModeOnce => 'Once';

  @override
  String get loopModeRepeat => 'Repeat';

  @override
  String loopNextShort(String time) {
    return 'Next $time';
  }

  @override
  String loopFireCount(int n) {
    return 'Fired $n times so far';
  }

  @override
  String get loopJump => 'Go to original';

  @override
  String get loopStop => 'Stop loop';

  @override
  String get loopEndedInfo => 'This loop has ended';

  @override
  String get loopViewAction => 'View loop chain';

  @override
  String get loopWriteAction => 'Write';

  @override
  String get loopViewBack => 'Back to timeline';

  @override
  String get locationCapture => 'Location';

  @override
  String get locationCaptureDesc =>
      'Automatically attach place & weather to logs';

  @override
  String get loopArm => 'Set loop';

  @override
  String get emptyWriteHint => 'Empty · tap to write';

  @override
  String get openInYoutube => 'Open in YouTube';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsData => 'Data';

  @override
  String get defaultBrowser => 'Default browser';

  @override
  String get defaultBrowserDesc => 'Web links will open in this browser';

  @override
  String get systemDefault => 'System default';

  @override
  String get browserEmpty => 'No browsers installed';

  @override
  String get exportLogs => 'Export everything';

  @override
  String get exportAllDesc => 'Logs, photos & repeats as one .looplog file';

  @override
  String get exporting => 'Exporting…';

  @override
  String get exportDone => 'Exported';

  @override
  String get exportCancel => 'Export canceled';

  @override
  String get exportFail => 'Couldn\'t save the file';

  @override
  String get importLogs => 'Import';

  @override
  String get importAllDesc =>
      'Restore from a .looplog file · existing logs are skipped';

  @override
  String get importConfirmMessage =>
      'Adds logs from the file and keeps what\'s already here.\nLogs with the same ID are skipped, so re-importing the same file never duplicates.';

  @override
  String get importing => 'Importing…';

  @override
  String importDone(int logs, int repeats) {
    return 'Imported $logs logs · $repeats repeats';
  }

  @override
  String get importCancel => 'Import canceled';

  @override
  String get importEmpty => 'Nothing to import';

  @override
  String get importFail => 'Couldn\'t read the .looplog file';

  @override
  String get howNotify => 'How should I alert you?';

  @override
  String get modeNotif => 'Notification';

  @override
  String get modeNotifDesc => 'Pings once and stops. Default — a gentle nudge';

  @override
  String get modeAlarm => 'Alarm';

  @override
  String get modeAlarmDesc =>
      'Rings until dismissed, even in silent. For must-keep loops';

  @override
  String get snoozeAction => 'Again in 10 min';

  @override
  String get notifAlarmChannelName => 'Loop alarms';

  @override
  String get testFire => 'Preview a fire';

  @override
  String get testFireDesc => 'Notification in 5s · alarm in 20s';

  @override
  String get testFireSoon => 'Firing soon: notification (5s) · alarm (20s)';

  @override
  String get detailOriginal => 'Created';

  @override
  String get detailPlace => 'Place';

  @override
  String get detailWeather => 'Weather';

  @override
  String get detailPhotos => 'Photos';

  @override
  String photoCount(int n) {
    return '$n photos';
  }

  @override
  String get detailNoContext => 'No location, weather, or photos';

  @override
  String get detailRecord => 'Info';

  @override
  String get unknown => 'Unknown';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get wmoClear => 'Clear';

  @override
  String get wmoPartly => 'Partly cloudy';

  @override
  String get wmoCloudy => 'Cloudy';

  @override
  String get wmoFog => 'Fog';

  @override
  String get wmoDrizzle => 'Drizzle';

  @override
  String get wmoRain => 'Rain';

  @override
  String get wmoSnow => 'Snow';

  @override
  String get wmoThunder => 'Thunderstorm';

  @override
  String get wmoUnknown => 'Unknown';

  @override
  String get notifRepeatTitle => '↩ Loop';

  @override
  String get notifFallbackBody => 'Time to revisit';

  @override
  String get notifConfirm => 'OK';

  @override
  String get notifChannelName => 'Loops';

  @override
  String get notifChannelDesc => 'Reminds you when a loop comes back';
}
