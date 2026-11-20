import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:loop/data/loop_db.dart';
import 'package:loop/models/log_entry.dart';
import 'package:loop/models/repeat_rule.dart';
import 'package:loop/services/mcp/mcp_tools.dart';

/// MCP 도구 — 입력 검증·날짜 필터·위치(장소명+좌표) 설정·스니펫·잘림.
/// (mcp-design.md §9)
void main() {
  late Directory tmp;
  late LoopDb db;
  late McpTools tools;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_mcp_tools_test');
    db = LoopDb(tmp)..open();
    tools = McpTools(db);
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
    double? latitude,
    double? longitude,
    String? place,
    int? weatherCode,
    double? temperatureC,
  }) => LogEntry(
    id: id,
    content: content,
    createdAt: at,
    originalCreatedAt: at,
    parentId: parentId,
    rootId: rootId,
    depth: depth,
    path: path,
    loopAt: loopAt,
    latitude: latitude,
    longitude: longitude,
    place: place,
    weatherCode: weatherCode,
    temperatureC: temperatureC,
  );

  ({bool isError, String text}) call(String name, Map<String, Object?> args) {
    final r = tools.call(name, args);
    final text = ((r['content'] as List).single as Map)['text'] as String;
    return (isError: r['isError'] as bool, text: text);
  }

  group('입력 검증 → isError', () {
    test('search_logs', () {
      final bad = <Map<String, Object?>>[
        {},
        {'query': 1},
        {'query': '   '},
        {'query': 'a' * 201},
        {'query': '카페', 'limit': 0},
        {'query': '카페', 'limit': 51},
        {'query': '카페', 'limit': 2.5},
        {'query': '카페', 'limit': '10'},
        {'query': '카페', 'from': '2026/10/01'},
        {'query': '카페', 'to': '2026-02-30'},
        {'query': '카페', 'from': '2026-10-05', 'to': '2026-10-01'},
        {'query': '카페', 'order': 'oldest'},
        {'query': '카페', 'bogus': true},
      ];
      for (final args in bad) {
        expect(call('search_logs', args).isError, isTrue, reason: '$args');
      }
      expect(call('search_logs', {'query': 'a' * 200}).isError, isFalse);
      expect(call('search_logs', {'query': '카페', 'limit': 50.0}).isError,
          isFalse);
    });

    test('get_log·get_chain·logs_on_day', () {
      expect(call('get_log', {}).isError, isTrue);
      expect(call('get_log', {'id': ''}).isError, isTrue);
      expect(call('get_log', {'id': 'nope'}).isError, isTrue);
      expect(call('get_log', {'id': 'nope'}).text, contains('nope'));
      expect(call('get_chain', {'id': 'nope'}).isError, isTrue);
      expect(call('logs_on_day', {}).isError, isTrue);
      expect(call('logs_on_day', {'date': '2026-13-01'}).isError, isTrue);
      expect(call('logs_on_day', {'date': '2026-10-01'}).isError, isFalse);
      expect(call('no_such_tool', {}).isError, isTrue);
    });
  });

  test('search_logs 날짜 필터·limit·결과 없음', () {
    db.insert(entry('a', '카페 라떼 하나', DateTime(2026, 10, 1, 9)));
    db.insert(entry('b', '카페 라떼 둘', DateTime(2026, 10, 2, 9)));
    db.insert(entry('c', '카페 라떼 셋', DateTime(2026, 10, 3, 9)));

    final ranged = call('search_logs', {
      'query': '카페 라떼',
      'from': '2026-10-02',
      'to': '2026-10-02',
    });
    expect(ranged.isError, isFalse);
    expect(ranged.text, contains('[b]'));
    expect(ranged.text, isNot(contains('[a]')));
    expect(ranged.text, isNot(contains('[c]')));

    final limited = call('search_logs', {'query': '카페 라떼', 'limit': 1});
    expect(limited.text, contains('[c]')); // 최신순 기본
    expect(limited.text, isNot(contains('[b]')));

    final none = call('search_logs', {'query': '없는말'});
    expect(none.isError, isFalse);
    expect(none.text, startsWith('No logs matched'));
  });

  test('스니펫 마커 → **, 전용영역 문자 미출력', () {
    db.insert(entry('s1', '오늘은 성수동 카페에서 공부했다', DateTime(2026, 10, 1)));
    for (final q in ['성수동 카페', '카페']) {
      // FTS(3자+)·LIKE(2자) 두 경로
      final r = call('search_logs', {'query': q});
      expect(r.text, contains('**$q**'), reason: q);
      expect(r.text, isNot(contains(LoopDb.snippetOpen)));
      expect(r.text, isNot(contains(LoopDb.snippetClose)));
    }
  });

  test('헤더 포맷 — 날짜·요일·장소(좌표)·날씨(영어)·미디어', () {
    db.insert(
      entry(
        'h1',
        '본문',
        DateTime(2026, 10, 31, 21, 14),
        latitude: 37.544581,
        longitude: 127.055961,
        place: '성수동',
        weatherCode: 0,
        temperatureC: 12.4,
      ),
    );
    db.insertImages('h1', [
      Uint8List.fromList([1]),
      Uint8List.fromList([2]),
    ]);
    final r = call('get_log', {'id': 'h1'});
    expect(
      r.text.split('\n').first,
      '[h1] 2026-10-31 (Sat) 21:14 · 성수동 (37.54458, 127.05596) · clear 12°C · 2 photos',
    );
    expect(r.text, contains('본문'));
    // 네 도구 모두 같은 헤더 — 좌표가 함께 간다 (2026-11-16 사용자 결정).
    for (final t in [
      r.text,
      call('search_logs', {'query': '본문'}).text,
      call('logs_on_day', {'date': '2026-10-31'}).text,
      call('get_chain', {'id': 'h1'}).text,
    ]) {
      expect(t, contains('37.54458, 127.05596'));
    }
  });

  test('위치 끔 — 장소명과 좌표가 모두 빠진다', () {
    db.insert(entry('h2', '좌표만', DateTime(2026, 10, 30, 8),
        latitude: 37.5, longitude: 127.0));
    expect(call('get_log', {'id': 'h2'}).text.split('\n').first,
        '[h2] 2026-10-30 (Fri) 08:00 · 37.50000, 127.00000');
    db.setSetting(McpTools.keyIncludePlace, '0');
    final t = call('get_log', {'id': 'h2'}).text;
    expect(t, isNot(contains('37.5')));
    expect(t, isNot(contains('127.0')));
  });

  test('장소명 — 설정 0이면 빠지고, 없거나 1이면 포함', () {
    db.insert(entry('p1', '장소 테스트', DateTime(2026, 10, 1), place: '성수동'));
    expect(call('get_log', {'id': 'p1'}).text, contains('성수동'));
    db.setSetting(McpTools.keyIncludePlace, '0');
    expect(call('get_log', {'id': 'p1'}).text, isNot(contains('성수동')));
    expect(call('search_logs', {'query': '테스트'}).text,
        isNot(contains('성수동')));
    db.setSetting(McpTools.keyIncludePlace, '1');
    expect(call('get_log', {'id': 'p1'}).text, contains('성수동'));
  });

  test('날씨 코드 → 영어 짧은 설명 (Wmo 재사용)', () {
    expect(McpTools.weatherWord(0), 'clear');
    expect(McpTools.weatherWord(3), 'cloudy');
    expect(McpTools.weatherWord(61), 'rain');
    expect(McpTools.weatherWord(95), 'thunderstorm');
    expect(McpTools.weatherWord(12345), isNull);
  });

  test('사슬 — get_chain 시간순, 위치 표시, 받은 사슬 표시', () {
    db.insert(entry('r', '원본', DateTime(2026, 10, 1, 9)));
    db.insert(entry('c1', '후속', DateTime(2026, 10, 2, 9),
        parentId: 'r', rootId: 'r', depth: 1, path: 'r/c1',
        loopAt: DateTime(2026, 11, 3, 9)));

    final chain = call('get_chain', {'id': 'c1'});
    expect(chain.isError, isFalse);
    expect(chain.text.indexOf('[r]'), lessThan(chain.text.indexOf('[c1]')));
    expect(chain.text, startsWith('Chain r · 2 logs'));
    expect(chain.text, isNot(contains('received chain')));

    final log = call('get_log', {'id': 'c1'});
    expect(log.text, contains('chain r · 2 of 2'));
    expect(log.text, contains('loop scheduled 2026-11-03 09:00 (notification)'));

    // chain_shares에 root가 있으면 받은 사슬 — 상대 기기 정보는 출력 안 함.
    final raw = sqlite3.open('${tmp.path}${Platform.pathSeparator}loop.db');
    raw.execute(
      "INSERT INTO chain_shares(root_id, peer_id, received_at, via) "
      "VALUES('r', 'peer-xyz', 0, 'nearby')",
    );
    raw.close();
    final received = call('get_chain', {'id': 'r'});
    expect(received.text, contains('(received chain)'));
    expect(received.text, isNot(contains('peer-xyz')));
    expect(call('get_log', {'id': 'r'}).text, contains('(received chain)'));
  });

  test('logs_on_day — 50건 넘으면 잘림 안내', () {
    final day = DateTime(2026, 10, 5);
    for (var i = 0; i < 52; i++) {
      db.insert(entry('n${i.toString().padLeft(2, '0')}', '기록 $i',
          day.add(Duration(minutes: i))));
    }
    final r = call('logs_on_day', {'date': '2026-10-05'});
    expect(r.text, startsWith('2026-10-05 (Mon) · 52 logs'));
    expect(r.text, contains('[n49]'));
    expect(r.text, isNot(contains('[n50]')));
    expect(r.text, contains('showing the first 50 of 52'));
  });

  test('20,000자 상한 — 잘리고 마지막 줄에 안내', () {
    final long = '가' * 9000;
    for (var i = 0; i < 3; i++) {
      db.insert(entry('L$i', long, DateTime(2026, 10, 1, 9, i)));
    }
    final r = call('logs_on_day', {'date': '2026-10-01'});
    expect(r.isError, isFalse);
    expect(r.text.length, lessThanOrEqualTo(McpTools.maxChars));
    expect(r.text.split('\n').last, McpTools.truncatedLine);

    final short = call('get_log', {'id': 'L0'});
    expect(short.text, isNot(contains('truncated')));
  });

  test('truncate — 서로게이트 쌍 한가운데서 자르지 않는다', () {
    final emoji = '😀' * 15000; // 30,000 code units
    final t = McpTools.truncate(emoji);
    expect(t.length, lessThanOrEqualTo(McpTools.maxChars));
    final body = t.substring(0, t.lastIndexOf('\n'));
    expect(body.runes.every((r) => r == 0x1F600), isTrue);
  });

  group('upcoming_loops — 단발 루프 + 반복 알림 (앱 다가오는 루프와 같은 목록)', () {
    // 2026-11-18 실사용 버그: 매년 반복(생일)이 브리지에서 안 보였다.
    final now = DateTime(2026, 11, 18, 20, 40);

    void seed() {
      db.insert(entry('dinner', '회식', DateTime(2026, 11, 18, 9),
          loopAt: DateTime(2026, 11, 18, 21, 44)));
      db.insert(entry('checkup', '건강검진', DateTime(2026, 11, 10, 9),
              loopAt: DateTime(2026, 11, 27, 8, 14))
          .copyWith(loopAlarm: true));
      db.insert(entry('bday', '희경누나 생일', DateTime(2026, 11, 7, 21, 57)));
      db.insertRepeatRule(RepeatRule(
        id: 'r-bday',
        sourceLogId: 'bday',
        kind: RepeatKind.yearly,
        timeOfDay: '11-23 08:00',
        nextFireAt: DateTime(2026, 11, 23, 8),
        createdAt: DateTime(2026, 11, 7, 21, 58),
      ));
    }

    test('7일 — 단발과 매년 반복을 시간순으로, 알림/알람 구분', () {
      seed();
      final t = tools.upcomingLoopsAt(now);
      expect(t, startsWith('2 coming back in the next 7 days'));
      final dinner = t.indexOf('2026-11-18 (Wed) 21:44 · notification · once');
      final bday = t.indexOf(
          '2026-11-23 (Mon) 08:00 · notification · repeat yearly 11-23 08:00');
      expect(dinner, greaterThanOrEqualTo(0));
      expect(bday, greaterThan(dinner));
      expect(t, contains('[bday] 희경누나 생일'));
      expect(t, isNot(contains('건강검진'))); // 11/27은 7일 밖
    });

    test('days=10 — 창을 넓히면 11/27 알람도 나온다', () {
      seed();
      final t = tools.upcomingLoopsAt(now, days: 10);
      expect(t, startsWith('3 coming back in the next 10 days'));
      expect(t, contains('2026-11-27 (Fri) 08:14 · alarm · once'));
    });

    test('비어 있으면 안내, days 범위 밖은 isError', () {
      expect(tools.upcomingLoopsAt(now), 'Nothing is coming back in the next 7 days.');
      expect(call('upcoming_loops', {'days': 0}).isError, isTrue);
      expect(call('upcoming_loops', {'days': 32}).isError, isTrue);
      expect(call('upcoming_loops', {'when': 'x'}).isError, isTrue);
      expect(call('upcoming_loops', {}).isError, isFalse);
    });

    test('검색 결과에도 반복 알림이 붙는다', () {
      seed();
      final hit = call('search_logs', {'query': '희경'});
      expect(hit.text,
          contains('repeat yearly 11-23 08:00 · next 2026-11-23 08:00 (notification)'));
      expect(call('get_log', {'id': 'checkup'}).text,
          contains('loop scheduled 2026-11-27 08:14 (alarm)'));
    });

    test('도구 정의 — 5개, upcoming_loops 포함', () {
      final names = [for (final d in tools.definitions) d['name']];
      expect(names, ['search_logs', 'get_log', 'get_chain', 'logs_on_day', 'upcoming_loops']);
    });

    test('repeatText — 규칙 종류별 영어 표기', () {
      RepeatRule r(RepeatKind k, {int? n, String? tod}) => RepeatRule(
          id: 'x', sourceLogId: 's', kind: k, everyN: n, timeOfDay: tod,
          nextFireAt: now, createdAt: now);
      expect(McpTools.repeatText(r(RepeatKind.minutes, n: 10)), 'every 10 min');
      expect(McpTools.repeatText(r(RepeatKind.daily, tod: '21:00')), 'daily 21:00');
      expect(McpTools.repeatText(r(RepeatKind.monthly, n: 2, tod: '03-24 09:00')),
          'every 2 months on day 24 09:00');
      expect(McpTools.repeatText(r(RepeatKind.yearly, tod: '11-23 08:00')),
          'yearly 11-23 08:00');
    });
  });
}
