import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/loop_db.dart';
import 'services/image_store.dart';
import 'services/video_store.dart';
import 'design/tokens.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/incoming_share_notice.dart';
import 'screens/share_sheet.dart';
import 'screens/timeline_screen.dart';
import 'services/loop_notifications.dart';
import 'services/pc_link.dart';
import 'services/nearby_share.dart';
import 'services/share_files.dart';

/// AI 연동(PC 연결, ADR-002 맥 브리지) 포함 여부. 끄려면
/// `--dart-define=LOOP_MCP=false`.
const kMcpEnabled = bool.fromEnvironment('LOOP_MCP', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoopNotifications.init();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  // 이미지는 v10부터 파일 보관 — 기존 base64 행을 멱등 마이그레이션한다.
  // 실패(디스크 부족 등)는 치명적이지 않다 — 레거시 base64 경로로 계속
  // 읽히고 다음 실행에 재시도된다. 앱 시작을 막아선 안 된다.
  final images = ImageStore(dir);
  final db = LoopDb(dir, imageStore: images)..open();
  try {
    db.migrateLegacyImages();
  } catch (_) {}
  // PC 연결(ADR-002) — 맥 브리지에 붙는 클라이언트. 폰에서 켤 때만 소켓이
  // 열리므로 생성만 해둔다. 안드로이드는 연결 중 dataSync 포그라운드
  // 서비스로 30분(유휴) 세션을 붙든다 (ADR-003).
  final pcLink = kMcpEnabled
      ? PcLinkController(
          db: db,
          keeper: defaultTargetPlatform == TargetPlatform.android
              ? AndroidPcLinkKeeper()
              : null,
        )
      : null;
  // 끊긴 링크 자동 재연결은 전경 또는 세션 중에만 — 세션 없는 배경에선
  // 멈추고 복귀 때 바로 붙인다.
  if (pcLink != null) {
    AppLifecycleListener(
      onPause: () => pcLink.setForeground(false),
      onResume: () => pcLink.setForeground(true),
    );
  }
  runApp(LoopApp(db: db, videos: VideoStore(dir), images: images, pcLink: pcLink));
  _startShareJanitor();
  await _startShareReceiving(db, VideoStore(dir));
}

/// 공유 파일 청소 — 사건 즉시 삭제가 놓친 것(전송 중 앱이 죽음 등)의 안전망.
/// 시작 직후 1회, 앱으로 돌아올 때마다, 켜져 있는 동안 30분마다.
/// (세션이 끝날 때는 화면·받기 대기가 직접 부른다.) docs/share-design.md §6.5

void _startShareJanitor() {
  final janitor = ShareJanitor.instance = ShareJanitor();
  janitor
    ..sweep()
    ..startPeriodic();
  // 바인딩이 관찰자로 붙잡고 있어 따로 참조를 들 필요 없다.
  AppLifecycleListener(onResume: janitor.sweep);
}

/// 공유 수신 대기 — 앱이 켜져 있는 동안에만 근처 기기에 보인다.
/// (docs/share-design.md §6) 권한이 이미 있을 때만 조용히 시작한다 —
/// 처음이면 설정 › "가까운 기기에서 받기"에서 켠다. 미지원 플랫폼·권한
/// 없음이어도 앱은 정상 동작.
Future<void> _startShareReceiving(LoopDb db, VideoStore videos) async {
  final receiver = ShareReceiver.instance
    // 도착한 사슬을 요약 시트로 — 사용자가 가져오기/거절을 고른다.
    ..onReceived = (file) => ReceiveSheet.openSheet(db, file, videos);
  // 받는 중·중단을 어느 화면에서든 하단 스낵바로.
  IncomingShareNotice(
    receiver: receiver,
    messenger: () => LoopAppNavigator.messengerKey.currentState,
  ).attach();
  try {
    await receiver.startIfAllowed(db);
  } catch (_) {}
}

class LoopApp extends StatelessWidget {
  const LoopApp({
    super.key,
    required this.db,
    required this.videos,
    required this.images,
    this.pcLink,
  });

  final LoopDb db;
  final VideoStore videos;
  final ImageStore images;

  /// PC 연결 — 맥 브리지 클라이언트. 앱 전체에 하나.
  final PcLinkController? pcLink;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loop',
      navigatorKey: LoopAppNavigator.key,
      scaffoldMessengerKey: LoopAppNavigator.messengerKey,
      debugShowCheckedModeBanner: false,
      // 폰(시스템) 언어를 따른다. 미지원 언어는 한국어로.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLoopTheme(),
      home: TimelineScreen(db: db, videos: videos, images: images, pcLink: pcLink),
    );
  }
}
