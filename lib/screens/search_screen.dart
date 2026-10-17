import 'dart:async';

import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../utils/time_format.dart';

/// 전문 검색 화면 — FTS5 역색인이라 타이핑마다 즉시 결과가 온다 (250ms 디바운스).
/// 기본은 BM25 관련도순, 칩으로 최신순 전환. 결과를 탭하면 그 로그를
/// 돌려주고, 타임라인이 그날로 이동한다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.db});

  final LoopDb db;

  static Future<LogEntry?> show(BuildContext context, {required LoopDb db}) =>
      Navigator.push<LogEntry>(
        context,
        MaterialPageRoute(builder: (_) => SearchScreen(db: db)),
      );

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<({LogEntry log, String snippet})> _results = [];

  /// 한 번이라도 검색했는가 — "결과 없음"과 "아직 입력 전"을 구별.
  bool _searched = false;
  String _lastQuery = '';
  bool _byRelevance = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  void _run(String q) {
    setState(() {
      _lastQuery = q;
      _results = widget.db.searchDetailed(q, byRelevance: _byRelevance);
      _searched = true;
    });
  }

  /// 정렬 칩 탭 — 즉시 다시 검색 (디바운스 없이).
  void _setSort(bool byRelevance) {
    if (_byRelevance == byRelevance) return;
    setState(() => _byRelevance = byRelevance);
    _run(_lastQuery);
  }

  /// trigram 역색인은 3자 이상부터 — 그 미만(LIKE 폴백)에선 정렬이 무의미해 숨긴다.
  bool get _canSort => _lastQuery.trim().runes.length >= 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: LoopColors.bg,
      appBar: AppBar(
        backgroundColor: LoopColors.bg,
        iconTheme: const IconThemeData(color: LoopColors.textDim),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: LoopColors.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: const TextStyle(color: LoopColors.textDim),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
      body: !_searched
          ? const SizedBox.shrink()
          : Column(
              children: [
                if (_canSort && _results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        LoopSpacing.m, LoopSpacing.xs, LoopSpacing.m, 0),
                    child: Row(
                      children: [
                        _chip(l10n.sortRelevance, _byRelevance,
                            () => _setSort(true)),
                        const SizedBox(width: LoopSpacing.xs),
                        _chip(l10n.sortRecent, !_byRelevance,
                            () => _setSort(false)),
                      ],
                    ),
                  ),
                Expanded(
                  child: _results.isEmpty
                      ? Center(
                          child: Text(l10n.searchEmpty,
                              style: const TextStyle(
                                  color: LoopColors.textDim, fontSize: 14)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: LoopSpacing.xl, top: LoopSpacing.xs),
                          itemCount: _results.length,
                          itemBuilder: (context, i) => _tile(_results[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? LoopColors.surfaceHi : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? LoopColors.line : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? LoopColors.mint : LoopColors.textDim,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// 스니펫 렌더링 — 마커(\uE000/\uE001) 사이를 밝게 칠한다.
  /// 매치가 본문에 없으면(장소 매치 등) 원문으로 폴백.
  Widget _snippetText(({LogEntry log, String snippet}) r) {
    final snip = r.snippet;
    final open = snip.indexOf(LoopDb.snippetOpen);
    final close = snip.indexOf(LoopDb.snippetClose);
    final base = const TextStyle(
        color: LoopColors.textDim, fontSize: 14, height: 1.4);
    final hit = const TextStyle(
        color: LoopColors.text,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600);

    if (open >= 0 && close > open) {
      return Text.rich(
        TextSpan(children: [
          TextSpan(text: snip.substring(0, open), style: base),
          TextSpan(text: snip.substring(open + 1, close), style: hit),
          TextSpan(text: snip.substring(close + 1), style: base),
        ]),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    final body = r.log.content.isEmpty ? snip : r.log.content;
    return Text(body,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: LoopColors.text, fontSize: 14, height: 1.4));
  }

  Widget _tile(({LogEntry log, String snippet}) r) {
    final log = r.log;
    return GestureDetector(
      onTap: () => Navigator.pop(context, log),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: LoopSpacing.m, vertical: LoopSpacing.xs),
        padding: const EdgeInsets.all(LoopSpacing.m),
        decoration: BoxDecoration(
          color: LoopColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatCard(log.createdAt),
              style: const TextStyle(
                color: LoopColors.textDim,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (log.content.isNotEmpty || r.snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              _snippetText(r),
            ],
            if (log.place != null) ...[
              const SizedBox(height: 4),
              Text(
                log.place!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: LoopColors.textDim, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
