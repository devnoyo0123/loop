import 'dart:io';
import 'dart:typed_data';

/// 동영상 파일 저장소 — 본문은 app dir/videos/ 아래 파일로, DB엔 파일명만.
/// (v9: base64 인라인은 이미지 전용 — 동영상이 로그 DB를 오염시키지 않게
/// 물리 분리. docs/growth-ideas.md "촬영 첨부")
class VideoStore {
  VideoStore(this.baseDir);

  /// getApplicationSupportDirectory — Android에선 app files 디렉터리.
  final Directory baseDir;

  static const ext = '.mp4';

  Directory get dir =>
      Directory('${baseDir.path}/videos')..createSync(recursive: true);

  /// 저장하고 파일명을 돌려준다 (파일명 = `<videoId>.mp4` — id 충돌 없음).
  String save(String videoId, Uint8List bytes) {
    final fileName = '$videoId$ext';
    write(fileName, bytes);
    return fileName;
  }

  /// 내보낸 파일명 그대로 복원할 때 — 확장자를 다시 붙이지 않는다.
  void write(String fileName, Uint8List bytes) {
    fileFor(fileName).writeAsBytesSync(bytes, flush: true);
  }

  File fileFor(String fileName) => File('${dir.path}/$fileName');

  /// 대표 프레임(썸네일) — 유튜브 프리뷰처럼 카드에 보여주는용. (v10.2)
  /// 파일명은 동영상에서 유도: `<id>.mp4` → `<id>.jpg`
  String saveThumb(String videoFileName, Uint8List bytes) {
    final name = videoFileName.replaceAll(RegExp(r'\.mp4$'), '.jpg');
    fileFor(name).writeAsBytesSync(bytes, flush: true);
    return name;
  }

  Uint8List? readThumb(String videoFileName) =>
      read(videoFileName.replaceAll(RegExp(r'\.mp4$'), '.jpg'));

  /// 파일이 살아있을 때만 본문 — 없으면 null(내보내기가 메타만 인라인).
  Uint8List? read(String fileName) {
    final f = fileFor(fileName);
    return f.existsSync() ? f.readAsBytesSync() : null;
  }

  void delete(String fileName) {
    final f = fileFor(fileName);
    if (f.existsSync()) f.deleteSync();
  }
}
