import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/loop_db.dart';

/// .looplog(JSONL) 가져오기 — 내보내기([ExportService])의 역.
/// SAF "열기"로 고른 문서를 512KB 청크로 읽어 줄 단위로 되돌리고,
/// [LoopDb.importLines]가 같은 id는 건너뛰며 머지한다.
class ImportService {
  static const _ch = MethodChannel('app.loop/export');

  /// 파일을 고르고 바로 가져온다.
  /// 선택 취소면 null, 완료면 통계. 형식이 틀리면 FormatException.
  static Future<ImportStats?> pickAndImport(LoopDb db) async {
    final uri = await _ch.invokeMethod<String>('pick');
    if (uri == null) return null; // 사용자가 파일 선택을 취소

    final handle = await _ch.invokeMethod<int>('openRead', {'uri': uri});
    if (handle == null) return null;
    try {
      return await db.importLines(linesFromChunks(_chunks(handle)));
    } finally {
      await _ch.invokeMethod('closeRead', {'handle': handle});
    }
  }

  static Stream<Uint8List> _chunks(int handle) async* {
    while (true) {
      final chunk =
          await _ch.invokeMethod<Uint8List>('readChunk', {'handle': handle});
      if (chunk == null || chunk.isEmpty) break;
      yield chunk;
    }
  }

  /// 청크 바이트 스트림 → JSONL 줄 스트림.
  /// 청크 경계에서 멀티바이트 문자가 잘려도 chunked decoder가 이어준다.
  /// (네이티브 채널 없이 테스트할 수 있도록 분리)
  static Stream<String> linesFromChunks(Stream<Uint8List> chunks) async* {
    final decoded = StringBuffer();
    final decoderSink = utf8.decoder
        .startChunkedConversion(StringConversionSink.fromStringSink(decoded));
    var carry = '';
    await for (final chunk in chunks) {
      decoderSink.add(chunk);
      final text = carry + decoded.toString();
      decoded.clear();
      final parts = text.split('\n');
      carry = parts.removeLast(); // 마지막 조각은 다음 청크와 이어진다
      for (final line in parts) {
        final t = line.trim();
        if (t.isNotEmpty) yield t;
      }
    }
    decoderSink.close();
    final rest = (carry + decoded.toString()).trim();
    if (rest.isNotEmpty) yield rest;
  }
}
