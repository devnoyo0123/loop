import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';

/// .looplog(JSONL) 내보내기 — 무손실 전체 덤프 검증.
void main() {
  late Directory tmp;
  late LoopDb db;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_export_test');
    db = LoopDb(tmp)..open();
  });

  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  List<Map<String, Object?>> dump() =>
      [for (final line in db.exportLines()) jsonDecode(line)];

  test('빈 DB — 헤더 한 줄뿐', () {
    final lines = dump();
    expect(lines, hasLength(1));
    expect(lines.single['type'], 'looplog');
    expect(lines.single['version'], 1);
  });

  test('로그 무손실 — 모든 필드가 그대로 나온다', () {
    db.insert(LogEntry(
      id: 'x1',
      content: '줄바꿈도\n따옴표도 "포함" 내용',
      createdAt: DateTime(2026, 8, 31, 9, 12),
      originalCreatedAt: DateTime(2026, 8, 31, 9, 0),
      parentId: 'root0',
      rootId: 'root0',
      depth: 1,
      path: 'root0/x1',
      loopAt: DateTime(2026, 9, 1, 8),
      loopDone: true,
      latitude: 37.5,
      longitude: 127.0,
      place: '성수동',
      weatherCode: 61,
      temperatureC: 22.4,
      repeatRuleId: 'r1',
    ));

    final line = dump().singleWhere((m) => m['type'] == 'log');
    expect(line['id'], 'x1');
    expect(line['content'], '줄바꿈도\n따옴표도 "포함" 내용');
    expect(line['createdAt'], '2026-08-31T09:12:00.000');
    expect(line['originalCreatedAt'], '2026-08-31T09:00:00.000');
    expect(line['parentId'], 'root0');
    expect(line['rootId'], 'root0');
    expect(line['depth'], 1);
    expect(line['path'], 'root0/x1');
    expect(line['loopAt'], '2026-09-01T08:00:00.000');
    expect(line['loopDone'], true);
    expect(line['latitude'], 37.5);
    expect(line['longitude'], 127.0);
    expect(line['place'], '성수동');
    expect(line['weatherCode'], 61);
    expect(line['temperatureC'], 22.4);
    expect(line['repeatRuleId'], 'r1');
  });

  test('이미지는 log 줄 뒤에 image 줄로, position 순서대로', () {
    db.insert(LogEntry(
        id: 'p1',
        content: '사진 로그',
        createdAt: DateTime(2026, 8, 31, 9),
        originalCreatedAt: DateTime(2026, 8, 31, 9)));
    db.insertImages('p1', [
      Uint8List.fromList([1, 2, 3]),
      Uint8List.fromList([9, 8, 7]),
    ]);

    final lines = dump();
    final images = lines.where((m) => m['type'] == 'image').toList();
    expect(images, hasLength(2));
    expect(images[0]['logId'], 'p1');
    expect(images[0]['position'], 0);
    expect(images[1]['position'], 1);
    // base64 왕복 — 원래 바이트와 동일
    expect(base64Decode(images[1]['base64'] as String), [9, 8, 7]);
  });

  test('반복 규칙 — 살아있는 규칙과 멈춘 규칙 모두 기록', () {
    db.insertRepeatRule(RepeatRule(
      id: 'r1',
      sourceLogId: 's1',
      kind: RepeatKind.daily,
      timeOfDay: '21:30',
      nextFireAt: DateTime(2026, 9, 1, 21, 30),
      fireCount: 3,
      active: true,
      createdAt: DateTime(2026, 8, 30, 21, 30),
    ));
    db.insertRepeatRule(RepeatRule(
      id: 'r2',
      sourceLogId: 's2',
      kind: RepeatKind.minutes,
      everyN: 10,
      nextFireAt: DateTime(2026, 9, 1, 10),
      fireCount: 1,
      active: false,
      createdAt: DateTime(2026, 8, 30, 9),
      stoppedAt: DateTime(2026, 8, 30, 12),
    ));

    final repeats = dump().where((m) => m['type'] == 'repeat').toList();
    expect(repeats, hasLength(2));
    // created_at 순서 — r2(08-30 09:00)가 r1(08-30 21:30)보다 먼저
    expect(repeats[0]['kind'], 'minutes');
    expect(repeats[0]['everyN'], 10);
    expect(repeats[0]['active'], false);
    expect(repeats[0]['stoppedAt'], '2026-08-30T12:00:00.000');
    expect(repeats[1]['kind'], 'daily');
    expect(repeats[1]['timeOfDay'], '21:30');
    expect(repeats[1]['fireCount'], 3);
    expect(repeats[1]['active'], true);
    expect(repeats[1]['stoppedAt'], isNull);
  });

  test('로그는 시간 순서, fork 계보 필드도 함께', () {
    final base = DateTime(2026, 8, 30, 9);
    db.insert(LogEntry(
        id: 'root',
        content: '원본',
        createdAt: base,
        originalCreatedAt: base));
    db.insert(LogEntry(
        id: 'fork1',
        content: '이어쓰기',
        createdAt: base.add(const Duration(hours: 1)),
        originalCreatedAt: base.add(const Duration(hours: 1)),
        parentId: 'root',
        rootId: 'root',
        depth: 1,
        path: 'root/fork1'));

    final logs = dump().where((m) => m['type'] == 'log').toList();
    expect([logs[0]['id'], logs[1]['id']], ['root', 'fork1']);
    expect(logs[1]['parentId'], 'root');
    expect(logs[1]['path'], 'root/fork1');
  });

  test('모든 줄은 독립적인 JSON — 한 줄에 개행 없음', () {
    db.insert(LogEntry(
        id: 'n1',
        content: '줄바꿈\n포함\n내용',
        createdAt: DateTime(2026, 8, 31, 9),
        originalCreatedAt: DateTime(2026, 8, 31, 9)));
    final rawLines = db.exportLines().toList();
    for (final line in rawLines) {
      expect(line.contains('\n'), isFalse);
      expect(() => jsonDecode(line), returnsNormally);
    }
    expect(rawLines, hasLength(2)); // 헤더 + 로그 1개
  });
}
