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
  String get testFireDesc => 'Thông báo sau 5 giây · báo thức sau 20 giây';

  @override
  String get testFireSoon =>
      'Sắp kích hoạt: thông báo (5 giây) · báo thức (20 giây)';

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
}
