import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/repeat_rule.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/nearby_share.dart';
import '../services/nearby_transport.dart';
import '../services/share_files.dart';
import '../services/share_platform.dart';
import '../services/video_store.dart';
import '../utils/time_format.dart';
import 'timeline_screen.dart';

/// 앱 수준 이벤트(공유 수신)가 시트를 띄울 때 쓰는 루트 네비게이터 키.
class LoopAppNavigator {
  static final key = GlobalKey<NavigatorState>();

  /// 루트 스낵바 — 받는 중 알림처럼 화면과 무관한 앱 수준 알림용.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
}

/// 사슬 공유 — 보내기 시트. (docs/mockups/share-p2p-1, docs/share-design.md §5)
class ShareSheet extends StatefulWidget {
  const ShareSheet({
    super.key,
    required this.db,
    required this.rootId,
    this.videos,
    this.transport,
    this.platform,
  });

  final LoopDb db;

  /// 사슬 원본 — 이 로그와 그 모든 하위가 페이로드가 된다.
  final String rootId;

  final VideoStore? videos;

  /// 테스트용 주입 — 없으면 실제 Nearby 구현·기기 정보.
  final NearbyTransport? transport;
  final SharePlatform? platform;

  static Future<void> open(
    BuildContext context, {
    required LoopDb db,
    required String rootId,
    VideoStore? videos,
    NearbyTransport? transport,
    SharePlatform? platform,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ShareSheet(
          db: db,
          rootId: rootId,
          videos: videos,
          transport: transport,
          platform: platform,
        ),
      ),
    ),
  );

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  late final TextEditingController _name;
  bool _stripLocation = true; // 위치는 빼고 보내는 게 기본
  bool _stripMedia = false;
  late final ShareChainStats _stats;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.db.shareName() ?? '');
    _stats = ShareChainStats.of(widget.db, widget.rootId);
    if (_name.text.isEmpty) _prefillDeviceName();
  }

  /// 표시명 기본값은 기기 이름 (share-design.md §2) — 저장은 보낼 때.
  Future<void> _prefillDeviceName() async {
    final name = await (widget.platform ?? NearbyShareDefaults.platform)
        .deviceName();
    if (mounted && _name.text.isEmpty) _name.text = name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ChainParticipant _self() {
    // 첫 공유라면 여기서 기기 정체성이 태어난다. (share-design.md §2)
    final name = _name.text.trim();
    widget.db.setShareName(name);
    return ChainParticipant(id: widget.db.peerId(), name: name);
  }

  List<ChainParticipant> get _participants => [_self()];

  /// 페이로드를 임시 파일로 — Nearby 파일 페이로드로 스트리밍 전송된다.
  Future<File> _writeTempFile() async {
    // 공유 전용 폴더(share/) — 청소·수동 정리가 관리한다. (share-design.md §6.5)
    final dir = await ShareTempFiles.dir();
    final file = File(
      '${dir.path}/loop-chain-${DateTime.now().millisecondsSinceEpoch}.looplog',
    );
    ShareTempFiles.hold(file.path); // 쓰는 동안 청소 제외 — 전송 화면이 이어 받는다
    final sink = file.openWrite();
    try {
      final buf = StringBuffer();
      for (final line in widget.db.exportChainLines(
        rootId: widget.rootId,
        participants: _participants,
        stripLocation: _stripLocation,
        includeMedia: !_stripMedia,
        videoLoader: widget.videos == null
            ? null
            : (fileName) {
                final bytes = widget.videos!.read(fileName);
                return bytes == null ? null : base64Encode(bytes);
              },
      )) {
        buf
          ..write(line)
          ..write('\n');
        if (buf.length >= 512 * 1024) {
          sink.write(buf);
          buf.clear();
        }
      }
      if (buf.isNotEmpty) sink.write(buf);
    } finally {
      await sink.flush();
      await sink.close();
    }
    return file;
  }

  Future<void> _sendNearby() async {
    final file = await _writeTempFile();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop(); // 시트를 닫고 전송 화면으로
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ShareTransferScreen(
          file: file,
          myName: _self().name,
          stats: _stats,
          transport: widget.transport,
          platform: widget.platform,
        ),
      ),
    );
  }

  Future<void> _exportFile() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final ok = await ExportService.exportLines(
      'loop-chain-${n.year}${two(n.month)}${two(n.day)}'
      '-${two(n.hour)}${two(n.minute)}.looplog',
      widget.db.exportChainLines(
        rootId: widget.rootId,
        participants: _participants,
        stripLocation: _stripLocation,
        includeMedia: !_stripMedia,
        videoLoader: widget.videos == null
            ? null
            : (fileName) {
                final bytes = widget.videos!.read(fileName);
                return bytes == null ? null : base64Encode(bytes);
              },
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.exportDone : l10n.exportCancel),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final root = widget.db.byId(widget.rootId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '↩ ${l10n.shareChainTitle}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (root != null && root.content.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: LoopColors.surfaceHi,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    root.content,
                    style: const TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatCard(root.createdAt),
                    style: const TextStyle(fontSize: 12, color: LoopColors.textDim),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _count(_stats.logs, l10n.shareCountLogs),
              const SizedBox(width: 8),
              _count(_stats.photos, l10n.shareCountPhotos),
              const SizedBox(width: 8),
              _count(_stats.videos, l10n.shareCountVideos),
              const SizedBox(width: 8),
              _count(_stats.repeats, l10n.shareCountRepeats),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.shareNameLabel,
              hintText: l10n.shareNameHint,
              counterText: '',
            ),
            maxLength: 20,
            // 입력 즉시 저장 — 공유를 실행하지 않고 닫아도 이름이 남는다.
            onChanged: (v) => widget.db.setShareName(v.trim()),
          ),
          _toggle(
            l10n.shareStripLocation,
            l10n.shareStripLocationDesc,
            _stripLocation,
            (v) => setState(() => _stripLocation = v),
          ),
          _toggle(
            l10n.shareStripMedia,
            l10n.shareStripMediaDesc,
            _stripMedia,
            (v) => setState(() => _stripMedia = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sendNearby,
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
            ),
            child: Text(
              l10n.shareSendNearby,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: _exportFile,
            child: Text(l10n.shareExportFile),
          ),
        ],
      ),
    );
  }

  Widget _count(int n, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: LoopColors.surfaceHi,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$n',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: LoopColors.mint,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: LoopColors.textDim)),
        ],
      ),
    ),
  );

  Widget _toggle(String label, String desc, bool value, ValueChanged<bool> on) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14.5)),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: LoopColors.textDim),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: on, activeThumbColor: LoopColors.mint),
        ],
      );
}

