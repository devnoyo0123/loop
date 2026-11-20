import 'dart:io';

import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/browser_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/location_service.dart';
import '../services/image_store.dart';
import '../services/loop_notifications.dart';
import '../services/pc_link.dart';
import '../services/nearby_share.dart';
import '../services/alarm_permission.dart';
import '../widgets/alarm_permission_prompt.dart';
import '../services/share_files.dart';
import '../services/video_store.dart';
import '../utils/starters.dart';
import 'guide_screen.dart';
import '../utils/coach_tour.dart';
import 'pc_link_screen.dart';

/// 앱 설정 시트 — 지금은 "기본 브라우저" 선택.
/// 여기서 고른 브라우저로 웹 링크가 항상 열린다 (시스템 기본값도 가능).
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.db,
    required this.videos,
    required this.images,
    this.receiver,
    this.shareDir,
    this.pcLink,
  });

  final LoopDb db;

  /// PC 연결 — 맥 브리지에 붙는 클라이언트(ADR-002). 없으면 항목을 숨긴다.
  final PcLinkController? pcLink;
  /// 공유 임시 폴더 — 없으면 앱 캐시의 share/. 테스트는 임시 폴더를 넘긴다.
  final Future<Directory> Function()? shareDir;

  /// 근거리 받기 대기 — 없으면 앱 전역 인스턴스. 테스트는 가짜 전송 계층으로
  /// 만든 것을 넘긴다.
  final ShareReceiver? receiver;

  /// 동영상·이미지 파일 저장소 — 내보내기 인라인·가져오기 복원에 쓴다.
  final VideoStore videos;
  final ImageStore images;

  /// 설정 저장 키 — db.settings 테이블. ('' = 시스템 기본값)
  static const browserPrefKey = 'browser_package';

  /// 위치 자동 캡처 키. ('0' = 끔, 그 외/없음 = 켬 — 기본 ON)
  static const locationCaptureKey = 'location_capture';

  /// 그때의 나 아침 알림 키. ('0' = 끔, 그 외/없음 = 켬 — 기본 ON)
  static const onThisDayKey = 'on_this_day';

  /// 하루 마무리 시각 키. ("HH:mm", 없음 = 기본 21:00) — "오늘 저녁" 칩,
  /// 스타터의 매일 밤, 그때의 나의 저녁 짝이 쓰는 하나의 기준.
  static const dayEndKey = 'day_end';

  /// 저장된 마무리 시각. ("HH:mm" — 값이 없거나 깨졌으면 기본 21:00)
  static String dayEndOf(LoopDb db) {
    final v = db.getSetting(dayEndKey);
    return v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)
        ? dayEndDefault
        : v;
  }

  static Future<void> show(
    BuildContext context, {
    required LoopDb db,
    required VideoStore videos,
    required ImageStore images,
    ShareReceiver? receiver,
    PcLinkController? pcLink,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // 항목이 늘어 시트가 화면을 넘는다 — 높이를 제한하고 스크롤하게.
    // (v10.1: 데이터 섹션이 화면 밖으로 밀려나던 문제 수정)
    builder: (_) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: SettingsSheet(
            db: db,
            videos: videos,
            images: images,
            receiver: receiver,
            pcLink: pcLink,
          ),
        ),
      ),
    ),
  );

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  String? _preferred;
  List<({String package, String label})> _browsers = [];
  String? _systemDefault;
  bool _loading = true;
  bool _exporting = false;
  bool _importing = false;

  /// 위치 자동 캡처 — 로그에 장소·날씨를 붙인다. (기본 ON)
  bool _locationOn = true;

  /// 그때의 나 아침 알림 — 과거의 기록을 다시 들려준다. (기본 ON)
  bool _onThisDayOn = true;

  /// 하루 마무리 시각 — "오늘 저녁"의 기준. (기본 21:00)
  TimeOfDay _dayEnd = const TimeOfDay(hour: 21, minute: 0);

  /// 근거리 받기 — 켜는 동안(권한 요청 중) 스위치를 잠근다.
  late final ShareReceiver _receiver;
  bool _receiveBusy = false;

  /// 공유 임시 파일 사용량 — 정리 행에 보여준다(읽는 중 null).
  ({int files, int bytes})? _shareUsage;
  bool _cleaning = false;

  @override
  void initState() {
    super.initState();
    _receiver = widget.receiver ?? ShareReceiver.instance;
    _receiver.addListener(_receiverChanged);
    widget.pcLink?.addListener(_receiverChanged);
    _loadShareUsage();
    _preferred = BrowserService.preferredPackage;
    _locationOn = widget.db.getSetting(SettingsSheet.locationCaptureKey) != '0';
    _onThisDayOn = widget.db.getSetting(SettingsSheet.onThisDayKey) != '0';
    final parts = SettingsSheet.dayEndOf(widget.db).split(':');
    _dayEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    _load();
  }

  @override
  void dispose() {
    _receiver.removeListener(_receiverChanged);
    widget.pcLink?.removeListener(_receiverChanged);
    super.dispose();
  }

  void _receiverChanged() {
    if (mounted) setState(() {});
  }

  Future<Directory> _shareFolder() => ShareTempFiles.dir(widget.shareDir);

  Future<void> _loadShareUsage() async {
    try {
      final u = await ShareTempFiles.usage(await _shareFolder());
      if (mounted) setState(() => _shareUsage = u);
    } catch (_) {
      if (mounted) setState(() => _shareUsage = (files: 0, bytes: 0));
    }
  }

  /// 공유 임시 파일 수동 정리 — 받다 만 파일·전송용 임시 파일을 지운다.
  /// 지금 주고받는 중인 파일은 남긴다. (share-design.md §6.5)
  Future<void> _cleanShareFiles() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shareCleanTitle),
        content: Text(l10n.shareCleanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.shareCleanAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cleaning = true);
    final cleared = await ShareTempFiles.clear(await _shareFolder());
    if (!mounted) return;
    setState(() => _cleaning = false);
    await _loadShareUsage();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.shareCleanDone(formatShareBytes(cleared.bytes))),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 가까운 기기에서 받기 — 켜면 그때 권한을 요청한다. (share-design.md §6)
  /// 거부되면 스위치는 꺼진 채로 이유를 알린다.
  Future<void> _toggleReceive(bool on) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _receiveBusy = true);
    var active = false;
    try {
      active = await _receiver.setEnabled(widget.db, on);
    } catch (_) {
      active = false;
    }
    if (!mounted) return;
    setState(() => _receiveBusy = false);
    if (on && !active) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sharePermBody),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _load() async {
    final res = await BrowserService.browsers();
    if (!mounted) return;
    setState(() {
      _browsers = res.browsers;
      _systemDefault = res.systemDefault;
      _loading = false;
    });
  }

  Future<void> _choose(String? pkg) async {
    setState(() => _preferred = pkg);
    BrowserService.preferredPackage = pkg;
    widget.db.setSetting(SettingsSheet.browserPrefKey, pkg ?? '');
  }

  /// 위치 자동 캡처 스위치 — 다음 저장부터 반영된다.
  Future<void> _toggleLocation(bool on) async {
    setState(() => _locationOn = on);
    LocationService.enabled = on;
    widget.db.setSetting(SettingsSheet.locationCaptureKey, on ? '' : '0');
  }

  /// 그때의 나 스위치 — 시트를 닫으면 타임라인이 예약을 다시 맞춘다.
  Future<void> _toggleOnThisDay(bool on) async {
    setState(() => _onThisDayOn = on);
    widget.db.setSetting(SettingsSheet.onThisDayKey, on ? '' : '0');
  }

  /// 하루 마무리 시각 선택 — "오늘 저녁" 칩과 스타터의 매일 밤이 따라온다.
  Future<void> _pickDayEnd() async {
    final t = await showTimePicker(context: context, initialTime: _dayEnd);
    if (t == null) return;
    setState(() => _dayEnd = t);
    widget.db.setSetting(
      SettingsSheet.dayEndKey,
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}',
    );
  }

  /// 전체 내보내기 — 저장 위치를 고르고 .looplog로 기록.
  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final ok = await ExportService.export(
        widget.db,
        fileName: ExportService.defaultFileName(),
        videos: widget.videos,
        images: widget.images,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.exportDone : l10n.exportCancel),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportFail),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// 가져오기 — 확인 대화상자 → SAF 파일 선택 → 머지 임포트.
  Future<void> _import() async {
    if (_importing) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importLogs),
        content: Text(
          l10n.importConfirmMessage,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.importLogs),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _importing = true);
    try {
      final stats = await ImportService.pickAndImport(
        widget.db,
        videos: widget.videos,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stats == null
                ? l10n.importCancel
                : stats.isEmpty
                ? l10n.importEmpty
                : l10n.importDone(stats.logs, stats.repeats),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importFail)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importFail)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// 발화 체험 — 알림(5초)·알람(20초)을 하나씩 울려본다. 실기기 감각 확인용.
  ///
  /// 새로 설치한 사람이 가장 먼저 눌러보는 버튼이다 — 전체 화면 알림이
  /// 막혀 있으면 알람이 소리만 나서 "알람이 안 된다"가 첫인상이 된다.
  /// 그래서 울리기 전에 먼저 권한을 안내한다. (2026-11-01)
  Future<void> _testFire() async {
    await AlarmPermissionPrompt.maybeShow(
      context,
      AlarmPermissionGuard(db: widget.db),
      force: true,
      requirePending: false,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    await LoopNotifications.scheduleLoop(
      logId: 'preview-notif',
      body: l10n.notifFallbackBody,
      at: now.add(const Duration(seconds: 5)),
      alarm: false,
      // 알림 모드 예시임을 알려 실제 알람 알림과 섞이지 않게 한다.
      title: l10n.testNotifTitle,
    );
    await LoopNotifications.scheduleLoop(
      logId: 'preview-alarm',
      body: l10n.notifFallbackBody,
      at: now.add(const Duration(seconds: 20)),
      alarm: true,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.testFireSoon),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.m,
        LoopSpacing.l,
        LoopSpacing.m,
        LoopSpacing.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsTitle,
            style: const TextStyle(
              color: LoopColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LoopSpacing.m),
          Text(
            l10n.defaultBrowser,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.defaultBrowserDesc,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 11),
          ),
          const SizedBox(height: LoopSpacing.s),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(LoopSpacing.l),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LoopColors.lavender,
                  ),
                ),
              ),
            )
          else if (_browsers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LoopSpacing.l),
              child: Text(
                l10n.browserEmpty,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
              ),
            )
          else ...[
            _row(
              label: l10n.systemDefault,
              sub: _systemDefault,
              selected: _preferred == null,
              onTap: () => _choose(null),
            ),
            for (final b in _browsers)
              _row(
                label: b.label,
                sub: b.package,
                selected: _preferred == b.package,
                onTap: () => _choose(b.package),
              ),
          ],
          const SizedBox(height: LoopSpacing.l),
          // 위치 자동 캡처 — 개인 기록 앱이라 꺼둘 수 있어야 한다.
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: LoopColors.textDim,
              ),
              const SizedBox(width: LoopSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationCapture,
                      style: const TextStyle(
                        color: LoopColors.text,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.locationCaptureDesc,
                      style: const TextStyle(
                        color: LoopColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _locationOn,
                activeThumbColor: LoopColors.mint,
                onChanged: _toggleLocation,
              ),
            ],
          ),
          if (_receiver.supported) ...[
            const SizedBox(height: LoopSpacing.l),
            // 가까운 기기에서 받기 — 앱이 켜져 있는 동안만 옆 기기에 보인다.
            Row(
              children: [
                const Icon(
                  Icons.wifi_tethering,
                  size: 18,
                  color: LoopColors.textDim,
                ),
                const SizedBox(width: LoopSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.receiveSetting,
                        style: const TextStyle(
                          color: LoopColors.text,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.receiveSettingDesc,
                        style: const TextStyle(
                          color: LoopColors.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const ValueKey('share-receive-switch'),
                  value: _receiver.active,
                  activeThumbColor: LoopColors.mint,
                  onChanged: _receiveBusy ? null : _toggleReceive,
                ),
              ],
            ),
          ],
          const SizedBox(height: LoopSpacing.l),
          // 그때의 나 — 아침마다 과거의 기록을 다시 들려준다.
          Row(
            children: [
              const Icon(
                Icons.history_edu_outlined,
                size: 18,
                color: LoopColors.textDim,
              ),
              const SizedBox(width: LoopSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onThisDaySetting,
                      style: const TextStyle(
                        color: LoopColors.text,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.onThisDaySettingDesc,
                      style: const TextStyle(
                        color: LoopColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _onThisDayOn,
                activeThumbColor: LoopColors.mint,
                onChanged: _toggleOnThisDay,
              ),
            ],
          ),
          const SizedBox(height: LoopSpacing.l),
          // 하루 마무리 시각 — "오늘 저녁"의 기준. (탭 = 시계로 변경)
          GestureDetector(
            onTap: _pickDayEnd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s + 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.nights_stay_outlined,
                    size: 18,
                    color: LoopColors.textDim,
                  ),
                  const SizedBox(width: LoopSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dayEndSetting,
                          style: const TextStyle(
                            color: LoopColors.text,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          l10n.dayEndSettingDesc,
                          style: const TextStyle(
                            color: LoopColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _dayEnd.format(context),
                    style: const TextStyle(
                      color: LoopColors.mint,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: LoopColors.textDim,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: LoopSpacing.l),
          Text(
            l10n.settingsData,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: LoopSpacing.s),
          _actionRow(
            icon: _exporting
                ? Icons.hourglass_empty_outlined
                : Icons.ios_share_outlined,
            label: _exporting ? l10n.exporting : l10n.exportLogs,
            sub: l10n.exportAllDesc,
            onTap: _exporting ? null : _export,
          ),
          _actionRow(
            icon: _importing
                ? Icons.hourglass_empty_outlined
                : Icons.download_outlined,
            label: _importing ? l10n.importing : l10n.importLogs,
            sub: l10n.importAllDesc,
            onTap: _importing ? null : _import,
          ),
          _actionRow(
            key: const ValueKey('share-clean-row'),
            icon: Icons.cleaning_services_outlined,
            label: l10n.shareCleanTitle,
            sub: switch (_shareUsage) {
              null => '…',
              (bytes: 0, files: _) => l10n.shareCleanEmpty,
              final u => l10n.shareCleanDesc(formatShareBytes(u.bytes)),
            },
            onTap: _cleaning || (_shareUsage?.files ?? 0) == 0
                ? null
                : _cleanShareFiles,
          ),
          if (widget.pcLink case final pc?)
            // PC 연결 — 맥 브리지에 폰이 클라이언트로 붙는다 (ADR-002).
            _actionRow(
              key: const ValueKey('pclink-settings-row'),
              icon: Icons.cable,
              label: l10n.pcLinkSettingTitle,
              sub: pc.status == PcLinkStatus.connected
                  ? l10n.pcLinkSettingConnected
                  : l10n.pcLinkSettingOff,
              onTap: () => PcLinkScreen.show(context, controller: pc),
            ),
          _actionRow(
            icon: Icons.alarm,
            label: l10n.testFire,
            sub: l10n.testFireDesc,
            onTap: _testFire,
          ),
          const SizedBox(height: LoopSpacing.l),
          Text(
            l10n.settingsAppInfo,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: LoopSpacing.s),
          // Loop 사용법 — 기능이 많아 그림으로 안내한다. (2026-11-01 사용자 요청)
          _actionRow(
            key: const ValueKey('guide-row'),
            icon: Icons.menu_book_outlined,
            label: l10n.guideOpen,
            sub: l10n.guideOpenDesc,
            onTap: () => GuideScreen.open(context),
          ),
          // 첫 루프 투어(코치 마크)를 처음부터 다시 — 설정을 닫으면 타임라인이
          // ①부터 띄운다. [Loop 걸기] 한 번짜리 안내(⑤)도 다시 보이게.
          _actionRow(
            key: const ValueKey('tour-replay-row'),
            icon: Icons.tips_and_updates_outlined,
            label: l10n.coachReplay,
            sub: l10n.coachReplayDesc,
            onTap: () {
              widget.db.setSetting(CoachTour.storeKey, CoachStep.write.name);
              widget.db.deleteSetting(CoachTour.armHintKey);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  /// 실행형 행 — 라디오가 아니라 눌러서 동작하는 설정 항목.
  Widget _actionRow({
    Key? key,
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s + 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? LoopColors.mint : LoopColors.textDim,
            ),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled ? LoopColors.text : LoopColors.textDim,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LoopColors.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required String label,
    String? sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s + 2),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? LoopColors.mint : LoopColors.textDim,
            ),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? LoopColors.text : LoopColors.textDim,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (sub != null && sub != label)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LoopColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
