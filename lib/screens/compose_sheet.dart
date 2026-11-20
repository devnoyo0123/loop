import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../services/image_service.dart';
import '../utils/time_format.dart';
import '../utils/coach_tour.dart';
import '../utils/video_duration.dart';
import '../widgets/coach_mark.dart';
import 'loop_sheet.dart';

/// 작성 결과: 내용 + 루프 예약(시각·알림/알람) + 첨부 이미지(압축된 JPEG).
class ComposeResult {
  const ComposeResult(
    this.content,
    this.loopAt, {
    this.loopAlarm = false,
    this.images = const [],
    this.video,
  });

  final String content;
  final DateTime? loopAt;

  /// 루프를 알람처럼(무음 무시·꺼야 멈춤·전체화면) 울릴지. (2026-10-18)
  final bool loopAlarm;
  final List<Uint8List> images;

  /// 촬영한 동영상 본문 (v1: 로그당 1개) — 저장은 타임라인이 VideoStore로.
  final Uint8List? video;
}

/// 첫 루프 투어(②·③)를 작성 시트 안에서 진행하기 위한 연결점.
/// 타임라인이 [CoachTour]를 들고 있고, 시트는 단계만 보고 이벤트만 알린다.
class ComposeCoach {
  const ComposeCoach({
    required this.step,
    required this.onLoopReserved,
    required this.onLoopCleared,
    required this.onSkip,
  });

  final ValueListenable<CoachStep> step;
  final VoidCallback onLoopReserved;
  final VoidCallback onLoopCleared;
  final VoidCallback onSkip;
}

/// 로그 작성 시트. [parent]가 있으면 포크(이어쓰기) 모드.
/// [banner]는 스타터 등 상단 안내 한 줄 — 포크 배너와 같은 자리.
class ComposeSheet extends StatefulWidget {
  const ComposeSheet({super.key, this.parent, this.banner, this.coach});

  final LogEntry? parent;

  final String? banner;

  /// 첫 루프 투어 진행 중일 때만 — 예약·저장 버튼에 코치 마크.
  final ComposeCoach? coach;

