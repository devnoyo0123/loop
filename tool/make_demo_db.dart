// 스토어 스크린샷·사용법 그림용 데모 DB 생성기 — 개인 기록 대신 에뮬레이터에 넣을 샘플.
// Flutter 의존(l10n)이 있어 flutter test로 돌린다:
//   DEMO_OUT=/tmp/demo_ko DEMO_LANG=ko flutter test test/make_demo_db_test.dart
// 타임라인 1화면에 담기는 양(광고 슬롯 8장 미만)으로 구성한다.
// 언어: 앱이 지원하는 8개(ko/en/ja/zh/es/vi/it/hi) — 본문·장소명만 번역.
import 'dart:io';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';

/// 언어별 데모 본문·장소명. 키는 앱 언어 코드와 같다.
class _DemoTexts {
  const _DemoTexts({
    required this.retro,
    required this.fork,
    required this.alarm,
    required this.reading,
    required this.readingFork,
    required this.bakery,
    required this.busy,
    required this.placeSeongdong,
    required this.placeMapo,
  });

  final String retro; // src1 — 주간 회고 (사슬 시작)
  final String fork; // fork1 — 이어쓰기
  final String alarm; // alarm1 — 알람 걸린 로그
  final String reading; // rep1 — 반복 원본
  final String readingFork; // repfork1 — 반복 발화 이어쓰기
  final String bakery; // d1 — 일상
  final String busy; // d2 — 일상(인용)
  final String placeSeongdong;
  final String placeMapo;
}

