import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/services/image_store.dart';

/// 이미지 파일 전환 (v10) — 사진 본문을 DB base64에서 파일로.
/// 이중 경로(파일 우선, 레거시 base64 폴백) + 멱등 마이그레이션 검증.
void main() {
  late Directory tmp;
  late ImageStore images;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('image_store_test');
    images = ImageStore(tmp);
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  LogEntry log(String id, String content, DateTime at) =>
      LogEntry(id: id, content: content, createdAt: at, originalCreatedAt: at);

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  group('파일 경로 — 스토어가 있으면 본문은 파일로', () {
    late Directory tmpDb;
    late LoopDb db;

    setUp(() {
      tmpDb = Directory.systemTemp.createTempSync('image_db_test');
      db = LoopDb(tmpDb, imageStore: images)..open();
    });

    tearDown(() {
      db.close();
      tmpDb.deleteSync(recursive: true);
    });

    test('insertImages → 파일 저장 + DB엔 파일명, base64는 비움', () {
      db.insert(log('a', '사진 로그', DateTime(2026, 10, 30, 9)));
      db.insertImages('a', [bytes('photo-a'), bytes('photo-b')]);

      final recs = db.imageFileNamesFor('a');
      expect(recs, hasLength(2));
      for (final fileName in recs) {
        expect(images.fileFor(fileName).existsSync(), isTrue);
      }
      // 읽기 — 파일 본문이 순서대로 돌아온다
      final loaded = db.imagesFor('a');
      expect(loaded.map(utf8.decode), ['photo-a', 'photo-b']);
      // 썸네일 — 첫 장 base64로 돌아온다
      final summary = db.imageSummariesFor({'a'})['a']!;
      expect(summary.count, 2);
      expect(utf8.decode(base64Decode(summary.firstBase64!)), 'photo-a');
    });

    test('마이그레이션 — 구버전 DB(베이스64)를 새 앱이 열면 파일로 옮긴다 (멱등)', () {
      // 구버전 앱 — 스토어 없이 쓴 DB (base64 인라인).
      final legacyDb = LoopDb(tmpDb)..open();
      legacyDb.insert(log('a', '레거시', DateTime(2026, 10, 30)));
      legacyDb.insertImages('a', [bytes('legacy photo')]);
      legacyDb.close();

      // 새 앱 — 스토어와 함께 열고 마이그레이션.
      expect(db.migrateLegacyImages(), 1);
      expect(db.imageFileNamesFor('a'), hasLength(1));
      expect(
        images.fileFor(db.imageFileNamesFor('a').single).existsSync(),
        isTrue,
      );
      expect(utf8.decode(db.imagesFor('a').single), 'legacy photo');

      // 두 번 돌려도 0 — 멱등
      expect(db.migrateLegacyImages(), 0);
    });

    test('내보내기/가져오기 라운드트립 — 파일 장도 base64 인라인으로 무손실', () async {
      db.insert(log('a', '첨부 로그', DateTime(2026, 10, 30)));
      db.insertImages('a', [bytes('roundtrip 📷')]);

      final tmpOut = Directory.systemTemp.createTempSync('image_export');
      addTearDown(() => tmpOut.deleteSync(recursive: true));
      final storeB = ImageStore(tmpOut);
      final dbB = LoopDb(tmpOut, imageStore: storeB)..open();
      addTearDown(dbB.close);

      final stats = await dbB.importLines(
        Stream.fromIterable(
          db.exportLines(
            imageLoader: (fileName) {
              final b = images.read(fileName);
              return b == null ? null : base64Encode(b);
            },
          ),
        ),
      );

      expect(stats.images, 1);
      expect(utf8.decode(dbB.imagesFor('a').single), 'roundtrip 📷');
      // 가져온 장도 파일로 보관된다
      expect(dbB.imageFileNamesFor('a'), hasLength(1));
    });
  });

  group('없는 파일 — 조용히 숨김', () {
    late Directory tmpDb;
    late LoopDb db;

    setUp(() {
      tmpDb = Directory.systemTemp.createTempSync('image_missing_test');
      db = LoopDb(tmpDb, imageStore: images)..open();
    });

    tearDown(() {
      db.close();
      tmpDb.deleteSync(recursive: true);
    });

    test('파일이 지워진 장은 읽기·썸네일에서 건너뛴다 (크래시 없음)', () {
      db.insert(log('a', '사라진 사진', DateTime(2026, 10, 30)));
      db.insertImages('a', [bytes('gone')]);
      // 파일만 삭제 (백업 제외·기기 이전 시나리오)
      for (final fileName in db.imageFileNamesFor('a')) {
        images.delete(fileName);
      }

      expect(db.imagesFor('a'), isEmpty);
      expect(db.imageSummariesFor({'a'})['a'], isNull); // 썸네일도 숨김
    });

    test('스토어 없는 DB(레거시)는 base64 경로 그대로 — 기존 동작 유지', () {
      final legacyDb = LoopDb(tmpDb)..open();
      addTearDown(legacyDb.close);
      legacyDb.insert(log('b', '레거시', DateTime(2026, 10, 30)));
      legacyDb.insertImages('b', [bytes('inline')]);
      expect(utf8.decode(legacyDb.imagesFor('b').single), 'inline');
    });
  });
}
