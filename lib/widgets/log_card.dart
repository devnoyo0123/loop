import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
import '../services/browser_service.dart';
import '../services/weather_service.dart';
import '../utils/time_format.dart';
import '../utils/web_link.dart';
import '../utils/youtube.dart';
/// 카드 메뉴 액션. fork/알림/반복은 통합 `loop` 하나로 흡수됐다 —
/// LoopSheet에서 지금 이어쓰기·한 번·반복을 고른다. (사용자 결정)
/// - loopView: 루프 사슬 보기 (최상위 원본 → … → 이 로그)
/// - loopForkTap: 빈 루프 도착 로그를 탭함 — 루프 보기/작성 시트를 띄운다.
enum LogMenuAction {
  edit,
  changeTime,
  loop,
  loopView,
  loopForkTap,
  delete
}

/// 타임라인의 로그 한 장. 포크면 들여쓰기 + 라벤더 연결 표시.
/// - 텍스트는 3줄까지 (넘으면 …) — 화면에 최소 3~4장 보이기 위한 높이 제한
/// - 이미지가 있으면 인디케이터, 텍스트 없이 이미지만 있으면 첫 장을 썸네일로
/// - 탭하면 상세: 전체 이미지 + 장소·날씨·원본 시각
class LogCard extends StatefulWidget {
  const LogCard({
    super.key,
    required this.log,
    this.parent,
    required this.onAction,
    this.imageSummary,
    this.imagesLoader,
    this.activeRepeatAsSource,
    this.activeRepeatAsFork,
  });

  final LogEntry log;

  /// 포크 부모 로그 (현재 윈도우에 없으면 null).
  final LogEntry? parent;

  final void Function(LogMenuAction action) onAction;

  /// 이 로그의 이미지 요약 (장수 + 첫 이미지 base64). 없으면 null.
  final LogImageSummary? imageSummary;

  /// 상세 펼칠 때 전체 이미지를 읽어오는 로더.
  final List<Uint8List> Function()? imagesLoader;

  /// 이 로그가 원본인 살아있는 반복 규칙. (🔁 상태 칩)
  final RepeatRule? activeRepeatAsSource;

  /// 이 로그를 반복 발화가 생성했다면 그 살아있는 규칙. (중지 가능)
  final RepeatRule? activeRepeatAsFork;

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  bool _expanded = false;
  Uint8List? _thumb;
  String? _thumbSource;
  List<Uint8List>? _images;
  String? _imagesSource;

  LogEntry get _log => widget.log;

  bool get _hasImages => (widget.imageSummary?.count ?? 0) > 0;