const _texts = <String, _DemoTexts>{
  'ko': _DemoTexts(
    retro: '프로젝트 회고 — 이번 주에 제일 잘한 건 "작게 쪼개서 매일 끝낸 것". 다음 주도 이 리듬을 지키자.',
    fork: '아침에 다시 읽음. "매일 끝내기"를 구체화하면 → 퇴근 전 10분 정리 루틴. 오늘부터.',
    alarm: '엄마 생신 선물 주문하기 — 오늘 안에!',
    reading: '밤 9시 독서 30분. 『생각에 관한 생각』 3장부터.',
    readingFork: '3장 끝. "손실 회피"가 내 결정 대부분을 설명한다는 게 불편할 만큼 정확함.',
    bakery: '점심에 성수동 새 빵집. 소금빵이 미쳤다. 다음엔 동료들이랑.',
    busy: '"바쁜 것과 중요한 것은 다르다" — 오늘 회의에서 들은 말. 내 할 일 목록을 다시 봐야겠다.',
    placeSeongdong: '서울특별시 성동구',
    placeMapo: '서울특별시 마포구',
  ),
  'en': _DemoTexts(
    retro: 'Weekly retro — the best thing this week: breaking work into small pieces and finishing one every day. Keep that rhythm next week.',
    fork: 'Reread this morning. Making "finish daily" concrete → a 10-minute wrap-up routine before leaving work. Starting today.',
    alarm: 'Order Mom\'s birthday present — today, no excuses!',
    reading: 'Read 30 min at 9pm. "Thinking, Fast and Slow", from chapter 3.',
    readingFork: 'Finished chapter 3. "Loss aversion" explains most of my decisions — uncomfortably accurate.',
    bakery: 'Lunch at the new bakery in Seongsu. The salt bread is unreal. Bringing the team next time.',
    busy: '"Busy is not the same as important" — heard in today\'s meeting. Time to look at my to-do list again.',
    placeSeongdong: 'Seongdong-gu, Seoul',
    placeMapo: 'Mapo-gu, Seoul',
  ),
  'ja': _DemoTexts(
    retro: '週間ふりかえり — 今週いちばん良かったのは「仕事を小さく分けて毎日終わらせたこと」。来週もこのリズムで。',
    fork: '朝に再読。「毎日終わらせる」を具体化 → 退勤前の10分まとめ習慣。今日から。',
    alarm: '母の誕生日プレゼントを注文する — 今日中に!',
    reading: '夜9時は読書30分。『ファスト&スロー』3章から。',
    readingFork: '3章読了。「損失回避」が自分の決断のほとんどを説明している — ズバリすぎて怖い。',
    bakery: '昼は聖水洞の新しいベーカリー。塩パンが激うま。次は同僚と来よう。',
    busy: '「忙しいことと大切なことは違う」 — 今日の会議で聞いた言葉。TODOリストを見直そう。',
    placeSeongdong: 'ソウル特別市城東区',
    placeMapo: 'ソウル特別市麻浦区',
  ),
  'zh': _DemoTexts(
    retro: '每周复盘 — 本周做得最好的一件事：把工作拆小，每天完成一件。下周也保持这个节奏。',
    fork: '早上重读。把"每天完成"具体化 → 下班前10分钟收尾习惯。今天开始。',
    alarm: '给妈妈订生日礼物 — 就今天！',
    reading: '晚上9点读书30分钟。《思考，快与慢》从第3章开始。',
    readingFork: '第3章读完。"损失厌恶"几乎能解释我的全部决定 — 准确得让人不太舒服。',
    bakery: '中午去了圣水洞新开的面包店。盐面包绝了。下次带同事来。',
    busy: '"忙和重要不是一回事" — 今天会上听到的话。该重新看看我的待办清单了。',
    placeSeongdong: '首尔特别市城东区',
    placeMapo: '首尔特别市麻浦区',
  ),
  'es': _DemoTexts(
    retro: 'Retro semanal — lo mejor de la semana: dividir el trabajo en partes pequeñas y terminar una cada día. Mantener ese ritmo.',
    fork: 'Releído esta mañana. Concretar "terminar a diario" → rutina de 10 minutos antes de salir del trabajo. Desde hoy.',
    alarm: 'Pedir el regalo de cumpleaños de mamá — ¡hoy, sin excusas!',
    reading: 'Leer 30 min a las 21. "Pensar rápido, pensar despacio", desde el capítulo 3.',
    readingFork: 'Capítulo 3 terminado. La "aversión a la pérdida" explica casi todas mis decisiones — inquietantemente precisa.',
    bakery: 'Comida en la panadería nueva de Seongsu. El pan de sal es una locura. La próxima con el equipo.',
    busy: '"Ocupado no es lo mismo que importante" — lo oí hoy en la reunión. Toca revisar mi lista de tareas.',
    placeSeongdong: 'Seongdong-gu, Seúl',
    placeMapo: 'Mapo-gu, Seúl',
  ),
  'vi': _DemoTexts(
    retro: 'Nhìn lại tuần — điều tốt nhất: chia việc nhỏ và mỗi ngày xong một việc. Tuần sau giữ nhịp này.',
    fork: 'Đọc lại sáng nay. Cụ thể hóa "xong mỗi ngày" → 10 phút tổng kết trước khi tan làm. Từ hôm nay.',
    alarm: 'Đặt quà sinh nhật cho mẹ — hôm nay, không né tránh!',
    reading: 'Đọc 30 phút lúc 9 tối. "Tư duy, nhanh và chậm", từ chương 3.',
    readingFork: 'Xong chương 3. "Ngại mất mát" giải thích gần như mọi quyết định của tôi — chính xác đến khó chịu.',
    bakery: 'Trưa ở tiệm bánh mới khu Seongsu. Bánh muối tuyệt vời. Lần sau rủ đồng nghiệp.',
    busy: '"Bận và quan trọng là hai chuyện khác nhau" — nghe trong họp hôm nay. Đến lúc xem lại danh sách việc.',
    placeSeongdong: 'Quận Seongdong, Seoul',
    placeMapo: 'Quận Mapo, Seoul',
  ),
  'it': _DemoTexts(
    retro: 'Bilancio settimanale — la cosa migliore: spezzettare il lavoro e portarne a termine uno al giorno. Stesso ritmo la prossima settimana.',
    fork: 'Riletto stamattina. Rendere concreto "finire ogni giorno" → 10 minuti di chiusura prima di uscire. Da oggi.',
    alarm: 'Ordinare il regalo di compleanno alla mamma — oggi, senza scuse!',
    reading: 'Letura 30 min alle 21. "Pensieri lenti e veloci", dal capitolo 3.',
    readingFork: 'Capitolo 3 finito. L\'"avversione alla perdita" spiega quasi tutte le mie decisioni — inquietantemente precisa.',
    bakery: 'Pranzo nella pasticceria nuova di Seongsu. Il pane al sale è incredibile. La prossima volta con i colleghi.',
    busy: '"Essere occupati non è essere importanti" — sentito oggi in riunione. Da rivedere la mia lista di cose da fare.',
    placeSeongdong: 'Seongdong-gu, Seul',
    placeMapo: 'Mapo-gu, Seul',
  ),
  'hi': _DemoTexts(
    retro: 'साप्ताहिक समीक्षा — इस हफ़्ते सबसे अच्छा: काम को छोटे हिस्सों में बाँटकर हर दिन एक पूरा करना. अगला हफ़्ता भी यही लय.',
    fork: 'सुबह दोबारा पढ़ा. "हर दिन पूरा करना" को ठोस बनाएँ → काम छोड़ने से पहले 10 मिनट की समीक्षा रूटीन. आज से.',
    alarm: 'मम्मी के जन्मदिन का तोहफ़ा ऑर्डर करें — आज ही!',
    reading: 'रात 9 बजे 30 मिनट पढ़ाई. "तेज़ और धीमी सोच", अध्याय 3 से.',
    readingFork: 'अध्याय 3 पूरा. "नुकसान से बचने की प्रवृत्ति" मेरे ज़्यादातर फ़ैसलों को समझाती है — चौंकाने वाली सच्चाई.',
    bakery: 'दोपहर में Seongsu की नई बेकरी. नमक वाली ब्रेड कमाल है. अगली बार साथियों के साथ.',
    busy: '"व्यस्त होना और महत्वपूर्ण होना अलग बात है" — आज मीटिंग में सुना. अपनी काम की सूची फिर देखनी होगी.',
    placeSeongdong: 'सियोल सेओंगदोंग-गु',
    placeMapo: 'सियोल मापो-गु',
  ),
};

