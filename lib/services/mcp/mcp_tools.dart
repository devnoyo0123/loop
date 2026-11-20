import '../../data/loop_db.dart';
import '../../models/log_entry.dart';
import '../../models/repeat_rule.dart';
import '../../utils/upcoming.dart';
import '../weather_service.dart';

/// MCP 읽기 전용 도구 5개 — 스키마·입력 검증·실행·텍스트 포맷.
/// (docs/mcp-design.md §9)
///
/// [definitions]는 폰이 브리지에 hello로 그대로 알린다 — 도구를 여기에 더하면
/// 앱 업데이트만으로 Claude에 노출된다(브리지 1.3+). 2026-11-18 사용자 결정.
///
/// 출력은 LLM이 읽는 텍스트라 앱 언어와 무관하게 영어 라벨을 쓴다.
/// 위치(장소명 + 위도·경도 좌표)는 설정 `mcp_include_place`가 '0'이 아닐 때만
/// (기본 포함) 붙인다. 좌표는 2026-11-16 사용자 결정으로 추가 — 이전엔 항상 제외.
class McpTools {
  McpTools(this.db);

  final LoopDb db;

  /// 위치(장소명·좌표) 포함 설정 키 — '1'(기본) | '0'. (§10)
  static const keyIncludePlace = 'mcp_include_place';

  /// 응답 텍스트 총 길이 상한 (§9.3).
  static const maxChars = 20000;
  static const truncatedLine =
      '…truncated — narrow the date range or lower limit';

  static const _maxQueryChars = 200;
  static const _defaultLimit = 20;
  static const _maxLimit = 50;
  static const _maxDayLogs = 50;
  static const _defaultUpcomingDays = 7;
  static const _maxUpcomingDays = 31;

  static const _dateSchema = {
    'type': 'string',
    'pattern': r'^\d{4}-\d{2}-\d{2}$',
  };

