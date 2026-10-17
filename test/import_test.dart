import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/services/import_service.dart';

void main() {
  late Directory tmpA;
  late Directory tmpB;
  late LoopDb dbA; // 내보내는 쪽
  late LoopDb dbB; // 가져오는 쪽 (빈 DB = 복원 시나리오)

  setUp(() {
    tmpA = Directory.systemTemp.createTempSync('loop_imp_a');
    tmpB = Directory.systemTemp.createTempSync('loop_imp_b');
    dbA = LoopDb(tmpA)..open();
    dbB = LoopDb(tmpB)..open();
  });

  tearDown(() {
    dbA.close();
    dbB.close();
    tmpA.deleteSync(recursive: true);
    tmpB.deleteSync(recursive: true);
  });

  LogEntry entry(String id, String content, DateTime at, {String? parentId}) =>
      LogEntry(
        id: id,
        content: content,
        createdAt: at,
        originalCreatedAt: at,
        parentId: parentId,
        rootId: parentId == null ? null : 'src',
        depth: parentId == null ? 0 : 1,
      );

  test('roundtrip — 로그·이미지·반복이 빠짐없이 다른 DB로 옮겨진다', () async {
    final now = DateTime.fromMillisecondsSinceEpoch(
        DateTime(2026, 10, 17, 9, 30).millisecondsSinceEpoch);
    dbA.insert(entry('src', '원본 로그 🎉', now));
    dbA.insertImages('src', [Uint8List.fromList([1, 2, 3])]);
    dbA.insertRepeatRule(RepeatRule(
      id: 'r1',
      sourceLogId: 'src',
      kind: RepeatKind.daily,
      timeOfDay: '09:00',
      nextFireAt: now.add(const Duration(days: 1)),
      fireCount: 3,
      createdAt: now,
    ));

    final lines = dbA.exportLines().toList();
    final stats = await dbB.importLines(Stream.fromIterable(lines));

    expect(stats.logs, 1);
    expect(stats.images, 1);
    expect(stats.repeats, 1);

    final log = dbB.byId('src')!;
    expect(log.content, '원본 로그 🎉');
    expect(log.loopCount, 0);

    final images = dbB.imagesFor('src');
    expect(images, hasLength(1));
    expect(images.first, [1, 2, 3]);

    final rule = dbB.repeatRuleById('r1')!;
    expect(rule.kind, RepeatKind.daily);
    expect(rule.timeOfDay, '09:00');
    expect(rule.fireCount, 3);
    expect(dbB.activeRepeatRules(), hasLength(1));
  });

  test('loopCount까지 무손실 — v6 필드도 옮겨진다', () async {
    final now = DateTime(2026, 10, 17, 9, 30);
    dbA.insert(entry('src', '복습 세 번 한 로그', now));
    // 내보내기 전에 카운트를 올린다.
    for (var i = 0; i < 3; i++) {
      dbA.incrementLoopCount('src');
    }
    await dbB.importLines(Stream.fromIterable(dbA.exportLines()));
    expect(dbB.byId('src')!.loopCount, 3);
  });

  test('머지 — 같은 파일을 두 번 가져와도 중복이 생기지 않는다', () async {
    dbA.insert(entry('a1', '첫번째', DateTime(2026, 10, 17, 9)));
    dbA.insert(entry('a2', '두번째', DateTime(2026, 10, 17, 10)));
    final lines = dbA.exportLines().toList();

    final first = await dbB.importLines(Stream.fromIterable(lines));
    expect(first.logs, 2);
    final second = await dbB.importLines(Stream.fromIterable(lines));
    expect(second.isEmpty, isTrue); // 전부 건너뜀
    expect(dbB.window(limit: 50), hasLength(2));
  });

  test('머지 — 기존 로그를 지키고 새 로그만 더한다', () async {
    dbB.insert(entry('mine', '내가 방금 쓴 로그', DateTime(2026, 10, 17, 8)));
    dbA.insert(entry('a1', '가져온 로그', DateTime(2026, 10, 17, 9)));

    final stats =
        await dbB.importLines(Stream.fromIterable(dbA.exportLines()));

    expect(stats.logs, 1);
    expect(dbB.byId('mine')!.content, '내가 방금 쓴 로그');
    expect(dbB.byId('a1')!.content, '가져온 로그');
  });

  test('형식이 틀린 파일은 FormatException — DB는 그대로(rollback)', () async {
    dbB.insert(entry('mine', '살아남아야 함', DateTime(2026, 10, 17, 8)));

    final bad = Stream.fromIterable([
      '{"type":"something-else"}',
      '{"type":"log","id":"x"}',
    ]);
    expect(() => dbB.importLines(bad), throwsFormatException);
    // 트랜잭션 롤백 확인 — 헤더 다음 줄은 파싱 전에 예외라 아무것도 안 들어감.
    expect(dbB.window(limit: 50), hasLength(1));
  });

  test('빈 파일도 FormatException', () async {
    expect(() => dbB.importLines(const Stream.empty()), throwsFormatException);
  });

  test('가져온 살아있는 반복 규칙의 다음 발화가 과거면 settleRepeats가 몰아 생성',
      () async {
    final now = DateTime.now();
    final past = DateTime.fromMillisecondsSinceEpoch(
        now.subtract(const Duration(minutes: 90)).millisecondsSinceEpoch);
    dbA.insert(entry('src', '다른 기기의 매일 루프', past));
    dbA.insertRepeatRule(RepeatRule(
      id: 'r-x',
      sourceLogId: 'src',
      kind: RepeatKind.hours,
      everyN: 1,
      nextFireAt: past,
      createdAt: past,
    ));

    await dbB.importLines(Stream.fromIterable(dbA.exportLines()));
    final created = dbB.settleRepeats();
    expect(created, 2); // 90분 놓친 1시간 반복 — -90분, -30분
    expect(dbB.repeatRuleById('r-x')!.nextFireAt.isAfter(now), isTrue);
  });

  test('청크 경계에서 한글·이모지가 잘려도 줄이 온전하다', () async {
    final header = '{"type":"looplog","version":1}';
    final logLine =
        '{"type":"log","id":"e1","content":"루프 로그 🎉👏 한글","createdAt":"2026-10-17T09:00:00.000","originalCreatedAt":"2026-10-17T09:00:00.000"}';
    final whole = '$header\n$logLine\n';
    final bytes = Uint8List.fromList(utf8.encode(whole));

    // 가능한 모든 지점에서 잘라 두 청크로 흘려보낸다 — 경계가 멀티바이트 한가운데여도.
    for (var cut = 1; cut < bytes.length; cut++) {
      final lines = await ImportService.linesFromChunks(Stream.fromIterable([
        Uint8List.sublistView(bytes, 0, cut),
        Uint8List.sublistView(bytes, cut),
      ])).toList();
      expect(lines, [header, logLine], reason: 'cut at byte $cut');
    }
  });
}
