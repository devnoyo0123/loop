// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get emptyTimeline =>
      'अभी कोई एंट्री नहीं.\nपहला विचार लिखने के लिए + दबाएँ.';

  @override
  String get emptyAtDate =>
      'उस समय कोई एंट्री नहीं.\nऊपर से तारीख बदलें या नवीनतम पर लौटें.';

  @override
  String get jumpToDate => 'तारीख पर जाएँ';

  @override
  String get backToLatest => 'नवीनतम पर लौटें';

  @override
  String get searchHint => 'टेक्स्ट और जगह खोजें';

  @override
  String get searchEmpty => 'कोई परिणाम नहीं';

  @override
  String get sortRelevance => 'प्रासंगिकता';

  @override
  String get sortRecent => 'नवीनतम';

  @override
  String get editContent => 'टेक्स्ट संपादित करें';

  @override
  String get changeTime => 'समय बदलें';

  @override
  String get deleteAction => 'हटाएँ';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get stop => 'रोकें';

  @override
  String get deleteLogTitle => 'एंट्री हटाएँ';

  @override
  String get deleteLogMessage =>
      'इस एंट्री को हटाएँ? जारी लिखी गई एंट्रियाँ बनी रहेंगी.';

  @override
  String get stopRepeatTitle => 'Loop रोकें';

  @override
  String stopRepeatMessage(String rule) {
    return '$rule लूप रोकना है?\nअगली बार से रद्द होगा, बनी बनाई एंट्रियाँ रहेंगी.';
  }

  @override
  String get composeHint => 'अभी का विचार…';

  @override
  String forkOf(String time) {
    return '↩ $time की एंट्री से जारी';
  }

  @override
  String get saveLog => 'एंट्री सहेजें';

  @override
  String get attachPhoto => 'फ़ोटो जोड़ें';

  @override
  String get reserveAlarm => 'रिमाइंडर सेट करें';

  @override
  String get alarmTitle => '⏰ रिमाइंडर';

  @override
  String get tapToChangeTime => 'तारीख और समय बदलने के लिए टैप करें';

  @override
  String get pastTimeHint => 'यह समय निकल चुका है — आने वाला समय चुनें';

  @override
  String get in10min => '10 मिनट बाद';

  @override
  String get in1hour => '1 घंटे बाद';

  @override
  String get tomorrow => 'कल';

  @override
  String get nextWeek => 'अगले हफ़्ते';

  @override
  String get in1month => '1 महीने बाद';

  @override
  String loopCurveHint(int n, String interval) {
    return 'फॉरगेटिंग कर्व समीक्षा #$n · सुझाया $interval';
  }

  @override
  String get recommended => 'सुझाव';

  @override
  String get custom => 'कस्टम';

  @override
  String get notifyAtThisTime => 'इस समय याद दिलाएँ';

  @override
  String get repeatTitle => '↩ Loop';

  @override
  String get repeatDesc =>
      'रिपीट चालू होने पर हर बार इस एंट्री की जारी एंट्री अपने आप बनती है. कभी भी रोक सकते हैं.';

  @override
  String get preset10min => '10 मिनट';

  @override
  String get preset30min => '30 मिनट';

  @override
  String get preset1hour => '1 घंटा';

  @override
  String get preset3hours => '3 घंटे';

  @override
  String get preset6hours => '6 घंटे';

  @override
  String get presetDaily => 'रोज़';

  @override
  String get fireTime => 'समय';

  @override
  String get unitMinutes => 'मिनट';

  @override
  String get unitHours => 'घंटे';

  @override
  String nextFire(String time, String rule) {
    return 'अगली बार $time · फिर $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return 'हर $n मिनट';
  }

  @override
  String ruleEveryHours(int n) {
    return 'हर $n घंटे';
  }

  @override
  String ruleDaily(String time) {
    return 'रोज़ $time';
  }

  @override
  String ruleWeekday(String time) {
    return 'हफ़्ते के दिनों में $time';
  }

  @override
  String get presetWeekday => 'हफ़्ते के दिन';

  @override
  String get presetMonthly => 'हर महीने';

  @override
  String get presetYearly => 'हर साल';

  @override
  String get presetLadder => 'सीढ़ी';

  @override
  String get ruleLadder => 'विस्मरण वक्र सीढ़ी';

  @override
  String get curveSteps =>
      '10 मिन → 1 घं → आज रात → कल → 1 सप्ताह → 1 महीना · कुल 6 बार';

  @override
  String get fireDate => 'तारीख';

  @override
  String get unitMonths => 'महीने';

  @override
  String get unitYears => 'साल';

  @override
  String ruleMonthly(int day, String time) {
    return 'हर महीने $day तारीख, $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return 'हर $n महीने में $day तारीख, $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return 'हर साल $date को $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return 'हर $n साल में $date को $time';
  }

  @override
  String get upcomingTitle => 'आने वाले लूप · 7 दिन';

  @override
  String get upcomingEmpty => 'इस हफ़्ते कोई लूप नहीं';

  @override
  String get noContent => '(कोई सामग्री नहीं)';

  @override
  String continuedFrom(String time) {
    return '↩ $time से जारी';
  }

  @override
  String get locationRecorded => 'स्थान सहेजा गया';

  @override
  String repeatNth(int n) {
    return 'लूप #$n';
  }

  @override
  String get repeatEnded => 'लूप समाप्त';

  @override
  String get loopAction => '↩ Loop';

  @override
  String get loopWriteNow => 'अभी जारी रखें';

  @override
  String get loopAgain => 'फिर याद दिलाएँ';

  @override
  String get loopModeOnce => 'एक बार';

  @override
  String get loopModeRepeat => 'रिपीट';

  @override
  String loopNextShort(String time) {
    return 'अगली बार $time';
  }

  @override
  String loopFireCount(int n) {
    return 'अब तक $n बार लौटा';
  }

  @override
  String get loopJump => 'मूल एंट्री पर जाएँ';

  @override
  String get loopStop => 'लूप रोकें';

  @override
  String get loopEndedInfo => 'यह लूप खत्म हो गया';

  @override
  String get loopViewAction => 'लूप श्रृंखला देखें';

  @override
  String get loopWriteAction => 'लिखें';

  @override
  String get loopViewBack => 'वापस जाएँ';

  @override
  String get mineOnlyTitle => 'केवल मेरे लूप';

  @override
  String get mineOnlyBack => 'सभी देखें';

  @override
  String get locationCapture => 'स्थान';

  @override
  String get locationCaptureDesc =>
      'एंट्री के साथ जगह और मौसम अपने आप रिकॉर्ड होगा';

  @override
  String get loopArm => 'लूप सेट करें';

  @override
  String get emptyWriteHint => 'खाली · लिखने के लिए टैप करें';

  @override
  String get openInYoutube => 'YouTube में खोलें';

  @override
  String get openInBrowser => 'ब्राउज़र में खोलें';

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsData => 'डेटा';

  @override
  String get defaultBrowser => 'डिफ़ॉल्ट ब्राउज़र';

  @override
  String get defaultBrowserDesc => 'लिंक इसी ब्राउज़र में खुलेंगे';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get browserEmpty => 'कोई ब्राउज़र इंस्टॉल नहीं है';

  @override
  String get exportLogs => 'सब एक्सपोर्ट करें';

  @override
  String get exportAllDesc => 'एंट्री·फ़ोटो·रिपीट सब एक .looplog फ़ाइल में';

  @override
  String get exporting => 'एक्सपोर्ट हो रहा है…';

  @override
  String get exportDone => 'एक्सपोर्ट हो गया';

  @override
  String get exportCancel => 'सेव रद्द किया';

  @override
  String get exportFail => 'फ़ाइल सेव नहीं हो सकी';

  @override
  String get importLogs => 'इंपोर्ट करें';

  @override
  String get importAllDesc =>
      '.looplog फ़ाइल से वापस लाएँ · मौजूदा एंट्री छोड़ दी जाएँगी';

  @override
  String get importConfirmMessage =>
      'मौजूदा एंट्रियाँ वैसे ही रहेंगी, फ़ाइल की एंट्रियाँ जुड़ेंगी.\nएक जैसी एंट्री छोड़ दी जाती हैं, दोबारा इंपोर्ट करने पर डुप्लिकेट नहीं बनेगा.';

  @override
  String get importing => 'इंपोर्ट हो रहा है…';

  @override
  String importDone(int logs, int repeats) {
    return '$logs एंट्री · $repeats रिपीट इंपोर्ट हुए';
  }

  @override
  String get importCancel => 'इंपोर्ट रद्द किया';

  @override
  String get importEmpty => 'इंपोर्ट करने को कुछ नहीं';

  @override
  String get importFail => '.looplog फ़ाइल नहीं पढ़ी जा सकी';

  @override
  String get howNotify => 'कैसे बताऊँ?';

  @override
  String get modeNotif => 'नोटिफिकेशन';

  @override
  String get modeNotifDesc => 'एक बार बताकर बस. डिफ़ॉल्ट — हल्का रिमाइंडर';

  @override
  String get modeAlarm => 'अलार्म';

  @override
  String get modeAlarmDesc =>
      'बंद करने तक बजता रहेगा, साइलेंट में भी. ज़रूरी लूप के लिए';

  @override
  String get snoozeAction => '10 मिनट बाद फिर';

  @override
  String get notifAlarmChannelName => 'लूप अलार्म';

  @override
  String get testFire => 'टेस्ट करें';

  @override
  String get testNotifTitle => 'टेस्ट · सूचना';

  @override
  String get overlayPermTitle => 'अन्य ऐप्स के ऊपर अलार्म दिखाएँ';

  @override
  String get overlayPermBody =>
      'दूसरे ऐप इस्तेमाल करते समय भी अलार्म को फ़ुल स्क्रीन पर बजाने के लिए Loop को \"अन्य ऐप्स के ऊपर दिखाएँ\" अनुमति चाहिए। अगली स्क्रीन पर अनुमति दें।';

  @override
  String get overlayPermOpen => 'सेटिंग खोलें';

  @override
  String get testFireDesc => '5 सेकंड में नोटिफिकेशन · 20 सेकंड में अलार्म';

  @override
  String get testFireSoon =>
      'अभी आएगा: नोटिफिकेशन (5 सेकंड) · अलार्म (20 सेकंड)';

  @override
  String get fullScreenHint =>
      'फुल-स्क्रीन अलार्म के लिए \"अलार्म और रिमाइंडर\" की अनुमति दें.';

  @override
  String get openSettings => 'सेटिंग खोलें';

  @override
  String get detailOriginal => 'मूल एंट्री';

  @override
  String get detailPlace => 'जगह';

  @override
  String get detailWeather => 'मौसम';

  @override
  String get detailPhotos => 'फ़ोटो';

  @override
  String photoCount(int n) {
    return '$n फ़ोटो';
  }

  @override
  String get detailNoContext => 'कोई स्थान, मौसम या फ़ोटो नहीं';

  @override
  String get detailRecord => 'जानकारी';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get yesterday => 'कल';

  @override
  String get wmoClear => 'साफ़';

  @override
  String get wmoPartly => 'थोड़े बादल';

  @override
  String get wmoCloudy => 'बादल';

  @override
  String get wmoFog => 'कोहरा';

  @override
  String get wmoDrizzle => 'बूँदा-बाँदी';

  @override
  String get wmoRain => 'बारिश';

  @override
  String get wmoSnow => 'बर्फ़';

  @override
  String get wmoThunder => 'आंधी-तूफ़ान';

  @override
  String get wmoUnknown => 'अज्ञात';

  @override
  String get notifRepeatTitle => '↩ Loop';

  @override
  String get notifFallbackBody => 'लूप लौटने का समय';

  @override
  String get notifConfirm => 'ठीक है';

  @override
  String get notifChannelName => 'लूप';

  @override
  String get notifChannelDesc => 'लौटने वाले लूप की सूचना देता है';

  @override
  String get statsTitle => 'रिकॉर्ड फ़्लो';

  @override
  String get statsEmpty =>
      'एंट्रियाँ जमा होने पर फ़्लो दिखेगा.\nपहला विचार लिखने के लिए + दबाएँ.';

  @override
  String statsReturnsLine(int n) {
    return 'विचार $n बार लौटा';
  }

  @override
  String get statsReturnsZero => 'लूप लगाइए, विचार वापस आएगा';

  @override
  String get statsTotalLogs => 'लिखी एंट्रियाँ';

  @override
  String get statsActiveDays => 'लिखे गए दिन';

  @override
  String get statsStreakNow => 'अभी की लय';

  @override
  String get statsStreakBest => 'सबसे लंबी लय';

  @override
  String statsDays(int n) {
    return '$n दिन';
  }

  @override
  String get statsHeatmapCaption => 'पिछले 15 हफ़्ते';

  @override
  String get statsHeatmapLess => 'कम';

  @override
  String get statsHeatmapMore => 'ज़्यादा';

  @override
  String get statsTopChains => 'सबसे लंबी श्रृंखला';

  @override
  String statsChainLinkings(int n) {
    return '$n बार जुड़ी';
  }

  @override
  String get starterQuickTitle => '10 मिनट का लूप';

  @override
  String get starterQuickDesc => 'अभी लिखें — 10 मिनट में वापस आएगा';

  @override
  String get starterDailyTitle => 'हर रात एक पंक्ति';

  @override
  String get starterDailyDesc => 'आपका दिन हर रात 9 बजे वापस आता है';

  @override
  String get starterWeekTitle => 'एक हफ़्ते का लूप';

  @override
  String get starterWeekDesc => 'अभी लिखें, एक हफ़्ते बाद दोबारा पढ़ें';

  @override
  String starterInMinutes(int n) {
    return '$n मिनट में';
  }

  @override
  String starterEveryNight(String time) {
    return 'हर रात $time बजे';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ $when वापस आएगा';
  }

  @override
  String get onThisDayTitle => 'आपका पुराना रूप';

  @override
  String get onThisDayWeekAgo => 'एक हफ़्ता पहले';

  @override
  String get onThisDayMonthAgo => 'एक महीने पहले';

  @override
  String get onThisDayYearAgo => 'एक साल पहले';

  @override
  String get onThisDayChannelName => 'आपका पुराना रूप';

  @override
  String get onThisDayChannelDesc =>
      'हर सुबह पुराने रिकॉर्ड के साथ वापस आता है';

  @override
  String get onThisDaySetting => 'पुराने रूप की सुबही चिट्ठी';

  @override
  String get onThisDaySettingDesc =>
      'एक हफ़्ता, महीना या साल पहले का रिकॉर्ड सुबह 9 बजे लौटता है';

  @override
  String get shareStats => 'साझा करें';

  @override
  String get shareCardTagline => 'एक डायरी जहाँ ख़याल आपके पास लौटते हैं';

  @override
  String get shareFail => 'शेयर कार्ड नहीं बन सका';

  @override
  String get loopAttachHeadLabel =>
      '↩ इस श्रृंखला की नवीनतम प्रविष्टि से जुड़ता है';

  @override
  String get loopAttachHereLabel => '↩ इस प्रविष्टि से शाखा निकलती है';

  @override
  String get loopAttachHereAction => 'यहाँ से';

  @override
  String get loopAttachHeadAction => 'श्रृंखला के अंत में';

  @override
  String get todayEvening => 'आज शाम';

  @override
  String get dayEndSetting => 'दिन के समेटने का समय';

  @override
  String get dayEndSettingDesc =>
      '\"आज शाम\" चिप और रात के लूप इसी समय को इस्तेमाल करते हैं';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get takeVideo => 'वीडियो रिकॉर्ड करें';

  @override
  String get videoAttached => 'वीडियो संलग्न है';

  @override
  String get videoOpenRow => 'वीडियो · चलाने के लिए टैप करें';

  @override
  String get videoPlayFail => 'यह वीडियो चलाने के लिए कोई ऐप नहीं मिली';

  @override
  String get videoTooLong => 'वीडियो अधिकतम 1 मिनट तक का हो सकता है';

  @override
  String get shareChainAction => 'Loop साझा करें';

  @override
  String get shareChainTitle => 'Loop साझा करें';

  @override
  String get shareCountLogs => 'एंट्री';

  @override
  String get shareCountPhotos => 'तस्वीरें';

  @override
  String get shareCountVideos => 'वीडियो';

  @override
  String get shareCountRepeats => 'लूप';

  @override
  String get shareNameLabel => 'प्रदर्शित नाम';

  @override
  String get shareNameHint => 'सामने वाला यही नाम देखेगा';

  @override
  String get shareStripLocation => 'बिना लोकेशन भेजें';

  @override
  String get shareStripLocationDesc =>
      'एंट्री की जगह और निर्देशांक नहीं जाएंगे';

  @override
  String get shareStripMedia => 'बिना फ़ोटो·वीडियो भेजें';

  @override
  String get shareStripMediaDesc => 'सिर्फ़ लिखी हुई एंट्री जाएगी';

  @override
  String get shareSendNearby => 'पास के डिवाइस पर भेजें';

  @override
  String get shareExportFile => 'फ़ाइल में निर्यात करें (.looplog)';

  @override
  String get shareSearching => 'पास के डिवाइस खोज रहे हैं…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · जुड़ा';
  }

  @override
  String get shareSending => 'भेज रहे हैं';

  @override
  String get shareHintOffline =>
      'इंटरनेट या सर्वर बीच में नहीं — आमतौर पर कुछ सेकंड में पूरा।';

  @override
  String get shareSent => 'भेज दिया';

  @override
  String get shareSendFail => 'भेजा नहीं जा सका';

  @override
  String get sharePermTitle => 'पास के डिवाइस की अनुमति';

  @override
  String get sharePermBody =>
      'पास के डिवाइस खोजने के लिए लोकेशन और पास के डिवाइस अनुमति चाहिए। डेटा सीधे दोनों डिवाइस के बीच जाता है, कहीं सेव नहीं होता।';

  @override
  String receiveFrom(String name) {
    return '$name ने आपको एक चेन भेजी';
  }

  @override
  String get receiveTitle => 'चेन इम्पोर्ट करें';

  @override
  String get receiveBadgeNoLocation => 'बिना लोकेशन भेजी गई';

  @override
  String get receiveQuestion => 'कैसे इम्पोर्ट करें?';

  @override
  String get receiveOnly => 'सिर्फ़ एंट्री इम्पोर्ट करें';

  @override
  String get receiveOnlyDesc =>
      'चेन ज्यों की त्यों टाइमलाइन पर जुड़ेगी। कोई रिमाइंडर नहीं।';

  @override
  String get receiveAdopt => 'जीवित लूप के रूप में अपनाएँ';

  @override
  String get receiveAdoptDesc => 'लूप अब मेरे शेड्यूल पर मुझे याद दिलाएगा।';

  @override
  String get receiveImport => 'इम्पोर्ट करें';

  @override
  String get receiveDecline => 'मना करें';

  @override
  String get receiveDone => 'इम्पोर्ट हो गया';

  @override
  String receiveDoneDesc(int count) {
    return '$count एंट्री टाइमलाइन पर जुड़ गईं।';
  }

  @override
  String get receiveAdoptedTitle => '🔁 जीवित लूप के रूप में अपनाया';

  @override
  String get receiveAdoptedDesc =>
      'इतिहास वैसा ही रहेगा; रिमाइंडर अब मेरे शेड्यूल पर।';

  @override
  String receiveNextFire(String time) {
    return 'अगली बार $time';
  }

  @override
  String get viewChainAction => 'चेन देखें';

  @override
  String get laterAction => 'बाद में';

  @override
  String get receiveFail => 'इम्पोर्ट नहीं हो सका';

  @override
  String get shareTapToSend => 'भेजने के लिए टैप करें';

  @override
  String get shareWaitingReceiver =>
      'दूसरे फ़ोन पर सेटिंग › पास के डिवाइस से पाएं चालू करें, तो वह यहाँ दिखेगा';

  @override
  String get shareNotFound => 'पास का कोई डिवाइस नहीं मिला';

  @override
  String get shareRetry => 'फिर से खोजें';

  @override
  String get receiveSetting => 'पास के डिवाइस से पाएं';

  @override
  String get receiveSettingDesc =>
      'ऐप खुला रहने तक पास के डिवाइस आपका प्रदर्शित नाम देख सकते हैं';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return 'लगभग $seconds सेकंड बाकी';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return 'लगभग $minutes मिनट बाकी';
  }

  @override
  String get shareSlowHint =>
      'Bluetooth से धीरे भेजा जा रहा है। रद्द करें, दोनों फ़ोन पर Wi-Fi चालू करें और फिर से भेजें — बहुत तेज़ होगा।';

  @override
  String get shareStalled =>
      'कुछ देर तक प्रगति नहीं हुई, इसलिए रुक गया। फ़ोन पास रखें और फिर से भेजें।';

  @override
  String receiveIncoming(String name) {
    return '$name भेज रहे हैं…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return '$name से भेजना बीच में रुक गया';
  }

  @override
  String get shareCleanTitle => 'शेयर की अस्थायी फ़ाइलें हटाएं';

  @override
  String shareCleanDesc(String size) {
    return '$size · अधूरी और भेजने की अस्थायी फ़ाइलें';
  }

  @override
  String get shareCleanEmpty => 'हटाने के लिए कुछ नहीं है';

  @override
  String get shareCleanConfirm => 'चल रहे ट्रांसफ़र की फ़ाइलें रखी जाएंगी।';

  @override
  String get shareCleanAction => 'हटाएं';

  @override
  String shareCleanDone(String size) {
    return '$size हटाया गया';
  }

  @override
  String get alarmPermTitle => 'अलार्म स्क्रीन पर दिखाने के लिए अनुमति चाहिए';

  @override
  String get alarmPermBody =>
      'अभी अलार्म बजने पर सिर्फ़ आवाज़ आती है, स्क्रीन पर कुछ नहीं दिखता। \'फ़ुल-स्क्रीन सूचनाएं\' की अनुमति दें, ताकि स्क्रीन बंद होने पर भी अलार्म लॉक स्क्रीन पर दिखे।';

  @override
  String get settingsAppInfo => 'ऐप जानकारी';

  @override
  String get guideOpen => 'Loop कैसे इस्तेमाल करें';

  @override
  String get guideOpenDesc => 'हर फ़ीचर, तस्वीरों के साथ';

  @override
  String get guideTitle => 'Loop कैसे इस्तेमाल करें';

  @override
  String get guideIntroTitle => 'Loop क्या है';

  @override
  String get guideIntroBody =>
      'एक डायरी जो आपके बीते विचारों को फिर से लौटाती है। अभी का विचार लिखें, लूप लगाएं, और तय समय पर वह लॉग फिर आपके पास आएगा।';

  @override
  String get guideWriteTitle => 'लॉग लिखें';

  @override
  String get guideWriteBody =>
      'नीचे दाईं ओर + दबाकर अभी का विचार लिखें। फ़ोटो या 1 मिनट तक का वीडियो जोड़ सकते हैं। जगह और मौसम अपने आप सहेजे जाते हैं (सेटिंग में बंद कर सकते हैं)।';

  @override
  String get guideLoopTitle => 'लूप लगाएं — फिर लौटाएं';

  @override
  String get guideLoopBody =>
      'लॉग का ⋯ › ↩ Loop। \'एक बार\' तय समय पर एक बार लौटाता है (भूलने के वक्र के हिसाब से समय सुझाया जाता है)। नोटिफिकेशन एक बार याद दिलाता है; अलार्म पुष्टि करने तक बजता है।';

  @override
  String get guideRepeatTitle => 'रिपीट लूप';

  @override
  String get guideRepeatBody =>
      'लूप शीट में \'रिपीट\' चुनें तो हर 10 मिनट, रोज़, कार्यदिवस, हर महीने आदि पर लौटता रहेगा। हर बार आगे लिखने की जगह बनती है। रोकने के लिए: ⋯ › लूप रोकें।';

  @override
  String get guideFlowTitle => 'आगे लिखें और श्रृंखला देखें';

  @override
  String get guideFlowBody =>
      'लौटे हुए लॉग पर आगे लिखने से बैंगनी रेखा से जुड़ी श्रृंखला बनती है। ⋯ › लूप श्रृंखला देखें से पहले लॉग से अब तक एक लाइन में देखें। ऊपर का बटन पूरी टाइमलाइन पर लौटाता है।';

  @override
  String get guideUpcomingTitle => 'आने वाले 7 दिन';

  @override
  String get guideUpcomingBody =>
      'ऊपर पहला आइकन (आने वाले लूप · 7 दिन) दबाएं — आज से 7 दिनों में लौटने वाले सभी लूप एक नज़र में दिखेंगे।';

  @override
  String get guideRhythmTitle => 'सुबह और शाम की लय';

  @override
  String get guideRhythmBody =>
      'सुबह 9 बजे Loop आपको 1 हफ़्ते, 1 महीने और 1 साल पहले आज के लॉग सुनाता है। दिन खत्म होने का समय शाम के सुझाव और रात के लूप के लिए इस्तेमाल होता है। दोनों सेटिंग में बदलें।';

  @override
  String get guideShareTitle => 'Loop साझा करें — पास वाले को';

  @override
  String get guideShareBody =>
      'लॉग का ⋯ › Loop साझा करें › पास के डिवाइस पर भेजें। बिना इंटरनेट या सर्वर के सीधे पास के फ़ोन पर जाता है। पाने वाला सेटिंग › पास के डिवाइस से पाएं चालू करे। जगह डिफ़ॉल्ट रूप से नहीं भेजी जाती।';

  @override
  String get guideBackupTitle => 'बैकअप — एक्सपोर्ट और इंपोर्ट';

  @override
  String get guideBackupBody =>
      'सेटिंग › सब एक्सपोर्ट करें से लॉग, फ़ोटो, वीडियो और रिपीट एक .looplog फ़ाइल में सहेजें। नए फ़ोन पर सेटिंग › इंपोर्ट करें — पहले से मौजूद लॉग छोड़ दिए जाते हैं। समय-समय पर एक्सपोर्ट करते रहें।';

  @override
  String get guideStatsTitle => 'रिकॉर्ड फ़्लो · खोज · तारीख';

  @override
  String get guideStatsBody =>
      'ऊपर के आइकन से खोजें: खोज टेक्स्ट और जगह से, तारीख पर जाएँ उसी दिन पर, और रिकॉर्ड फ़्लो दिखाता है कि विचार कितनी बार लौटे, लगातार दिन और सबसे लंबी श्रृंखला।';

  @override
  String get guideAlarmTitle => 'अलार्म स्क्रीन पर दिखाएं';

  @override
  String get guideAlarmBody =>
      'अलार्म लॉक स्क्रीन के ऊपर दिखे, इसके लिए \'फ़ुल-स्क्रीन सूचनाएं\' की अनुमति दें। पूछे जाने पर सेटिंग खोलें › Loop चालू करें। बंद होने पर अलार्म सिर्फ़ बजता है। सेटिंग › टेस्ट करें से आज़माएं।';

  @override
  String get coachSkip => 'छोड़ें';

  @override
  String get coachGotIt => 'ठीक है';

  @override
  String get coachWriteTitle => 'अभी मन में जो आ रहा है, वह लिखिए';

  @override
  String get coachWriteBody =>
      'न कोई शीर्षक, न फ़ोल्डर। जो विचार आए, उसे वैसे ही लिख दीजिए।';

  @override
  String get coachReserveTitle => 'तय कीजिए कि इसे फिर कब देखना है';

  @override
  String get coachReserveBody =>
      '10 मिनट बाद, आज रात, एक हफ़्ते बाद… चुनिए कि यह विचार कब लौटे।';

  @override
  String get coachSaveTitle => 'सहेजते ही लूप तैयार';

  @override
  String get coachSaveBody => 'आपके चुने हुए समय पर यह विचार फिर लौट आएगा।';

  @override
  String get coachReturnTitle => 'लौटने पर आगे लिखिए';

  @override
  String get coachReturnBody =>
      'रिमाइंडर आए तो \'अभी जारी रखें\' दबाइए। विचार एक कड़ी की तरह जुड़ते जाएँगे।';

  @override
  String get coachArmTitle => 'पुरानी एंट्री पर भी लूप लगा सकते हैं';

  @override
  String get coachArmBody => '\'लूप सेट करें\' दबाइए, यह विचार फिर लौट आएगा।';

  @override
  String get coachReplay => 'ट्यूटोरियल फिर देखें';

  @override
  String get coachReplayDesc => 'पहला लूप बनाने की गाइड शुरू से फिर देखें';

  @override
  String get pcLinkSettingTitle => 'PC कनेक्शन';

  @override
  String get pcLinkSettingOff => 'कनेक्ट नहीं है';

  @override
  String get pcLinkSettingConnected => 'कनेक्टेड';

  @override
  String get pcLinkTitle => 'PC कनेक्शन';

  @override
  String get pcLinkIntro =>
      'Mac पर Claude Code को आपकी डायरी खोजने देता है। कनेक्ट होने के बाद, स्क्रीन बंद होने या दूसरे ऐप इस्तेमाल करने पर भी आखिरी उपयोग के बाद 1 घंटे तक कनेक्शन बना रहता है।';

  @override
  String get pcLinkHostLabel => 'PC पता (IP)';

  @override
  String get pcLinkHostHint => 'उदा: 192.168.0.8';

  @override
  String get pcLinkConnect => 'कनेक्ट करें';

  @override
  String get pcLinkConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get pcLinkCodeTitle => 'पेयरिंग कोड';

  @override
  String get pcLinkCodeBody =>
      'PC पर Claude से कनेक्शन कोड दिखाने के लिए कहें, फिर दिए गए 8 अंक दर्ज करें।';

  @override
  String get pcLinkCodeHint => '8 अंक';

  @override
  String get pcLinkCodeSubmit => 'सबमिट करें';

  @override
  String get pcLinkConnectedTitle => 'कनेक्टेड';

  @override
  String get pcLinkConnectedBody =>
      'Claude अब आपकी डायरी खोज सकता है। आखिरी उपयोग के बाद 1 घंटे तक कनेक्शन बना रहता है।';

  @override
  String get pcLinkQueries => 'उत्तर दी गई क्वेरी';

  @override
  String get pcLinkDisconnect => 'डिस्कनेक्ट करें';

  @override
  String get pcLinkUnpair => 'पेयरिंग हटाएँ';

  @override
  String get pcLinkErrRefused =>
      'कनेक्ट नहीं हो सकता — PC पता जाँचें और सुनिश्चित करें कि Claude Code चल रहा है।';

  @override
  String get pcLinkErrTimeout =>
      'कोई प्रतिक्रिया नहीं — जाँचें कि आप PC के समान Wi-Fi पर हैं।';

  @override
  String get pcLinkErrBadHost => 'पते का प्रारूप गलत है।';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'गलत कोड ($left प्रयास शेष)';
  }

  @override
  String get pcLinkErrTooMany =>
      'बहुत अधिक प्रयास — थोड़ी देर बाद पुनः प्रयास करें।';

  @override
  String get pcLinkErrBusy => 'कोई और फ़ोन पहले से कनेक्ट है।';

  @override
  String get pcLinkErrCodeExpired =>
      'कोड समाप्त — Claude से नया कोड लें और फिर से कनेक्ट करें।';

  @override
  String get pcLinkErrDisconnected => 'कनेक्शन टूट गया।';

  @override
  String get pcLinkReconnecting => 'कनेक्शन टूट गया — फिर से जोड़ रहे हैं…';

  @override
  String get guidePcTitle => 'अपने PC से Claude द्वारा खोजें';

  @override
  String get guidePcBody =>
      'सेटअप — अपने कंप्यूटर के Claude Code में Loop प्लगइन इंस्टॉल करें। Claude Code में ये दो लाइनें टाइप करें: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop। फिर बस Claude से कहें «मेरा फ़ोन कनेक्ट करो» — वह पता और 8-अंकों का कोड देगा। ① सेटिंग्स → PC कनेक्शन में वह पता डालकर कनेक्ट करें ② कोड डालें और कनेक्शन पूरा — अब से यह अपने आप दोबारा जुड़ जाएगा। डायरी फ़ोन पर ही रहती है — केवल क्वेरी और परिणाम Wi-Fi पर चलते हैं।';
}
