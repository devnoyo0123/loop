import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../design/tokens.dart';

/// 코치 마크 한 장의 내용. [target]이 가리키는 위젯을 비추고 옆에 말풍선.
class CoachSpec {
  const CoachSpec({
    required this.target,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.onSkip,
    this.number,
    this.total,
    this.actionLabel,
    this.onAction,
    this.dim = true,
    this.bubbleAbove,
  });

  final GlobalKey target;

  /// 말풍선을 이 위젯의 바로 위에 띄운다(예: 작성 시트 전체) — 입력창이나
  /// 키보드를 가리지 않게. null이면 대상 주변의 넓은 쪽.
  final GlobalKey? bubbleAbove;
  final String title;
  final String body;

  /// "① / ④" 진행 표시. null이면 숨김(단발 안내 ⑤).
  final int? number;
  final int? total;

  final String skipLabel;
  final VoidCallback onSkip;

  /// [확인] 같은 넘김 버튼 — 없으면 사용자가 실제 버튼을 눌러야 넘어간다.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 주변을 어둡게 덮을지. 작성 시트처럼 입력이 필요한 화면에서는 끈다.
  final bool dim;
}

/// [child] 위에 코치 마크를 띄운다. [spec]이 null이면 아무것도 없다.
///
/// 어두운 막과 테두리 링은 터치를 막지 않는다(IgnorePointer) — 비춘 버튼을
/// 실제로 눌러 다음 단계로 가야 하고, 입력창도 계속 쓸 수 있어야 한다.
/// 터치를 받는 건 말풍선(건너뛰기·확인)뿐.
class CoachMarkLayer extends StatefulWidget {
  const CoachMarkLayer({super.key, required this.child, this.spec});

  final Widget child;
  final CoachSpec? spec;

  @override
  State<CoachMarkLayer> createState() => _CoachMarkLayerState();
}

class _CoachMarkLayerState extends State<CoachMarkLayer> {
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant CoachMarkLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    // build 도중 show/hide를 부르지 않도록 프레임 뒤로 미룬다.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final want = widget.spec != null;
      if (want && !_portal.isShowing) _portal.show();
      if (!want && _portal.isShowing) _portal.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (_) {
        final spec = widget.spec;
        return spec == null ? const SizedBox.shrink() : CoachMarkOverlay(spec: spec);
      },
      child: widget.child,
    );
  }
}

/// 실제 그림 — 대상 위치를 따라가며(키보드·스크롤로 움직여도) 다시 그린다.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({super.key, required this.spec});

  final CoachSpec spec;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Rect? _rect;
  Rect? _anchor;
  late final Ticker _ticker = createTicker(_onTick);
  int _stableTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant CoachMarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.target != widget.spec.target) _wake();
  }

  /// 키보드가 올라오거나 화면이 회전하면 다시 추적.
  @override
  void didChangeMetrics() => _wake();

  void _wake() {
    _stableTicks = 0;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    final r = _measure(widget.spec.target);
    final a = widget.spec.bubbleAbove == null ? null : _measure(widget.spec.bubbleAbove!);
    if (r != _rect || a != _anchor) {
      setState(() {
        _rect = r;
        _anchor = a;
      });
      _stableTicks = 0;
    } else if (++_stableTicks > 20) {
      // 자리가 잡히면 멈춘다 — 계속 프레임을 돌리지 않게.
      _ticker.stop();
    }
  }

  Rect? _measure(GlobalKey key) {
    final ctx = key.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final overlayBox = context.findRenderObject();
    if (overlayBox is! RenderBox) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final rect = _rect;
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        if (rect == null) return const SizedBox.shrink();
        final hole = rect.inflate(6);
        final mq = MediaQuery.of(context);
        // 키보드가 덮은 부분은 없는 셈 치고, 보이는 공간이 넓은 쪽에 둔다.
        final visibleBottom = size.height - mq.viewInsets.bottom;
        final anchor = _anchor;
        final below = anchor == null &&
            (visibleBottom - hole.bottom) >= (hole.top - mq.padding.top);
        final bottomEdge = anchor?.top ?? hole.top;
        const margin = 16.0;
        final width = (size.width - margin * 2).clamp(0.0, 360.0);
        final left = (hole.center.dx - width / 2).clamp(margin, size.width - margin - width);
        return Stack(
          children: [
            IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: _HolePainter(hole: hole, dim: spec.dim),
              ),
            ),
            Positioned(
              left: left,
              width: width,
              top: below ? hole.bottom + 12 : null,
              bottom: below ? null : size.height - bottomEdge + 12,
              child: _Bubble(spec: spec),
            ),
          ],
        );
      },
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter({required this.hole, required this.dim});
  final Rect hole;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    if (dim) {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(rr);
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.62));
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = LoopColors.lavender,
    );
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) => old.hole != hole || old.dim != dim;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.spec});
  final CoachSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LoopColors.surfaceHi,
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LoopColors.lavender, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (spec.number != null)
                  Text(
                    '${spec.number} / ${spec.total}',
                    style: const TextStyle(
                      color: LoopColors.lavender,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: spec.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: LoopColors.textDim,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(spec.skipLabel, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                spec.title,
                style: const TextStyle(
                  color: LoopColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                spec.body,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 13.5, height: 1.45),
              ),
            ),
            if (spec.actionLabel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: spec.onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: LoopColors.lavender,
                    foregroundColor: LoopColors.bg,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(spec.actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
