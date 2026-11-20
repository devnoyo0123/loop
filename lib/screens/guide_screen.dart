import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/guide_content.dart';

/// Loop 사용법 — 기능마다 실제 화면 그림 + 짧은 설명. 설정 › 앱 정보에서 연다.
/// 그림을 탭하면 크게 본다(확대·이동 가능).
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const GuideScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final sections = guideSections(l10n, lang);
    return Scaffold(
      backgroundColor: LoopColors.bg,
      appBar: AppBar(
        backgroundColor: LoopColors.bg,
        foregroundColor: LoopColors.text,
        title: Text(l10n.guideTitle),
      ),
      body: Center(
        // 폴드·태블릿에서도 읽기 편한 폭.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              LoopSpacing.m,
              LoopSpacing.s,
              LoopSpacing.m,
              LoopSpacing.l * 2,
            ),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: LoopSpacing.l),
            itemBuilder: (context, i) =>
                _SectionCard(index: i, section: sections[i]),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.index, required this.section});

  final int index;
  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('guide-${section.id}'),
      padding: const EdgeInsets.all(LoopSpacing.m),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) ...[
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: LoopColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: LoopColors.bg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: LoopSpacing.s),
              ],
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: LoopColors.text,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoopSpacing.s),
          Text(
            section.body,
            style: const TextStyle(
              color: LoopColors.textDim,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: LoopSpacing.m),
          Row(
            children: [
              for (var i = 0; i < section.images.length; i++) ...[
                if (i > 0) const SizedBox(width: LoopSpacing.s),
                Expanded(child: Center(child: _Shot(path: section.images[i]))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 화면 그림 — 캡처 비율로 자리를 먼저 잡는다(디코딩 전에도 레이아웃이 튀지
/// 않게). 세로가 너무 길지 않게 높이를 묶는다 — 폭은 부모가 Center로 느슨하게
/// 줘야 비율대로 줄어든다(꽉 채우면 비율이 깨져 잘린다). 탭하면 크게.
class _Shot extends StatelessWidget {
  const _Shot({required this.path});

  final String path;

  /// 캡처 원본 비율 — 1080×2340에서 상태바·내비바를 잘라낸 1080×2180.
  static const aspect = 1080 / 2180;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _zoom(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: AspectRatio(
          aspectRatio: aspect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: LoopColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                semanticLabel: '',
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: LoopColors.textDim,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _zoom(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: InteractiveViewer(
          maxScale: 4,
          child: Center(child: Image.asset(path, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
