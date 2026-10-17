import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';

/// FTS5 trigram 전문 검색 — 역색인 동기화(트리거)와 마이그레이션 재구축 검증.
void main() {
  late Directory tmp;
  late LoopDb db;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_fts_test');
    db = LoopDb(tmp)..open();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  LogEntry entry(String id, String content, DateTime at, {String? place}) =>
      LogEntry(
        id: id,
        content: content,
        createdAt: at,
        originalCreatedAt: at,
        place: place,
      );

  test('trigram — 한글 3자 이상 부분문자열 매치', () {
    db.insert(entry('a1', '오늘 서울에 갔다', DateTime(2026, 8, 31, 9)));
    db.insert(entry('a2', '부산 여행', DateTime(2026, 8, 30, 9)));

    final hits = db.search('서울에');
    expect(hits.map((e) => e.id), ['a1']);
  });

  test('3자 미만은 LIKE 폴백 — 2자도 부분문자열로 찾는다', () {
    db.insert(entry('b1', '제주도 여행 계획', DateTime(2026, 8, 31, 9)));
    db.insert(entry('b2', '출근', DateTime(2026, 8, 30, 9)));

    final hits = db.search('여행');
    expect(hits.map((e) => e.id), ['b1']);
  });

  test('장소(place)도 검색 대상', () {
    db.insert(entry('c1', '커피 마심',
        DateTime(2026, 8, 31, 9), place: '성수동 카페'));
    db.insert(entry('c2', '산책', DateTime(2026, 8, 30, 9)));

    expect(db.search('성수동').map((e) => e.id), ['c1']);
    // 2자 폴백으로도 place 매치
    expect(db.search('성수').map((e) => e.id), ['c1']);
  });

  test('수정·삭제 시 트리거로 역색인 동기화', () {
    db.insert(entry('d1', '러닝 5km', DateTime(2026, 8, 31, 9)));
    expect(db.search('러닝').map((e) => e.id), ['d1']);

    final orig = db.byId('d1')!;
    db.updateContent('d1', '수영 1km');
    expect(orig.content, isNotNull); // 읽기 전용 스냅샷 확인용
    expect(db.search('러닝'), isEmpty);
    expect(db.search('수영').map((e) => e.id), ['d1']);

    db.delete('d1');
    expect(db.search('수영'), isEmpty);
  });

  test('재오픈 후에도 검색 유지 (WAL + fts 파일)', () {
    db.insert(entry('e1', '빵집 탐방', DateTime(2026, 8, 31, 9)));
    db.close();

    final reopened = LoopDb(tmp)..open();
    expect(reopened.search('빵집').map((e) => e.id), ['e1']);
    reopened.close();
  });

  test('옛날 DB(user_version 4) 재구축 — 기존 로그가 검색된다', () {
    db.insert(entry('f1', '재구축 대상 로그', DateTime(2026, 8, 31, 9)));
    db.close();

    // 버전을 4로 되돌려 "FTS 생기기 전 DB"를 흉내 낸다
    final raw = sqlite3.open('${tmp.path}${Platform.pathSeparator}loop.db');
    raw.execute('PRAGMA user_version = 4');
    raw.close();

    final migrated = LoopDb(tmp)..open();
    expect(migrated.search('재구축').map((e) => e.id), ['f1']);
    migrated.close();
  });

  test('빈·공백 쿼리는 빈 결과', () {
    db.insert(entry('g1', '아무거나', DateTime(2026, 8, 31, 9)));
    expect(db.search(''), isEmpty);
    expect(db.search('   '), isEmpty);
  });

  test('따옴표 포함 쿼리도 안전 (MATCH 구문 이스케이프)', () {
    db.insert(entry('h1', "他说 'hello' 월드", DateTime(2026, 8, 31, 9)));
    expect(db.search("'hel").map((e) => e.id), ['h1']);
    expect(db.search('hello').map((e) => e.id), ['h1']);
  });

  test('BM25 관련도순 — 많이 담긴 로그가 먼저, 최신순과 순서가 갈린다', () {
    final old = DateTime(2026, 6, 1, 9);
    final recent = DateTime(2026, 8, 31, 9);
    // 오래된 로그에 '운동을' 3번, 최신 로그에 1번
    db.insert(entry(
        'i1', '운동을 하고 또 운동을 하고 저녁에도 운동을 했다', old));
    db.insert(entry('i2', '아침 운동을 했다', recent));

    final byRel = db.searchDetailed('운동을', byRelevance: true);
    expect(byRel.map((r) => r.log.id).toList(), ['i1', 'i2']);

    final byDate = db.searchDetailed('운동을', byRelevance: false);
    expect(byDate.map((r) => r.log.id).toList(), ['i2', 'i1']);
  });

  test('스니펫 — 매치 부분이 마커로 둘러싸인다 (FTS 경로)', () {
    db.insert(entry('j1', '아침에 운동을 하고 출근했다', DateTime(2026, 8, 31, 9)));
    final r = db.searchDetailed('운동을').single;
    expect(r.snippet, contains('\uE000운동을\uE001'));
    expect(r.snippet.indexOf('\uE000'), lessThan(r.snippet.indexOf('\uE001')));
  });

  test('스니펫 — 2자 LIKE 폴백도 수제 스니펫으로 매치 표시', () {
    db.insert(entry('k1', '오늘도 운동 가야지', DateTime(2026, 8, 31, 9)));
    final r = db.searchDetailed('운동').single;
    expect(r.snippet, contains('\uE000운동\uE001'));
  });

  test('스니펫 — 본문이 아니라 장소 매치면 원문 그대로', () {
    db.insert(LogEntry(
      id: 'l1',
      content: '커피 마심',
      createdAt: DateTime(2026, 8, 31, 9),
      originalCreatedAt: DateTime(2026, 8, 31, 9),
      place: '성수동 카페',
    ));
    final r = db.searchDetailed('성수').single;
    expect(r.snippet.contains('\uE000'), isFalse); // 본문엔 매치가 없다
  });
}