/// 전송 화면 — 발견 목록에서 기기 선택 → 연결 → 진행 → 완료/실패.
/// (docs/mockups/share-p2p-2) 상태 머신은 [ShareSendController]가 갖고,
/// 이 화면은 그리기만 한다 — 전송 계층은 생성자로 갈아 끼울 수 있다.
class ShareTransferScreen extends StatefulWidget {
  const ShareTransferScreen({
    super.key,
    required this.file,
    required this.myName,
    required this.stats,
    this.transport,
    this.platform,
    this.clock,
  });

  final File file;
  final String myName;
  final ShareChainStats stats;

  /// 테스트용 주입 — 없으면 실제 Nearby 구현·시계.
  final NearbyTransport? transport;
  final SharePlatform? platform;
  final DateTime Function()? clock;

  @override
  State<ShareTransferScreen> createState() => _ShareTransferScreenState();
}

class _ShareTransferScreenState extends State<ShareTransferScreen> {
  late final ShareSendController _c;

  @override
  void initState() {
    super.initState();
    _c = ShareSendController(
      file: widget.file,
      myName: widget.myName,
      transport: widget.transport,
      platform: widget.platform,
      clock: widget.clock,
    )..addListener(_changed);
    ShareTempFiles.hold(widget.file.path); // 보내는 동안 청소 제외
    _c.start();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c
      ..removeListener(_changed)
      ..dispose(); // 진행 중이면 취소까지
    _deleteFile();
    // 세션 종료 — 남은 쓰레기(이전에 죽은 세션 포함)도 같이 청소.
    ShareJanitor.instance?.sweep();
    super.dispose();
  }

