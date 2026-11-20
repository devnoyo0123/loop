import 'dart:io';
import 'dart:typed_data';

/// 이미지 파일 저장소 — 사진 본문을 app dir/images/ 아래 파일로 보관한다.
/// (v10: base64 DB 인라인에서 파일로 전환 — 로그 DB 크기 보호. 비디오의
/// VideoStore와 같은 패턴. 자동 백업에서는 제외 — 구글 포토 백업이 1차
/// 안전망, 수동 .looplog 내보내기가 2차)
class ImageStore {
  ImageStore(this.baseDir);

  final Directory baseDir;

  static const ext = '.jpg';

  Directory get dir => Directory('${baseDir.path}/images')
    ..createSync(recursive: true);

  /// 저장하고 파일명을 돌려준다 (파일명 = `<imageId>.jpg`).
  String save(String imageId, Uint8List bytes) {
    final fileName = '$imageId$ext';
    write(fileName, bytes);
    return fileName;
  }

  /// 내보낸 파일명 그대로 복원할 때 — 확장자를 다시 붙이지 않는다.
  void write(String fileName, Uint8List bytes) {
    fileFor(fileName).writeAsBytesSync(bytes, flush: true);
  }

  File fileFor(String fileName) => File('${dir.path}/$fileName');

  /// 파일이 살아있을 때만 본문 — 없으면 null(카드·상세에서 조용히 숨김).
  Uint8List? read(String fileName) {
    final f = fileFor(fileName);
    return f.existsSync() ? f.readAsBytesSync() : null;
  }

  void delete(String fileName) {
    final f = fileFor(fileName);
    if (f.existsSync()) f.deleteSync();
  }
}
