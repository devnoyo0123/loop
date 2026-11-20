import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 공유 카드 캡처·공유 (기획: docs/growth-ideas.md "공유 카드").
///
/// 카드 위젯을 오버레이의 화면 밖(-10000px)에 한 프레임 그려 PNG로 뽑고,
/// 임시 파일로 저장해 시스템 공유 시트를 연다. 로컬에서만 만들어지고
/// 어디로 보낼지는 사용자가 고른다 — 로컬 퍼스트 원칙 그대로.
class ShareCardService {
  /// [card]를 PNG로 공유한다. 성공 여부를 돌려준다(실패는 조용히 false).
  static Future<bool> share(
    BuildContext context, {
    required Widget card,
  }) async {
    OverlayEntry? entry;
    try {
      final boundaryKey = GlobalKey();
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(key: boundaryKey, child: card),
        ),
      );
      final overlay = Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return false;
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return false;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/loop_stats_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      return true;
    } catch (_) {
      return false;
    } finally {
      entry?.remove();
    }
  }
}
