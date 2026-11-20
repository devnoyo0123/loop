import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/services/video_store.dart';

/// 동영상 첨부 (v9) — DB 메타 + 파일 저장소 + 내보내기/가져오기 라운드트립.
/// 파일 본문은 VideoStore가, DB엔 파일명만 — 두 쪽이 함께 움직인다.
void main() {
  late Directory tmp;
  late LoopDb db;
  late VideoStore videos;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('video_test');
    db = LoopDb(tmp)..open();
    videos = VideoStore(tmp);
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  LogEntry log(String id, String content, DateTime at) =>
      LogEntry(id: id, content: content, createdAt: at, originalCreatedAt: at);

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  test('삽입·조회 — 파일 저장 + DB 메타가 한 쌍으로 붙는다', () {
    db.insert(log('a', '동영상 로그', DateTime(2026, 10, 30, 9)));
    final fileName = videos.save('v1', bytes('fake video bytes'));
    db.insertVideo('a', fileName, 16);

    final recs = db.videosFor('a');
    expect(recs, hasLength(1));
    expect(recs.single.fileName, 'v1.mp4');
    expect(recs.single.size, 16);
    expect(videos.fileFor('v1.mp4').existsSync(), isTrue);
    expect(db.videoCountsFor({'a', 'b'})['a'], 1);
    expect(db.videoCountsFor({'b'}), isEmpty);
  });

  test('로그 삭제 시 메타 연쇄 — 파일은 VideoStore가 별도로 지운다', () {
    db.insert(log('a', '지워질 로그', DateTime(2026, 10, 30)));
    final fileName = videos.save('v1', bytes('x'));
    db.insertVideo('a', fileName, 1);

    db.delete('a');
    expect(db.videosFor('a'), isEmpty); // 메타는 연쇄 삭제
    // 파일 본문은 호출자가 지운다 — 타임라인 삭제 경로에서 처리.
    expect(videos.fileFor('v1.mp4').existsSync(), isTrue);
  });

  test('내보내기/가져오기 라운드트립 — base64 인라인으로 무손실', () async {
    db.insert(log('a', '원본', DateTime(2026, 10, 30, 9)));
    final body = bytes('video payload 🎬');
    db.insertVideo('a', videos.save('v1', body), body.length);

    final tmpOut = Directory.systemTemp.createTempSync('video_export');
    addTearDown(() => tmpOut.deleteSync(recursive: true));
    final dbB = LoopDb(tmpOut)..open();
    addTearDown(dbB.close);
    final storeB = VideoStore(tmpOut);

    await dbB.importLines(
      Stream.fromIterable(
        db.exportLines(
          videoLoader: (fileName) {
            final b = videos.read(fileName);
            return b == null ? null : base64Encode(b);
          },
        ),
      ),
      videoWriter: storeB.write,
    );

    final recs = dbB.videosFor('a');
    expect(recs, hasLength(1));
    expect(storeB.read('v1.mp4'), body); // 바이트 동일 — 무손실
  });

  test('파일 없이 메타만 온 동영상 — 기록은 남고 본문은 건너뛴다', () async {
    db.insert(log('a', '메타만', DateTime(2026, 10, 30, 9)));
    db.insertVideo('a', 'missing.mp4', 10);

    final tmpOut = Directory.systemTemp.createTempSync('video_meta');
    addTearDown(() => tmpOut.deleteSync(recursive: true));
    final dbB = LoopDb(tmpOut)..open();
    addTearDown(dbB.close);

    // loader 없이 내보내기 — base64가 null로 나간다
    final stats = await dbB.importLines(
      Stream.fromIterable(db.exportLines()),
      videoWriter: (fileName, b) => fail('쓰기가 호출되면 안 된다'),
    );
    expect(stats.videos, 1);
    expect(dbB.videosFor('a'), hasLength(1)); // 기록 유지
  });

  test('VideoStore.read — 없는 파일은 null (내보내기가 메타만 인라인)', () {
    expect(videos.read('ghost.mp4'), isNull);
  });
}
