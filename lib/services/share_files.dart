import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 공유가 만드는 파일의 수명 관리 — 쓰레기가 쌓이지 않게.
/// (docs/share-design.md §6.5)
///
/// 공유 파일은 전부 앱 캐시의 전용 폴더 `share/` 하나에만 생긴다:
///  - `loop-chain-*.looplog` 보내는 쪽 페이로드
///  - `in-<ep>-<pid>.part`   받는 중(STREAM을 Kotlin이 흘려 씀) — 미완성은 여기 남는다
///  - `in-<ep>-<pid>.looplog` 다 받아 받기 시트에 넘긴 것
/// Downloads 등 공용 폴더는 쓰지 않는다(§6.6 STREAM 전환).
///
/// 지우는 시점은 세 겹:
///  1. 사건 즉시 — 실패·취소·끊김·받기 끄기·시트 닫기 때 그 파일을 바로.
///  2. 주기 청소 [ShareJanitor] — 앱 시작·복귀·세션 종료·30분마다.
///  3. 수동 정리 — 설정 › "공유 임시 파일 정리" ([clear]).
/// 쓰는 중인 파일은 [hold]로 표시돼 어느 쪽도 건드리지 않는다.
class ShareTempFiles {
  ShareTempFiles._();

  static const folder = 'share';

  /// 공유 전용 폴더 (없으면 만든다). [cacheRoot]는 테스트 주입용.
  static Future<Directory> dir([
    Future<Directory> Function()? cacheRoot,
  ]) async {
    final root = await (cacheRoot ?? getTemporaryDirectory)();
    final d = Directory('${root.path}/$folder');
    await d.create(recursive: true);
    return d;
  }

  static final _held = <String>{};

  /// 쓰는 중인 파일 — 청소·수동 정리가 건드리지 않는다. 다 쓰면 [release].
  static void hold(String path) => _held.add(path);
  static void release(String path) => _held.remove(path);
  static bool isHeld(String path) => _held.contains(path);

  /// 주기 청소 — 쓰는 중이 아니고 [minAge]보다 오래된 파일을 지운다. 나이
  /// 조건은 막 만들어져 아직 hold 전인 파일(받기 시트가 뜨기 직전 등)을
  /// 지우는 경쟁을 막는다. 지운 개수를 돌려준다.
  static Future<int> sweep(
    Directory dir, {
    Duration minAge = const Duration(minutes: 10),
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now()).subtract(minAge);
    var deleted = 0;
    for (final f in await _files(dir)) {
      if (isHeld(f.path)) continue;
      try {
        if ((await f.lastModified()).isAfter(cutoff)) continue;
        await f.delete();
        deleted++;
      } catch (_) {
        // 동시에 지워졌거나 접근 불가 — 다음 청소에서 다시
      }
    }
    return deleted;
  }

  /// 수동 정리 — 쓰는 중인 것만 빼고 전부. 지운 개수·바이트.
  static Future<({int files, int bytes})> clear(Directory dir) async {
    var files = 0, bytes = 0;
    for (final f in await _files(dir)) {
      if (isHeld(f.path)) continue;
      try {
        final size = await f.length();
        await f.delete();
        files++;
        bytes += size;
      } catch (_) {}
    }
    return (files: files, bytes: bytes);
  }

  /// 정리할 수 있는 양(쓰는 중 제외) — 설정 행에 보여준다.
  static Future<({int files, int bytes})> usage(Directory dir) async {
    var files = 0, bytes = 0;
    for (final f in await _files(dir)) {
      if (isHeld(f.path)) continue;
      try {
        bytes += await f.length();
        files++;
      } catch (_) {}
    }
    return (files: files, bytes: bytes);
  }

  static Future<List<File>> _files(Directory dir) async {
    if (!await dir.exists()) return const [];
    return [
      await for (final e in dir.list(followLinks: false))
        if (e is File) e,
    ];
  }
}

/// 바이트 표기 — 1MB 미만은 KB, 이상은 소수 한 자리 MB. (전송 화면·설정)
String formatShareBytes(int bytes) {
  const mb = 1024 * 1024;
  if (bytes < mb) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / mb).toStringAsFixed(1)} MB';
}

/// 주기 청소. 언제 부를지는 앱이 정한다(main.dart: 시작·복귀·30분 주기,
/// 화면: 세션 종료). 겹쳐 불려도 한 번만 돈다.
class ShareJanitor {
  ShareJanitor({
    Future<Directory> Function()? shareDir,
    this.minAge = const Duration(minutes: 10),
    this.interval = const Duration(minutes: 30),
  }) : shareDir = shareDir ?? ShareTempFiles.dir;

  /// 앱 전역 청소기 — main.dart가 꽂는다. 세션이 끝난 화면·받기 대기가
  /// `ShareJanitor.instance?.sweep()`으로 부른다(테스트에선 null — 무동작).
  static ShareJanitor? instance;

  final Future<Directory> Function() shareDir;
  final Duration minAge;
  final Duration interval;

  Timer? _timer;
  Future<int>? _running;

  /// 청소 1회 — 지운 개수. 진행 중이면 그 결과를 같이 기다린다.
  Future<int> sweep() =>
      _running ??= _sweep().whenComplete(() => _running = null);

  Future<int> _sweep() async {
    try {
      return await ShareTempFiles.sweep(await shareDir(), minAge: minAge);
    } catch (_) {
      return 0;
    }
  }

  /// 앱이 켜져 있는 동안 [interval]마다 청소.
  void startPeriodic() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => sweep());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