  void _deleteFile() {
    try {
      if (widget.file.existsSync()) widget.file.deleteSync();
    } catch (_) {}
    ShareTempFiles.release(widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stage = _c.stage;
    final sending = stage == ShareStage.sending;
    final failed = stage == ShareStage.fail;
    return Scaffold(
      backgroundColor: LoopColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.shareSendNearby,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!_c.finished)
                    TextButton(
                      onPressed: () async {
                        await _c.cancel();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(l10n.cancel),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _stageText(l10n),
                style: TextStyle(
                  fontSize: 13.5,
                  color: failed ? LoopColors.danger : LoopColors.mint,
                ),
              ),
              const SizedBox(height: 18),
              if (stage == ShareStage.searching)
                Expanded(child: _deviceList(l10n))
              else ...[
                if (_c.device != null) _selectedCard(l10n),
                if (failed && _failureHelp(l10n) != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _failureHelp(l10n)!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: LoopColors.textDim,
                    ),
                  ),
                ],
                if (sending) ...[
                  const Spacer(),
                  Text(
                    '${(_c.progress * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: LoopColors.mint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.shareSending,
                    style: const TextStyle(fontSize: 13, color: LoopColors.textDim),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: _c.progress,
                      minHeight: 10,
                      backgroundColor: LoopColors.surfaceHi,
                      color: LoopColors.mint,
                    ),
                  ),
                  if (_progressDetail(l10n) case final detail?) ...[
                    const SizedBox(height: 10),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: LoopColors.textDim),
                    ),
                  ],
                  if (_c.slow) ...[
                    const SizedBox(height: 14),
                    Container(
                      key: const ValueKey('share-slow-hint'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LoopColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LoopColors.lavender),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.wifi, size: 18, color: LoopColors.lavender),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.shareSlowHint,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                ] else
                  const Spacer(),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LoopColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LoopColors.line),
                ),
                child: Text(
                  l10n.shareHintOffline,
                  style: const TextStyle(fontSize: 13, height: 1.55, color: Color(0xFFC9CDD9)),
                ),
              ),
              if (failed)
                TextButton(
                  onPressed: _c.retry,
                  child: Text(l10n.shareRetry),
                ),
              if (_c.finished)
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: LoopColors.lavender,
                    foregroundColor: LoopColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    stage == ShareStage.done ? l10n.shareSent : l10n.laterAction,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 발견 목록 — 탭해서 고른다(자동 연결 없음). 비었으면 받는 쪽 안내.
  Widget _deviceList(AppLocalizations l10n) {
    final devices = _c.devices;
    if (devices.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 24),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: LoopColors.mint),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.shareWaitingReceiver,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.55, color: LoopColors.textDim),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final d = devices[i];
        return Material(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: ValueKey('share-device-${d.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _c.select(d),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LoopColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone, color: LoopColors.mint),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      d.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    l10n.shareTapToSend,
                    style: const TextStyle(fontSize: 12.5, color: LoopColors.mint),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 고른 기기 카드 — 연결·전송·완료·실패 상태.
  Widget _selectedCard(AppLocalizations l10n) {
    final failed = _c.stage == ShareStage.fail;
    final name = _c.device!.name;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: failed ? LoopColors.danger : LoopColors.mint,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: failed ? LoopColors.danger : LoopColors.mint,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                failed ? '!' : '✓',
                style: const TextStyle(color: LoopColors.bg, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  failed ? l10n.shareSendFail : l10n.shareDeviceConnected(name),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: failed ? LoopColors.danger : LoopColors.mint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stageText(AppLocalizations l10n) {
    switch (_c.stage) {
      case ShareStage.searching:
        return l10n.shareSearching;
      case ShareStage.connecting:
      case ShareStage.sending:
        return l10n.shareDeviceConnected(_c.device?.name ?? '');
      case ShareStage.done:
        return l10n.shareSent;
      case ShareStage.fail:
        return _c.failure == ShareFailure.notFound
            ? l10n.shareNotFound
            : l10n.shareSendFail;
    }
  }

  /// 실패 때 다음 행동 안내 — 권한이면 이유, 못 찾았으면 받는 쪽 설정.
  /// "3.2 MB / 12 MB · 0.2 MB/s · 약 45초 남음" — 속도를 아직 모르면 생략.
  String? _progressDetail(AppLocalizations l10n) {
    final rate = _c.bytesPerSecond;
    if (rate == null || _c.totalBytes <= 0) return null;
    final base = l10n.shareProgressDetail(
      formatShareBytes(_c.sentBytes),
      formatShareBytes(_c.totalBytes),
      formatShareBytes(rate.round()),
    );
    final eta = _c.eta;
    if (eta == null) return base;
    return '$base · ${formatShareEta(l10n, eta)}';
  }

  String? _failureHelp(AppLocalizations l10n) => switch (_c.failure) {
    ShareFailure.stalled => l10n.shareStalled,
    ShareFailure.permission => l10n.sharePermBody,
    ShareFailure.notFound => l10n.shareWaitingReceiver,
    _ => null,
  };
}

/// 남은 시간 — 1분 미만은 5초 단위 올림, 그 이상은 분 올림.
String formatShareEta(AppLocalizations l10n, Duration eta) {
  final s = eta.inSeconds;
  if (s < 60) {
    final rounded = ((s + 4) ~/ 5) * 5;
    return l10n.shareEtaSeconds(rounded < 5 ? 5 : rounded);
  }
  return l10n.shareEtaMinutes((s + 59) ~/ 60);
}

/// 공유받은 사슬 — 요약 → 가져오기 방식 선택 → 완료.
/// (docs/mockups/share-p2p-3·4) 파일은 Nearby 수신 콜백이 넘겨준 것.
class ReceiveSheet extends StatefulWidget {
  const ReceiveSheet({
    super.key,
    required this.db,
    required this.file,
    required this.videos,
  });

  final LoopDb db;
  final File file;
  final VideoStore videos;

  /// Nearby 수신 콜백에서 연다 — 루트 네비게이터 키로 띄운다.
  static Future<void> openSheet(
    LoopDb db,
    File file,
    VideoStore videos,
  ) async {
    final context = LoopAppNavigator.key.currentState?.context;
    if (context == null || !context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: ReceiveSheet(db: db, file: file, videos: videos),
      ),
    );
  }

  @override
  State<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<ReceiveSheet> {
  bool _adopt = true; // 이어받기가 기본 선택
  bool _importing = false;
  ChainImportResult? _result;
  RepeatRule? _adoptedRule;
  _ChainPeek? _peek;

  @override
  void initState() {
    super.initState();
    ShareTempFiles.hold(widget.file.path); // 시트가 떠 있는 동안 청소 제외
    _peekFile();
  }

  /// 시트가 어떻게 닫히든(가져오기·거절·바깥 탭·실패) 받은 임시 파일은
  /// 여기서 지운다 — 가져온 내용은 이미 DB와 미디어 저장소에 있다.
  @override
  void dispose() {
    try {
      if (widget.file.existsSync()) widget.file.deleteSync();
    } catch (_) {}
    ShareTempFiles.release(widget.file.path);
    ShareJanitor.instance?.sweep();
    super.dispose();
  }

  Future<void> _peekFile() async {
    try {
      final peek = await _ChainPeek.of(widget.file);
      if (mounted) setState(() => _peek = peek);
    } catch (_) {
      if (mounted) setState(() => _peek = null); // 깨진 페이로드 — 거절만 노출
    }
  }

  Stream<Uint8List> _chunks() => widget.file
      .openRead()
      .map((c) => c is Uint8List ? c : Uint8List.fromList(c));

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await widget.db.importSharedChainLines(
        ImportService.linesFromChunks(_chunks()),
        via: 'p2p',
        adoptLoop: _adopt,
        videoWriter: (fileName, bytes) => widget.videos.save(
          fileName.endsWith(VideoStore.ext)
              ? fileName.substring(0, fileName.length - VideoStore.ext.length)
              : fileName,
          bytes,
        ),
      );
      final rule = _adopt ? widget.db.activeRuleInChain(result.rootId ?? '') : null;
      if (!mounted) return;
      setState(() {
        _result = result;
        _adoptedRule = rule;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(LoopAppNavigator.key.currentState!.context)
          .showSnackBar(
        SnackBar(content: Text(l10n.receiveFail), duration: const Duration(seconds: 3)),
      );
      if (mounted) setState(() => _importing = false);
    }
  }

  void _close({required bool viewChain}) {
    if (_result != null) {
      // 임시 파일은 dispose가 지운다.
      // 타임라인이 새 사슬을 잡도록 — 화면에 돌아올 때 리로드.
      TimelineScreen.shareDataChanged(
        viewChainId: viewChain ? _result!.rootId : null,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = _result;

    // ── 완료 (mockup 4) ──
    if (result != null) {
      final root = result.rootId == null ? null : widget.db.byId(result.rootId!);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LoopColors.mint.withValues(alpha: .1),
                  border: Border.all(color: LoopColors.mint, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: LoopColors.mint,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.receiveDone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.receiveDoneDesc(result.logs),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: LoopColors.textDim),
            ),
            const SizedBox(height: 18),
            if (root != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LoopColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LoopColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(root.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 6),
                    Text(
                      formatCard(root.createdAt),
                      style: const TextStyle(fontSize: 12, color: LoopColors.textDim),
                    ),
                  ],
                ),
              ),
            if (_adoptedRule != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LoopColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LoopColors.lavender.withValues(alpha: .4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.receiveAdoptedTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LoopColors.lavender,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.receiveAdoptedDesc,
                      style: const TextStyle(fontSize: 13, height: 1.55),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.receiveNextFire(formatCard(_adoptedRule!.nextFireAt)),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: LoopColors.mint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _close(viewChain: true),
              style: FilledButton.styleFrom(
                backgroundColor: LoopColors.lavender,
                foregroundColor: LoopColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.viewChainAction),
            ),
            TextButton(
              onPressed: () => _close(viewChain: false),
              child: Text(l10n.laterAction),
            ),
          ],
        ),
      );
    }

    final peek = _peek;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            peek == null ? l10n.receiveTitle : l10n.receiveFrom(peek.senderName),
            style: const TextStyle(fontSize: 12.5, color: LoopColors.mint),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.receiveTitle,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          if (peek != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: LoopColors.surfaceHi,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peek.rootContent, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                  const SizedBox(height: 5),
                  Text(
                    '${l10n.shareCountLogs} ${peek.logs} · '
                    '${l10n.shareCountPhotos} ${peek.photos} · '
                    '${l10n.shareCountVideos} ${peek.videos}',
                    style: const TextStyle(fontSize: 12, color: LoopColors.textDim),
                  ),
                ],
              ),
            ),
            if (peek.locationStripped)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LoopColors.mint.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LoopColors.mint.withValues(alpha: .25)),
                    ),
                    child: Text(
                      '🔒 ${l10n.receiveBadgeNoLocation}',
                      style: const TextStyle(fontSize: 11.5, color: LoopColors.mint),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.receiveQuestion,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _choice(
            selected: !_adopt,
            icon: '📥',
            title: l10n.receiveOnly,
            desc: l10n.receiveOnlyDesc,
            onTap: () => setState(() => _adopt = false),
          ),
          const SizedBox(height: 10),
          _choice(
            selected: _adopt,
            icon: '🔁',
            title: l10n.receiveAdopt,
            desc: l10n.receiveAdoptDesc,
            onTap: () => setState(() => _adopt = true),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _importing || peek == null ? null : _import,
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.receiveImport),
          ),
          TextButton(
            onPressed: () => _close(viewChain: false),
            child: Text(l10n.receiveDecline),
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required bool selected,
    required String icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LoopColors.surfaceHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? LoopColors.lavender : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? LoopColors.lavender : LoopColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: selected
                  ? const Color(0xFFB9AEE6)
                  : LoopColors.textDim,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 시트 요약 카운트 — 미리보기용.
class ShareChainStats {
  ShareChainStats(this.logs, this.photos, this.videos, this.repeats);

  factory ShareChainStats.of(LoopDb db, String rootId) {
    final s = db.chainStats(rootId);
    return ShareChainStats(s.logs, s.photos, s.videos, s.repeats);
  }

  final int logs;
  final int photos;
  final int videos;
  final int repeats;
}

/// 페이로드 가볍게 훑기 — 임포트 전 요약. (라인 재사용: ImportService)
class _ChainPeek {
  _ChainPeek({
    required this.senderName,
    required this.rootContent,
    required this.logs,
    required this.photos,
    required this.videos,
    required this.locationStripped,
  });

  final String senderName;
  final String rootContent;
  final int logs;
  final int photos;
  final int videos;
  final bool locationStripped;

  static Future<_ChainPeek> of(File file) async {
    String? senderName;
    String rootContent = '';
    var logs = 0;
    var photos = 0;
    var videos = 0;
    var locationStripped = false;
    await for (final line
        in ImportService.linesFromChunks(file.openRead().map(_asBytes))) {
      final m = jsonDecode(line) as Map<String, Object?>;
      switch (m['type']) {
        case 'looplog':
          final participants = m['participants'] as List<Object?>? ?? const [];
          if (participants.isNotEmpty) {
            senderName = (participants.first as Map)['name'] as String;
          }
        case 'log':
          logs++;
          if (m['rootId'] == null) {
            rootContent = (m['content'] as String?) ?? '';
            locationStripped =
                m['latitude'] == null && m['longitude'] == null;
          }
        case 'image':
          photos++;
        case 'video':
          videos++;
      }
    }
    return _ChainPeek(
      senderName: senderName ?? 'Loop',
      rootContent: rootContent,
      logs: logs,
      photos: photos,
      videos: videos,
      locationStripped: locationStripped,
    );
  }

  static Uint8List _asBytes(List<int> c) =>
      c is Uint8List ? c : Uint8List.fromList(c);
}
