import 'package:flutter/services.dart';

import '../data/loop_db.dart';

/// .looplog(JSONL) 내보내기.
/// SAF 문서 생성(저장 위치 선택) → DB에서 한 줄씩 읽어 512KB 청크로 기록.
/// 이미지가 많아도 메모엔 항상 한 청크만 있다.
class ExportService {
  static const _ch = MethodChannel('app.loop/export');

  static const _mime = 'application/octet-stream';
  static const _chunkBytes = 512 * 1024;

  /// 내보내기 실행. 저장 위치에서 취소하면 false, 완료하면 true.
  static Future<bool> export(LoopDb db, {required String fileName}) async {
    final uri = await _ch.invokeMethod<String>(
        'create', {'name': fileName, 'mime': _mime});
    if (uri == null) return false; // 사용자가 저장 위치에서 취소

    final handle = await _ch.invokeMethod<int>('open', {'uri': uri});
    if (handle == null) return false;
    final buf = StringBuffer();
    try {
      for (final line in db.exportLines()) {
        buf..write(line)..write('\n');
        if (buf.length >= _chunkBytes) {
          await _write(handle, buf);
        }
      }
      if (buf.isNotEmpty) await _write(handle, buf);
      await _ch.invokeMethod('close', {'handle': handle});
    } catch (_) {
      // 부분 파일을 닫고 지운다 — 실패한 파일이 남으면 안 된다.
      await _ch.invokeMethod('abort', {'handle': handle});
      rethrow;
    }
    return true;
  }

  static Future<void> _write(int handle, StringBuffer buf) async {
    await _ch.invokeMethod(
        'write', {'handle': handle, 'text': buf.toString()});
    buf.clear();
  }

  /// 기본 파일명 — loop-20260831-1432.looplog
  static String defaultFileName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'loop-${n.year}${two(n.month)}${two(n.day)}'
        '-${two(n.hour)}${two(n.minute)}.looplog';
  }
}
