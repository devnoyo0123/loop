import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../models/log_entry.dart';
import '../models/repeat_rule.dart';

/// SQLite 저장소. 스키마·쿼리 설계는 docs/data-model.md 참고.
class LoopDb {
  LoopDb(this.directory);

  final Directory directory;
  late final Database _db;
  final _random = Random();

  /// FTS5를 못 쓰는 환경이면 false — 검색이 전부 LIKE 스캔으로 폴백.
  bool _ftsAvailable = true;

  static const _tableSchema = '''
    CREATE TABLE IF NOT EXISTS logs (
      id                  TEXT PRIMARY KEY,
      content             TEXT NOT NULL,
      created_at          INTEGER NOT NULL,
      original_created_at INTEGER NOT NULL,
      parent_id           TEXT,
      root_id             TEXT,
      depth               INTEGER DEFAULT 0,
      path                TEXT,
      loop_at             INTEGER,
      loop_done           INTEGER DEFAULT 0,
      latitude            REAL,
      longitude           REAL,
      place               TEXT,
      weather_code        INTEGER,
      temperature_c       REAL
    );
  ''';

  static const _indexSchema = '''
    CREATE INDEX IF NOT EXISTS idx_created_at ON logs(created_at, id);
    CREATE INDEX IF NOT EXISTS idx_parent     ON logs(parent_id);
    CREATE INDEX IF NOT EXISTS idx_path       ON logs(path);
    CREATE INDEX IF NOT EXISTS idx_repeat     ON logs(repeat_rule_id);
  ''';

  /// v3: 이미지는 개념상 로그의 일부(같은 id, 같은 시계열 위치)지만
  /// 물리적으로만 별도 테이블 — 본문 윈도우 쿼리가 무거워지는 걸 막는다.
  /// 화면에 보이는 로그의 이미지 요약/본체만 필요할 때 읽는다.
  static const _imageTableSchema = '''
    CREATE TABLE IF NOT EXISTS log_images (
      id       TEXT PRIMARY KEY,
      log_id   TEXT NOT NULL,
      position INTEGER NOT NULL,
      base64   TEXT NOT NULL
    );
  ''';

  static const _imageIndexSchema = '''
    CREATE INDEX IF NOT EXISTS idx_log_images ON log_images(log_id, position);
  ''';

  /// v4: 반복 규칙 — "매일 이 시간", "N분/N시간마다".
  /// 발화마다 source_log_id의 포크가 생성된다. (docs/data-model.md v4)
  static const _repeatTableSchema = '''
    CREATE TABLE IF NOT EXISTS repeat_rules (
      id            TEXT PRIMARY KEY,
      source_log_id TEXT NOT NULL,
      kind          TEXT NOT NULL,
      every_n       INTEGER,
      time_of_day   TEXT,
      next_fire_at  INTEGER NOT NULL,
      fire_count    INTEGER DEFAULT 0,
      active        INTEGER DEFAULT 1,
      created_at    INTEGER NOT NULL,
      stopped_at    INTEGER
    );
  ''';

  static const _repeatIndexSchema = '''
    CREATE INDEX IF NOT EXISTS idx_repeat_active ON repeat_rules(active, next_fire_at);
    CREATE INDEX IF NOT EXISTS idx_repeat_source ON repeat_rules(source_log_id);
  ''';

