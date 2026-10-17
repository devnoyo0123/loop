import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';

void main() {
  late Directory tmp;
  late LoopDb db;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_db_test');
    db = LoopDb(tmp)..open();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  LogEntry entry(
    String id,
    String content,
    DateTime at, {
    String? parentId,
    String? rootId,
    int depth = 0,
    String? path,
    DateTime? loopAt,
    bool loopDone = false,
    double? latitude,
    double? longitude,
    String? place,
    int? weatherCode,
    double? temperatureC,
  }) =>
      LogEntry(
        id: id,
        content: content,
        createdAt: at,
        originalCreatedAt: at,
        parentId: parentId,
        rootId: rootId,
        depth: depth,
        path: path,
        loopAt: loopAt,
        loopDone: loopDone,
        latitude: latitude,
        longitude: longitude,
        place: place,
        weatherCode: weatherCode,
        temperatureC: temperatureC,
      );

  test('insert 후 최신 위 시계열 정렬', () {
    db.insert(entry('a1', '첫', DateTime(2026, 8, 31, 9, 0)));
    db.insert(entry('a2', '둘', DateTime(2026, 8, 31, 12, 0)));
    db.insert(entry('a3', '셋', DateTime(2026, 8, 31, 10, 0)));

    final logs = db.window();
    expect(logs.map((l) => l.id).toList(), ['a2', 'a3', 'a1']);
  });

  test('keyset 페이징 — 앵커 다음 페이지, 중복 없이 이어짐', () {
    for (var i = 0; i < 10; i++) {
      db.insert(entry('id$i', '로그$i', DateTime(2026, 8, 31, 0, i)));
    }
    final first = db.window(limit: 4);
    expect(first.length, 4);

    final last = first.last;
    final second = db.window(
      anchor: (time: last.createdAt, id: last.id),
      limit: 4,
    );
    expect(second.length, 4);
    expect(
      second.map((l) => l.id).toSet().intersection(first.map((l) => l.id).toSet()),
      isEmpty,
    );
    // 시간 역순이 이어져야 함
    expect(second.first.createdAt.isBefore(first.last.createdAt), isTrue);
  });

  test('시간 수정 시 시계열 위치 재정렬 + 원본 시각 보존', () {
    db.insert(entry('a1', '첫', DateTime(2026, 8, 31, 9, 0)));
    db.insert(entry('a2', '둘', DateTime(2026, 8, 31, 12, 0)));

    db.updateCreatedAt('a2', DateTime(2026, 8, 31, 8, 0));
    final logs = db.window();
    expect(logs.first.id, 'a1');
    expect(logs.last.id, 'a2');
    expect(logs.last.originalCreatedAt, DateTime(2026, 8, 31, 12, 0));
  });

  test('포크 — 경로/깊이/루트 보존', () {
    final parent = entry('p1', '원본', DateTime(2026, 8, 31, 9, 0));
    db.insert(parent);
    final child = entry(
      'c1',
      '이어쓰기',
      DateTime(2026, 8, 31, 9, 10),
      parentId: parent.id,
      rootId: parent.rootId ?? parent.id,
      depth: parent.depth + 1,
      path: '${parent.path ?? parent.id}/c1',
    );
    db.insert(child);

    final loaded = db.byId('c1')!;
    expect(loaded.parentId, 'p1');
    expect(loaded.rootId, 'p1');
    expect(loaded.depth, 1);
    expect(loaded.path, 'p1/c1');
    expect(loaded.isFork, isTrue);
  });

  test('settleExpiredLoops — 지난 루프만 소화 처리', () {
    db.insert(entry(
      'a1',
      '지난 루프',
      DateTime(2026, 8, 31, 9, 0),
      loopAt: DateTime(2026, 8, 31, 9, 10),
    ));
    db.insert(entry(
      'a2',
      '미래 루프',
      DateTime(2026, 8, 31, 9, 0),
      loopAt: DateTime(2099, 1, 1, 0, 0),
    ));

    db.settleExpiredLoops();

    expect(db.byId('a1')!.loopDone, isTrue);
    expect(db.byId('a2')!.loopDone, isFalse);
  });

  test('이미지 저장·요약·상세 로드', () {
    db.insert(entry('a1', '사진과 생각', DateTime(2026, 8, 31, 9, 0)));
    final img1 = Uint8List.fromList([1, 2, 3]);
    final img2 = Uint8List.fromList([9, 8, 7]);
    db.insertImages('a1', [img1, img2]);

    // 요약: 장수 + 첫 이미지
    final summaries = db.imageSummariesFor({'a1'});
    expect(summaries['a1']!.count, 2);
    expect(summaries['a1']!.firstBase64, base64Encode(img1));

    // 상세: 본문 순서대로 전체
    final images = db.imagesFor('a1');
    expect(images, hasLength(2));
    expect(images[0], img1);
    expect(images[1], img2);

    // 이미지 없는 로그는 요약에서 빠짐
    db.insert(entry('a2', '글만', DateTime(2026, 8, 31, 10, 0)));
    expect(db.imageSummariesFor({'a2'}).containsKey('a2'), isFalse);

    // 본문 윈도우 쿼리는 이미지와 무관하게 동작
    expect(db.window().map((l) => l.id).toList(), ['a2', 'a1']);
  });

  test('로그 삭제 시 이미지도 연쇄 삭제', () {
    db.insert(entry('a1', '사진 로그', DateTime(2026, 8, 31, 9, 0)));
    db.insertImages('a1', [Uint8List.fromList([1, 1, 1])]);
    expect(db.imageSummariesFor({'a1'}).containsKey('a1'), isTrue);

    db.delete('a1');
    expect(db.byId('a1'), isNull);
    expect(db.imageSummariesFor({'a1'}).containsKey('a1'), isFalse);
    expect(db.imagesFor('a1'), isEmpty);
  });

  test('재오픈 — WAL 모드로 데이터 영속', () {
    db.insert(entry('a1', '영속성', DateTime(2026, 8, 31, 9, 0)));
    db.close();

    final reopened = LoopDb(tmp)..open();
    expect(reopened.byId('a1')!.content, '영속성');
    reopened.close();
  });

  test('위치·날씨 필드 roundtrip', () {
    db.insert(entry(
      'a1',
      '한강에서',
      DateTime(2026, 8, 31, 9, 0),
      latitude: 37.517,
      longitude: 126.996,
      place: '서울특별시 성동구',
      weatherCode: 61,
      temperatureC: 23.4,
    ));

    final loaded = db.byId('a1')!;
    expect(loaded.hasLocation, isTrue);
    expect(loaded.latitude, 37.517);
    expect(loaded.longitude, 126.996);
    expect(loaded.place, '서울특별시 성동구');
    expect(loaded.weatherCode, 61);
    expect(loaded.temperatureC, 23.4);

    db.insert(entry('a2', '위치 없는 로그', DateTime(2026, 8, 31, 10, 0)));
    expect(db.byId('a2')!.hasLocation, isFalse);
    expect(db.byId('a2')!.weatherCode, isNull);
  });

  test('v1 스키마 DB → v2 자동 마이그레이션', () {
    db.close();
    // setUp이 만든 v2 DB를 지우고 진짜 v1 스키마로 시작
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('${tmp.path}${Platform.pathSeparator}loop.db$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    final old = sqlite3.open('${tmp.path}${Platform.pathSeparator}loop.db');
    old.execute('''
      CREATE TABLE logs (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        original_created_at INTEGER NOT NULL
      )
    ''');
    old.execute(
        "INSERT INTO logs VALUES ('old1', '옛날 로그', 1788200000000, 1788200000000)");
    old.close();

    final migrated = LoopDb(tmp)..open();
    final oldEntry = migrated.byId('old1')!;
    expect(oldEntry.content, '옛날 로그');
    expect(oldEntry.hasLocation, isFalse); // 새 컬럼은 전부 null

    migrated.insert(entry('new1', '새 로그', DateTime(2026, 8, 31, 9, 0),
        latitude: 37.5, longitude: 127.0, weatherCode: 0, temperatureC: 30));
    expect(migrated.byId('new1')!.latitude, 37.5);
    expect(migrated.byId('new1')!.weatherCode, 0);
    migrated.close();
  });

  test('window until — 날짜 이동용 상한 윈도우', () {
    db.insert(entry('d1', '6/1', DateTime(2026, 6, 1, 9)));
    db.insert(entry('d2a', '6/2 오전', DateTime(2026, 6, 2, 8)));
    db.insert(entry('d2b', '6/2 오후', DateTime(2026, 6, 2, 20)));
    db.insert(entry('d3', '6/3', DateTime(2026, 6, 3, 10)));

    // 6/3 자정까지 = 6/2 하루 전체 포함, 6/3 제외 (상한 미포함)
    final until = DateTime(2026, 6, 3);
    final w = db.window(until: until, limit: 2); // 첫 페이지 2개
    expect(w.map((e) => e.id).toList(), ['d2b', 'd2a']);

    // 앵커와 조합 — 날짜 이동 상태에서의 이어 읽기 (앵커보다 과거분)
    final more = db.window(
      anchor: (time: w.last.createdAt, id: w.last.id),
      until: until,
      limit: 2,
    );
    expect(more.map((e) => e.id).toList(), ['d1']);

    // 상한보다 과거가 비어 있으면 빈 목록 (그때 로그 없음)
    expect(db.window(until: DateTime(2020, 1, 1)), isEmpty);
  });

  test('pendingLoopsBetween — 창 안의 미소화 단발 루프만 발화 시각순으로', () {    db.insert(entry('past', '지난 루프', DateTime(2026, 10, 1, 9),
        loopAt: DateTime(2026, 10, 10, 9))); // 창 밖(과거)
    db.insert(entry('in1', '창 안 첫째', DateTime(2026, 10, 15, 9),
        loopAt: DateTime(2026, 10, 18, 9)));
    db.insert(entry('in2', '창 안 둘째', DateTime(2026, 10, 15, 10),
        loopAt: DateTime(2026, 10, 16, 9)));
    db.insert(entry('beyond', '창 밖 미래', DateTime(2026, 10, 15, 11),
        loopAt: DateTime(2026, 10, 30, 9)));
    db.insert(entry('done', '이미 소화', DateTime(2026, 10, 15, 12),
        loopAt: DateTime(2026, 10, 17, 9), loopDone: true));

    final from = DateTime(2026, 10, 15, 12);
    final to = DateTime(2026, 10, 22, 12);
    final pending = db.pendingLoopsBetween(from, to);
    // 창 안 미소화만, 발화 시각 오름차순 — 'done'은 소화돼 제외.
    expect(pending.map((e) => e.id).toList(), ['in2', 'in1']);
  });

  test('pendingOneShotLoops — 미래 단발만, 소화·과거분 제외 (복원 재예약용)', () {
    db.insert(entry('past', '지난 루프', DateTime(2026, 10, 1, 9),
        loopAt: DateTime(2026, 10, 10, 9))); // 과거 — settle 대상, 여기선 제외
    db.insert(entry('future1', '내일 루프', DateTime(2026, 10, 15, 9),
        loopAt: DateTime(2026, 10, 18, 9)));
    db.insert(entry('future2', '다음 주 루프', DateTime(2026, 10, 15, 10),
        loopAt: DateTime(2026, 10, 22, 9)));
    db.insert(entry('done', '이미 소화한 미래 루프', DateTime(2026, 10, 15, 11),
        loopAt: DateTime(2026, 10, 20, 9), loopDone: true));

    final pending = db.pendingOneShotLoops();
    expect(pending.map((e) => e.id).toList(), ['future1', 'future2']);
  });

  test('settings KV — 저장·덮어쓰기·없으면 null', () {    expect(db.getSetting('browser_package'), isNull);
    db.setSetting('browser_package', 'com.android.chrome');
    expect(db.getSetting('browser_package'), 'com.android.chrome');
    db.setSetting('browser_package', 'org.mozilla.firefox');
    expect(db.getSetting('browser_package'), 'org.mozilla.firefox');
    db.setSetting('other_key', 'x');
    expect(db.getSetting('browser_package'), 'org.mozilla.firefox');

    // 재오픈해도 남는다 (WAL 영속)
    db.close();
    final again = LoopDb(tmp)..open();
    expect(again.getSetting('browser_package'), 'org.mozilla.firefox');
    again.close();
  });
}