void buildDemoDb(String outDir, String lang) {
  final tx = _texts[lang] ?? _texts['en']!;
  final dir = Directory(outDir)..createSync(recursive: true);
  for (final f in dir.listSync()) {
    f.deleteSync();
  }
  final db = LoopDb(dir)..open();
  final now = DateTime.now();
  DateTime t(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day - daysAgo, h, m);

  // 원본 ― 어제 밤의 생각 (이어쓰기 체인의 시작, 1회 복습 완료)
  db.insert(LogEntry(
    id: 'src1',
    content: tx.retro,
    createdAt: t(1, 22, 40),
    originalCreatedAt: t(1, 22, 40),
    latitude: 37.56, longitude: 127.04,
    place: tx.placeSeongdong,
    weatherCode: 2, temperatureC: 14,
    loopCount: 1,
  ));
  // 이어쓰기 (루프로 돌아와서 쓴 것)
  db.insert(LogEntry(
    id: 'fork1',
    content: tx.fork,
    createdAt: t(0, 8, 15),
    originalCreatedAt: t(0, 8, 15),
    parentId: 'src1', rootId: 'src1', depth: 1, path: 'src1/fork1',
    latitude: 37.56, longitude: 127.04,
    place: tx.placeSeongdong,
    weatherCode: 0, temperatureC: 11,
    loopCount: 1,
  ));
  // 알람 루프가 걸린 로그 (오늘 저녁)
  db.insert(LogEntry(
    id: 'alarm1',
    content: tx.alarm,
    createdAt: t(0, 9, 2),
    originalCreatedAt: t(0, 9, 2),
    loopAt: DateTime(now.year, now.month, now.day + 1, 19, 0), // 내일 — 예약 칩이 보이게
    loopAlarm: true,
  ));
  // 반복 루프 원본 (매일 밤 9시 독서)
  db.insert(LogEntry(
    id: 'rep1',
    content: tx.reading,
    createdAt: t(3, 20, 55),
    originalCreatedAt: t(3, 20, 55),
    weatherCode: 61, temperatureC: 9,
    place: tx.placeMapo,
  ));
  db.insertRepeatRule(RepeatRule(
    id: 'rule1',
    sourceLogId: 'rep1',
    kind: RepeatKind.daily,
    timeOfDay: '21:00',
    nextFireAt: DateTime(now.year, now.month, now.day + 1, 21, 0), // 내일 — 발화 전
    fireCount: 2,
    createdAt: t(3, 20, 55),
  ));
  // 반복 발화로 생긴 이어쓰기 (어제, 작성 완료)
  db.insert(LogEntry(
    id: 'repfork1',
    content: tx.readingFork,
    createdAt: t(1, 21, 0),
    originalCreatedAt: t(1, 21, 0),
    parentId: 'rep1', rootId: 'rep1', depth: 1, path: 'rep1/repfork1',
    repeatRuleId: 'rule1',
  ));
  // 가벼운 일상 로그들
  db.insert(LogEntry(
    id: 'd1',
    content: tx.bakery,
    createdAt: t(0, 12, 48),
    originalCreatedAt: t(0, 12, 48),
    latitude: 37.54, longitude: 127.05,
    place: tx.placeSeongdong,
    weatherCode: 1, temperatureC: 17,
  ));
  db.insert(LogEntry(
    id: 'd2',
    content: tx.busy,
    createdAt: t(0, 15, 30),
    originalCreatedAt: t(0, 15, 30),
  ));
  // 공유 시트 표시명 (settings.share_name) — 기기명이 대신 나오지 않게.
  db.setSetting('share_name', lang == 'ko' ? '민수' : 'Minsu');
  db.close();
  stdout.writeln('demo db → ${dir.path}/loop.db ($lang)');
}
