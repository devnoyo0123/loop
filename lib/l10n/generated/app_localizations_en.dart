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
  String get pastTimeHint =>
      'That time has already passed — pick a time in the future';

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
  String get recommended => 'Suggested';

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
  String get presetMonthly => 'Monthly';

  @override
  String get presetYearly => 'Yearly';

  @override
  String get presetLadder => 'Ladder';

  @override
  String get ruleLadder => 'Forgetting-curve ladder';

  @override
  String get curveSteps =>
      '10 min → 1 hr → tonight → tomorrow → 1 wk → 1 mo · 6 fires';

  @override
  String get fireDate => 'Fire date';

  @override
  String get unitMonths => 'mo';

  @override
  String get unitYears => 'yr';

  @override
  String ruleMonthly(int day, String time) {
    return 'Monthly on day $day at $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return 'Every $n months on day $day at $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return 'Yearly on $date at $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return 'Every $n years on $date at $time';
  }

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
  String get mineOnlyTitle => 'My loops only';

  @override
  String get mineOnlyBack => 'View all';

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
  String get testNotifTitle => 'Test fire · notification';

  @override
  String get overlayPermTitle => 'Show alarm over other apps';

  @override
  String get overlayPermBody =>
      'To ring in full screen even while you\'re using another app, Loop needs the \"Display over other apps\" permission. Please allow it on the next screen.';

  @override
  String get overlayPermOpen => 'Open settings';

  @override
  String get testFireDesc => 'Notification in 5s · alarm in 20s';

  @override
  String get testFireSoon => 'Firing soon: notification (5s) · alarm (20s)';

  @override
  String get fullScreenHint =>
      'To show alarms full-screen, allow \'Alarms & reminders\'.';

  @override
  String get openSettings => 'Open settings';

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

  @override
  String get statsTitle => 'Your flow';

  @override
  String get statsEmpty =>
      'Your flow appears as you write.\nTap + to leave your first thought.';

  @override
  String statsReturnsLine(int n) {
    return 'Your thoughts came back to you $n times';
  }

  @override
  String get statsReturnsZero =>
      'Set a loop, and your thoughts will come back to you';

  @override
  String get statsTotalLogs => 'Logs';

  @override
  String get statsActiveDays => 'Days written';

  @override
  String get statsStreakNow => 'Current streak';

  @override
  String get statsStreakBest => 'Best streak';

  @override
  String statsDays(int n) {
    return '$n days';
  }

  @override
  String get statsHeatmapCaption => 'Last 15 weeks';

  @override
  String get statsHeatmapLess => 'Less';

  @override
  String get statsHeatmapMore => 'More';

  @override
  String get statsTopChains => 'Longest chains';

  @override
  String statsChainLinkings(int n) {
    return '$n continuations';
  }

  @override
  String get starterQuickTitle => '10-minute loop';

  @override
  String get starterQuickDesc => 'Write now — it comes back in 10 minutes';

  @override
  String get starterDailyTitle => 'One line every night';

  @override
  String get starterDailyDesc => 'Your day returns every night at 9';

  @override
  String get starterWeekTitle => 'One-week loop';

  @override
  String get starterWeekDesc => 'Write now, revisit it in a week';

  @override
  String starterInMinutes(int n) {
    return 'in $n min';
  }

  @override
  String starterEveryNight(String time) {
    return 'every night at $time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ Comes back $when';
  }

  @override
  String get onThisDayTitle => 'Your past self';

  @override
  String get onThisDayWeekAgo => 'a week ago';

  @override
  String get onThisDayMonthAgo => 'a month ago';

  @override
  String get onThisDayYearAgo => 'a year ago';

  @override
  String get onThisDayChannelName => 'Your past self';

  @override
  String get onThisDayChannelDesc =>
      'Revisits you with a past log every morning';

  @override
  String get onThisDaySetting => 'Past self morning note';

  @override
  String get onThisDaySettingDesc =>
      'A log from a week, month, or year ago returns at 9 AM';

  @override
  String get shareStats => 'Share';

  @override
  String get shareCardTagline => 'A journal where thoughts come back to you';

  @override
  String get shareFail => 'Couldn\'t create the share card';

  @override
  String get loopAttachHeadLabel =>
      '↩ Continues from the latest entry in this chain';

  @override
  String get loopAttachHereLabel => '↩ Branches from this entry';

  @override
  String get loopAttachHereAction => 'From here';

  @override
  String get loopAttachHeadAction => 'At chain\'s end';

  @override
  String get todayEvening => 'Tonight';

  @override
  String get dayEndSetting => 'Day wrap-up time';

  @override
  String get dayEndSettingDesc =>
      'Used by the \"Tonight\" chip and the nightly loop';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get takeVideo => 'Record video';

  @override
  String get videoAttached => 'Video attached';

  @override
  String get videoOpenRow => 'Video · tap to play';

  @override
  String get videoPlayFail => 'Couldn\'t find an app to play this video';

  @override
  String get videoTooLong => 'Videos can be up to 1 minute';

  @override
  String get shareChainAction => 'Share Loop';

  @override
  String get shareChainTitle => 'Share Loop';

  @override
  String get shareCountLogs => 'Logs';

  @override
  String get shareCountPhotos => 'Photos';

  @override
  String get shareCountVideos => 'Videos';

  @override
  String get shareCountRepeats => 'Loops';

  @override
  String get shareNameLabel => 'Display name';

  @override
  String get shareNameHint => 'The name the other person sees';

  @override
  String get shareStripLocation => 'Send without location';

  @override
  String get shareStripLocationDesc => 'Places & coordinates are left out';

  @override
  String get shareStripMedia => 'Send without photos & videos';

  @override
  String get shareStripMediaDesc => 'Text logs only';

  @override
  String get shareSendNearby => 'Send to a nearby device';

  @override
  String get shareExportFile => 'Export as file (.looplog)';

  @override
  String get shareSearching => 'Looking for nearby devices…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · connected';
  }

  @override
  String get shareSending => 'Sending';

  @override
  String get shareHintOffline =>
      'No internet or server involved — usually done in seconds.';

  @override
  String get shareSent => 'Sent';

  @override
  String get shareSendFail => 'Couldn\'t send';

  @override
  String get sharePermTitle => 'Nearby devices permission';

  @override
  String get sharePermBody =>
      'Finding nearby devices needs location & nearby-devices permission. Data goes device-to-device directly and is never stored anywhere.';

  @override
  String receiveFrom(String name) {
    return '$name sent you a chain';
  }

  @override
  String get receiveTitle => 'Import chain';

  @override
  String get receiveBadgeNoLocation => 'Sent without location';

  @override
  String get receiveQuestion => 'How do you want it?';

  @override
  String get receiveOnly => 'Import records only';

  @override
  String get receiveOnlyDesc =>
      'The chain lands on your timeline as-is. No reminders.';

  @override
  String get receiveAdopt => 'Adopt as a living loop';

  @override
  String get receiveAdoptDesc =>
      'The repeat fires with my reminders from now on, on my schedule.';

  @override
  String get receiveImport => 'Import';

  @override
  String get receiveDecline => 'Decline';

  @override
  String get receiveDone => 'Imported';

  @override
  String receiveDoneDesc(int count) {
    return '$count records are now on your timeline.';
  }

  @override
  String get receiveAdoptedTitle => '🔁 Adopted as a living loop';

  @override
  String get receiveAdoptedDesc =>
      'The history stays untouched — reminders now follow my schedule.';

  @override
  String receiveNextFire(String time) {
    return 'Next fire $time';
  }

  @override
  String get viewChainAction => 'View chain';

  @override
  String get laterAction => 'Later';

  @override
  String get receiveFail => 'Couldn\'t import';

  @override
  String get shareTapToSend => 'Tap to send';

  @override
  String get shareWaitingReceiver =>
      'On the other phone, turn on Settings › Receive from nearby devices and it shows up here';

  @override
  String get shareNotFound => 'Couldn\'t find a nearby device';

  @override
  String get shareRetry => 'Search again';

  @override
  String get receiveSetting => 'Receive from nearby devices';

  @override
  String get receiveSettingDesc =>
      'While the app is open, nearby devices can see your display name';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return 'About ${seconds}s left';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return 'About $minutes min left';
  }

  @override
  String get shareSlowHint =>
      'Sending slowly over Bluetooth. Cancel, turn on Wi-Fi on both phones, and send again — it\'s much faster.';

  @override
  String get shareStalled =>
      'No progress for a while, so it stopped. Keep the phones close and send again.';

  @override
  String receiveIncoming(String name) {
    return '$name is sending…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return 'Transfer from $name was interrupted';
  }

  @override
  String get shareCleanTitle => 'Clear sharing temp files';

  @override
  String shareCleanDesc(String size) {
    return '$size · unfinished and temporary transfer files';
  }

  @override
  String get shareCleanEmpty => 'Nothing to clear';

  @override
  String get shareCleanConfirm => 'Files in an active transfer are kept.';

  @override
  String get shareCleanAction => 'Clear';

  @override
  String shareCleanDone(String size) {
    return 'Cleared $size';
  }

  @override
  String get alarmPermTitle => 'Allow alarms to show on screen';

  @override
  String get alarmPermBody =>
      'Right now an alarm only makes a sound and doesn\'t appear on screen. Allow \'full-screen notifications\' so alarms show over the lock screen, even when the screen is off.';

  @override
  String get settingsAppInfo => 'About';

  @override
  String get guideOpen => 'How to use Loop';

  @override
  String get guideOpenDesc => 'Every feature, with pictures';

  @override
  String get guideTitle => 'How to use Loop';

  @override
  String get guideIntroTitle => 'What Loop is';

  @override
  String get guideIntroBody =>
      'A journal that brings your past thoughts back. Write what\'s on your mind, set a loop, and the log comes back to you when you chose.';

  @override
  String get guideWriteTitle => 'Write a log';

  @override
  String get guideWriteBody =>
      'Tap + at the bottom right to write what\'s on your mind. Attach photos or a video up to 1 minute. Place and weather are saved automatically (turn off in Settings › Location).';

  @override
  String get guideLoopTitle => 'Set a loop — bring it back';

  @override
  String get guideLoopBody =>
      'Log ⋯ › ↩ Loop. \'Once\' brings it back one time (a time based on the forgetting curve is suggested). A notification nudges once; an alarm rings until you dismiss it.';

  @override
  String get guideRepeatTitle => 'Repeating loops';

  @override
  String get guideRepeatBody =>
      'Choose \'Repeat\' in the loop sheet to bring it back every 10 minutes, daily, on weekdays, monthly and more. Each time, a spot to continue the log appears. To end it: ⋯ › Stop loop.';

  @override
  String get guideFlowTitle => 'Continue and view the chain';

  @override
  String get guideFlowBody =>
      'Write on a log that came back and it joins a chain with a purple line. Use ⋯ › View loop chain to see it from the first log in one line. Tap \'Back to timeline\' at the top to return.';

  @override
  String get guideUpcomingTitle => 'Upcoming 7 days';

  @override
  String get guideUpcomingBody =>
      'Tap the first icon at the top (Upcoming · 7 days) to see every loop coming back in the next 7 days.';

  @override
  String get guideRhythmTitle => 'Morning and evening rhythm';

  @override
  String get guideRhythmBody =>
      'Past self morning note: at 9 AM, logs from a week, a month and a year ago today. Day wrap-up time: the \'Tonight\' chip and nightly loops use this time. Change both in Settings.';

  @override
  String get guideShareTitle => 'Share Loop — to the person next to you';

  @override
  String get guideShareBody =>
      'Log ⋯ › Share Loop › Send to a nearby device. It goes straight to the phone next to you, with no internet or server. The receiver turns on Settings › Receive from nearby devices. Location is left out by default.';

  @override
  String get guideBackupTitle => 'Backup — export and import';

  @override
  String get guideBackupBody =>
      'Settings › Export everything saves logs, photos, videos and repeats into one .looplog file. On a new phone, use Settings › Import — logs you already have are skipped. Export now and then.';

  @override
  String get guideStatsTitle => 'Your flow, search and dates';

  @override
  String get guideStatsBody =>
      'Use the icons at the top. Search finds content and places, Jump to date opens that day, and Your flow shows how often thoughts came back, your streaks and your longest chains.';

  @override
  String get guideAlarmTitle => 'Let alarms show on screen';

  @override
  String get guideAlarmBody =>
      'For alarms to appear over the lock screen, allow \'full-screen notifications\'. When Loop asks, tap Open settings and turn Loop on. Without it, alarms only make a sound. Try Settings › Preview a fire.';

  @override
  String get coachSkip => 'Skip';

  @override
  String get coachGotIt => 'Got it';

  @override
  String get coachWriteTitle => 'Write what\'s on your mind right now';

  @override
  String get coachWriteBody =>
      'No titles, no folders. Just put the thought down as it is.';

  @override
  String get coachReserveTitle => 'Choose when to see it again';

  @override
  String get coachReserveBody =>
      'In 10 minutes, tonight, next week… pick when this thought should come back.';

  @override
  String get coachSaveTitle => 'Save, and your loop is set';

  @override
  String get coachSaveBody =>
      'This thought will come back at the time you chose.';

  @override
  String get coachReturnTitle => 'When it returns, keep writing';

  @override
  String get coachReturnBody =>
      'When the reminder arrives, tap \'Write now\'. Your thoughts link up into a chain.';

  @override
  String get coachArmTitle => 'You can loop past logs too';

  @override
  String get coachArmBody =>
      'Tap \'Set loop\' and this thought will come back to you.';

  @override
  String get coachReplay => 'Replay the tour';

  @override
  String get coachReplayDesc => 'Walk through making your first loop again';

  @override
  String get pcLinkSettingTitle => 'PC connection';

  @override
  String get pcLinkSettingOff => 'Not connected';

  @override
  String get pcLinkSettingConnected => 'Connected';

  @override
  String get pcLinkTitle => 'PC connection';

  @override
  String get pcLinkIntro =>
      'Lets Claude Code on your Mac search your journal. Once connected, the link stays on for 1 hour after the last use — even with the screen off or in other apps.';

  @override
  String get pcLinkHostLabel => 'PC address (IP)';

  @override
  String get pcLinkHostHint => 'e.g. 192.168.0.8';

  @override
  String get pcLinkConnect => 'Connect';

  @override
  String get pcLinkConnecting => 'Connecting…';

  @override
  String get pcLinkCodeTitle => 'Pairing code';

  @override
  String get pcLinkCodeBody =>
      'Ask Claude on the PC to show the connection code, then enter the 8 digits it gives you.';

  @override
  String get pcLinkCodeHint => '8 digits';

  @override
  String get pcLinkCodeSubmit => 'Submit';

  @override
  String get pcLinkConnectedTitle => 'Connected';

  @override
  String get pcLinkConnectedBody =>
      'Claude can now search your journal. The link stays on for 1 hour after the last use.';

  @override
  String get pcLinkQueries => 'Queries answered';

  @override
  String get pcLinkDisconnect => 'Disconnect';

  @override
  String get pcLinkUnpair => 'Unpair';

  @override
  String get pcLinkErrRefused =>
      'Can\'t connect — check the PC address and that Claude Code is running.';

  @override
  String get pcLinkErrTimeout =>
      'No response — check that you\'re on the same Wi-Fi as the PC.';

  @override
  String get pcLinkErrBadHost => 'The address format looks wrong.';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'Wrong code ($left attempts left)';
  }

  @override
  String get pcLinkErrTooMany => 'Too many attempts — try again in a moment.';

  @override
  String get pcLinkErrBusy => 'Another phone is already connected.';

  @override
  String get pcLinkErrCodeExpired =>
      'Code expired — get a new one from Claude and reconnect.';

  @override
  String get pcLinkErrDisconnected => 'Connection lost.';

  @override
  String get pcLinkReconnecting => 'Connection lost — reconnecting…';

  @override
  String get guidePcTitle => 'Search from your computer with Claude';

  @override
  String get guidePcBody =>
      'Setup — install the Loop plugin in Claude Code on your computer. Type these two lines in Claude Code: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. Then just tell Claude \"connect my phone\" — it gives you the address and an 8-digit code. ① In Settings → PC connection, enter that address and connect ② enter the code and you\'re connected — it reconnects automatically from then on. Logs stay on your phone; only queries and results travel over your Wi-Fi.';
}
