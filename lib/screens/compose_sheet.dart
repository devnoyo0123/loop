import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../services/image_service.dart';
import '../utils/time_format.dart';
import 'loop_sheet.dart';

/// 작성 결과: 내용 + 알림 예약 시각(선택) + 첨부 이미지(압축된 JPEG).
class ComposeResult {
  const ComposeResult(this.content, this.loopAt, {this.images = const []});

  final String content;
  final DateTime? loopAt;
  final List<Uint8List> images;
}

/// 로그 작성 시트. [parent]가 있으면 포크(이어쓰기) 모드.
class ComposeSheet extends StatefulWidget {
  const ComposeSheet({super.key, this.parent});

  final LogEntry? parent;

  static Future<ComposeResult?> show(
    BuildContext context, {
    LogEntry? parent,
  }) =>
      showModalBottomSheet<ComposeResult>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: ComposeSheet(parent: parent),
        ),
      );

  @override
  State<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<ComposeSheet> {
  final _controller = TextEditingController();
  final _images = <Uint8List>[];
  bool _picking = false;

  /// ⏰ 버튼으로 예약한 알림 시각.
  DateTime? _loopAt;

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
      final prepared = await ImageService.prepareAll(
        [for (final f in files.take(remaining)) await f.readAsBytes()],
        limit: remaining,
      );
      if (prepared.isNotEmpty && mounted) {
        setState(() => _images.addAll([for (final p in prepared) p.jpegBytes]));
      }
    } catch (_) {
      // 픽 취소 등 — 조용히 무시
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// ⏰ 버튼 — 알림 예약 시트를 열고 결과를 반영한다.
  Future<void> _reserveLoop() async {
    final at = await LoopOncePicker.show(context, initial: _loopAt);
    if (at != null && mounted) setState(() => _loopAt = at);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _images.isEmpty) return;
    Navigator.pop(
      context,
      ComposeResult(text, _loopAt, images: List.of(_images)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parent = widget.parent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LoopSpacing.m, LoopSpacing.l, LoopSpacing.m, LoopSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parent != null)
            Padding(
              padding: const EdgeInsets.only(bottom: LoopSpacing.s),
              child: Text(
                l10n.forkOf(formatMixed(
                    parent.createdAt, DateTime.now(), l10n.yesterday)),
                style: const TextStyle(
                    color: LoopColors.lavender, fontSize: 13),
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
                  color: LoopColors.text, fontSize: 16, height: 1.5),
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
                      strokeWidth: 2, color: LoopColors.lavender))
              : const Icon(Icons.photo_library_outlined,
                  color: LoopColors.textDim),
          tooltip: l10n.attachPhoto,
        ),
        IconButton(
          onPressed: _reserveLoop,
          icon: Icon(
            _loopAt == null
                ? Icons.notification_add_outlined
                : Icons.notifications_active,
            color:
                _loopAt == null ? LoopColors.textDim : LoopColors.mint,
          ),
          tooltip: l10n.reserveAlarm,
        ),
        if (_loopAt != null) ...[
          Text(
            formatMixed(_loopAt!, DateTime.now(), l10n.yesterday),
            style: const TextStyle(color: LoopColors.mint, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _loopAt = null),
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
            child: Image.memory(bytes,
                cacheWidth: 120,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                gaplessPlayback: true),
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
                child: const Icon(Icons.close, size: 12,
                    color: LoopColors.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
