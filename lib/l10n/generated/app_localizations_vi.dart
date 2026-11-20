// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get emptyTimeline =>
      'Chưa có ghi chép nào.\nDùng + để lưu suy nghĩ đầu tiên.';

  @override
  String get emptyAtDate =>
      'Không có ghi chép ngày đó.\nĐổi ngày ở trên hoặc quay lại mới nhất.';

  @override
  String get jumpToDate => 'Đến ngày';

  @override
  String get backToLatest => 'Về mới nhất';

  @override
  String get searchHint => 'Tìm nội dung, địa điểm';

  @override
  String get searchEmpty => 'Không có kết quả';

  @override
  String get sortRelevance => 'Độ liên quan';

  @override
  String get sortRecent => 'Mới nhất';

  @override
  String get editContent => 'Sửa nội dung';

  @override
  String get changeTime => 'Đổi giờ';

  @override
  String get deleteAction => 'Xóa';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get stop => 'Dừng';

  @override
  String get deleteLogTitle => 'Xóa ghi chép';

  @override
  String get deleteLogMessage =>
      'Xóa ghi chép này? Các ghi chép viết tiếp vẫn còn.';

  @override
  String get stopRepeatTitle => 'Dừng vòng lặp';

  @override
  String stopRepeatMessage(String rule) {
    return 'Dừng vòng lặp $rule?\nCác lần kích hoạt tới sẽ bị huỷ, ghi chú đã tạo thì còn.';
  }

  @override
  String get composeHint => 'Suy nghĩ lúc này…';

  @override
  String forkOf(String time) {
    return '↩ Viết tiếp ghi chép $time';
  }

  @override
  String get saveLog => 'Lưu ghi chép';

  @override
  String get attachPhoto => 'Đính kèm ảnh';

  @override
  String get reserveAlarm => 'Đặt nhắc';

  @override
  String get alarmTitle => '⏰ Đặt nhắc';

  @override
  String get tapToChangeTime => 'Chạm để đổi ngày giờ';

  @override
  String get pastTimeHint =>
      'Thời điểm đó đã qua rồi — hãy chọn lại thời điểm trong tương lai';

  @override
  String get in10min => 'Sau 10 phút';

  @override
  String get in1hour => 'Sau 1 giờ';

  @override
  String get tomorrow => 'Ngày mai';

  @override
  String get nextWeek => 'Tuần sau';

  @override
  String get in1month => 'Sau 1 tháng';

  @override
  String loopCurveHint(int n, String interval) {
    return 'Ôn tập lần thứ $n của đường cong quên · gợi ý $interval';
  }

  @override
  String get recommended => 'Gợi ý';

  @override
  String get custom => 'Tự chọn';

  @override
  String get notifyAtThisTime => 'Nhắc tôi vào giờ này';

  @override
  String get repeatTitle => '↩ Vòng lặp';

  @override
  String get repeatDesc =>
      'Khi bật lặp, mỗi lần kích hoạt sẽ tự tạo phần viết tiếp của ghi chú này. Có thể dừng bất cứ lúc nào.';

  @override
  String get preset10min => '10 phút';

  @override
  String get preset30min => '30 phút';

  @override
  String get preset1hour => '1 giờ';

  @override
  String get preset3hours => '3 giờ';

  @override
  String get preset6hours => '6 giờ';

  @override
  String get presetDaily => 'Hàng ngày';

  @override
  String get fireTime => 'Giờ kích hoạt';

  @override
  String get unitMinutes => 'phút';

  @override
  String get unitHours => 'giờ';

  @override
  String nextFire(String time, String rule) {
    return 'Lần tới $time · sau đó $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return 'Mỗi $n phút';
  }

  @override
  String ruleEveryHours(int n) {
    return 'Mỗi $n giờ';
  }

  @override
  String ruleDaily(String time) {
    return 'Hàng ngày lúc $time';
  }

  @override
  String ruleWeekday(String time) {
    return 'Ngày trong tuần $time';
  }

  @override
  String get presetWeekday => 'Ngày trong tuần';

  @override
  String get presetMonthly => 'Hàng tháng';

  @override
  String get presetYearly => 'Hàng năm';

  @override
  String get presetLadder => 'Thang lặp';

  @override
  String get ruleLadder => 'Thang đường quên';

  @override
  String get curveSteps =>
      '10 phút → 1 giờ → tối nay → ngày mai → 1 tuần → 1 tháng · 6 lần';

  @override
  String get fireDate => 'Ngày kích hoạt';

  @override
  String get unitMonths => 'tháng';

  @override
  String get unitYears => 'năm';

  @override
  String ruleMonthly(int day, String time) {
    return 'Hàng tháng vào ngày $day lúc $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return 'Mỗi $n tháng vào ngày $day lúc $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return 'Hàng năm vào $date lúc $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return 'Mỗi $n năm vào $date lúc $time';
  }

  @override
  String get upcomingTitle => 'Sắp tới · 7 ngày';

  @override
  String get upcomingEmpty => 'Không có vòng lặp nào trong tuần này';

  @override
  String get noContent => '(không có nội dung)';

  @override
  String continuedFrom(String time) {
    return '↩ Tiếp từ $time';
  }

  @override
  String get locationRecorded => 'Đã ghi vị trí';

  @override
  String repeatNth(int n) {
    return 'Vòng lặp lần thứ $n';
  }

  @override
  String get repeatEnded => 'Vòng lặp đã kết thúc';

  @override
  String get loopAction => '↩ Vòng lặp';

  @override
  String get loopWriteNow => 'Viết tiếp ngay';

  @override
  String get loopAgain => 'Nhắc tôi';

  @override
  String get loopModeOnce => 'Một lần';

  @override
  String get loopModeRepeat => 'Lặp lại';

  @override
  String loopNextShort(String time) {
    return 'Lần sau $time';
  }

  @override
  String loopFireCount(int n) {
    return 'Đã lặp $n lần';
  }

  @override
  String get loopJump => 'Đến bản gốc';

  @override
  String get loopStop => 'Dừng vòng lặp';

  @override
  String get loopEndedInfo => 'Vòng lặp này đã kết thúc';

  @override
  String get loopViewAction => 'Xem vòng lặp';

  @override
  String get loopWriteAction => 'Viết';

  @override
  String get loopViewBack => 'Quay lại dòng thời gian';

  @override
  String get mineOnlyTitle => 'Chỉ vòng lặp của tôi';

  @override
  String get mineOnlyBack => 'Xem tất cả';

  @override
  String get locationCapture => 'Vị trí';

  @override
  String get locationCaptureDesc => 'Tự động ghi kèm địa điểm & thời tiết';

  @override
  String get loopArm => 'Đặt vòng lặp';

  @override
  String get emptyWriteHint => 'Trống · chạm để viết';

  @override
  String get openInYoutube => 'Mở trong YouTube';

  @override
  String get openInBrowser => 'Mở trong trình duyệt';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsData => 'Dữ liệu';

  @override
  String get defaultBrowser => 'Trình duyệt mặc định';

  @override
  String get defaultBrowserDesc => 'Liên kết web sẽ mở bằng trình duyệt này';

  @override
  String get systemDefault => 'Mặc định hệ thống';

  @override
  String get browserEmpty => 'Chưa có trình duyệt nào';

  @override
  String get exportLogs => 'Xuất tất cả';

  @override
  String get exportAllDesc =>
      'Ghi chép, ảnh, lặp lại gọn trong một file .looplog';

  @override
  String get exporting => 'Đang xuất…';

  @override
  String get exportDone => 'Đã xuất';

  @override
  String get exportCancel => 'Đã hủy lưu';

  @override
  String get exportFail => 'Không lưu được file';

  @override
  String get importLogs => 'Nhập';

  @override
  String get importAllDesc => 'Khôi phục từ file .looplog · bỏ qua log đã có';

  @override
  String get importConfirmMessage =>
      'Giữ nguyên log hiện có và thêm log từ file vào.\nLog trùng ID sẽ bị bỏ qua nên nhập lại cùng một file cũng không bị trùng.';

  @override
  String get importing => 'Đang nhập…';

  @override
  String importDone(int logs, int repeats) {
    return 'Đã nhập $logs log · $repeats vòng lặp';
  }

  @override
  String get importCancel => 'Đã hủy nhập';

  @override
  String get importEmpty => 'Không có gì để nhập';

  @override
  String get importFail => 'Không đọc được file .looplog';

  @override
  String get howNotify => 'Báo bạn thế nào?';

  @override
  String get modeNotif => 'Thông báo';

  @override
  String get modeNotifDesc => 'Báo một lần rồi hết. Mặc định — nhắc nhẹ nhàng';

  @override
  String get modeAlarm => 'Báo thức';

  @override
  String get modeAlarmDesc =>
      'Kêu đến khi tắt, kể cả im lặng. Cho vòng lặp nhất định phải giữ';

  @override
  String get snoozeAction => '10 phút nữa nhắc lại';

  @override
  String get notifAlarmChannelName => 'Báo thức vòng lặp';

  @override
  String get testFire => 'Thử kích hoạt';

  @override
  String get testNotifTitle => 'Thử phát · thông báo';

  @override
  String get overlayPermTitle => 'Hiện báo thức trên ứng dụng khác';

  @override
  String get overlayPermBody =>
      'Để báo thức chuông toàn màn hình ngay cả khi bạn đang dùng ứng dụng khác, Loop cần quyền \"Hiển thị trên ứng dụng khác\". Hãy cho phép ở màn hình tiếp theo.';

  @override
  String get overlayPermOpen => 'Mở cài đặt';

  @override
  String get testFireDesc => 'Thông báo sau 5 giây · báo thức sau 20 giây';

  @override
  String get testFireSoon =>
      'Sắp kích hoạt: thông báo (5 giây) · báo thức (20 giây)';

  @override
  String get fullScreenHint =>
      'Để báo thức hiện toàn màn hình, hãy cho phép \"Báo thức và nhắc nhở\".';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get detailOriginal => 'Bản ghi gốc';

  @override
  String get detailPlace => 'Địa điểm';

  @override
  String get detailWeather => 'Thời tiết';

  @override
  String get detailPhotos => 'Ảnh';

  @override
  String photoCount(int n) {
    return '$n ảnh';
  }

  @override
  String get detailNoContext => 'Không có vị trí, thời tiết, ảnh';

  @override
  String get detailRecord => 'Ghi chép';

  @override
  String get unknown => 'Không rõ';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get wmoClear => 'Trời quang';

  @override
  String get wmoPartly => 'Ít mây';

  @override
  String get wmoCloudy => 'Nhiều mây';

  @override
  String get wmoFog => 'Sương mù';

  @override
  String get wmoDrizzle => 'Mưa phùn';

  @override
  String get wmoRain => 'Mưa';

  @override
  String get wmoSnow => 'Tuyết';

  @override
  String get wmoThunder => 'Dông';

  @override
  String get wmoUnknown => 'Không rõ';

  @override
  String get notifRepeatTitle => '↩ Vòng lặp';

  @override
  String get notifFallbackBody => 'Đến giờ vòng lặp quay lại';

  @override
  String get notifConfirm => 'Đã biết';

  @override
  String get notifChannelName => 'Vòng lặp';

  @override
  String get notifChannelDesc => 'Báo khi vòng lặp quay lại';

  @override
  String get statsTitle => 'Dòng chảy của bạn';

  @override
  String get statsEmpty =>
      'Dòng chảy sẽ hiện ra khi bạn viết.\nChạm + để ghi lại suy nghĩ đầu tiên.';

  @override
  String statsReturnsLine(int n) {
    return 'Suy nghĩ của bạn đã quay lại $n lần';
  }

  @override
  String get statsReturnsZero => 'Đặt vòng lặp, suy nghĩ sẽ quay lại với bạn';

  @override
  String get statsTotalLogs => 'Đã ghi';

  @override
  String get statsActiveDays => 'Ngày có ghi';

  @override
  String get statsStreakNow => 'Chuỗi hiện tại';

  @override
  String get statsStreakBest => 'Chuỗi dài nhất';

  @override
  String statsDays(int n) {
    return '$n ngày';
  }

  @override
  String get statsHeatmapCaption => '15 tuần gần đây';

  @override
  String get statsHeatmapLess => 'Ít';

  @override
  String get statsHeatmapMore => 'Nhiều';

  @override
  String get statsTopChains => 'Chuỗi dài nhất';

  @override
  String statsChainLinkings(int n) {
    return '$n lần nối tiếp';
  }

  @override
  String get starterQuickTitle => 'Vòng lặp 10 phút';

  @override
  String get starterQuickDesc => 'Viết ngay, nó quay lại sau 10 phút';

  @override
  String get starterDailyTitle => 'Mỗi tối một dòng';

  @override
  String get starterDailyDesc => 'Ngày hôm ấy quay lại mỗi tối 9 giờ';

  @override
  String get starterWeekTitle => 'Vòng lặp một tuần';

  @override
  String get starterWeekDesc => 'Viết ngay, nhìn lại sau một tuần';

  @override
  String starterInMinutes(int n) {
    return 'sau $n phút';
  }

  @override
  String starterEveryNight(String time) {
    return 'mỗi tối $time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ Quay lại $when';
  }

  @override
  String get onThisDayTitle => 'Bạn của ngày ấy';

  @override
  String get onThisDayWeekAgo => 'một tuần trước';

  @override
  String get onThisDayMonthAgo => 'một tháng trước';

  @override
  String get onThisDayYearAgo => 'một năm trước';

  @override
  String get onThisDayChannelName => 'Bạn của ngày ấy';

  @override
  String get onThisDayChannelDesc =>
      'Mỗi sáng mang lại một ghi chép từ quá khứ';

  @override
  String get onThisDaySetting => 'Lời nhắn buổi sáng từ quá khứ';

  @override
  String get onThisDaySettingDesc =>
      'Ghi chép của một tuần, một tháng hoặc một năm trước quay lại lúc 9 giờ sáng';

  @override
  String get shareStats => 'Chia sẻ';

  @override
  String get shareCardTagline => 'Nhật ký nơi suy nghĩ quay lại với bạn';

  @override
  String get shareFail => 'Không tạo được thẻ chia sẻ';

  @override
  String get loopAttachHeadLabel => '↩ Nối tiếp từ ghi chép mới nhất của chuỗi';

  @override
  String get loopAttachHereLabel => '↩ Nhánh từ ghi chép này';

  @override
  String get loopAttachHereAction => 'Từ đây';

  @override
  String get loopAttachHeadAction => 'Cuối chuỗi';

  @override
  String get todayEvening => 'Tối nay';

  @override
  String get dayEndSetting => 'Giờ khép lại của ngày';

  @override
  String get dayEndSettingDesc =>
      'Chip \"Tối nay\" và vòng lặp mỗi đêm dùng giờ này';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get takeVideo => 'Quay video';

  @override
  String get videoAttached => 'Đã đính kèm video';

  @override
  String get videoOpenRow => 'Video · chạm để phát';

  @override
  String get videoPlayFail => 'Không tìm thấy ứng dụng phát video';

  @override
  String get videoTooLong => 'Video chỉ có thể dài tối đa 1 phút';

  @override
  String get shareChainAction => 'Chia sẻ vòng lặp';

  @override
  String get shareChainTitle => 'Chia sẻ vòng lặp';

  @override
  String get shareCountLogs => 'Ghi chép';

  @override
  String get shareCountPhotos => 'Ảnh';

  @override
  String get shareCountVideos => 'Video';

  @override
  String get shareCountRepeats => 'Vòng lặp';

  @override
  String get shareNameLabel => 'Tên hiển thị';

  @override
  String get shareNameHint => 'Tên người nhận sẽ thấy';

  @override
  String get shareStripLocation => 'Gửi không kèm vị trí';

  @override
  String get shareStripLocationDesc =>
      'Địa điểm và tọa độ trong ghi chép sẽ bị lược bỏ';

  @override
  String get shareStripMedia => 'Gửi không kèm ảnh·video';

  @override
  String get shareStripMediaDesc => 'Chỉ gửi ghi chép chữ';

  @override
  String get shareSendNearby => 'Gửi tới thiết bị gần đây';

  @override
  String get shareExportFile => 'Xuất ra tệp (.looplog)';

  @override
  String get shareSearching => 'Đang tìm thiết bị gần đây…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · đã kết nối';
  }

  @override
  String get shareSending => 'Đang gửi';

  @override
  String get shareHintOffline =>
      'Không qua internet hay máy chủ — thường xong trong vài chục giây.';

  @override
  String get shareSent => 'Đã gửi';

  @override
  String get shareSendFail => 'Không gửi được';

  @override
  String get sharePermTitle => 'Quyền thiết bị lân cận';

  @override
  String get sharePermBody =>
      'Cần quyền vị trí và thiết bị lân cận để tìm thiết bị gần đây. Dữ liệu truyền trực tiếp giữa hai máy và không lưu ở đâu cả.';

  @override
  String receiveFrom(String name) {
    return '$name đã gửi cho bạn một chuỗi';
  }

  @override
  String get receiveTitle => 'Nhập chuỗi';

  @override
  String get receiveBadgeNoLocation => 'Được gửi không kèm vị trí';

  @override
  String get receiveQuestion => 'Bạn muốn nhập thế nào?';

  @override
  String get receiveOnly => 'Chỉ nhập ghi chép';

  @override
  String get receiveOnlyDesc =>
      'Chuỗi được dán nguyên bản vào dòng thời gian. Không báo thức.';

  @override
  String get receiveAdopt => 'Tiếp nhận làm vòng lặp sống';

  @override
  String get receiveAdoptDesc =>
      'Vòng lặp sẽ nhắc lại theo lịch của tôi, bắt đầu từ bây giờ.';

  @override
  String get receiveImport => 'Nhập';

  @override
  String get receiveDecline => 'Từ chối';

  @override
  String get receiveDone => 'Đã nhập';

  @override
  String receiveDoneDesc(int count) {
    return '$count ghi chép đã được dán vào dòng thời gian.';
  }

  @override
  String get receiveAdoptedTitle => '🔁 Đã tiếp nhận làm vòng lặp sống';

  @override
  String get receiveAdoptedDesc =>
      'Lịch sử giữ nguyên; nhắc nhở giờ theo lịch của tôi.';

  @override
  String receiveNextFire(String time) {
    return 'Lần nhắc tới $time';
  }

  @override
  String get viewChainAction => 'Xem chuỗi';

  @override
  String get laterAction => 'Để sau';

  @override
  String get receiveFail => 'Không nhập được';

  @override
  String get shareTapToSend => 'Chạm để gửi';

  @override
  String get shareWaitingReceiver =>
      'Trên máy kia, bật Cài đặt › Nhận từ thiết bị gần đây là máy sẽ hiện ở đây';

  @override
  String get shareNotFound => 'Không tìm thấy thiết bị gần đây';

  @override
  String get shareRetry => 'Tìm lại';

  @override
  String get receiveSetting => 'Nhận từ thiết bị gần đây';

  @override
  String get receiveSettingDesc =>
      'Khi ứng dụng đang mở, thiết bị gần đây có thể thấy tên hiển thị của bạn';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return 'Còn khoảng $seconds giây';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return 'Còn khoảng $minutes phút';
  }

  @override
  String get shareSlowHint =>
      'Đang gửi chậm qua Bluetooth. Hãy hủy, bật Wi-Fi trên cả hai máy rồi gửi lại — nhanh hơn nhiều.';

  @override
  String get shareStalled =>
      'Không có tiến triển một lúc nên đã dừng. Hãy để hai máy gần nhau và gửi lại.';

  @override
  String receiveIncoming(String name) {
    return '$name đang gửi…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return 'Việc gửi từ $name đã bị gián đoạn';
  }

  @override
  String get shareCleanTitle => 'Dọn tệp tạm khi chia sẻ';

  @override
  String shareCleanDesc(String size) {
    return '$size · tệp nhận dở và tệp tạm để gửi';
  }

  @override
  String get shareCleanEmpty => 'Không có gì để dọn';

  @override
  String get shareCleanConfirm => 'Tệp đang truyền sẽ được giữ lại.';

  @override
  String get shareCleanAction => 'Dọn';

  @override
  String shareCleanDone(String size) {
    return 'Đã dọn $size';
  }

  @override
  String get alarmPermTitle => 'Cần quyền để báo thức hiện lên màn hình';

  @override
  String get alarmPermBody =>
      'Hiện báo thức chỉ phát âm thanh mà không hiện trên màn hình. Cho phép \'thông báo toàn màn hình\' để báo thức hiện ngay trên màn hình khóa, kể cả khi màn hình đang tắt.';

  @override
  String get settingsAppInfo => 'Thông tin';

  @override
  String get guideOpen => 'Cách dùng Loop';

  @override
  String get guideOpenDesc => 'Mọi tính năng, bằng hình ảnh';

  @override
  String get guideTitle => 'Cách dùng Loop';

  @override
  String get guideIntroTitle => 'Loop là gì';

  @override
  String get guideIntroBody =>
      'Cuốn sổ giúp những suy nghĩ đã qua quay trở lại. Ghi điều bạn đang nghĩ, đặt vòng lặp, và ghi chép sẽ quay lại đúng lúc bạn chọn.';

  @override
  String get guideWriteTitle => 'Viết ghi chép';

  @override
  String get guideWriteBody =>
      'Chạm + ở góc dưới bên phải để ghi điều bạn đang nghĩ. Có thể đính kèm ảnh hoặc video dưới 1 phút. Địa điểm và thời tiết được lưu tự động (tắt trong Cài đặt › Vị trí).';

  @override
  String get guideLoopTitle => 'Đặt vòng lặp — cho nó quay lại';

  @override
  String get guideLoopBody =>
      'Ghi chép ⋯ › ↩ Vòng lặp. \'Một lần\' quay lại một lần (gợi ý giờ theo đường cong quên lãng). Thông báo nhắc nhẹ một lần; báo thức reo cho đến khi bạn xác nhận.';

  @override
  String get guideRepeatTitle => 'Vòng lặp lặp lại';

  @override
  String get guideRepeatBody =>
      'Chọn \'Lặp lại\' để ghi chép quay lại mỗi 10 phút, hằng ngày, ngày thường, hằng tháng… Mỗi lần quay lại sẽ có chỗ để viết tiếp. Để dừng: ⋯ › Dừng vòng lặp.';

  @override
  String get guideFlowTitle => 'Viết tiếp và xem vòng lặp';

  @override
  String get guideFlowBody =>
      'Viết tiếp trên ghi chép vừa quay lại để tạo chuỗi nối bằng đường màu tím. ⋯ › Xem vòng lặp cho thấy từ ghi chép đầu tiên trên một dòng. Nút phía trên đưa bạn về dòng thời gian.';

  @override
  String get guideUpcomingTitle => '7 ngày tới';

  @override
  String get guideUpcomingBody =>
      'Chạm biểu tượng đầu tiên phía trên (Sắp tới · 7 ngày) để xem mọi vòng lặp sẽ quay lại trong 7 ngày tới.';

  @override
  String get guideRhythmTitle => 'Nhịp sáng và tối';

  @override
  String get guideRhythmBody =>
      'Lời nhắn buổi sáng từ quá khứ: 9 giờ sáng, ghi chép của 1 tuần, 1 tháng, 1 năm trước. Giờ khép lại của ngày: nhãn \'Tối nay\' và vòng lặp mỗi tối dùng giờ này. Đổi cả hai trong Cài đặt.';

  @override
  String get guideShareTitle => 'Chia sẻ vòng lặp — cho người bên cạnh';

  @override
  String get guideShareBody =>
      'Ghi chép ⋯ › Chia sẻ vòng lặp › Gửi tới thiết bị gần đây. Đến thẳng điện thoại bên cạnh, không cần internet hay máy chủ. Người nhận bật Cài đặt › Nhận từ thiết bị gần đây. Mặc định không gửi vị trí.';

  @override
  String get guideBackupTitle => 'Sao lưu — xuất và nhập';

  @override
  String get guideBackupBody =>
      'Cài đặt › Xuất tất cả lưu ghi chép, ảnh, video và lặp lại vào một tệp .looplog. Trên máy mới dùng Cài đặt › Nhập; ghi chép đã có sẽ được bỏ qua. Thỉnh thoảng hãy xuất một lần.';

  @override
  String get guideStatsTitle => 'Dòng chảy, tìm kiếm và ngày';

  @override
  String get guideStatsBody =>
      'Dùng các biểu tượng phía trên. Tìm kiếm theo nội dung và địa điểm, Đến ngày mở đúng ngày đó, Dòng chảy của bạn cho thấy số lần suy nghĩ quay lại, chuỗi liên tục và chuỗi dài nhất.';

  @override
  String get guideAlarmTitle => 'Cho báo thức hiện trên màn hình';

  @override
  String get guideAlarmBody =>
      'Để báo thức hiện trên màn hình khóa, hãy cho phép \'thông báo toàn màn hình\'. Khi Loop nhắc, chạm Mở cài đặt rồi bật Loop. Nếu tắt, báo thức chỉ phát âm thanh. Thử bằng Cài đặt › Thử kích hoạt.';

  @override
  String get coachSkip => 'Bỏ qua';

  @override
  String get coachGotIt => 'Đã hiểu';

  @override
  String get coachWriteTitle => 'Hãy viết ra điều bạn đang nghĩ lúc này';

  @override
  String get coachWriteBody =>
      'Không cần tiêu đề hay thư mục. Cứ ghi lại suy nghĩ như nó đến nhé.';

  @override
  String get coachReserveTitle => 'Hãy chọn lúc xem lại';

  @override
  String get coachReserveBody =>
      'Sau 10 phút, tối nay, một tuần nữa… chọn lúc suy nghĩ này quay lại với bạn.';

  @override
  String get coachSaveTitle => 'Lưu lại là vòng lặp đã sẵn sàng';

  @override
  String get coachSaveBody => 'Suy nghĩ này sẽ quay lại đúng giờ bạn đã chọn.';

  @override
  String get coachReturnTitle => 'Khi nó quay lại, hãy viết tiếp';

  @override
  String get coachReturnBody =>
      'Khi có nhắc, chạm «Viết tiếp ngay». Suy nghĩ sẽ nối thành một chuỗi.';

  @override
  String get coachArmTitle => 'Ghi chép cũ cũng đặt vòng lặp được';

  @override
  String get coachArmBody =>
      'Chạm «Đặt vòng lặp» để suy nghĩ này quay lại với bạn.';

  @override
  String get coachReplay => 'Xem lại hướng dẫn';

  @override
  String get coachReplayDesc => 'Xem lại từ đầu cách tạo vòng lặp đầu tiên';

  @override
  String get pcLinkSettingTitle => 'Kết nối PC';

  @override
  String get pcLinkSettingOff => 'Chưa kết nối';

  @override
  String get pcLinkSettingConnected => 'Đã kết nối';

  @override
  String get pcLinkTitle => 'Kết nối PC';

  @override
  String get pcLinkIntro =>
      'Cho phép Claude Code trên Mac tìm kiếm nhật ký của bạn. Sau khi kết nối, liên kết được giữ 1 giờ kể từ lần dùng cuối, kể cả khi tắt màn hình hoặc dùng ứng dụng khác.';

  @override
  String get pcLinkHostLabel => 'Địa chỉ PC (IP)';

  @override
  String get pcLinkHostHint => 'VD: 192.168.0.8';

  @override
  String get pcLinkConnect => 'Kết nối';

  @override
  String get pcLinkConnecting => 'Đang kết nối…';

  @override
  String get pcLinkCodeTitle => 'Mã ghép nối';

  @override
  String get pcLinkCodeBody =>
      'Hỏi Claude trên PC hiển thị mã kết nối, rồi nhập 8 chữ số được cung cấp.';

  @override
  String get pcLinkCodeHint => '8 chữ số';

  @override
  String get pcLinkCodeSubmit => 'Xác nhận';

  @override
  String get pcLinkConnectedTitle => 'Đã kết nối';

  @override
  String get pcLinkConnectedBody =>
      'Claude giờ có thể tìm kiếm nhật ký của bạn. Kết nối được giữ 1 giờ kể từ lần dùng cuối.';

  @override
  String get pcLinkQueries => 'Truy vấn đã trả lời';

  @override
  String get pcLinkDisconnect => 'Ngắt kết nối';

  @override
  String get pcLinkUnpair => 'Bỏ ghép nối';

  @override
  String get pcLinkErrRefused =>
      'Không thể kết nối — kiểm tra địa chỉ PC và Claude Code đang chạy.';

  @override
  String get pcLinkErrTimeout =>
      'Không có phản hồi — kiểm tra xem bạn và PC cùng Wi-Fi.';

  @override
  String get pcLinkErrBadHost => 'Định dạng địa chỉ không hợp lệ.';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'Sai mã (còn $left lần)';
  }

  @override
  String get pcLinkErrTooMany => 'Vượt quá số lần thử — thử lại sau ít phút.';

  @override
  String get pcLinkErrBusy => 'Đã có điện thoại khác kết nối.';

  @override
  String get pcLinkErrCodeExpired =>
      'Mã đã hết hạn — lấy mã mới từ Claude và kết nối lại.';

  @override
  String get pcLinkErrDisconnected => 'Mất kết nối.';

  @override
  String get pcLinkReconnecting => 'Mất kết nối — đang kết nối lại…';

  @override
  String get guidePcTitle => 'Tìm kiếm bằng Claude trên máy tính';

  @override
  String get guidePcBody =>
      'Chuẩn bị — cài plugin Loop vào Claude Code trên máy tính. Nhập hai dòng sau trong Claude Code: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. Sau đó chỉ cần nói với Claude «kết nối điện thoại của tôi» — nó sẽ cho bạn địa chỉ và mã 8 chữ số. ① Trong Cài đặt → Kết nối PC, nhập địa chỉ đó và kết nối ② nhập mã là xong — từ đó tự động kết nối lại. Nhật ký vẫn nằm trên điện thoại — chỉ câu hỏi và kết quả đi qua Wi-Fi.';
}