  static Future<ComposeResult?> show(
    BuildContext context, {
    LogEntry? parent,
    String? banner,
    ComposeCoach? coach,
  }) => showModalBottomSheet<ComposeResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      // 하단 제스처 바에 [로그 남기기] 버튼이 가려지지 않게 SafeArea.
      child: SafeArea(
        top: false,
        child: ComposeSheet(parent: parent, banner: banner, coach: coach),
      ),
    ),
  );

  @override
  State<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<ComposeSheet> {
  final _controller = TextEditingController();
  final _images = <Uint8List>[];
  bool _picking = false;

  /// ⏰ 버튼으로 예약한 루프 시각과 방식(알림/알람).
  DateTime? _loopAt;
  bool _loopAlarm = false;

  // 코치 마크 대상 — ② 예약 버튼, ③ 저장 버튼.
  final _reserveKey = GlobalKey();
  final _saveKey = GlobalKey();
  final _sheetKey = GlobalKey(); // 말풍선은 시트 위 빈 곳에 — 입력창·키보드를 가리지 않게

  /// 촬영한 동영상 본문 — v1은 로그당 하나. (저장은 VideoStore가 파일로)
  Uint8List? _videoBytes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking) return;
    final remaining = ImageService.maxImagesPerLog - _images.length;
    if (remaining <= 0) return;
    setState(() => _picking = true);
    try {
      final files = await ImagePicker().pickMultiImage();
      final prepared = await ImageService.prepareAll([
        for (final f in files.take(remaining)) await f.readAsBytes(),
      ], limit: remaining);
      if (prepared.isNotEmpty && mounted) {
        setState(() => _images.addAll([for (final p in prepared) p.jpegBytes]));
      }
    } catch (_) {
      // 픽 취소 등 — 조용히 무시
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 사진 촬영 — 시스템 카메라 앱을 띄워 찍은 한 장을 같은 파이프라인으로
  /// 압축해 첨부한다. (image_picker가 카메라 인텐트를 대행 — 앱에 카메라
  /// 권한·네이티브 코드가 필요 없고, 셔터음 등은 기기 카메라 앱 정책을
  /// 그대로 따른다. 2026-10-30 결정: 무음 기능은 넣지 않는다)
  Future<void> _shoot() async {
    if (_picking) return;
    final remaining = ImageService.maxImagesPerLog - _images.length;
    if (remaining <= 0) return;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.camera);
      if (file == null) return; // 촬영 취소
      final bytes = await file.readAsBytes();
      final prepared = await ImageService.prepareAll([bytes], limit: remaining);
      if (prepared.isNotEmpty && mounted) {
        setState(() => _images.addAll([for (final p in prepared) p.jpegBytes]));
      }
    } catch (_) {
      // 카메라 없는 환경·취소 등 — 조용히 무시
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 동영상 촬영 — 시스템 카메라 앱의 동영상 모드(사진 촬영과 같은 인텐트
  /// 방식). 길이는 1분으로 제한해 파일 크기가 폭주하지 않게 한다.
  Future<void> _shootVideo() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: videoMaxDuration,
      );
      if (file == null) return; // 촬영 취소
      final bytes = await file.readAsBytes();
      // EXTRA_DURATION_LIMIT를 무시하는 서드파티 카메라 앱이 있어 한 번 더
      // 검문 — 초과분은 첨부하지 않는다.
      if (videoExceedsLimit(bytes)) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.videoTooLong),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      if (mounted) setState(() => _videoBytes = bytes);
    } catch (_) {
      // 카메라 없는 환경·취소 등 — 조용히 무시
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// ⏰ 버튼 — 루프 예약 시트를 열고 결과를 반영한다.
  /// 이어쓰기라면 부모 체인의 루프 횟수로 망각곡선 추천 간격을 따른다.
  Future<void> _reserveLoop() async {
    final r = await LoopOncePicker.show(
      context,
      initial: _loopAt,
      initialAsAlarm: _loopAlarm,
      loopCount: widget.parent?.loopCount ?? 0,
    );
    if (r != null && mounted) {
      setState(() {
        _loopAt = r.at;
        _loopAlarm = r.asAlarm;
      });
      widget.coach?.onLoopReserved();
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    // 동영상만 찍어도 저장된다 — 쓰기 강제하지 않음. (v10.2 사용자 결정)
    if (text.isEmpty && _images.isEmpty && _videoBytes == null) return;
    Navigator.pop(
      context,
      ComposeResult(
        text,
        _loopAt,
        loopAlarm: _loopAlarm,
        images: List.of(_images),
        video: _videoBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    if (coach == null) return _buildSheet(context);
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<CoachStep>(
      valueListenable: coach.step,
      builder: (context, step, child) => CoachMarkLayer(
        spec: switch (step) {
          CoachStep.reserve => CoachSpec(
            target: _reserveKey,
            number: 2,
            total: CoachTour.total,
            title: l10n.coachReserveTitle,
            body: l10n.coachReserveBody,
            skipLabel: l10n.coachSkip,
            onSkip: coach.onSkip,
            dim: false, // 입력 중인 시트 — 덮지 않고 링·말풍선만
            bubbleAbove: _sheetKey,
          ),
          CoachStep.save => CoachSpec(
            target: _saveKey,
            number: 3,
            total: CoachTour.total,
            title: l10n.coachSaveTitle,
            body: l10n.coachSaveBody,
            skipLabel: l10n.coachSkip,
            onSkip: coach.onSkip,
            dim: false,
            bubbleAbove: _sheetKey,
          ),
          _ => null,
        },
        child: child!,
      ),
      child: _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parent = widget.parent;
    return Padding(
      key: _sheetKey,
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
          if (parent != null)
            Padding(
              padding: const EdgeInsets.only(bottom: LoopSpacing.s),
              child: Text(
                l10n.forkOf(
                  formatMixed(parent.createdAt, DateTime.now(), l10n.yesterday),
                ),
                style: const TextStyle(
                  color: LoopColors.lavender,
                  fontSize: 13,
                ),
              ),
            ),
          if (widget.banner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: LoopSpacing.s),
              child: Text(
                widget.banner!,
                style: const TextStyle(color: LoopColors.mint, fontSize: 13),
              ),
            ),
          // 글이 화면을 넘으면 시트가 밀리지 않도록 TextField 자체가 스크롤
          // 되게 제한한다 — 첨부 행·저장 버튼은 항상 아래에 보인다.
          Flexible(
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(
                color: LoopColors.text,
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: l10n.composeHint,
                hintStyle: const TextStyle(color: LoopColors.textDim),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          _attachRow(l10n),
          const SizedBox(height: LoopSpacing.m),
          FilledButton(
            key: _saveKey,
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
            ),
            onPressed: _submit,
            child: Text(l10n.saveLog),
          ),
        ],
      ),
    );
  }

  Widget _attachRow(AppLocalizations l10n) {
    return Row(
      children: [
        IconButton(
          onPressed: _picking ? null : _pick,
          icon: _picking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LoopColors.lavender,
                  ),
                )
              : const Icon(
                  Icons.photo_library_outlined,
                  color: LoopColors.textDim,
                ),
          tooltip: l10n.attachPhoto,
        ),
        IconButton(
          onPressed: _picking ? null : _shoot,
          icon: const Icon(
            Icons.photo_camera_outlined,
            color: LoopColors.textDim,
          ),
          tooltip: l10n.takePhoto,
        ),
        IconButton(
          onPressed: _picking ? null : _shootVideo,
          icon: Icon(
            Icons.videocam_outlined,
            color: _videoBytes == null ? LoopColors.textDim : LoopColors.mint,
          ),
          tooltip: l10n.takeVideo,
        ),
        if (_videoBytes != null) ...[
          const Icon(Icons.videocam, size: 13, color: LoopColors.mint),
          const SizedBox(width: 3),
          Text(
            l10n.videoAttached,
            style: const TextStyle(color: LoopColors.mint, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _videoBytes = null),
            child: const Icon(Icons.close, size: 14, color: LoopColors.textDim),
          ),
        ],
        IconButton(
          key: _reserveKey,
          onPressed: _reserveLoop,
          icon: Icon(
            _loopAt == null
                ? Icons.notification_add_outlined
                : _loopAlarm
                ? Icons.alarm_on
                : Icons.notifications_active,
            color: _loopAt == null ? LoopColors.textDim : LoopColors.mint,
          ),
          tooltip: l10n.reserveAlarm,
        ),
        if (_loopAt != null) ...[
          Icon(
            _loopAlarm ? Icons.alarm : Icons.notifications_active,
            size: 13,
            color: LoopColors.mint,
          ),
          const SizedBox(width: 3),
          Text(
            formatMixed(_loopAt!, DateTime.now(), l10n.yesterday),
            style: const TextStyle(color: LoopColors.mint, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _loopAt = null;
                _loopAlarm = false;
              });
              widget.coach?.onLoopCleared();
            },
            child: const Icon(Icons.close, size: 14, color: LoopColors.textDim),
          ),
        ],
        Text(
          '${_images.length}/${ImageService.maxImagesPerLog}',
          style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
        ),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: SizedBox(
            height: 60,
            child: _images.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _images.length; i++)
                        _preview(i, _images[i]),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _preview(int index, Uint8List bytes) {
    return Padding(
      padding: const EdgeInsets.only(right: LoopSpacing.s),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              cacheWidth: 120,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                decoration: const BoxDecoration(
                  color: LoopColors.bg,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: LoopColors.textDim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
