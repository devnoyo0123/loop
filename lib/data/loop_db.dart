import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
import '../services/image_store.dart';

/// SQLite 저장소. 스키마·쿼리 설계는 docs/data-model.md 참고.
class LoopDb {
  LoopDb(this.directory, {this.imageStore});

  final Directory directory;

  /// 이미지 파일 저장소 — 있으면 새 이미지를 파일로 보관하고 읽을 때도
  /// 파일을 우선한다. null이면 구버전처럼 base64 인라인(테스트·폴백). (v10)
  final ImageStore? imageStore;
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
      id        TEXT PRIMARY KEY,
      log_id    TEXT NOT NULL,
      position  INTEGER NOT NULL,
      base64    TEXT,
      file_name TEXT
    );
  ''';

  /// v10: 파일 전환 — 기존 테이블에 file_name 컬럼 추가, base64는
  /// nullable로 완화(레거시 행 마이그레이션 후 비운다).
  static const _imageFileColumn = 'file_name TEXT';

  static const _imageIndexSchema = '''
    CREATE INDEX IF NOT EXISTS idx_log_images ON log_images(log_id, position);
  ''';

  /// v9: 동영상 — 파일은 app dir/videos/에, DB엔 경로·메타만.
  /// (이미지의 base64 인라인과 달리 용량이 커서 로그 DB를 오염시키지
  /// 않게 물리 분리. docs/growth-ideas.md "촬영 첨부")
  static const _videoTableSchema = '''
    CREATE TABLE IF NOT EXISTS log_videos (
      id        TEXT PRIMARY KEY,
      log_id    TEXT NOT NULL,
      position  INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      size      INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const _videoIndexSchema = '''
    CREATE INDEX IF NOT EXISTS idx_log_videos ON log_videos(log_id, position);
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

  /// v11: 공유 정체성 — 상대 기기 식별자와 표시명. (docs/share-design.md §3)
  static const _peersTableSchema = '''
    CREATE TABLE IF NOT EXISTS peers (
      id         TEXT PRIMARY KEY,
      name       TEXT NOT NULL,
      first_seen INTEGER NOT NULL,
      last_seen  INTEGER NOT NULL
    );
  ''';

  /// v11: 사슬 수신 기록 — 사슬당 출처 1개(첫 수신 유지). 로그 레벨 저자는
  /// logs.author_id가 담당하고, 여기엔 "직접 누구에게서 받았나"만 남는다.
  static const _chainSharesTableSchema = '''
    CREATE TABLE IF NOT EXISTS chain_shares (
      root_id     TEXT PRIMARY KEY,
      peer_id     TEXT NOT NULL,
      received_at INTEGER NOT NULL,
      via         TEXT NOT NULL
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
    // v11: 공유 출처 — null이면 내가 쓴 기록, 받은 기록은 보낸 이의 peers.id.
    'author_id': 'TEXT',
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
    final imageCols = _db
        .select('PRAGMA table_info(log_images)')
        .map((r) => r['name'])
        .toSet();
    if (!imageCols.contains('file_name')) {
      _db.execute('ALTER TABLE log_images ADD COLUMN $_imageFileColumn');
    }
    _db.execute(_imageIndexSchema);
    _db.execute(_videoTableSchema); // v9: 동영상 (파일은 VideoStore가 관리)
    _db.execute(_videoIndexSchema);
    _db.execute(_repeatTableSchema);
    _db.execute(_repeatIndexSchema);
    _db.execute(_settingsTableSchema); // IF NOT EXISTS — 구버전 DB도 자동 승격
    _db.execute(_peersTableSchema); // v11: 공유 정체성 (자동 승격)
    _db.execute(_chainSharesTableSchema);
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
    _db.execute('PRAGMA user_version = 11'); // v11: 공유 — peers·chain_shares·author_id
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

  /// 앱 설정 지우기 — 이후 [getSetting]은 null. (PC 연결 페어링 해제 등)
  void deleteSetting(String key) =>
      _db.execute('DELETE FROM settings WHERE key = ?', [key]);

  // ── 공유 정체성 (v11, docs/share-design.md §2) ────────────────

  static const _keyDeviceId = 'device_id';
  static const _keyShareName = 'share_name';

  /// 내 기기 식별자 — 첫 공유 시점에 한 번 생성돼 이후 불변. 기기명과
  /// 무관한 랜덤 값이라 이름을 바꿔도 동일하다. 한 번도 공유 안 한
  /// 설치본엔 존재하지 않는다(프라이버시).
  String peerId() =>
      getSetting(_keyDeviceId) ??
      () {
        final id = newId();
        setSetting(_keyDeviceId, id);
        return id;
      }();

  /// 공유 시 상대에게 보이는 표시명 (자기 선언, 언제든 변경 가능).
  String? shareName() => getSetting(_keyShareName);

  void setShareName(String name) => setSetting(_keyShareName, name);

  /// 상대 등록 — id는 불변, 이름·마지막 접촉만 갱신된다.
  void upsertPeer(String id, String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute(
      'INSERT INTO peers(id, name, first_seen, last_seen) VALUES(?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'name = excluded.name, last_seen = excluded.last_seen',
      [id, name, now, now],
    );
  }

  String? peerName(String id) {
    final rows = _db.select('SELECT name FROM peers WHERE id = ?', [id]);
    return rows.isEmpty ? null : rows.first['name'] as String;
  }

  /// 사슬의 수신 출처 — 공유받은 사슬이 아니면 null.
  ({String peerId, DateTime receivedAt, String via})? chainShareFor(
    String rootId,
  ) {
    final rows = _db.select(
      'SELECT peer_id, received_at, via FROM chain_shares WHERE root_id = ?',
      [rootId],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      peerId: r['peer_id'] as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(r['received_at'] as int),
      via: r['via'] as String,
    );
  }

  /// 사슬 요약 — 공유 시트 미리보기 카운트. (share-design.md §5)
  ({int logs, int photos, int videos, int repeats}) chainStats(String rootId) {
    final rows = _db.select(
      'SELECT id FROM logs WHERE id = ? OR path LIKE ?',
      [rootId, '$rootId/%'],
    );
    final ids = {for (final r in rows) r['id'] as String};
    var photos = 0;
    var videos = 0;
    // IN 절 변수 상한 대비 청크 — 거대 사슬(수백 로그)도 안전하게.
    final idList = ids.toList();
    for (var i = 0; i < idList.length; i += 500) {
      final chunk = idList.skip(i).take(500).toList();
      final marks = List.filled(chunk.length, '?').join(',');
      photos += _db
          .select(
            'SELECT COUNT(*) c FROM log_images WHERE log_id IN ($marks)',
            chunk,
          )
          .first['c'] as int;
      videos += _db
          .select(
            'SELECT COUNT(*) c FROM log_videos WHERE log_id IN ($marks)',
            chunk,
          )
          .first['c'] as int;
    }
    var repeats = 0;
    for (final r in _db.select('SELECT source_log_id FROM repeat_rules')) {
      if (ids.contains(r['source_log_id'])) repeats++;
    }
    return (logs: ids.length, photos: photos, videos: videos, repeats: repeats);
  }

  /// 사슬에 걸린 살아있는 반복 — 이어받기 완료 화면의 다음 발화 표시.
  RepeatRule? activeRuleInChain(String rootId) {
    final rows = _db.select(
      'SELECT * FROM repeat_rules WHERE active = 1 AND source_log_id IN '
      '(SELECT id FROM logs WHERE id = ? OR path LIKE ?)',
      [rootId, '$rootId/%'],
    );
    return rows.isEmpty ? null : _repeatFromRow(rows.first);
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
    authorId: r['author_id'] as String?,
  );

  /// 최신 위 시계열 윈도우. 더 과거 페이지는 [anchor]로 keyset 이어 읽기 —
  /// OFFSET이 없어서 로그가 아무리 쌓여도 읽기 속도가 일정하다.
  /// [until]은 상한(미포함) — 날짜 이동 시 "그날까지"의 윈도우를 읽는다.
  /// [mineOnly]는 내가 쓴 기록만 — 공유받은 기록(author_id != null)을 뺀다.
  List<LogEntry> window({
    ({DateTime time, String id})? anchor,
    DateTime? until,
    int limit = 100,
    bool mineOnly = false,
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
    if (mineOnly) {
      where.add('author_id IS NULL');
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
  ///
  /// [from]/[to]는 날짜 단위 포함 범위(기기 시간대) — [from]은 그날 0시,
  /// [to]는 다음날 0시(미포함)로 바꿔 `created_at`과 비교한다. (PC 연결 검색용)
  List<({LogEntry log, String snippet})> searchDetailed(
    String query, {
    int limit = 200,
    bool byRelevance = false,
    DateTime? from,
    DateTime? to,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final range = <String>[];
    final rangeArgs = <Object?>[];
    if (from != null) {
      range.add('logs.created_at >= ?');
      rangeArgs.add(
        DateTime(from.year, from.month, from.day).millisecondsSinceEpoch,
      );
    }
    if (to != null) {
      range.add('logs.created_at < ?');
      rangeArgs.add(
        DateTime(to.year, to.month, to.day + 1).millisecondsSinceEpoch,
      );
    }
    final rangeSql = range.isEmpty ? '' : 'AND ${range.join(' AND ')}';

    if (!_ftsAvailable || q.runes.length < 3) {
      var esc = q
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      final like = '%$esc%';
      final rows = _db.select(
        '''
        SELECT * FROM logs
        WHERE (content LIKE ? ESCAPE '\\'
            OR place    LIKE ? ESCAPE '\\')
          $rangeSql
        ORDER BY created_at DESC, id DESC
        LIMIT ?
        ''',
        [like, like, ...rangeArgs, limit],
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
        $rangeSql
      ORDER BY ${byRelevance ? 'bm25(logs_fts)' : 'logs.created_at DESC, logs.id DESC'}
      LIMIT ?
      ''',
      [phrase, ...rangeArgs, limit],
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
         repeat_rule_id, loop_count, loop_alarm, author_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        e.authorId,
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
    _db.execute('DELETE FROM log_videos WHERE log_id = ?', [id]);
    _db.execute('DELETE FROM logs WHERE id = ?', [id]);
  }

  // ── 이미지 (v3) ──────────────────────────────────────────────

  /// 이미지 저장. 이미지 스토어가 있으면 파일로 보관하고 DB엔 파일명만,
  /// 없으면(테스트·폴백) 구버전처럼 base64 인라인. 순서 = 리스트 순서.
  void insertImages(String logId, List<Uint8List> bytesList) {
    _db.execute('BEGIN');
    try {
      for (var i = 0; i < bytesList.length; i++) {
        final id = newId();
        String? fileName;
        String? base64;
        final store = imageStore;
        if (store != null) {
          fileName = store.save(id, bytesList[i]);
        } else {
          base64 = base64Encode(bytesList[i]);
        }
        _db.execute(
          'INSERT INTO log_images (id, log_id, position, base64, file_name) '
          'VALUES (?, ?, ?, ?, ?)',
          [id, logId, i, base64, fileName],
        );
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// v10 마이그레이션 — 레거시 base64 행을 파일로 옮기고 base64를 비운다.
  /// 멱등: 파일 쓰고 UPDATE 사이에 죽어도 다음 실행이 이어서 한다.
  /// (스토어가 없으면 아무것도 하지 않는다) 이동한 장수 반환.
  int migrateLegacyImages() {
    final store = imageStore;
    if (store == null) return 0;
    final rows = _db.select(
      'SELECT id, base64 FROM log_images '
      "WHERE file_name IS NULL AND base64 IS NOT NULL",
    );
    var moved = 0;
    for (final r in rows) {
      try {
        final bytes = base64Decode(r['base64'] as String);
        final fileName = store.save(r['id'] as String, bytes);
        // 파일이 디스크에 flush된 뒤에만 base64를 비운다 — 어느 시점에
        // 죽어도 원본(base64)이 남아 다음 실행이 이어간다. (유실 없음)
        _db.execute(
          'UPDATE log_images SET file_name = ?, base64 = NULL WHERE id = ?',
          [fileName, r['id']],
        );
        moved++;
      } catch (_) {
        // 디스크 부족 등 — 이 장은 base64를 남기고 다음 실행에 재시도
        continue;
      }
    }
    return moved;
  }

  /// 상세 화면용 — 로그의 전체 이미지. (본문 순서대로)
  /// 파일 우선, 레거시 base64 폴백. 파일이 사라진(백업 제외·기기 이전 등)
  /// 장은 조용히 건너뛴다. (v10)
  List<Uint8List> imagesFor(String logId) {
    final rows = _db.select(
      'SELECT base64, file_name FROM log_images '
      'WHERE log_id = ? ORDER BY position',
      [logId],
    );
    final out = <Uint8List>[];
    for (final r in rows) {
      final fileName = r['file_name'] as String?;
      if (fileName != null) {
        final bytes = imageStore?.read(fileName);
        if (bytes != null) out.add(bytes);
        continue;
      }
      final base64Body = r['base64'] as String?;
      if (base64Body != null) {
        out.add(Uint8List.fromList(base64Decode(base64Body)));
      }
    }
    return out;
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
      'SELECT log_id, base64, file_name FROM log_images '
      'WHERE log_id IN ($marks) AND position = 0',
      logIds.toList(),
    );
    for (final r in firsts) {
      final logId = r['log_id'] as String;
      final fileName = r['file_name'] as String?;
      final base64Body = r['base64'] as String?;
      String? firstBase64;
      if (fileName != null) {
        final bytes = imageStore?.read(fileName);
        if (bytes != null) firstBase64 = base64Encode(bytes);
      } else if (base64Body != null) {
        firstBase64 = base64Body;
      }
      if (firstBase64 == null) {
        // 대표 장(0번)을 못 읽으면 표시기 자체를 숨긴다 — 보이지 않는
        // 사진의 "N장" 칩은 거짓말이니까. (v10)
        summary.remove(logId);
        continue;
      }
      summary[logId] = LogImageSummary(
        count: summary[logId]?.count ?? 1,
        firstBase64: firstBase64,
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

  /// 사슬 전체 — [id]가 사슬 안 아무 로그여도 원본과 모든 후속을 시간순으로.
  /// [chainStats]와 같은 조건(원본 id 또는 path 전방 일치). 없는 id면 빈 목록.
  List<LogEntry> chainLogs(String id) {
    final log = byId(id);
    if (log == null) return const [];
    final root = log.rootId ?? log.id;
    final rows = _db.select(
      'SELECT * FROM logs WHERE id = ? OR path LIKE ? ORDER BY created_at, id',
      [root, '$root/%'],
    );
    return [for (final r in rows) _fromRow(r)];
  }

  /// 로그별 사진·동영상 개수 — 바이트를 읽는 [imagesFor] 대신 COUNT만.
  /// 첨부가 없는 로그는 결과에 없다(0으로 취급).
  Map<String, ({int images, int videos})> mediaCounts(List<String> ids) {
    final images = <String, int>{};
    final videos = <String, int>{};
    final idList = ids.toSet().toList();
    // IN 절 변수 상한 대비 청크 — chainStats와 같은 방식.
    for (var i = 0; i < idList.length; i += 500) {
      final chunk = idList.skip(i).take(500).toList();
      final marks = List.filled(chunk.length, '?').join(',');
      for (final r in _db.select(
        'SELECT log_id, COUNT(*) AS n FROM log_images '
        'WHERE log_id IN ($marks) GROUP BY log_id',
        chunk,
      )) {
        images[r['log_id'] as String] = r['n'] as int;
      }
      for (final r in _db.select(
        'SELECT log_id, COUNT(*) AS n FROM log_videos '
        'WHERE log_id IN ($marks) GROUP BY log_id',
        chunk,
      )) {
        videos[r['log_id'] as String] = r['n'] as int;
      }
    }
    return {
      for (final id in {...images.keys, ...videos.keys})
        id: (images: images[id] ?? 0, videos: videos[id] ?? 0),
    };
  }

  // ── 동영상 (v9 — 파일은 VideoStore, DB엔 메타만) ────────────

  /// 동영상 첨부 — 한 로그에 하나(v1). position은 현재 개수.
  void insertVideo(String logId, String fileName, int size) => _db.execute(
    'INSERT INTO log_videos (id, log_id, position, file_name, size) '
    'VALUES (?, ?, (SELECT COUNT(*) FROM log_videos WHERE log_id = ?), ?, ?)',
    [newId(), logId, logId, fileName, size],
  );

  /// 로그의 동영상 메타 전부 (파일 본문은 VideoStore가 읽는다).
  List<LogVideoRec> videosFor(String logId) => [
    for (final r in _db.select(
      'SELECT * FROM log_videos WHERE log_id = ? ORDER BY position',
      [logId],
    ))
      LogVideoRec(
        id: r['id'] as String,
        logId: r['log_id'] as String,
        fileName: r['file_name'] as String,
        size: (r['size'] as int?) ?? 0,
      ),
  ];

  /// 로그의 이미지 파일명 전부 — 삭제 시 파일 본문 정리용. (v10)
  List<String> imageFileNamesFor(String logId) => [
    for (final r in _db.select(
      'SELECT file_name FROM log_images '
      "WHERE log_id = ? AND file_name IS NOT NULL",
      [logId],
    ))
      r['file_name'] as String,
  ];

  /// 카드 칩용 — 윈도우 로그들의 동영상 개수 배치 조회.
  Map<String, int> videoCountsFor(Set<String> logIds) {
    if (logIds.isEmpty) return {};
    final marks = List.filled(logIds.length, '?').join(', ');
    return {
      for (final r in _db.select(
        'SELECT log_id, COUNT(*) AS n FROM log_videos '
        'WHERE log_id IN ($marks) GROUP BY log_id',
        logIds.toList(),
      ))
        r['log_id'] as String: r['n'] as int,
    };
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
      // 새 발화는 사슬의 현재 끝에서 — 직전 발화(첫 발화면 원본 줄기의
      // 최신 기록)에 건다. 이어지는 발화는 방금 만든 포크가 곧 그 끝이라
      // 캐치업 순서대로 사슬이 자란다. (v8: 방사형 → 체인형)
      final leaf = latestLeafOf(rule.sourceLogId);
      if (leaf == null) continue; // 원본과 하위 전부 삭제됨 — 발화 불가
      var parent = leaf; // 타입이 LogEntry로 확정 — 루프 안에서도 승격 유지
      var t = rule.nextFireAt;
      var fires = 0;
      // curve 사다리는 칸이 정해져 있다 — 남은 칸만큼만 몰아생성한다.
      final curveLeft = rule.kind == RepeatKind.curve
          ? RepeatRule.curveRungs - rule.fireCount
          : maxCatchUpPerSettle;
      while (!t.isAfter(now) && fires < curveLeft) {
        final id = newId();
        final fork = LogEntry(
          id: id,
          content: '',
          createdAt: t, // 예정됐던 발화 시각 — 잡아먹힌 시간의 자리에
          originalCreatedAt: t,
          parentId: parent.id,
          rootId: parent.rootId ?? parent.id,
          depth: parent.depth + 1,
          path: '${parent.path ?? parent.id}/$id',
          repeatRuleId: rule.id,
        );
        insert(fork);
        parent = fork; // 다음 발화는 이 발화에서 이어진다
        fires++;
        // curve는 칸마다 간격이 다르다 — 방금 발화한 칸의 다음 칸으로 진행.
        t = rule.kind == RepeatKind.curve
            ? RepeatRule.curveFireAfter(
                t, rule.fireCount + fires, rule.timeOfDay)
            : rule.nextFireAfter(t);
      }
      if (fires > 0) {
        // 사다리의 마지막 칸(1개월)까지 발화했으면 규칙은 스스로 끝난다 —
        // 사용자가 Stop을 누른 것과 같은 기록(active=0)을 남긴다.
        if (rule.kind == RepeatKind.curve &&
            rule.fireCount + fires >= RepeatRule.curveRungs) {
          _db.execute(
            'UPDATE repeat_rules SET active = 0, stopped_at = ?, '
            'fire_count = fire_count + ? WHERE id = ?',
            [nowMs, fires, rule.id],
          );
        } else {
          _db.execute(
            'UPDATE repeat_rules SET next_fire_at = ?, '
            'fire_count = fire_count + ? WHERE id = ?',
            [t.millisecondsSinceEpoch, fires, rule.id],
          );
        }
        created += fires;
      }
    }
    return created;
  }

  /// 사슬이 지금 끝나는 지점 — [logId]와 그 모든 하위 포크 중 가장 최근 것.
  /// 루프 부착의 기본값으로 쓴다: "현재 보인 로그"가 아니라 그 생각의
  /// 줄기가 지금까지 온 끝. (v8 — 루프는 사슬의 끝에서 이어진다)
  ///
  /// 하위 찾기는 materialized path의 전방 일치 — 중간 로그의 하위는
  /// 그 path가 '원본/…/이 로그/…'로 시작하므로 로그 자신의 path 접두사로.
  LogEntry? latestLeafOf(String logId) {
    final log = byId(logId);
    if (log == null) return null;
    final prefix = log.path ?? log.id; // 원본이면 path 대신 자기 id
    final rows = _db.select(
      'SELECT * FROM logs WHERE id = ? OR path LIKE ? '
      'ORDER BY created_at DESC, id DESC LIMIT 1',
      [logId, '$prefix/%'],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  // ── 통계 (docs/growth-ideas.md "기록 흐름 통계") ─────────────

  /// 쓴 기록(내용이 있는 로그)의 created_at 전체. 통계 화면이 날짜 버킷·
  /// 스트릭을 기기 시간대로 계산한다 — SQL 날짜 함수는 UTC라 쓰지 않는다.
  /// 통계는 열 때 한 번만 도는 전체 스캔이라 윈도우 최적화 대상이 아니다.
  List<int> writtenLogTimestamps() => [
    for (final r in _db.select(
      "SELECT created_at FROM logs WHERE TRIM(content) != ''",
    ))
      r['created_at'] as int,
  ];

  /// 생각이 다시 돌아온 총 횟수 — 단발 루프 복습 + 반복 규칙 발화.
  /// 포크는 카운트를 이어받아 태어나므로 체인(COALESCE(root_id, id))별
  /// loop_count의 최댓값이 그 사슬에서 돌아온 횟수다. 반복은 fire_count 합.
  int loopReturnCount() {
    final oneShot =
        _db
                .select(
                  'SELECT COALESCE(SUM(m), 0) AS n FROM '
                  '(SELECT MAX(loop_count) AS m FROM logs GROUP BY COALESCE(root_id, id))',
                )
                .first['n']
            as int;
    final repeats =
        _db
                .select(
                  'SELECT COALESCE(SUM(fire_count), 0) AS n FROM repeat_rules',
                )
                .first['n']
            as int;
    return oneShot + repeats;
  }

  /// 가장 많이 이어진 사슬 상위 — 체인(원본+포크 전체) 크기 순.
  /// logId는 사슬에서 가장 살아있는 윗쪽 로그(원본이 지워졌으면 최선발
  /// 포크)로, 루프 보기 진입의 앵커로 쓴다.
  List<({String chainId, int count, String logId})> topChains({int limit = 3}) {
    final rows = _db.select(
      'SELECT COALESCE(root_id, id) AS chain, COUNT(*) AS n FROM logs '
      'GROUP BY chain HAVING n >= 2 ORDER BY n DESC, chain LIMIT ?',
      [limit],
    );
    return [
      for (final r in rows)
        (
          chainId: r['chain'] as String,
          count: r['n'] as int,
          logId: _chainHead(r['chain'] as String),
        ),
    ];
  }

  /// 사슬의 머리 로그 id — 원본이 살아있으면 원본, 아니면 가장 얕은 포크.
  String _chainHead(String chainId) =>
      _db.select(
            'SELECT id FROM logs WHERE (id = ? OR root_id = ?) '
            'ORDER BY depth ASC, created_at ASC, id ASC LIMIT 1',
            [chainId, chainId],
          ).first['id']
          as String;

  /// 그날(로컬 자정~자정)의 로그 전부, 시간 순서 — '그때의 나' 후보 수집용.
  /// 날짜 경계는 기기 시간대 기준(시간 저장 원칙) — SQL 날짜 함수(UTC)를
  /// 쓰지 않고 Dart에서 경계를 계산해 ms로 비교한다.
  List<LogEntry> logsOnDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final rows = _db.select(
      'SELECT * FROM logs '
      'WHERE created_at >= ? AND created_at < ? '
      'ORDER BY created_at, id',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [for (final r in rows) _fromRow(r)];
  }

  // ── 내보내기 (.looplog = JSONL) ──────────────────────────────
  // 한 줄 = 데이터 하나. 종류: looplog(헤더) / log / image / repeat.
  // 무손실이라 나중에 가져오기(복원)도 같은 포맷으로 가능하다.
  /// 전체 데이터를 한 줄씩 흘려준다. 이미지 base64가 아무리 커도
  /// 한 번에 한 줄만 메모에 올라간다 — 저장소로 스트리밍하기 위한 설계.
  /// [videoLoader]를 주면 동영상 파일도 base64로 인라인(무손실 유지) —
  /// 파일이 없거나 loader가 null이면 메타만 나가고, 가져오기 쪽은
  /// 파일 없는 동영상을 조용히 건너뛴다(상세에서도 숨김).
  Iterable<String> exportLines({
    String? Function(String fileName)? videoLoader,
    String? Function(String fileName)? imageLoader,
  }) sync* {
    yield jsonEncode({
      'type': 'looplog',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
    });

    yield* _logAndImageLines(
      _db.select('SELECT * FROM logs ORDER BY created_at, id'),
      imageLoader: imageLoader,
    );
    for (final r in _db.select(
      'SELECT * FROM repeat_rules ORDER BY created_at, id',
    )) {
      yield jsonEncode(_repeatExportMap(_repeatFromRow(r)));
    }
    for (final v in _db.select(
      'SELECT * FROM log_videos ORDER BY log_id, position',
    )) {
      yield jsonEncode(_videoExportMap(v, videoLoader));
    }
  }

  /// 로그+그 이미지 라인들 — 전체 내보내기와 사슬 내보내기가 공유한다.
  Iterable<String> _logAndImageLines(
    List<Map<String, Object?>> rows, {
    String? Function(String fileName)? imageLoader,
    bool stripLocation = false,
    bool includeMedia = true,
  }) sync* {
    for (final r in rows) {
      final e = _fromRow(r);
      yield jsonEncode(_logExportMap(e, stripLocation: stripLocation));
      if (includeMedia) yield* _imageExportLines(e, imageLoader);
    }
  }

  /// 로그 라인 공통 직렬화. [stripLocation]은 공유용 — 장소·좌표는 빠지고
  /// 날씨는 남는다(share-design.md §1). authorId는 받은 기록에만 실린다.
  Map<String, Object?> _logExportMap(
    LogEntry e, {
    bool stripLocation = false,
  }) => {
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
    'latitude': stripLocation ? null : e.latitude,
    'longitude': stripLocation ? null : e.longitude,
    'place': stripLocation ? null : e.place,
    'weatherCode': e.weatherCode,
    'temperatureC': e.temperatureC,
    'repeatRuleId': e.repeatRuleId,
    'loopCount': e.loopCount,
    'loopAlarm': e.loopAlarm,
    if (e.authorId != null) 'authorId': e.authorId,
  };

  Iterable<String> _imageExportLines(
    LogEntry e,
    String? Function(String fileName)? imageLoader,
  ) sync* {
    for (final img in _db.select(
      'SELECT id, position, base64, file_name FROM log_images '
      'WHERE log_id = ? ORDER BY position',
      [e.id],
    )) {
      final fileName = img['file_name'] as String?;
      final legacy = img['base64'] as String?;
      // 파일 장은 loader로 인라인(무손실), 레거시 장은 그대로.
      final body = fileName != null ? imageLoader?.call(fileName) : legacy;
      yield jsonEncode({
        'type': 'image',
        'id': img['id'],
        'logId': e.id,
        'position': img['position'],
        'base64': body,
      });
    }
  }

  Map<String, Object?> _repeatExportMap(RepeatRule rule) => {
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
  };

  Map<String, Object?> _videoExportMap(
    Map<String, Object?> v,
    String? Function(String fileName)? videoLoader,
  ) {
    final fileName = v['file_name'] as String;
    return {
      'type': 'video',
      'id': v['id'],
      'logId': v['log_id'],
      'position': v['position'],
      'fileName': fileName,
      'size': v['size'],
      // 파일이 살아있을 때만 본문이 인라인된다 — 무손실 유지.
      'base64': videoLoader?.call(fileName),
    };
  }

  /// 사슬 스코프 내보내기 — 공유 페이로드. (docs/share-design.md §4)
  /// 헤더 participants의 첫 번째가 보낸 사람이다. 규칙은 원본 active 상태
  /// 그대로 실리고 받는 쪽 정책이 강제한다(비이어받기 → 무조건 정지 상태).
  /// [stripLocation](기본)일 때 장소·좌표만 비우고 날씨는 남는다.
  /// [includeMedia]가 false면 이미지·동영상 라인 자체를 싣지 않는다 —
  /// 메타만 보내 유령 흔적을 남기지 않으려는 것.
  Iterable<String> exportChainLines({
    required String rootId,
    required List<ChainParticipant> participants,
    bool stripLocation = true,
    bool includeMedia = true,
    String? Function(String fileName)? videoLoader,
    String? Function(String fileName)? imageLoader,
  }) sync* {
    yield jsonEncode({
      'type': 'looplog',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'participants': [
        for (final p in participants) {'id': p.id, 'name': p.name},
      ],
    });

    final rows = _db.select(
      'SELECT * FROM logs WHERE id = ? OR path LIKE ? ORDER BY created_at, id',
      [rootId, '$rootId/%'],
    );
    final ids = {for (final r in rows) r['id'] as String};
    yield* _logAndImageLines(
      rows,
      imageLoader: imageLoader,
      stripLocation: stripLocation,
      includeMedia: includeMedia,
    );
    for (final r in _db.select(
      'SELECT * FROM repeat_rules ORDER BY created_at, id',
    )) {
      if (!ids.contains(r['source_log_id'])) continue;
      yield jsonEncode(_repeatExportMap(_repeatFromRow(r)));
    }
    if (includeMedia) {
      for (final v in _db.select(
        'SELECT * FROM log_videos ORDER BY log_id, position',
      )) {
        if (!ids.contains(v['log_id'])) continue;
        yield jsonEncode(_videoExportMap(v, videoLoader));
      }
    }
  }

  /// 공유 페이로드 가져오기 — 출처 추적 버전. (docs/share-design.md §3·§4)
  /// participants를 peers에 등록하고, author 미지정 로그는 보낸 사람으로
  /// 스탬프한다. 규칙 정책([ruleForReceive]): 살아있던 규칙은 이어받기가
  /// 아니면 무조건 정지 상태로 들어온다 — catch-up 홍수 방지. 이어받기면
  /// 주기를 물려받아 next_fire_at을 지금부터 재계산한다.
  Future<ChainImportResult> importSharedChainLines(
    Stream<String> lines, {
    required String via,
    bool adoptLoop = false,
    void Function(String fileName, Uint8List bytes)? videoWriter,
  }) async {
    final it = StreamIterator(lines);
    if (!await it.moveNext()) throw const FormatException('빈 파일');
    final header = jsonDecode(it.current) as Map<String, Object?>;
    if (header['type'] != 'looplog') {
      throw const FormatException('.looplog 형식이 아님');
    }
    final rawParticipants = header['participants'] as List<Object?>?;
    if (rawParticipants == null || rawParticipants.isEmpty) {
      throw const FormatException('공유 페이로드가 아님 — participants 없음');
    }
    final participants = [
      for (final p in rawParticipants)
        ChainParticipant(
          id: (p as Map)['id'] as String,
          name: p['name'] as String,
        ),
    ];
    final sender = participants.first;
    final now = DateTime.now();
    for (final p in participants) {
      upsertPeer(p.id, p.name);
    }

    var logs = 0;
    var images = 0;
    var repeats = 0;
    var videos = 0;
    String? rootId;
    _db.execute('BEGIN');
    try {
      do {
        final row = jsonDecode(it.current) as Map<String, Object?>;
        switch (row['type'] as String?) {
          case 'log':
            final id = row['id'] as String;
            final e = _logFromExport(
              row,
              authorId: (row['authorId'] as String?) ?? sender.id,
            );
            if (rootId == null && e.rootId == null) rootId = id;
            if (_logExists(id)) continue;
            insert(e);
            logs++;
          case 'image':
            final id = row['id'] as String;
            if (_imageExists(id)) continue;
            final body = row['base64'] as String?;
            String? fileName;
            if (body != null && imageStore != null) {
              fileName = imageStore!.save(id, base64Decode(body));
            }
            _db.execute(
              'INSERT INTO log_images (id, log_id, position, base64, file_name) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                id,
                row['logId'],
                row['position'],
                fileName == null ? body : null,
                fileName,
              ],
            );
            images++;
          case 'repeat':
            final id = row['id'] as String;
            if (_repeatExists(id)) continue;
            final rule = _repeatFromExport(row);
            insertRepeatRule(
              ruleForReceive(rule, adopt: adoptLoop, receivedAt: now),
            );
            repeats++;
          case 'video':
            final id = row['id'] as String;
            if (_videoExists(id)) continue;
            final fileName = row['fileName'] as String;
            final base64Body = row['base64'] as String?;
            if (base64Body != null) {
              videoWriter?.call(fileName, base64Decode(base64Body));
            }
            _db.execute(
              'INSERT INTO log_videos (id, log_id, position, file_name, size) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                id,
                row['logId'],
                row['position'],
                fileName,
                (row['size'] as num?)?.toInt() ?? 0,
              ],
            );
            videos++;
        }
      } while (await it.moveNext());
      // 수신 기록 — 사슬당 첫 출처만 남긴다 (PRIMARY KEY + IGNORE).
      if (rootId != null) {
        _db.execute(
          'INSERT OR IGNORE INTO chain_shares(root_id, peer_id, received_at, via) '
          'VALUES (?, ?, ?, ?)',
          [rootId, sender.id, now.millisecondsSinceEpoch, via],
        );
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      it.cancel();
    }
    return ChainImportResult(
      logs: logs,
      images: images,
      videos: videos,
      repeats: repeats,
      rootId: rootId,
      senderId: sender.id,
    );
  }

  /// 받는 쪽 규칙 정책 — 유일한 강제 지점. (share-design.md §1)
  /// 살아있던 규칙: 이어받기면 주기를 물려받고 next_fire_at을 [receivedAt]
  /// 부터 재계산(발화 이력·fire_count는 그대로), 아니면 정지 상태로.
  /// 애초에 정지였던 규칙은 이어받기를 골라도 정지로 남는다.
  static RepeatRule ruleForReceive(
    RepeatRule rule, {
    required bool adopt,
    required DateTime receivedAt,
  }) {
    if (!rule.active) return rule;
    if (!adopt) {
      return RepeatRule(
        id: rule.id,
        sourceLogId: rule.sourceLogId,
        kind: rule.kind,
        everyN: rule.everyN,
        timeOfDay: rule.timeOfDay,
        nextFireAt: rule.nextFireAt,
        fireCount: rule.fireCount,
        active: false,
        createdAt: rule.createdAt,
        stoppedAt: receivedAt,
      );
    }
    return RepeatRule(
      id: rule.id,
      sourceLogId: rule.sourceLogId,
      kind: rule.kind,
      everyN: rule.everyN,
      timeOfDay: rule.timeOfDay,
      nextFireAt: RepeatRule.firstFireOf(
        rule.kind,
        everyN: rule.everyN,
        timeOfDay: rule.timeOfDay,
        now: receivedAt,
      ),
      fireCount: rule.fireCount,
      active: true,
      createdAt: rule.createdAt,
    );
  }

  /// .looplog(JSONL) 한 줄씩 가져오기 — [exportLines]의 역.
  ///
  /// ID가 전 세계적으로 유니크(시각+무작위)하므로 머지는 "같은 id면 건너뛴다"
  /// 한 가지 규칙으로 끝난다. 다른 기기 데이터를 더할 수도, 같은 백업을
  /// 두 번 가져와도 중복이 생기지 않는다. 살아있는 반복 규칙의 next_fire_at이
  /// 과거면 이후 settleRepeats가 몰아 생성한다 — 기존 동작과 같다.
  /// [videoWriter]를 주면 video 라인의 base64를 파일로 복원한다 — 파일
  /// 없이 메타만 온 동영상은 기록으로 남기되 본문은 건너뛴다.
  Future<ImportStats> importLines(
    Stream<String> lines, {
    void Function(String fileName, Uint8List bytes)? videoWriter,
  }) async {
    final it = StreamIterator(lines);
    if (!await it.moveNext()) throw const FormatException('빈 파일');
    final header = jsonDecode(it.current) as Map<String, Object?>;
    if (header['type'] != 'looplog') {
      throw const FormatException('.looplog 형식이 아님');
    }

    var logs = 0;
    var images = 0;
    var repeats = 0;
    var videos = 0;
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
            final body = row['base64'] as String?;
            String? fileName;
            if (body != null) {
              // 파일 저장소가 있으면 파일로 복원, 없으면 레거시 base64 인라인.
              if (imageStore != null) {
                fileName = imageStore!.save(id, base64Decode(body));
              }
            }
            _db.execute(
              'INSERT INTO log_images (id, log_id, position, base64, file_name) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                id,
                row['logId'],
                row['position'],
                fileName == null ? body : null,
                fileName,
              ],
            );
            images++;
          case 'repeat':
            final id = row['id'] as String;
            if (_repeatExists(id)) continue;
            insertRepeatRule(_repeatFromExport(row));
            repeats++;
          case 'video':
            final id = row['id'] as String;
            if (_videoExists(id)) continue;
            final fileName = row['fileName'] as String;
            final base64Body = row['base64'] as String?;
            if (base64Body != null) {
              videoWriter?.call(fileName, base64Decode(base64Body));
            }
            _db.execute(
              'INSERT INTO log_videos (id, log_id, position, file_name, size) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                id,
                row['logId'],
                row['position'],
                fileName,
                (row['size'] as num?)?.toInt() ?? 0,
              ],
            );
            videos++;
        }
      } while (await it.moveNext());
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      it.cancel();
    }
    return ImportStats(
      logs: logs,
      images: images,
      repeats: repeats,
      videos: videos,
    );
  }

  bool _videoExists(String id) =>
      _db.select('SELECT 1 FROM log_videos WHERE id = ?', [id]).isNotEmpty;

  bool _logExists(String id) =>
      _db.select('SELECT 1 FROM logs WHERE id = ?', [id]).isNotEmpty;

  bool _imageExists(String id) =>
      _db.select('SELECT 1 FROM log_images WHERE id = ?', [id]).isNotEmpty;

  bool _repeatExists(String id) =>
      _db.select('SELECT 1 FROM repeat_rules WHERE id = ?', [id]).isNotEmpty;

  /// 내보낸 필드 이름 그대로 — loopCount처럼 뒤에 추가된 필드가 없는
  /// 옛 백업도 기본값으로 받는다. [authorId]를 주면 라인의 값보다 우선
  /// (공유 임포트의 보낸 사람 스탬프).
  LogEntry _logFromExport(Map<String, Object?> r, {String? authorId}) => LogEntry(
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
    authorId: authorId ?? r['authorId'] as String?,
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
    this.videos = 0,
  });

  final int logs;
  final int images;
  final int repeats;
  final int videos;

  bool get isEmpty => logs == 0 && images == 0 && repeats == 0 && videos == 0;
}

/// 로그에 달린 동영상 메타 — 본문 파일은 VideoStore가 관리한다. (v9)
class LogVideoRec {
  const LogVideoRec({
    required this.id,
    required this.logId,
    required this.fileName,
    required this.size,
  });

  final String id;
  final String logId;
  final String fileName;
  final int size;
}

/// 공유 페이로드 헤더의 참여자 — 보낸 사람이 첫 번째. (share-design.md §4)
class ChainParticipant {
  const ChainParticipant({required this.id, required this.name});

  final String id;
  final String name;
}

/// 공유 사슬 임포트 결과 — 새로 들어온 것만 센다(같은 id는 건너뜀).
class ChainImportResult {
  const ChainImportResult({
    required this.logs,
    required this.images,
    required this.repeats,
    required this.videos,
    required this.rootId,
    required this.senderId,
  });

  final int logs;
  final int images;
  final int repeats;
  final int videos;

  /// 사슬 원본 id — 완료 화면의 "사슬 보기" 진입에 쓴다.
  final String? rootId;

  /// 직접 보낸 사람 (peers에 등록됨).
  final String senderId;

  bool get isEmpty => logs == 0 && images == 0 && repeats == 0 && videos == 0;
}