  /// 앱 설정 (기본 브라우저 등) — 로컬 퍼스트 원칙대로 SQLite에 함께 둔다.
  static const _settingsTableSchema = '''
    CREATE TABLE IF NOT EXISTS settings (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  /// v5: 전문 검색 — SQLite 내장 FTS5 역색인. trigram 토크나이저라
  /// 사전 없이도 한글 부분문자열(3자 이상)이 맞는다.
  /// 본문은 logs(외부 콘텐츠)에서 읽고, 트리거로 색인만 동기화한다.
  static const _ftsTableSchema = '''
    CREATE VIRTUAL TABLE IF NOT EXISTS logs_fts USING fts5(
      content,
      place,
      content='logs',
      content_rowid='rowid',
      tokenize='trigram'
    );
  ''';

  static const _ftsTriggerSchema = '''
    CREATE TRIGGER IF NOT EXISTS logs_fts_ai AFTER INSERT ON logs BEGIN
      INSERT INTO logs_fts(rowid, content, place)
        VALUES (new.rowid, new.content, new.place);
    END;
    CREATE TRIGGER IF NOT EXISTS logs_fts_ad AFTER DELETE ON logs BEGIN
      INSERT INTO logs_fts(logs_fts, rowid, content, place)
        VALUES ('delete', old.rowid, old.content, old.place);
    END;
    CREATE TRIGGER IF NOT EXISTS logs_fts_au AFTER UPDATE ON logs BEGIN
      INSERT INTO logs_fts(logs_fts, rowid, content, place)
        VALUES ('delete', old.rowid, old.content, old.place);
      INSERT INTO logs_fts(rowid, content, place)
        VALUES (new.rowid, new.content, new.place);
    END;
  ''';

  void open() {
    _db = sqlite3.open('${directory.path}${Platform.pathSeparator}loop.db');
    _db.execute('PRAGMA journal_mode = WAL;');
    _openSchema();
  }

  /// 최종 스키마 컬럼 (id/content/created_at/original_created_at 제외).
  /// 없는 컬럼은 어떤 구버전에서 열어도 자동으로 추가된다.
  static const _columns = <String, String>{
    'parent_id': 'TEXT',
    'root_id': 'TEXT',
    'depth': 'INTEGER DEFAULT 0',
    'path': 'TEXT',
    'loop_at': 'INTEGER',
    'loop_done': 'INTEGER DEFAULT 0',
    'latitude': 'REAL',
    'longitude': 'REAL',
    'place': 'TEXT',
    'weather_code': 'INTEGER',
    'temperature_c': 'REAL',
    'repeat_rule_id': 'TEXT',
    // v6: 망각곡선 — 이 체인에서 루프(한 번 알림)로 돌아온 횟수.
    'loop_count': 'INTEGER DEFAULT 0',
    // v7: 이 루프를 알람처럼(무음 무시·꺼야 멈춤·전체화면) 울릴지.
    'loop_alarm': 'INTEGER DEFAULT 0',
  };

  /// 테이블 생성 → 컬럼 마이그레이션 → 인덱스.
  /// 이 순서여야 옛날 테이블에 새 인덱스를 만들다가 터지지 않는다.
  void _openSchema() {
    final tableExists = _db
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'logs'",
        )
        .isNotEmpty;
    if (!tableExists) _db.execute(_tableSchema);

    final columns = _db
        .select('PRAGMA table_info(logs)')
        .map((r) => r['name'])
        .toSet();
    for (final entry in _columns.entries) {
      if (!columns.contains(entry.key)) {
        _db.execute('ALTER TABLE logs ADD COLUMN ${entry.key} ${entry.value}');
      }
    }

    _db.execute(_indexSchema);
    _db.execute(_imageTableSchema);
    _db.execute(_imageIndexSchema);
    _db.execute(_repeatTableSchema);
    _db.execute(_repeatIndexSchema);
    _db.execute(_settingsTableSchema); // IF NOT EXISTS — 구버전 DB도 자동 승격
    try {
      _db.execute(_ftsTableSchema);
      _db.execute(_ftsTriggerSchema);
    } catch (_) {
      _ftsAvailable = false; // FTS5 미번들 환경 — 검색은 LIKE 폴백으로
    }

    // FTS 도입(5) 뒤 처음 여는 DB면 기존 로그 전체를 색인한다.
    final uv = _db.select('PRAGMA user_version').first['user_version'] as int;
    if (_ftsAvailable && uv < 5) {
      _db.execute("INSERT INTO logs_fts(logs_fts) VALUES('rebuild')");
    }
    _db.execute('PRAGMA user_version = 7'); // v7: loop_alarm (루프별 알람)
  }

  /// 앱 설정 읽기. 없으면 null.
  String? getSetting(String key) {
    final rows = _db.select('SELECT value FROM settings WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  /// 앱 설정 쓰기 (upsert).
  void setSetting(String key, String value) {
    _db.execute(
      'INSERT INTO settings(key, value) VALUES(?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  void close() => _db.close();

  /// 시각 정렬 가능한 ID (base36 시각 접두사 10자 + 난수 8자).
  /// 같은 밀리초에 여러 개가 생겨도 문자열 정렬이 시간 순서를 유지한다.
  String newId() {
    final ts = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .padLeft(10, '0');
    final rand = List.generate(
      8,
      (_) => _random.nextInt(36).toRadixString(36),
    ).join();
    return '$ts$rand';
  }

  LogEntry _fromRow(Map<String, Object?> r) => LogEntry(
    id: r['id'] as String,
    content: r['content'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    originalCreatedAt: DateTime.fromMillisecondsSinceEpoch(
      r['original_created_at'] as int,
    ),
    parentId: r['parent_id'] as String?,
    rootId: r['root_id'] as String?,
    depth: (r['depth'] as int?) ?? 0,
    path: r['path'] as String?,
    loopAt: r['loop_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r['loop_at'] as int),
    loopDone: ((r['loop_done'] as int?) ?? 0) == 1,
    latitude: (r['latitude'] as num?)?.toDouble(),
    longitude: (r['longitude'] as num?)?.toDouble(),
    place: r['place'] as String?,
    weatherCode: (r['weather_code'] as num?)?.toInt(),
    temperatureC: (r['temperature_c'] as num?)?.toDouble(),
    repeatRuleId: r['repeat_rule_id'] as String?,
    loopCount: (r['loop_count'] as int?) ?? 0,
    loopAlarm: ((r['loop_alarm'] as int?) ?? 0) == 1,
  );

  /// 최신 위 시계열 윈도우. 더 과거 페이지는 [anchor]로 keyset 이어 읽기 —
  /// OFFSET이 없어서 로그가 아무리 쌓여도 읽기 속도가 일정하다.
  /// [until]은 상한(미포함) — 날짜 이동 시 "그날까지"의 윈도우를 읽는다.
  List<LogEntry> window({
    ({DateTime time, String id})? anchor,
    DateTime? until,
    int limit = 100,
  }) {
    final where = <String>[];
    final args = <Object?>[];
    if (anchor != null) {
      where.add('(created_at < ? OR (created_at = ? AND id < ?))');
      args
        ..add(anchor.time.millisecondsSinceEpoch)
        ..add(anchor.time.millisecondsSinceEpoch)
        ..add(anchor.id);
    }
    if (until != null) {
      where.add('created_at < ?');
      args.add(until.millisecondsSinceEpoch);
    }
    final rows = _db.select(
      '''
      SELECT * FROM logs
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY created_at DESC, id DESC
      LIMIT ?
      ''',
      [...args, limit],
    );
    return [for (final r in rows) _fromRow(r)];
  }

  LogEntry? byId(String id) {
    final rows = _db.select('SELECT * FROM logs WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// 전문 검색 — 내용과 장소를 최신순으로.
  ///
  /// FTS5 trigram 역색인이라 로그가 몇십만 개여도 일정한 속도.
  /// trigram은 3자 이상부터라, 그보다 짧은 질의는 LIKE 스캔으로 폴백
  /// (한글엔 대소문자가 없어 손해가 없다).
  /// 스니펫의 매치 표시 마커 — UI가 이 사이를 밝은 스팬으로 렌더링한다.
  /// (출력에 절대 안 나오는 전용영역 문자)
  static const snippetOpen = '\uE000';
  static const snippetClose = '\uE001';

  /// 검색 결과 + 매치 부분 스니펫. [byRelevance]면 BM25 관련도순,
  /// 아니면(기본) 최신순. [search]의 전체 결과판.
  List<({LogEntry log, String snippet})> searchDetailed(
    String query, {
    int limit = 200,
    bool byRelevance = false,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const [];

    if (!_ftsAvailable || q.runes.length < 3) {
      var esc = q
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      final like = '%$esc%';
      final rows = _db.select(
        '''
        SELECT * FROM logs
        WHERE content LIKE ? ESCAPE '\\'
           OR place    LIKE ? ESCAPE '\\'
        ORDER BY created_at DESC, id DESC
        LIMIT ?
        ''',
        [like, like, limit],
      );
      // 역색인이 없는 경로라 스니펫도 직접 만든다 — 매치 주변만 잘라 표시.
      return [
        for (final r in rows)
          (
            log: _fromRow(r),
            snippet: _manualSnippet(r['content'] as String, q),
          ),
      ];
    }

    // MATCH 문법(따옴표 등)과 사용자 입력을 분리 — 통째로 인용 처리.
    final phrase = '"${q.replaceAll('"', '""')}"';
    final rows = _db.select(
      '''
      SELECT logs.*,
             snippet(logs_fts, 0, '$snippetOpen', '$snippetClose', '…', 12)
               AS _snip
      FROM logs
      JOIN logs_fts ON logs.rowid = logs_fts.rowid
      WHERE logs_fts MATCH ?
      ORDER BY ${byRelevance ? 'bm25(logs_fts)' : 'logs.created_at DESC, logs.id DESC'}
      LIMIT ?
      ''',
      [phrase, limit],
    );
    return [
      for (final r in rows)
        (log: _fromRow(r), snippet: (r['_snip'] as String?) ?? ''),
    ];
  }

  List<LogEntry> search(String query, {int limit = 200}) => [
    for (final r in searchDetailed(query, limit: limit)) r.log,
  ];

  /// LIKE 폴백용 수제 스니펫 — 본문에서 매치 주변만 잘라 마커를 둘러준다.
  /// (이모지 등 보문 문자를 위해 rune 단위로 자른다)
  static String _manualSnippet(String text, String query, {int window = 36}) {
    final chars = text.runes.toList();
    final low = [for (final c in chars) String.fromCharCode(c).toLowerCase()];
    final qChars = [
      for (final c in query.runes) String.fromCharCode(c).toLowerCase(),
    ];
    for (var i = 0; i + qChars.length <= chars.length; i++) {
      var hit = true;
      for (var j = 0; j < qChars.length; j++) {
        if (low[i + j] != qChars[j]) {
          hit = false;
          break;
        }
      }
      if (!hit) continue;
      final start = (i - window).clamp(0, chars.length);
      final end = (i + qChars.length + window).clamp(0, chars.length);
      return '${start > 0 ? '…' : ''}'
          '${String.fromCharCodes(chars.sublist(start, i))}'
          '$snippetOpen'
          '${String.fromCharCodes(chars.sublist(i, i + qChars.length))}'
          '$snippetClose'
          '${String.fromCharCodes(chars.sublist(i + qChars.length, end))}'
          '${end < chars.length ? '…' : ''}';
    }
    return text; // 장소 매치 등 — 본문엔 없으면 원문 그대로
  }

  void insert(LogEntry e) {
    _db.execute(
      '''
      INSERT INTO logs
        (id, content, created_at, original_created_at,
         parent_id, root_id, depth, path, loop_at, loop_done,
         latitude, longitude, place, weather_code, temperature_c,
         repeat_rule_id, loop_count, loop_alarm)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        e.id,
        e.content,
        e.createdAt.millisecondsSinceEpoch,
        e.originalCreatedAt.millisecondsSinceEpoch,
        e.parentId,
        e.rootId,
        e.depth,
        e.path,
        e.loopAt?.millisecondsSinceEpoch,
        e.loopDone ? 1 : 0,
        e.latitude,
        e.longitude,
        e.place,
        e.weatherCode,
        e.temperatureC,
        e.repeatRuleId,
        e.loopCount,
        e.loopAlarm ? 1 : 0,
      ],
    );
  }

  void updateContent(String id, String content) =>
      _db.execute('UPDATE logs SET content = ? WHERE id = ?', [content, id]);

  /// 시간 수정 — 시계열 위치가 재정렬된다. (original_created_at은 불변)
  void updateCreatedAt(String id, DateTime at) => _db.execute(
    'UPDATE logs SET created_at = ? WHERE id = ?',
    [at.millisecondsSinceEpoch, id],
  );

  void markLoopDone(String id) =>
      _db.execute('UPDATE logs SET loop_done = 1 WHERE id = ?', [id]);

  /// 망각곡선 카운트 +1 — 단발 루프가 발화했거나 발화 전 "지금 이어쓰기"로
  /// 소비됐을 때. 곡선의 다음 간격을 고르는 기준이 된다.
  void incrementLoopCount(String id) => _db.execute(
    'UPDATE logs SET loop_count = loop_count + 1 WHERE id = ?',
    [id],
  );

  /// 기존 로그에 알림(루프) 예약을 걸거나 다시 건다. (menu: ⏰ 알림 예약)
  /// 재예약이면 소화 상태를 되돌린다. [alarm]이 null이면 기존 알람 플래그 유지.
  void updateLoopAt(String id, DateTime at, {bool? alarm}) => _db.execute(
    'UPDATE logs SET loop_at = ?, loop_done = 0, '
    'loop_alarm = COALESCE(?, loop_alarm) WHERE id = ?',
    [at.millisecondsSinceEpoch, alarm == null ? null : (alarm ? 1 : 0), id],
  );

  /// 저장 후 뒤에서 캡처한 맥락(위치·날씨)을 조용히 반영.
  /// 날씨는 실패 시 기존 값을 유지(COALESCE) — 나중에 다시 채울 수 있다.
  void updateCapture(
    String id, {
    required double latitude,
    required double longitude,
    String? place,
    int? weatherCode,
    double? temperatureC,
  }) => _db.execute(
    'UPDATE logs SET latitude = ?, longitude = ?, place = ?, '
    'weather_code = COALESCE(?, weather_code), '
    'temperature_c = COALESCE(?, temperature_c) '
    'WHERE id = ?',
    [latitude, longitude, place, weatherCode, temperatureC, id],
  );

  void delete(String id) {
    // 원본이 지워지면 그 원본의 살아있는 반복도 함께 멈춘다.
    stopRepeatForSource(id);
    _db.execute('DELETE FROM log_images WHERE log_id = ?', [id]);
    _db.execute('DELETE FROM logs WHERE id = ?', [id]);
  }

  // ── 이미지 (v3) ──────────────────────────────────────────────

  /// 이미지 저장. bytes는 여기서 base64로 인코딩된다. 순서 = 리스트 순서.
  void insertImages(String logId, List<Uint8List> bytesList) {
    _db.execute('BEGIN');
    try {
      for (var i = 0; i < bytesList.length; i++) {
        _db.execute(
          'INSERT INTO log_images (id, log_id, position, base64) VALUES (?, ?, ?, ?)',
          [newId(), logId, i, base64Encode(bytesList[i])],
        );
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// 상세 화면용 — 로그의 전체 이미지. (본문 순서대로)
  List<Uint8List> imagesFor(String logId) {
    final rows = _db.select(
      'SELECT base64 FROM log_images WHERE log_id = ? ORDER BY position',
      [logId],
    );
    return [
      for (final r in rows)
        Uint8List.fromList(base64Decode(r['base64'] as String)),
    ];
  }

  /// 타임라인 카드용 요약 — 장수 + 첫 이미지(썸네일 표시용)만.
  /// 윈도우의 로그 id들을 한 번에 읽는다. (본문 쿼리는 이미지를 안 읽음)
  Map<String, LogImageSummary> imageSummariesFor(Set<String> logIds) {
    if (logIds.isEmpty) return {};
    final marks = List.filled(logIds.length, '?').join(', ');
    final summary = <String, LogImageSummary>{};

    final counts = _db.select(
      'SELECT log_id, COUNT(*) AS cnt FROM log_images '
      'WHERE log_id IN ($marks) GROUP BY log_id',
      logIds.toList(),
    );
    for (final r in counts) {
      summary[r['log_id'] as String] = LogImageSummary(count: r['cnt'] as int);
    }

    final firsts = _db.select(
      'SELECT log_id, base64 FROM log_images '
      'WHERE log_id IN ($marks) AND position = 0',
      logIds.toList(),
    );
    for (final r in firsts) {
      final logId = r['log_id'] as String;
      summary[logId] = LogImageSummary(
        count: summary[logId]?.count ?? 1,
        firstBase64: r['base64'] as String,
      );
    }
    return summary;
  }

  /// 이 로그의 루프 사슬 — 최상위 원본부터 자기 자신까지 시간 순서.
  /// parentId를 따라 거슬러 올라가며, 중간이 삭제됐으면 있는 만큼만 반환.
  List<LogEntry> lineage(String id) {
    final chain = <LogEntry>[];
    var cur = byId(id);
    var guard = 0; // 데이터 이상으로 사이클이 생겨도 멈추도록
    while (cur != null && guard++ < 200) {
      chain.insert(0, cur);
      cur = cur.parentId == null ? null : byId(cur.parentId!);
    }
    return chain;
  }

  /// 아직 소화되지 않은 단발 루프 중 (from, to] 사이에 도래할 것들.
  /// 다가오는 루프 미리보기용 — 발화 예정 시각 순서.
  List<LogEntry> pendingLoopsBetween(DateTime from, DateTime to) {
    final rows = _db.select(
      'SELECT * FROM logs '
      'WHERE loop_at IS NOT NULL AND loop_done = 0 '
      'AND loop_at > ? AND loop_at <= ? ORDER BY loop_at',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [for (final r in rows) _fromRow(r)];
  }

  /// 아직 도래하지 않은 단발 루프 전부 — 앱 시작 때 OS 알람을 다시 걸기 위한
  /// 조회. 재부팅이나 자동 백업 복원(새 설치)에선 예약됐던 알람이 증발했을 수
  /// 있어, 앱이 켜질 때마다 미래분을 다시 걸어야 놓치지 않는다.
  List<LogEntry> pendingOneShotLoops() {
    final rows = _db.select(
      'SELECT * FROM logs '
      'WHERE loop_at IS NOT NULL AND loop_done = 0 AND loop_at > ? '
      'ORDER BY loop_at',
      [DateTime.now().millisecondsSinceEpoch],
    );
    return [for (final r in rows) _fromRow(r)];
  }

  /// 도는 시점(앱 시작·1분 타이머·복귀)마다 발화 시각이 지난 단발 루프를 소화.
  /// 반복과 마찬가지로 발화 시각으로 빈 포크 로그를 만들고(시계열 올바른
  /// 위치에 끼워짐) 원본은 소화(loop_done=1)한다. 생성 개수 반환.
  int settleExpiredLoops() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final due = _db.select(
      'SELECT * FROM logs '
      'WHERE loop_at IS NOT NULL AND loop_done = 0 AND loop_at <= ?',
      [nowMs],
    );
    for (final r in due) {
      final log = _fromRow(r);
      final at = log.loopAt!; // 예정됐던 발화 시각 — 그 순간의 자리에 생성
      final id = newId();
      insert(
        LogEntry(
          id: id,
          content: '',
          createdAt: at,
          originalCreatedAt: at,
          parentId: log.id,
          rootId: log.rootId ?? log.id,
          depth: log.depth + 1,
          path: '${log.path ?? log.id}/$id',
          // 포크도 체인 카운트를 이어받는다 — 포크에서 다시 루프를 걸면
          // 망각곡선의 다음 간격이 이어서 제안된다.
          loopCount: log.loopCount + 1,
        ),
      );
    }
    if (due.isNotEmpty) {
      // 소화 + 망각곡선 카운트 증가를 한 문장으로 — 대상은 방금 발화한 원본들.
      _db.execute(
        'UPDATE logs SET loop_done = 1, loop_count = loop_count + 1 '
        'WHERE loop_at IS NOT NULL AND loop_done = 0 AND loop_at <= ?',
        [nowMs],
      );
    }
    return due.length;
  }

  // ── 반복 규칙 (v4) ───────────────────────────────────────────

  /// 1회 정리당 규칙별 최대 몰아생성 수 — 10분 반복을 몇 주 안 켰을 때의
  /// 홍수 방지 안전장치. 넘친 만큼은 다음 정리 때 이어서 생성된다.
  static const maxCatchUpPerSettle = 200;

  void insertRepeatRule(RepeatRule r) => _db.execute(
    '''
        INSERT INTO repeat_rules
          (id, source_log_id, kind, every_n, time_of_day,
           next_fire_at, fire_count, active, created_at, stopped_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
    [
      r.id,
      r.sourceLogId,
      r.kind.name,
      r.everyN,
      r.timeOfDay,
      r.nextFireAt.millisecondsSinceEpoch,
      r.fireCount,
      r.active ? 1 : 0,
      r.createdAt.millisecondsSinceEpoch,
      r.stoppedAt?.millisecondsSinceEpoch,
    ],
  );

  RepeatRule _repeatFromRow(Map<String, Object?> r) => RepeatRule(
    id: r['id'] as String,
    sourceLogId: r['source_log_id'] as String,
    kind: RepeatKind.values.byName(r['kind'] as String),
    everyN: (r['every_n'] as num?)?.toInt(),
    timeOfDay: r['time_of_day'] as String?,
    nextFireAt: DateTime.fromMillisecondsSinceEpoch(r['next_fire_at'] as int),
    fireCount: (r['fire_count'] as int?) ?? 0,
    active: ((r['active'] as int?) ?? 1) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    stoppedAt: r['stopped_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r['stopped_at'] as int),
  );

  RepeatRule? repeatRuleById(String id) {
    final rows = _db.select('SELECT * FROM repeat_rules WHERE id = ?', [id]);
    return rows.isEmpty ? null : _repeatFromRow(rows.first);
  }

  List<RepeatRule> activeRepeatRules() => [
    for (final r in _db.select(
      'SELECT * FROM repeat_rules WHERE active = 1 ORDER BY next_fire_at',
    ))
      _repeatFromRow(r),
  ];

  /// 이 로그가 원본인 살아있는 반복. (카드 상태 표시용)
  RepeatRule? activeRepeatForSource(String sourceLogId) {
    final rows = _db.select(
      'SELECT * FROM repeat_rules WHERE source_log_id = ? AND active = 1',
      [sourceLogId],
    );
    return rows.isEmpty ? null : _repeatFromRow(rows.first);
  }

  /// 반복 멈춤 — 다음 발화부터 취소. 이미 생성된 로그는 남고, 규칙은
  /// 기록(active=0)으로 남아 "몇 번 반복됐는지"를 나중에도 셀 수 있다.
  void stopRepeat(String id) => _db.execute(
    'UPDATE repeat_rules SET active = 0, stopped_at = ? WHERE id = ?',
    [DateTime.now().millisecondsSinceEpoch, id],
  );

  void stopRepeatForSource(String sourceLogId) => _db.execute(
    'UPDATE repeat_rules SET active = 0, stopped_at = ? '
    'WHERE source_log_id = ? AND active = 1',
    [DateTime.now().millisecondsSinceEpoch, sourceLogId],
  );

  /// 앱이 켜졌을 때 도는 반복 정리. 발화 시각이 지난 규칙마다
  /// 그 시각대로 빈 포크 로그를 몰아 생성하고(시계열 올바른 위치에 끼워짐)
  /// 규칙의 다음 발화 시각을 미래로 밀어준다. 생성 개수 반환.
  int settleRepeats() {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    var created = 0;

    final due = _db.select(
      'SELECT * FROM repeat_rules WHERE active = 1 AND next_fire_at <= ?',
      [nowMs],
    );
    for (final row in due) {
      final rule = _repeatFromRow(row);
      // 소스는 발화마다가 아니라 한 번만 조회한다.
      final source = byId(rule.sourceLogId);
      var t = rule.nextFireAt;
      var fires = 0;
      while (!t.isAfter(now) && fires < maxCatchUpPerSettle) {
        final id = newId();
        insert(
          LogEntry(
            id: id,
            content: '',
            createdAt: t, // 예정됐던 발화 시각 — 잡아먹힌 시간의 자리에
            originalCreatedAt: t,
            parentId: rule.sourceLogId,
            rootId: source == null
                ? rule.sourceLogId
                : (source.rootId ?? source.id),
            depth: (source?.depth ?? 0) + 1,
            path: '${source?.path ?? rule.sourceLogId}/$id',
            repeatRuleId: rule.id,
          ),
        );
        fires++;
        t = rule.nextFireAfter(t);
      }
      if (fires > 0) {
        _db.execute(
          'UPDATE repeat_rules SET next_fire_at = ?, '
          'fire_count = fire_count + ? WHERE id = ?',
          [t.millisecondsSinceEpoch, fires, rule.id],
        );
        created += fires;
      }
    }
    return created;
  }

  // ── 내보내기 (.looplog = JSONL) ──────────────────────────────
  // 한 줄 = 데이터 하나. 종류: looplog(헤더) / log / image / repeat.
  // 무손실이라 나중에 가져오기(복원)도 같은 포맷으로 가능하다.
  /// 전체 데이터를 한 줄씩 흘려준다. 이미지 base64가 아무리 커도
  /// 한 번에 한 줄만 메모에 올라간다 — 저장소로 스트리밍하기 위한 설계.
  Iterable<String> exportLines() sync* {
    yield jsonEncode({
      'type': 'looplog',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
    });

    for (final r in _db.select('SELECT * FROM logs ORDER BY created_at, id')) {
      final e = _fromRow(r);
      yield jsonEncode({
        'type': 'log',
        'id': e.id,
        'content': e.content,
        'createdAt': e.createdAt.toIso8601String(),
        'originalCreatedAt': e.originalCreatedAt.toIso8601String(),
        'parentId': e.parentId,
        'rootId': e.rootId,
        'depth': e.depth,
        'path': e.path,
        'loopAt': e.loopAt?.toIso8601String(),
        'loopDone': e.loopDone,
        'latitude': e.latitude,
        'longitude': e.longitude,
        'place': e.place,
        'weatherCode': e.weatherCode,
        'temperatureC': e.temperatureC,
        'repeatRuleId': e.repeatRuleId,
        'loopCount': e.loopCount,
        'loopAlarm': e.loopAlarm,
      });
      for (final img in _db.select(
        'SELECT id, position, base64 FROM log_images '
        'WHERE log_id = ? ORDER BY position',
        [e.id],
      )) {
        yield jsonEncode({
          'type': 'image',
          'id': img['id'],
          'logId': e.id,
          'position': img['position'],
          'base64': img['base64'],
        });
      }
    }

    for (final r in _db.select(
      'SELECT * FROM repeat_rules ORDER BY created_at, id',
    )) {
      final rule = _repeatFromRow(r);
      yield jsonEncode({
        'type': 'repeat',
        'id': rule.id,
        'sourceLogId': rule.sourceLogId,
        'kind': rule.kind.name,
        'everyN': rule.everyN,
        'timeOfDay': rule.timeOfDay,
        'nextFireAt': rule.nextFireAt.toIso8601String(),
        'fireCount': rule.fireCount,
        'active': rule.active,
        'createdAt': rule.createdAt.toIso8601String(),
        'stoppedAt': rule.stoppedAt?.toIso8601String(),
      });
    }
  }

  /// .looplog(JSONL) 한 줄씩 가져오기 — [exportLines]의 역.
  ///
  /// ID가 전 세계적으로 유니크(시각+무작위)하므로 머지는 "같은 id면 건너뛴다"
  /// 한 가지 규칙으로 끝난다. 다른 기기 데이터를 더할 수도, 같은 백업을
  /// 두 번 가져와도 중복이 생기지 않는다. 살아있는 반복 규칙의 next_fire_at이
  /// 과거면 이후 settleRepeats가 몰아 생성한다 — 기존 동작과 같다.
  Future<ImportStats> importLines(Stream<String> lines) async {
    final it = StreamIterator(lines);
    if (!await it.moveNext()) throw const FormatException('빈 파일');
    final header = jsonDecode(it.current) as Map<String, Object?>;
    if (header['type'] != 'looplog') {
      throw const FormatException('.looplog 형식이 아님');
    }

    var logs = 0;
    var images = 0;
    var repeats = 0;
    _db.execute('BEGIN');
    try {
      do {
        final row = jsonDecode(it.current) as Map<String, Object?>;
        switch (row['type'] as String?) {
          case 'log':
            final id = row['id'] as String;
            if (_logExists(id)) continue;
            insert(_logFromExport(row));
            logs++;
          case 'image':
            final id = row['id'] as String;
            if (_imageExists(id)) continue;
            _db.execute(
              'INSERT INTO log_images (id, log_id, position, base64) '
              'VALUES (?, ?, ?, ?)',
              [id, row['logId'], row['position'], row['base64']],
            );
            images++;
          case 'repeat':
            final id = row['id'] as String;
            if (_repeatExists(id)) continue;
            insertRepeatRule(_repeatFromExport(row));
            repeats++;
        }
      } while (await it.moveNext());
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      it.cancel();
    }
    return ImportStats(logs: logs, images: images, repeats: repeats);
  }

  bool _logExists(String id) =>
      _db.select('SELECT 1 FROM logs WHERE id = ?', [id]).isNotEmpty;

  bool _imageExists(String id) =>
      _db.select('SELECT 1 FROM log_images WHERE id = ?', [id]).isNotEmpty;

  bool _repeatExists(String id) =>
      _db.select('SELECT 1 FROM repeat_rules WHERE id = ?', [id]).isNotEmpty;

  /// 내보낸 필드 이름 그대로 — loopCount처럼 뒤에 추가된 필드가 없는
  /// 옛 백업도 기본값으로 받는다.
  LogEntry _logFromExport(Map<String, Object?> r) => LogEntry(
    id: r['id'] as String,
    content: (r['content'] as String?) ?? '',
    createdAt: DateTime.parse(r['createdAt'] as String),
    originalCreatedAt: DateTime.parse(r['originalCreatedAt'] as String),
    parentId: r['parentId'] as String?,
    rootId: r['rootId'] as String?,
    depth: (r['depth'] as num?)?.toInt() ?? 0,
    path: r['path'] as String?,
    loopAt: r['loopAt'] == null ? null : DateTime.parse(r['loopAt'] as String),
    loopDone: (r['loopDone'] as bool?) ?? false,
    latitude: (r['latitude'] as num?)?.toDouble(),
    longitude: (r['longitude'] as num?)?.toDouble(),
    place: r['place'] as String?,
    weatherCode: (r['weatherCode'] as num?)?.toInt(),
    temperatureC: (r['temperatureC'] as num?)?.toDouble(),
    repeatRuleId: r['repeatRuleId'] as String?,
    loopCount: (r['loopCount'] as num?)?.toInt() ?? 0,
    loopAlarm: (r['loopAlarm'] as bool?) ?? false,
  );

  RepeatRule _repeatFromExport(Map<String, Object?> r) => RepeatRule(
    id: r['id'] as String,
    sourceLogId: r['sourceLogId'] as String,
    kind: RepeatKind.values.byName(r['kind'] as String),
    everyN: (r['everyN'] as num?)?.toInt(),
    timeOfDay: r['timeOfDay'] as String?,
    nextFireAt: DateTime.parse(r['nextFireAt'] as String),
    fireCount: (r['fireCount'] as num?)?.toInt() ?? 0,
    active: (r['active'] as bool?) ?? true,
    createdAt: DateTime.parse(r['createdAt'] as String),
    stoppedAt: r['stoppedAt'] == null
        ? null
        : DateTime.parse(r['stoppedAt'] as String),
  );
}

/// 가져오기 결과 통계 — 실제로 새로 들어온 것만 센다(같은 id는 건너뜀).
class ImportStats {
  const ImportStats({
    required this.logs,
    required this.images,
    required this.repeats,
  });

  final int logs;
  final int images;
  final int repeats;

  bool get isEmpty => logs == 0 && images == 0 && repeats == 0;
}
