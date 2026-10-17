import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 압축·인코딩까지 끝난 이미지 한 장. DB에는 base64 문자열로 들어간다.
class PreparedImage {
  const PreparedImage({required this.jpegBytes});

  /// 긴 변 1080px JPEG(q80)로 압축된 바이트.
  final Uint8List jpegBytes;

  String get base64 => base64Encode(jpegBytes);
}

/// 사진 첨부 파이프라인: 픽 → 리사이즈/JPEG 압축.
/// 원본 그대로 base64 하면 장당 수 MB라 3~4장 스크롤 목표와 충돌하므로
/// 저장 전에 한 번 줄인다. (docs/ui-design.md #13)
class ImageService {
  static const maxImagesPerLog = 10;
  static const _side = 1080;
  static const _quality = 80;

  static Future<PreparedImage?> prepare(Uint8List raw) async {
    try {
      final jpeg = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: _side,
        minHeight: _side,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
      if (jpeg.isEmpty) return null;
      return PreparedImage(jpegBytes: jpeg);
    } catch (_) {
      return null; // 디코딩 실패한 장 하나가 전체 첨부를 막지 않는다
    }
  }

  /// 여러 장 준비. [limit] 넘는 건 버린다.
  static Future<List<PreparedImage>> prepareAll(
    List<Uint8List> raws, {
    int limit = maxImagesPerLog,
  }) async {
    final out = <PreparedImage>[];
    for (final raw in raws) {
      if (out.length >= limit) break;
      final prepared = await prepare(raw);
      if (prepared != null) out.add(prepared);
    }
    return out;
  }
}
