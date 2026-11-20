import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';

void main() {
  late Directory tmp;
  late LoopDb minsu; // 보내는 사람
  late LoopDb jimin; // 받는 사람
  const minsuId = 'peer0001minsu';
  const jiminId = 'peer0002jimin';

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('share_payload_test');
    minsu = LoopDb(tmp)..open();
    // sqlite는 디렉터리를 만들어주지 않는다 — 받는 쪽 디렉터리 미리 생성
    Directory('${tmp.path}/jimin').createSync();
    jimin = LoopDb(Directory('${tmp.path}/jimin'))..open();
  });

  tearDown(() {
    minsu.close();
    jimin.close();
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
    double? latitude,
    double? longitude,
    String? place,
    int? weatherCode,
  }) => LogEntry(
    id: id,
    content: content,
    createdAt: at,
    originalCreatedAt: at,
    parentId: parentId,
    rootId: rootId,
    depth: depth,
    path: path,
    latitude: latitude,
    longitude: longitude,
    place: place,
    weatherCode: weatherCode,
  );

  /// 민수의 사슬 — 원본 R + 포크 C(위치·날씨 포함) + 살아있는 30분 반복.
  void seedMinsuChain() {
    minsu.insert(
      entry(
        'R',
        '물 하루 8잔 마시기',
        DateTime(2026, 10, 12, 8, 30),
        latitude: 37.54,
        longitude: 127.0,
        place: '서울특별시 성동구',
        weatherCode: 0,
      ),
    );
    minsu.insert(
      entry(
        'C',
        '지금 5잔째',
        DateTime(2026, 10, 14, 11, 5),
        parentId: 'R',
        rootId: 'R',
        depth: 1,
        path: 'R/C',
        weatherCode: 1,
      ),
    );
    minsu.insertImages('R', [Uint8List.fromList([1, 2, 3])]);
    minsu.insertRepeatRule(
      RepeatRule(
        id: 'rule1',
        sourceLogId: 'R',
        kind: RepeatKind.minutes,
        everyN: 30,
        nextFireAt: DateTime(2026, 10, 14, 12, 0),
        active: true,
        createdAt: DateTime(2026, 10, 12, 8, 30),
      ),
    );
  }

  List<String> exportFrom(
    LoopDb db, {
    List<ChainParticipant> participants = const [
      ChainParticipant(id: minsuId, name: '민수'),
    ],
    bool stripLocation = true,
    bool includeMedia = true,
  }) => db
      .exportChainLines(
        rootId: 'R',
        participants: participants,
        stripLocation: stripLocation,
        includeMedia: includeMedia,
      )
      .toList();

  group('exportChainLines', () {
    test('헤더에 participants, 위치는 빠지고 날씨는 남는다', () {
      seedMinsuChain();
      final lines = exportFrom(minsu);

      final header = jsonDecode(lines.first) as Map<String, Object?>;
      expect(header['type'], 'looplog');
      expect(
        header['participants'],
        [
          {'id': minsuId, 'name': '민수'},
        ],
      );

      final root = lines
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .firstWhere((m) => m['id'] == 'R');
      expect(root['latitude'], isNull);
      expect(root['place'], isNull);
      expect(root['weatherCode'], 0); // 날씨는 유지 — 공유해도 무해
    });

    test('stripLocation=false면 원본 그대로', () {
      seedMinsuChain();
      final root = exportFrom(minsu, stripLocation: false)
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .firstWhere((m) => m['id'] == 'R');
      expect(root['latitude'], 37.54);
      expect(root['place'], '서울특별시 성동구');
    });

    test('includeMedia=false면 이미지 라인 자체가 없다', () {
      seedMinsuChain();
      final types = exportFrom(minsu, includeMedia: false)
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .map((m) => m['type'])
          .toList();
      expect(types, containsAll(['log', 'repeat']));
      expect(types, isNot(contains('image')));
      expect(types, isNot(contains('video')));
    });

    test('미디어 포함 시 이미지 본문이 base64로 실린다', () {
      seedMinsuChain();
      final img = exportFrom(minsu)
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .firstWhere((m) => m['type'] == 'image');
      expect(img['base64'], base64Encode([1, 2, 3]));
    });

    test('규칙은 사슬에 속한 것만, 원본 active 상태 그대로', () {
      seedMinsuChain();
      final rules = exportFrom(minsu)
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .where((m) => m['type'] == 'repeat')
          .toList();
      expect(rules, hasLength(1));
      expect(rules.single['active'], true); // 강제는 받는 쪽 정책의 역할
    });
  });

  group('importSharedChainLines', () {
    test('author 스탬프 + peers 등록 + chain_shares 기록', () async {
      seedMinsuChain();
      final result = await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
      );

      expect(result.logs, 2);
      expect(result.rootId, 'R');
      expect(result.senderId, minsuId);
      expect(jimin.peerName(minsuId), '민수');
      expect(jimin.byId('R')!.authorId, minsuId);
      expect(jimin.byId('C')!.authorId, minsuId);
      final share = jimin.chainShareFor('R');
      expect(share, isNotNull);
      expect(share!.peerId, minsuId);
      expect(share.via, 'p2p');
    });

    test('비이어받기 — 살아있던 규칙은 정지 상태로 (홍수 방지)', () async {
      seedMinsuChain();
      await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
      );

      final rule = jimin.repeatRuleById('rule1')!;
      expect(rule.active, isFalse);
      expect(rule.stoppedAt, isNotNull);
      // settleRepeats가 건드리지 않는다 — 다음 발화가 과거여도 몰아생성 없음
      expect(jimin.settleRepeats(), 0);
    });

    test('이어받기 — 주기는 물려받고 다음 발화는 지금부터 재계산', () async {
      seedMinsuChain();
      final t0 = DateTime.now();
      await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
        adoptLoop: true,
      );
      final t1 = DateTime.now();

      final rule = jimin.repeatRuleById('rule1')!;
      expect(rule.active, isTrue);
      expect(rule.stoppedAt, isNull);
      expect(rule.fireCount, 0); // 이력은 그대로 — 여기선 발화 0회
      // 30분 주기 — 받은 시점 + 30분. DB는 밀리초 저장이라 마이크로초까지
      // 비교하면 같은 1ms 안에 끝난 실행에서 깨진다(flaky) — ms로 맞춘다.
      final t0ms = DateTime.fromMillisecondsSinceEpoch(t0.millisecondsSinceEpoch);
      expect(
        rule.nextFireAt.isBefore(t0ms.add(const Duration(minutes: 30))),
        isFalse,
      );
      expect(
        rule.nextFireAt.isBefore(t1.add(const Duration(minutes: 30))),
        isTrue,
      );
    });

    test('혼자인 기록(루프 없음) — 그 기록 하나만 오가고 출처가 남는다', () async {
      minsu.insert(entry('R', '그냥 메모', DateTime(2026, 11, 1, 9)));
      final lines = exportFrom(minsu);
      expect(lines.where((l) => l.contains('"type":"log"')), hasLength(1));
      expect(lines.where((l) => l.contains('"type":"repeat"')), isEmpty);

      final result = await jimin.importSharedChainLines(
        Stream.fromIterable(lines),
        via: 'p2p',
      );
      expect(result.logs, 1);
      expect(jimin.byId('R')!.content, '그냥 메모');
      expect(jimin.chainShareFor('R')?.peerId, minsuId);
    });

    test('막 건 루프(발화 전, 포크 없음) — 이어받기로 바로 내 루프가 된다', () async {
      minsu.insert(entry('R', '물 하루 8잔', DateTime(2026, 11, 1, 9)));
      minsu.insertRepeatRule(
        RepeatRule(
          id: 'rule1',
          sourceLogId: 'R',
          kind: RepeatKind.minutes,
          everyN: 30,
          nextFireAt: DateTime(2026, 11, 1, 9, 30),
          active: true,
          createdAt: DateTime(2026, 11, 1, 9),
        ),
      );
      final t0 = DateTime.now();
      await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
        adoptLoop: true,
      );
      final rule = jimin.repeatRuleById('rule1')!;
      expect(rule.active, isTrue);
      expect(rule.nextFireAt.isAfter(t0), isTrue); // 받은 시점부터 새로
      expect(jimin.byId('R'), isNotNull);
    });

    test('재임포트 — 중복 없고 첫 출처가 유지된다', () async {
      seedMinsuChain();
      await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
      );
      // 다른 사람이 같은 사슬을 다시 보낸다 — 머지는 skip, 출처는 첫 수신 유지
      final result = await jimin.importSharedChainLines(
        Stream.fromIterable(
          exportFrom(
            minsu,
            participants: const [ChainParticipant(id: jiminId, name: '지민')],
          ),
        ),
        via: 'file',
      );

      expect(result.logs, 0);
      expect(jimin.chainShareFor('R')!.peerId, minsuId);
      expect(jimin.byId('R')!.authorId, minsuId);
    });

    test('3단계 전파 — 민수→지민→나, 저자 구분이 끝까지 살아있다', () async {
      seedMinsuChain();
      // 지민이 민수의 사슬을 받고 자기 기록을 이어쓴다
      await jimin.importSharedChainLines(
        Stream.fromIterable(exportFrom(minsu)),
        via: 'p2p',
      );
      jimin.insert(
        entry(
          'J1',
          '나도 시작해봄',
          DateTime(2026, 10, 15, 9, 0),
          parentId: 'C',
          rootId: 'R',
          depth: 2,
          path: 'R/C/J1',
        ),
      );

      // 지민이 나에게 공유 — participants 첫 번째가 보낸 사람(지민)
      Directory('${tmp.path}/mine').createSync();
      final mine = LoopDb(Directory('${tmp.path}/mine'))..open();
      addTearDown(mine.close);
      await mine.importSharedChainLines(
        Stream.fromIterable(
          exportFrom(
            jimin,
            participants: const [
              ChainParticipant(id: jiminId, name: '지민'),
              ChainParticipant(id: minsuId, name: '민수'),
            ],
          ),
        ),
        via: 'p2p',
      );

      expect(mine.peerName(jiminId), '지민');
      expect(mine.peerName(minsuId), '민수'); // 3단계에서도 이름이 산다
      expect(mine.byId('R')!.authorId, minsuId);
      expect(mine.byId('C')!.authorId, minsuId);
      expect(mine.byId('J1')!.authorId, jiminId); // 지민의 이어쓰기
      expect(mine.chainShareFor('R')!.peerId, jiminId); // 직접 출처는 지민
    });

    test('participants 없는 구버전 파일은 공유 임포트가 거절한다', () async {
      final legacy = jsonEncode({
        'type': 'looplog',
        'version': 1,
        'exportedAt': '2026-10-01T09:00:00.000',
      });
      expect(
        () => jimin.importSharedChainLines(
          Stream.fromIterable([legacy]),
          via: 'file',
        ),
        throwsFormatException,
      );
    });
  });

  group('ruleForReceive — 받는 쪽 규칙 정책 (순수)', () {
    final alive = RepeatRule(
      id: 'r1',
      sourceLogId: 'R',
      kind: RepeatKind.hours,
      everyN: 2,
      nextFireAt: DateTime(2026, 10, 14, 12, 0),
      active: true,
      createdAt: DateTime(2026, 10, 12, 8, 30),
    );
    final receivedAt = DateTime(2026, 11, 1, 10, 0);

    test('비이어받기 — 같은 시각 유지, 정지로만', () {
      final r = LoopDb.ruleForReceive(alive, adopt: false, receivedAt: receivedAt);
      expect(r.active, isFalse);
      expect(r.stoppedAt, receivedAt);
      expect(r.nextFireAt, alive.nextFireAt);
      expect(r.fireCount, alive.fireCount);
    });

    test('이어받기 — 2시간 주기, 다음 발화는 받은 시점 + 2시간', () {
      final r = LoopDb.ruleForReceive(alive, adopt: true, receivedAt: receivedAt);
      expect(r.active, isTrue);
      expect(r.stoppedAt, isNull);
      expect(r.nextFireAt, receivedAt.add(const Duration(hours: 2)));
    });

    test('애초에 정지였던 규칙은 이어받기를 골라도 정지로 남는다', () {
      final stopped = RepeatRule(
        id: 'r2',
        sourceLogId: 'R',
        kind: RepeatKind.hours,
        everyN: 2,
        nextFireAt: DateTime(2026, 10, 14, 12, 0),
        active: false,
        stoppedAt: DateTime(2026, 10, 13, 18, 0),
        createdAt: DateTime(2026, 10, 12, 8, 30),
      );
      final r = LoopDb.ruleForReceive(
        stopped,
        adopt: true,
        receivedAt: receivedAt,
      );
      expect(r.active, isFalse);
      expect(r.stoppedAt, stopped.stoppedAt);
    });
  });

  group('기기 정체성', () {
    test('첫 호출에서 생성, 이후 불변 — DB를 다시 열어도 같다', () {
      final id1 = minsu.peerId();
      expect(minsu.peerId(), id1);
      minsu.close();
      final reopened = LoopDb(Directory('${tmp.path}/jimin'))..open();
      addTearDown(reopened.close);
      // 설정은 DB에 있으므로 같은 DB면 같은 id
      expect(jimin.peerId(), jimin.peerId());
      expect(reopened.peerId(), isNot(id1)); // 다른 DB = 다른 정체성
    });

    test('표시명 — 설정·변경, id와 무관', () {
      expect(minsu.shareName(), isNull);
      minsu.setShareName('민수의 Galaxy');
      expect(minsu.shareName(), '민수의 Galaxy');
      minsu.setShareName('민수');
      expect(minsu.shareName(), '민수');
      expect(minsu.peerId(), minsu.peerId()); // 이름이 바뮈져도 id는 그대로
    });

    test('upsertPeer — 이름 갱신, 첫 접촉 시각 유지', () {
      minsu.upsertPeer(jiminId, '지민');
      minsu.setShareName('민수'); // 노이즈 방지용 자리표시
      minsu.upsertPeer(jiminId, '지민이');
      expect(minsu.peerName(jiminId), '지민이');
    });
  });
}