  @override
  void didUpdateWidget(covariant LogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ListView가 State를 재사용하므로 로그가 바뀌면 캐시를 비운다.
    if (oldWidget.log.id != widget.log.id) {
      _expanded = false;
      _thumb = null;
      _thumbSource = null;
      _images = null;
      _imagesSource = null;
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) _loadImagesIfNeeded();
    });
  }

  void _loadImagesIfNeeded() {
    if (!_hasImages || widget.imagesLoader == null) return;
    if (_imagesSource == widget.log.id) return;
    _imagesSource = widget.log.id;
    _images = widget.imagesLoader!();
  }

  Uint8List? get _thumbOrNull {
    final src = widget.imageSummary?.firstBase64;
    if (_thumbSource != src) {
      _thumbSource = src;
      _thumb = src == null ? null : Uint8List.fromList(base64Decode(src));
    }
    return _thumb;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFork = _log.isFork;
    final imageOnly = _log.content.isEmpty && _hasImages;
    // 루프 발화로 생긴 빈 로그(반복·단발 모두)는 탭 시 루프 보기/작성 시트로.
    final emptyLoopFork =
        _log.content.isEmpty && !imageOnly && _log.isFork;
    final ytId = youtubeVideoId(_log.content);
    // 유튜브가 아닌 첫 웹 링크 — 파비콘 + 브라우저 열기 버튼.
    final webUrl = ytId == null ? firstWebUrl(_log.content) : null;
    return Container(
      margin: EdgeInsets.fromLTRB(
        isFork ? LoopSpacing.xl : LoopSpacing.m,
        LoopSpacing.xs,
        LoopSpacing.m,
        LoopSpacing.xs,
      ),
      padding: const EdgeInsets.fromLTRB(
          LoopSpacing.m, LoopSpacing.s + 4, LoopSpacing.s, LoopSpacing.s + 2),
      decoration: BoxDecoration(
        color: _expanded ? LoopColors.surfaceHi : LoopColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: isFork
              ? const BorderSide(color: LoopColors.lavender, width: 2)
              : BorderSide.none,
        ),
      ),
      child: GestureDetector(
        onTap: emptyLoopFork
            ? () => widget.onAction(LogMenuAction.loopForkTap)
            : _toggle,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(isFork, l10n),
                  if (_log.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _log.content,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: LoopColors.text, fontSize: 15, height: 1.45),
                    ),
                  ],
                  if (emptyLoopFork) ...[
                    const SizedBox(height: 4),
                    Text(
                      _loopForkPreview(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: LoopColors.text, fontSize: 14, height: 1.45),
                    ),
                  ],
                  if (ytId != null) ...[
                    const SizedBox(height: 6),
                    _youtubeInline(ytId),
                  ],
                  if (webUrl != null) ...[
                    const SizedBox(height: 6),
                    _webInline(webUrl),
                  ],
                  if (imageOnly) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _thumbOrNull!,
                        cacheWidth: 320, // 타임라인용 작은 디코딩
                        height: 176,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ],
                  if (_expanded) ...[
                    if (_images != null && _images!.isNotEmpty) ...[
                      const SizedBox(height: LoopSpacing.s),
                      for (final bytes in _images!)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: LoopSpacing.xs),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              bytes,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: LoopSpacing.s),
                    if (ytId != null) ...[
                      _youtubeOpenButton(ytId, l10n),
                      const SizedBox(height: LoopSpacing.s),
                    ],
                    if (webUrl != null) ...[
                      _webOpenButton(webUrl, l10n),
                      const SizedBox(height: LoopSpacing.s),
                    ],
                    _detail(l10n),
                  ],
                ],
              ),
            ),
            PopupMenuButton<LogMenuAction>(
              icon: const Icon(Icons.more_horiz,
                  size: 18, color: LoopColors.textDim),
              onSelected: widget.onAction,
              color: LoopColors.surfaceHi,
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: LogMenuAction.edit,
                    child: Text(l10n.editContent)),
                PopupMenuItem(
                    value: LogMenuAction.changeTime,
                    child: Text(l10n.changeTime)),
                PopupMenuItem(
                    value: LogMenuAction.loop,
                    child: Text(l10n.loopAction)),
                // 포크만 사슬이 있다 — 최상위 원본까지의 루프 보기.
                if (_log.isFork)
                  PopupMenuItem(
                      value: LogMenuAction.loopView,
                      child: Text(l10n.loopViewAction)),
                PopupMenuItem(
                    value: LogMenuAction.delete,
                    child: Text(l10n.deleteAction)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 루프 발화 로그의 미리보기 — 루프를 누르기 전에 무엇에 대한
  /// 루프인지 보이게 원본(부모) 내용 앞 10자만 건네준다. (사용자 요청)
  /// 부모를 모르거나 원본 내용도 비어 있으면 기존 힌트로 폴백.
  String _loopForkPreview(AppLocalizations l10n) {
    final source =
        widget.parent?.content.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (source.isEmpty) return l10n.emptyWriteHint;
    final chars = source.characters;
    return chars.length > 10 ? '${chars.take(10).toString()}…' : source;
  }

  Widget _header(bool isFork, AppLocalizations l10n) {
    // 칩이 여러 개 얹히면(이어짐 + 루프 + 반복…) 헤더가 가로 한계를 넘는다.
    // 시각만 고정폭으로 두고 나머지 텍스트 칩은 전부 유연하게 줄어
    // 말줄임으로 해결한다 — RIGHT OVERFLOWED 방지.
    return Row(
      children: [
        // 로그엔 타이틀이 없다 — 날짜·시간·위치·내용이 곧 전부.
        Text(
          formatCard(_log.createdAt),
          style: const TextStyle(
            color: LoopColors.textDim,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (_log.hasLocation) ...[
          const SizedBox(width: LoopSpacing.s),
          Flexible(
            child: Text(
              _log.place ?? l10n.locationRecorded,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: LoopColors.textDim, fontSize: 11),
            ),
          ),
        ],
        if (isFork) ...[
          const SizedBox(width: LoopSpacing.s),
          Flexible(
            child: Text(
              l10n.continuedFrom(widget.parent == null
                  ? ''
                  : formatMixed(
                      widget.parent!.createdAt, DateTime.now(), l10n.yesterday)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: LoopColors.lavender, fontSize: 11),
            ),
          ),
        ],
        if (_hasImages && _log.content.isNotEmpty) ...[
          const SizedBox(width: LoopSpacing.s),
          const Icon(Icons.photo_library_outlined,
              size: 11, color: LoopColors.textDim),
          const SizedBox(width: 2),
          Text(
            '${widget.imageSummary!.count}',
            style: const TextStyle(color: LoopColors.textDim, fontSize: 11),
          ),
        ],
        if (_log.weatherCode != null) ...[
          const SizedBox(width: LoopSpacing.s),
          _weatherChip(_log.weatherCode!, _log.temperatureC, l10n),
        ],
        if (_log.hasPendingLoop) ...[
          const SizedBox(width: LoopSpacing.s),
          _flexChip(
            icon: const Icon(Icons.loop, size: 11, color: LoopColors.mint),
            label:
                '↩ ${formatMixed(_log.loopAt!, DateTime.now(), l10n.yesterday)}',
            style: const TextStyle(color: LoopColors.mint, fontSize: 11),
          ),
        ],
        if (widget.activeRepeatAsSource != null) ...[
          const SizedBox(width: LoopSpacing.s),
          // 원본의 루프 상태 칩 — 탭하면 Loop 정보 시트 (상태·중지는 그 안에서).
          _flexChip(
            icon: const Icon(Icons.repeat, size: 11, color: LoopColors.mint),
            label: widget.activeRepeatAsSource!.label(l10n),
            style: const TextStyle(color: LoopColors.mint, fontSize: 11),
            onTap: () => widget.onAction(LogMenuAction.loop),
          ),
        ],
        if (_log.isRepeatFork) ...[
          const SizedBox(width: LoopSpacing.s),
          _repeatForkChip(l10n),
        ],
      ],
    );
  }

  /// 헤더용 유연 칩 — 공간이 부족하면 라벨이 말줄임으로 줄어든다.
  /// [onTap]이 있으면 탭 가능(Loop 시트 열기 등).
  Widget _flexChip({
    required Widget icon,
    required String label,
    required TextStyle style,
    VoidCallback? onTap,
  }) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
    final chip = onTap == null
        ? row
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: row,
          );
    return Flexible(child: chip);
  }

  /// 반복(루프) 발화로 생성된 로그의 칩 — "Loop N회째".
  /// 살아있는 루프면 탭해서 Loop 정보 시트(원본 이동·중지).
  Widget _repeatForkChip(AppLocalizations l10n) {
    final rule = widget.activeRepeatAsFork;
    final active = rule != null;
    final label = active
        ? l10n.repeatNth(rule.fireCount)
        : l10n.repeatEnded;
    final style = TextStyle(
      color: active ? LoopColors.mint : LoopColors.textDim,
      fontSize: 11,
    );
    return _flexChip(
      icon: Icon(Icons.repeat, size: 11, color: style.color),
      label: label,
      style: style,
      onTap: active ? () => widget.onAction(LogMenuAction.loop) : null,
    );
  }

  Widget _weatherChip(int code, double? temperature, AppLocalizations l10n) {
    final w = Wmo.describe(code);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(w.icon, size: 12, color: w.color),
        const SizedBox(width: 3),
        Text(
          temperature == null
              ? Wmo.label(l10n, w.kind)
              : '${temperature.round()}°',
          style: TextStyle(color: w.color, fontSize: 11),
        ),
      ],
    );
  }

  /// 본문 아래 작은 인라인 썸네일 — 사진이 있어도 항상 보인다. (사용자 결정)
  /// 탭은 카드 전체와 마찬가지로 펼침 토글이 이어받는다.
  Widget _youtubeInline(String videoId) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            youtubeThumbUrl(videoId),
            width: 112,
            height: 63,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 112,
              height: 63,
              color: LoopColors.surfaceHi,
              child: const Icon(Icons.play_circle_outline,
                  size: 20, color: LoopColors.textDim),
            ),
          ),
        ),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YouTube',
                  style: TextStyle(color: LoopColors.text, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                'youtu.be/$videoId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: LoopColors.textDim, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 펼친 화면의 열기 버튼 — 인라인 썸네일 탭은 펼침이고, 실제 이동은 여기서.
  Widget _youtubeOpenButton(String videoId, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openYoutube(videoId),
        icon: const Icon(Icons.play_circle_outline, size: 16),
        label: Text(l10n.openInYoutube),
        style: OutlinedButton.styleFrom(
          foregroundColor: LoopColors.lavender,
          side: const BorderSide(color: LoopColors.line),
          padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s),
        ),
      ),
    );
  }

  Future<void> _openYoutube(String videoId) async {
    try {
      await launchUrl(youtubeWatchUri(videoId),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // 열 앱이 없는 등 — 조용히 무시
    }
  }

  /// 일반 웹 링크 인라인 — 파비콘 + 도메인. (유튜브 인라인의 짝)
  Widget _webInline(String url) {
    final uri = Uri.parse(url);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            color: LoopColors.surfaceHi,
            child: Image.network(
              faviconUrl(uri.host),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.language,
                  size: 22, color: LoopColors.textDim),
            ),
          ),
        ),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(uri.host,
                  style: const TextStyle(
                      color: LoopColors.text, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: LoopColors.textDim, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 브라우저 열기 버튼 — 설정에서 고른 브라우저로 연다. (BrowserService)
  Widget _webOpenButton(String url, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => BrowserService.open(url),
        icon: const Icon(Icons.language, size: 16),
        label: Text(l10n.openInBrowser),
        style: OutlinedButton.styleFrom(
          foregroundColor: LoopColors.mint,
          side: const BorderSide(color: LoopColors.line),
          padding: const EdgeInsets.symmetric(vertical: LoopSpacing.s),
        ),
      ),
    );
  }

  Widget _detail(AppLocalizations l10n) {
    final rows = <Widget>[
      _row(
          l10n.detailOriginal,
          formatMixed(
              _log.originalCreatedAt, DateTime.now(), l10n.yesterday)),
      // 좌표는 내부 저장 전용 — 화면에는 장소명만 보여준다. (사용자 결정)
      if (_log.hasLocation)
        _row(l10n.detailPlace, _log.place ?? l10n.unknown),
      if (_log.weatherCode != null)
        _row(
          l10n.detailWeather,
          '${Wmo.label(l10n, Wmo.describe(_log.weatherCode!).kind)}'
          '${_log.temperatureC == null ? '' : ' ${_log.temperatureC!.round()}°'}',
        ),
      if (_hasImages)
        _row(l10n.detailPhotos, l10n.photoCount(widget.imageSummary!.count)),
      if (!_log.hasLocation && _log.weatherCode == null && !_hasImages)
        _row(l10n.detailRecord, l10n.detailNoContext),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoopSpacing.s),
      decoration: BoxDecoration(
        color: LoopColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(label,
                  style: const TextStyle(
                      color: LoopColors.textDim, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: LoopColors.text, fontSize: 12)),
            ),
          ],
        ),
      );
}