  /// `tools/list` 응답의 도구 정의 (JSON Schema).
  List<Map<String, Object?>> get definitions => [
    {
      'name': 'search_logs',
      'description':
          'Full-text search over the journal (content and place). Returns '
          'matching logs with a snippet; matches are wrapped in **. Use '
          'get_log or get_chain with an id for the full text.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'minLength': 1,
            'maxLength': _maxQueryChars,
            'description': 'Text to find. 3+ characters use the index.',
          },
          'limit': {
            'type': 'integer',
            'minimum': 1,
            'maximum': _maxLimit,
            'default': _defaultLimit,
          },
          'from': {
            ..._dateSchema,
            'description': 'Start date YYYY-MM-DD (inclusive, local time).',
          },
          'to': {
            ..._dateSchema,
            'description': 'End date YYYY-MM-DD (inclusive, local time).',
          },
          'order': {
            'type': 'string',
            'enum': ['recent', 'relevance'],
            'default': 'recent',
          },
        },
        'required': ['query'],
        'additionalProperties': false,
      },
    },
    {
      'name': 'get_log',
      'description': 'One log in full, with metadata.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'minLength': 1},
        },
        'required': ['id'],
        'additionalProperties': false,
      },
    },
    {
      'name': 'get_chain',
      'description':
          'The whole chain (original log and all follow-ups) containing the '
          'given log id, oldest first.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'minLength': 1,
            'description': 'Any log id in the chain.',
          },
        },
        'required': ['id'],
        'additionalProperties': false,
      },
    },
    {
      'name': 'logs_on_day',
      'description':
          'All logs written on one day (local time), oldest first, up to '
          '$_maxDayLogs.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'date': {..._dateSchema, 'description': 'YYYY-MM-DD'},
        },
        'required': ['date'],
        'additionalProperties': false,
      },
    },
    {
      'name': 'upcoming_loops',
      'description':
          'Loops and repeat reminders (반복 알림) that will come back in the '
          'next N days, soonest first — the same list as the app\'s Upcoming '
          'sheet. Each entry: when, alarm or notification, once or the repeat '
          'rule, and the log it brings back (get_log/get_chain with the id). '
          'Use this for "what is coming up", birthdays, reminders.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'integer',
            'minimum': 1,
            'maximum': _maxUpcomingDays,
            'default': _defaultUpcomingDays,
            'description': 'How many days ahead to look.',
          },
        },
        'additionalProperties': false,
      },
    },
  ];

  /// `tools/call` 실행. 입력 오류·없는 id도 예외가 아니라 `isError: true`
  /// 결과로 돌려준다 — LLM이 읽고 고쳐 다시 부르도록. (§9.1)
  Map<String, Object?> call(String name, Map<String, Object?> args) {
    try {
      final text = switch (name) {
        'search_logs' => _searchLogs(args),
        'get_log' => _getLog(args),
        'get_chain' => _getChain(args),
        'logs_on_day' => _logsOnDay(args),
        'upcoming_loops' => _upcomingLoops(args),
        _ => throw _InputError('Unknown tool: $name'),
      };
      return textResult(text);
    } on _InputError catch (e) {
      return errorResult(e.message);
    }
  }

  static Map<String, Object?> textResult(String text) => {
    'content': [
      {'type': 'text', 'text': truncate(text)},
    ],
    'isError': false,
  };

  static Map<String, Object?> errorResult(String message) => {
    'content': [
      {'type': 'text', 'text': message},
    ],
    'isError': true,
  };

  /// 20,000자 상한 — 넘으면 그 지점에서 자르고 마지막 줄에 안내를 붙인다.
  /// 안내 줄까지 포함해 [maxChars]를 넘지 않는다.
  static String truncate(String text) {
    if (text.length <= maxChars) return text;
    var cut = maxChars - truncatedLine.length - 1;
    // 서로게이트 쌍(이모지 등) 한가운데서 자르지 않는다.
    final unit = text.codeUnitAt(cut - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) cut--;
    return '${text.substring(0, cut)}\n$truncatedLine';
  }

  // ── 도구 ──────────────────────────────────────────────────────

  String _searchLogs(Map<String, Object?> args) {
    _rejectUnknown(args, const {'query', 'limit', 'from', 'to', 'order'});
    final rawQuery = args['query'];
    if (rawQuery is! String) {
      throw _InputError('"query" is required and must be a string.');
    }
    final query = rawQuery.trim();
    final qLen = query.runes.length;
    if (qLen < 1 || qLen > _maxQueryChars) {
      throw _InputError('"query" must be 1-$_maxQueryChars characters.');
    }
    final limit = _intArg(args, 'limit', _defaultLimit, 1, _maxLimit);
    final from = _dateArg(args, 'from');
    final to = _dateArg(args, 'to');
    if (from != null && to != null && from.isAfter(to)) {
      throw _InputError('"from" must not be after "to".');
    }
    final order = args['order'] ?? 'recent';
    if (order != 'recent' && order != 'relevance') {
      throw _InputError('"order" must be "recent" or "relevance".');
    }

    final hits = db.searchDetailed(
      query,
      limit: limit,
      byRelevance: order == 'relevance',
      from: from,
      to: to,
    );
    final range = [
      if (from != null) 'from ${_ymd(from)}',
      if (to != null) 'to ${_ymd(to)}',
    ].join(' ');
    if (hits.isEmpty) {
      return 'No logs matched "$query"${range.isEmpty ? '' : ' ($range)'}.';
    }
    final ctx = _FormatContext(this, [for (final h in hits) h.log]);
    final buf = StringBuffer(
      '${hits.length} log${hits.length == 1 ? '' : 's'} matched "$query"'
      '${range.isEmpty ? '' : ' ($range)'}, '
      '${order == 'relevance' ? 'most relevant' : 'newest'} first.\n',
    );
    for (final h in hits) {
      buf
        ..write('\n')
        ..write(ctx.format(h.log, body: _snippet(h.snippet, h.log.content)))
        ..write('\n');
    }
    return buf.toString().trimRight();
  }

  String _getLog(Map<String, Object?> args) {
    _rejectUnknown(args, const {'id'});
    final id = _idArg(args);
    final log = db.byId(id);
    if (log == null) throw _InputError('No log with id "$id".');
    return _FormatContext(this, [log]).format(log, body: log.content);
  }

  String _getChain(Map<String, Object?> args) {
    _rejectUnknown(args, const {'id'});
    final id = _idArg(args);
    final logs = db.chainLogs(id);
    if (logs.isEmpty) throw _InputError('No log with id "$id".');
    final root = logs.first.rootId ?? logs.first.id;
    final ctx = _FormatContext(this, logs);
    final buf = StringBuffer(
      'Chain $root · ${logs.length} log${logs.length == 1 ? '' : 's'}'
      '${ctx.received(root) ? ' (received chain)' : ''}, oldest first.\n',
    );
    for (final log in logs) {
      buf
        ..write('\n')
        ..write(ctx.format(log, body: log.content, chainLine: false))
        ..write('\n');
    }
    return buf.toString().trimRight();
  }

  String _logsOnDay(Map<String, Object?> args) {
    _rejectUnknown(args, const {'date'});
    if (args['date'] == null) {
      throw _InputError('"date" is required (YYYY-MM-DD).');
    }
    final day = _dateArg(args, 'date')!;
    final all = db.logsOnDay(day);
    final head = '${_ymd(day)} (${_weekday(day)})';
    if (all.isEmpty) return 'No logs on $head.';
    final logs = all.take(_maxDayLogs).toList();
    final ctx = _FormatContext(this, logs);
    final buf = StringBuffer(
      '$head · ${all.length} log${all.length == 1 ? '' : 's'}, oldest first.\n',
    );
    for (final log in logs) {
      buf
        ..write('\n')
        ..write(ctx.format(log, body: log.content))
        ..write('\n');
    }
    if (all.length > logs.length) {
      buf.write(
        '\n…showing the first ${logs.length} of ${all.length} logs on this '
        'day — use search_logs with from/to to narrow down.',
      );
    }
    return buf.toString().trimRight();
  }

  /// 단발 루프 + 반복 알림 회차, 시간순. 계산은 앱 시트와 같은 [upcomingFires].
  String _upcomingLoops(Map<String, Object?> args, {DateTime? now}) {
    _rejectUnknown(args, const {'days'});
    final days = _intArg(
      args,
      'days',
      _defaultUpcomingDays,
      1,
      _maxUpcomingDays,
    );
    final from = now ?? DateTime.now();
    final fires = upcomingFires(
      db,
      from: from,
      to: from.add(Duration(days: days)),
    );
    final span = 'the next $days day${days == 1 ? '' : 's'}';
    if (fires.isEmpty) return 'Nothing is coming back in $span.';
    final buf = StringBuffer(
      '${fires.length} coming back in $span (from ${_ymdHm(from)}), '
      'soonest first.\n',
    );
    for (final f in fires) {
      final when = '${_ymd(f.at)} (${_weekday(f.at)}) '
          '${_two(f.at.hour)}:${_two(f.at.minute)}';
      final how = f.rule == null
          ? 'once'
          : 'repeat ${repeatText(f.rule!)}'
              '${f.rule!.fireCount > 0 ? ' · fired ${f.rule!.fireCount}×' : ''}';
      final content = (f.log ?? db.byId(f.logId))?.content.trim() ?? '';
      buf
        ..write('\n')
        ..write('$when · ${f.alarm ? 'alarm' : 'notification'} · $how\n')
        ..write('[${f.logId}] ${content.isEmpty ? '(empty)' : _head(content, max: 80)}\n');
    }
    return buf.toString().trimRight();
  }

  /// 테스트용 — 기준 시각을 주입한다.
  String upcomingLoopsAt(DateTime now, {int? days}) =>
      _upcomingLoops({'days': ?days}, now: now);

  /// 반복 규칙 → 영어 한 줄. ("yearly 11-23 08:00", "every 10 min")
  static String repeatText(RepeatRule r) {
    final tod = r.timeOfDay ?? '';
    final parts = tod.split(' ');
    final clock = parts.last;
    final date = parts.length == 2 ? parts.first : '';
    final day = date.contains('-') ? int.tryParse(date.split('-').last) : null;
    final n = r.everyN ?? 1;
    return switch (r.kind) {
      RepeatKind.minutes => 'every $n min',
      RepeatKind.hours => 'every $n h',
      RepeatKind.daily => 'daily $clock',
      RepeatKind.weekday => 'weekdays $clock (skips weekends and holidays)',
      RepeatKind.monthly =>
        '${n == 1 ? 'monthly' : 'every $n months'} on day ${day ?? '?'} $clock',
      RepeatKind.yearly => '${n == 1 ? 'yearly' : 'every $n years'} $date $clock',
      RepeatKind.curve => 'forgetting-curve ladder',
    };
  }

  // ── 입력 검증 ────────────────────────────────────────────────

  static void _rejectUnknown(Map<String, Object?> args, Set<String> allowed) {
    final extra = args.keys.where((k) => !allowed.contains(k)).toList();
    if (extra.isNotEmpty) {
      throw _InputError(
        'Unknown argument${extra.length == 1 ? '' : 's'}: ${extra.join(', ')}. '
        'Allowed: ${allowed.join(', ')}.',
      );
    }
  }

  static String _idArg(Map<String, Object?> args) {
    final id = args['id'];
    if (id is! String || id.trim().isEmpty) {
      throw _InputError('"id" is required and must be a non-empty string.');
    }
    return id.trim();
  }

  static int _intArg(
    Map<String, Object?> args,
    String key,
    int fallback,
    int min,
    int max,
  ) {
    final v = args[key];
    if (v == null) return fallback;
    if (v is num && v == v.roundToDouble() && v >= min && v <= max) {
      return v.toInt();
    }
    throw _InputError('"$key" must be an integer between $min and $max.');
  }

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// YYYY-MM-DD → 기기 시간대 그날 0시. 없으면 null, 형식·실재 날짜 아니면 오류.
  static DateTime? _dateArg(Map<String, Object?> args, String key) {
    final v = args[key];
    if (v == null) return null;
    final m = v is String ? _datePattern.firstMatch(v) : null;
    if (m != null) {
      final y = int.parse(m[1]!);
      final mo = int.parse(m[2]!);
      final d = int.parse(m[3]!);
      final date = DateTime(y, mo, d);
      // 2026-02-30처럼 넘어가는 날짜는 거절.
      if (date.year == y && date.month == mo && date.day == d) return date;
    }
    throw _InputError('"$key" must be a valid date in YYYY-MM-DD format.');
  }

  // ── 포맷 ──────────────────────────────────────────────────────

  /// 스니펫 마커(전용영역 문자) → `**`. 스니펫이 비면 본문 앞부분.
  static String _snippet(String snippet, String content) {
    final s = snippet.isEmpty ? _head(content) : snippet;
    return s
        .replaceAll(LoopDb.snippetOpen, '**')
        .replaceAll(LoopDb.snippetClose, '**');
  }

  static String _head(String text, {int max = 120}) {
    final runes = text.runes.toList();
    if (runes.length <= max) return text;
    return '${String.fromCharCodes(runes.take(max))}…';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _ymd(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

  static String _ymdHm(DateTime t) =>
      '${_ymd(t)} ${_two(t.hour)}:${_two(t.minute)}';

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _weekday(DateTime t) => _weekdays[t.weekday - 1];

  /// WMO 코드 → 영어 짧은 설명. 앱의 [Wmo] 분류를 재사용한다.
  static String? weatherWord(int code) => switch (Wmo.describe(code).kind) {
    WmoKind.clear => 'clear',
    WmoKind.partly => 'partly cloudy',
    WmoKind.cloudy => 'cloudy',
    WmoKind.fog => 'fog',
    WmoKind.drizzle => 'drizzle',
    WmoKind.rain => 'rain',
    WmoKind.snow => 'snow',
    WmoKind.thunder => 'thunderstorm',
    WmoKind.unknown => null,
  };
}

/// 한 번의 도구 호출 동안 쓰는 메타 캐시 — 미디어 개수·사슬·수신 여부를
/// 로그마다 따로 묻지 않게 묶는다.
class _FormatContext {
  _FormatContext(this.tools, List<LogEntry> logs)
    : _media = tools.db.mediaCounts([for (final l in logs) l.id]),
      _includePlace = tools.db.getSetting(McpTools.keyIncludePlace) != '0';

  final McpTools tools;
  final Map<String, ({int images, int videos})> _media;
  final bool _includePlace;
  final _chains = <String, List<LogEntry>>{};
  final _received = <String, bool>{};

  bool received(String root) =>
      _received[root] ??= tools.db.chainShareFor(root) != null;

  List<LogEntry> _chain(LogEntry log) {
    final root = log.rootId ?? log.id;
    return _chains[root] ??= tools.db.chainLogs(root);
  }

  /// ```
  /// [id] 2026-10-31 (Sat) 21:14 · 성수동 · clear 12°C · 2 photos
  /// chain <root> · 3 of 5 (received chain) · loop scheduled 2026-11-03 09:00
  /// 본문 또는 스니펫
  /// ```
  String format(LogEntry log, {required String body, bool chainLine = true}) {
    final t = log.createdAt;
    final head = <String>[
      '[${log.id}] ${McpTools._ymd(t)} (${McpTools._weekday(t)}) '
          '${McpTools._two(t.hour)}:${McpTools._two(t.minute)}',
    ];
    if (_includePlace) {
      final place = log.place?.trim();
      final coords = log.latitude != null && log.longitude != null
          ? '${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}'
          : null;
      final hasPlace = place != null && place.isNotEmpty;
      if (hasPlace && coords != null) {
        head.add('$place ($coords)');
      } else if (hasPlace) {
        head.add(place);
      } else if (coords != null) {
        head.add(coords);
      }
    }
    final weather = [
      if (log.weatherCode != null) McpTools.weatherWord(log.weatherCode!),
      if (log.temperatureC != null) '${log.temperatureC!.round()}°C',
    ].whereType<String>().join(' ');
    if (weather.isNotEmpty) head.add(weather);
    final media = _media[log.id];
    if (media != null && media.images > 0) {
      head.add('${media.images} photo${media.images == 1 ? '' : 's'}');
    }
    if (media != null && media.videos > 0) {
      head.add('${media.videos} video${media.videos == 1 ? '' : 's'}');
    }

    final meta = <String>[];
    if (chainLine) {
      final chain = _chain(log);
      final root = log.rootId ?? log.id;
      final isReceived = received(root);
      if (chain.length > 1 || isReceived) {
        final pos = chain.indexWhere((l) => l.id == log.id) + 1;
        meta.add(
          'chain $root'
          '${chain.length > 1 && pos > 0 ? ' · $pos of ${chain.length}' : ''}'
          '${isReceived ? ' (received chain)' : ''}',
        );
      }
    }
    if (log.loopAt != null) {
      meta.add(
        'loop ${log.loopDone ? 'done' : 'scheduled'} '
        '${McpTools._ymdHm(log.loopAt!)} '
        '(${log.loopAlarm ? 'alarm' : 'notification'})',
      );
    }
    // 반복 알림은 로그가 아니라 repeat_rules에 있다 — 원본 로그에 붙여 보여준다.
    final rule = tools.db.activeRepeatForSource(log.id);
    if (rule != null) {
      meta.add(
        'repeat ${McpTools.repeatText(rule)} · next '
        '${McpTools._ymdHm(rule.nextFireAt)} (notification)',
      );
    }

    return [
      head.join(' · '),
      if (meta.isNotEmpty) meta.join(' · '),
      body,
    ].join('\n');
  }
}

class _InputError implements Exception {
  _InputError(this.message);
  final String message;
}
