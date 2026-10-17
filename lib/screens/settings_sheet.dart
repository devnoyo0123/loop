import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/browser_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/location_service.dart';
import '../services/loop_notifications.dart';

/// 앱 설정 시트 — 지금은 "기본 브라우저" 선택.
/// 여기서 고른 브라우저로 웹 링크가 항상 열린다 (시스템 기본값도 가능).
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.db});

  final LoopDb db;

  /// 설정 저장 키 — db.settings 테이블. ('' = 시스템 기본값)
  static const browserPrefKey = 'browser_package';

  /// 위치 자동 캡처 키. ('0' = 끔, 그 외/없음 = 켬 — 기본 ON)
  static const locationCaptureKey = 'location_capture';

  static Future<void> show(BuildContext context, {required LoopDb db}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SettingsSheet(db: db),
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

  @override
  void initState() {
    super.initState();
    _preferred = BrowserService.preferredPackage;
    _locationOn = widget.db.getSetting(SettingsSheet.locationCaptureKey) != '0';
    _load();
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

  /// 전체 내보내기 — 저장 위치를 고르고 .looplog로 기록.
  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final ok = await ExportService.export(
        widget.db,
        fileName: ExportService.defaultFileName(),
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
      final stats = await ImportService.pickAndImport(widget.db);
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
  Future<void> _testFire() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    await LoopNotifications.scheduleLoop(
      logId: 'preview-notif',
      body: l10n.notifFallbackBody,
      at: now.add(const Duration(seconds: 5)),
      alarm: false,
    );
    await LoopNotifications.scheduleLoop(
      logId: 'preview-alarm',
      body: l10n.notifFallbackBody,
      at: now.add(const Duration(seconds: 20)),
      alarm: true,
      dbDir: widget.db.directory.path,
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
            icon: Icons.alarm,
            label: l10n.testFire,
            sub: l10n.testFireDesc,
            onTap: _testFire,
          ),
        ],
      ),
    );
  }

  /// 실행형 행 — 라디오가 아니라 눌러서 동작하는 설정 항목.
  Widget _actionRow({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
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
