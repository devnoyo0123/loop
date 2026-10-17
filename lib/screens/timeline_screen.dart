import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
import '../services/browser_service.dart';
import '../services/location_service.dart';
import '../services/loop_notifications.dart';
import '../services/weather_service.dart';
import '../widgets/log_card.dart';
import 'compose_sheet.dart';
import 'loop_sheet.dart';
import 'search_screen.dart';
import 'settings_sheet.dart';
import 'upcoming_sheet.dart';

/// 타임라인 단일 화면 — 최신이 맨 위, 아래로 갈수록 과거.
/// 포크 로그는 시각 위치에 그대로 섞여 들어온다. (docs/ui-design.md)
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.db});

  final LoopDb db;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with WidgetsBindingObserver {
  static const _pageSize = 100;

  final _scroll = ScrollController();
  final _parents = <String, LogEntry>{};
  final _imageSummaries = <String, LogImageSummary>{};

  /// 살아있는 반복(루프) 규칙 — id 기준 / 원본 로그 id 기준.
  final _rulesById = <String, RepeatRule>{};
  final _rulesBySource = <String, RepeatRule>{};
  List<LogEntry> _logs = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _exhausted = false;

  /// 날짜 이동 중이면 선택한 '날' (자정). null = 최신 화면.
  DateTime? _jumpAt;

  /// 포그라운드 동안 1분마다 루프 발화를 정산 — 앱을 켜둔 채로 있어도
  /// 다음 발화가 제자리에 생긴다. (기존엔 시작할 때만이라 놓쳤던 문제)
  Timer? _settleTimer;

  /// 루프 보기 중이면 그 로그 id — 타임라인 대신 최상위 원본부터의
  /// 사슬(원본 → 루프 → 루프의 루프 → … → 이 로그)만 보여준다.
  String? _lineageId;

  /// 단발 루프 + 반복 규칙 발화를 한 번에 정산. 새로 생긴 게 있으면 갱신.
  void _settle() {
    final created = widget.db.settleExpiredLoops() + widget.db.settleRepeats();
    if (created > 0) _reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 알림의 `확인` 액션 → 발화 소화(빈 포크 포함) + 화면 갱신.
    // (반복 알림은 payload가 규칙 id라 여기선 아무것도 안 걸린다 — 포크는
    //  settleRepeats가 이미 만들었으니)
    LoopNotifications.onConfirmLog = (logId) {
      if (widget.db.settleExpiredLoops() > 0) _reload();
    };
    // 알림 본문 탭 → 그 로그가 있는 날로 이동.
    LoopNotifications.onOpenLog = _openFromNotification;
    // 콜드스타트 — 알림 탭으로 실행됐다면 첫 로드 전에 날짜를 잡아둔다.
    final pending = LoopNotifications.pendingOpenLog;
    if (pending != null) _openFromNotification(pending);
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    _loadBrowserPref();
    _reload();
    _settleTimer = Timer.periodic(const Duration(minutes: 1), (_) => _settle());
  }

  /// 다른 앱을 갔다가 돌아오면 — 그사이 발화한 루프를 몰아 생성.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _settle();
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  /// 시작 설정 반영 — 기본 브라우저 + 위치 자동 캡처 스위치 상태.
  Future<void> _loadBrowserPref() async {
    final v = widget.db.getSetting(SettingsSheet.browserPrefKey);
    BrowserService.preferredPackage = (v == null || v.isEmpty) ? null : v;
    LocationService.enabled =
        widget.db.getSetting(SettingsSheet.locationCaptureKey) != '0';
  }

  void _reload() {
    widget.db.settleExpiredLoops();
    widget.db.settleRepeats(); // 놓친 반복 발화를 발화 시각대로 몰아 생성
    _syncRepeatNotifications();
    _syncOneShotNotifications();
    // 루프 보기 중엔 사슬만 — 페이지 나눔·날짜 이동과는 무관하게 전체 사슬.
    final logs = _lineageId != null
        ? widget.db.lineage(_lineageId!)
        : widget.db.window(
            until: _jumpAt?.add(const Duration(days: 1)),
            limit: _pageSize,
          );
    _cacheParents(logs);
    _cacheRules();
    setState(() {
      _logs = logs;
      _imageSummaries
        ..clear()
        ..addAll(widget.db.imageSummariesFor(logs.map((l) => l.id).toSet()));
      _loading = false;
      _exhausted = _lineageId != null || logs.length < _pageSize; // 사슬은 페이지 없음
    });
  }

  void _cacheRules() {
    _rulesById.clear();
    _rulesBySource.clear();
    for (final r in widget.db.activeRepeatRules()) {
      _rulesById[r.id] = r;
      _rulesBySource[r.sourceLogId] = r;
    }
  }

  /// 살아있는 규칙의 다가오는 발화 알림을 다시 맞춘다.
  /// settle 직후/규칙 변경 직후에 호출 — 실패해도 로직에는 지장 없다.
  /// initState에서도 도니 context 대신 시스템 locale을 조회한다.
  void _syncRepeatNotifications() {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    for (final rule in widget.db.activeRepeatRules()) {
      final content = widget.db.byId(rule.sourceLogId)?.content.trim() ?? '';
      unawaited(
        LoopNotifications.scheduleRepeatFires(
          ruleId: rule.id,
          preview: content.isEmpty ? l10n.notifFallbackBody : content,
          firstAt: rule.nextFireAt,
          nextAfter: rule.nextFireAfter,
        ),
      );
    }
  }

  /// 미래의 단발 루프 알람을 다시 건다 — 재부팅·자동 백업 복원(새 설치)에선
  /// 예약됐던 OS 알람이 증발했을 수 있다. 반복은 위에서 매번 다시 걸리지만
  /// 단발은 여기서 책임진다. 같은 로그는 같은 알람 id라 덮어쓰기라 안전.
  void _syncOneShotNotifications() {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    for (final log in widget.db.pendingOneShotLoops()) {
      unawaited(
        LoopNotifications.scheduleLoop(
          logId: log.id,
          body: log.content.trim().isEmpty
              ? l10n.notifFallbackBody
              : log.content,
          at: log.loopAt!,
          alarm: log.loopAlarm,
          dbDir: widget.db.directory.path,
        ),
      );
    }
  }

  Future<void> _stopRepeat(RepeatRule rule) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.stopRepeatTitle),
        content: Text(
          l10n.stopRepeatMessage(rule.label(l10n)),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.stop),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await LoopNotifications.cancelRepeat(rule.id);
    widget.db.stopRepeat(rule.id);
    _reload();
  }

  /// 날짜 이동 — 그날의 마지막 로그가 맨 위에 오는 윈도우로 다시 읽는다.
  Future<void> _pickJumpDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _jumpAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    setState(() => _jumpAt = DateTime(date.year, date.month, date.day));
    _reload();
  }

  /// 최신 화면으로 복귀.
  void _exitJump() {
    setState(() => _jumpAt = null);
    _reload();
  }

  /// 루프 보기 종료 — 전체 타임라인으로 복귀.
  void _exitLineage() {
    setState(() => _lineageId = null);
    _reload();
  }

  /// 루프 보기 진입 — 이 로그의 사슬(최상위 원본 → … → 이 로그)만 본다.
  void _enterLineage(LogEntry log) {
    setState(() {
      _lineageId = log.id;
      _jumpAt = null; // 사슬은 날짜 필터와 함께 쓰지 않는다
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _reload();
  }

  /// 알림 탭 — 그 로그가 있는 '날'로 이동 (검색 점프와 같은 패턴).
  /// 이미 삭제된 루프면 조용히 무시.
  void _openFromNotification(String logId) {
    LoopNotifications.pendingOpenLog = null;
    final log = widget.db.byId(logId);
    if (log == null) return;
    _jumpToDayOf(log);
  }

  /// [log]가 있는 '날'로 타임라인을 이동 — 알림·검색·미리보기 점프의 공통 패턴.
  void _jumpToDayOf(LogEntry log) {
    setState(() {
      _jumpAt = DateTime(
        log.createdAt.year,
        log.createdAt.month,
        log.createdAt.day,
      );
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _reload();
  }

  /// 검색 — 결과를 고르면 그 로그가 있는 날로 타임라인을 이동한다.
  /// (검색은 찾는 도구, 타임라인이 작업대 — 전체 액션은 거기서)
  Future<void> _search() async {
    final hit = await SearchScreen.show(context, db: widget.db);
    if (hit == null || !mounted) return;
    _jumpToDayOf(hit);
  }

  /// 다가오는 루프 미리보기 — 이번 주에 올 루프를 한 장에 보고,
  /// 항목을 고르면 그 원본 로그가 있는 날로 이동한다.
  Future<void> _showUpcoming() async {
    final logId = await UpcomingSheet.show(context, db: widget.db);
    if (logId == null || !mounted) return;
    final log = widget.db.byId(logId);
    if (log == null) return;
    _jumpToDayOf(log);
  }

  /// keyset 페이징 — 마지막 로그를 앵커로 그 다음 100개.
  void _loadMore() {
    if (_loading || _loadingMore || _exhausted || _logs.isEmpty) return;
    final last = _logs.last;
    setState(() => _loadingMore = true);
    final more = widget.db.window(
      anchor: (time: last.createdAt, id: last.id),
      limit: _pageSize,
    );
    _cacheParents(more);
    _imageSummaries.addAll(
      widget.db.imageSummariesFor(more.map((l) => l.id).toSet()),
    );
    setState(() {
      _logs.addAll(more);
      _loadingMore = false;
      _exhausted = more.length < _pageSize;
    });
  }

  /// 포크 카드의 "↩ 언제에서 이어짐" 표시용 부모 캐시.
  void _cacheParents(List<LogEntry> logs) {
    for (final log in logs) {
      final pid = log.parentId;
      if (pid == null || _parents.containsKey(pid)) continue;
      final p = widget.db.byId(pid);
      if (p != null) _parents[pid] = p;
    }
  }

  Future<void> _compose({LogEntry? parent}) async {
    final result = await ComposeSheet.show(context, parent: parent);
    if (result == null || !mounted) return;

    // 저장은 즉시 — 위치·날씨 때문에 로그가 늦게 뜨면 안 된다.
    final id = widget.db.newId();
    final now = DateTime.now();
    final entry = LogEntry(
      id: id,
      content: result.content,
      createdAt: now,
      originalCreatedAt: now,
      parentId: parent?.id,
      rootId: parent == null ? null : (parent.rootId ?? parent.id),
      depth: parent == null ? 0 : parent.depth + 1,
      path: parent == null ? null : '${parent.path ?? parent.id}/$id',
      loopAt: result.loopAt,
    );
    widget.db.insert(entry);

    // 이미지는 같은 로그의 일부 — 개념상 인라인, 물리적으로 log_images.
    if (result.images.isNotEmpty) {
      widget.db.insertImages(id, result.images);
    }
    // 새 로그는 '지금'에 남는다 — 날짜 이동 중이었다면 최신 화면으로 복귀.
    _jumpAt = null;
    _reload(); // ← 바로 화면에 뜬다

    if (result.loopAt != null) {
      await LoopNotifications.scheduleLoop(
        logId: id,
        body: result.content,
        at: result.loopAt!,
      );
    }
    // 이어쓰기로 루프를 소화시켰다면 원본의 예약을 정리 — OS 알람도 취소해야
    // 이미 돌아온 루프가 나중에 다시 울리지 않는다.
    // 발화를 기다리지 않고 돌아온 것도 복습 1회 — 망각곡선 카운트에 들어간다.
    if (parent != null && parent.hasPendingLoop) {
      widget.db.markLoopDone(parent.id);
      widget.db.incrementLoopCount(parent.id);
      await LoopNotifications.cancel(parent.id);
      _reload();
    }

    // 위치·날씨 캡처는 저장 뒤 뒤에서 조용히 — 실패해도 로그는 이미 있다.
    unawaited(_attachContext(id));
  }

  Future<void> _attachContext(String logId) async {
    final location = await LocationService.capture();
    if (location == null) return;
    final weather = await WeatherService.fetch(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    widget.db.updateCapture(
      logId,
      latitude: location.latitude,
      longitude: location.longitude,
      place: location.place,
      weatherCode: weather?.code,
      temperatureC: weather?.temperatureC,
    );
    if (mounted) _reload(); // 헤더에 장소·날씨가 조용히 나타난다
  }

  Future<void> _onAction(LogEntry log, LogMenuAction action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case LogMenuAction.edit:
        final controller = TextEditingController(text: log.content);
        final text = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.editContent),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: Text(l10n.save),
              ),
            ],
          ),
        );
        if (text != null && text.isNotEmpty) {
          widget.db.updateContent(log.id, text);
        }
      case LogMenuAction.loopForkTap:
        // 루프 도착 빈 로그 탭 — 루프 보기 또는 작성하기.
        final choice = await showModalBottomSheet<LogMenuAction>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.account_tree,
                    color: LoopColors.lavender,
                  ),
                  title: Text(l10n.loopViewAction),
                  onTap: () =>
                      Navigator.pop(sheetContext, LogMenuAction.loopView),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.loopWriteAction),
                  onTap: () => Navigator.pop(sheetContext, LogMenuAction.edit),
                ),
              ],
            ),
          ),
        );
        if (choice == null || !mounted) return;
        if (choice == LogMenuAction.loopView) {
          _enterLineage(log);
          return;
        }
        // 작성하기 — 빈 껍데기를 채운다 (메뉴의 편집과 같은 대화상자).
        final controller = TextEditingController(text: log.content);
        final text = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.loopWriteAction),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: Text(l10n.save),
              ),
            ],
          ),
        );
        if (text != null && text.isNotEmpty) {
          widget.db.updateContent(log.id, text);
          _reload();
        }
        return;
      case LogMenuAction.loopView:
        _enterLineage(log);
        return;
      case LogMenuAction.changeTime:
        final date = await showDatePicker(
          context: context,
          initialDate: log.createdAt,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(log.createdAt),
        );
        if (time == null) return;
        widget.db.updateCreatedAt(
          log.id,
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      case LogMenuAction.loop:
        // 통합 Loop 시트 — 지금 이어쓰기 / 한 번 알림 / 반복 / 정보·중지.
        // 반복 발화 로그는 규칙이 끝났어도 정보를 보여줘야 하니 DB에서 조회.
        final rule =
            _rulesBySource[log.id] ??
            (log.repeatRuleId != null
                ? widget.db.repeatRuleById(log.repeatRuleId!)
                : null);
        final result = await LoopSheet.open(
          context,
          log: log,
          source: rule == null ? null : widget.db.byId(rule.sourceLogId),
          rule: rule,
          canJump: log.isRepeatFork,
        );
        if (result == null || !mounted) return;
        switch (result) {
          case LoopWriteNow():
            await _compose(parent: log);
            return; // _compose가 reload를 이미 함
          case LoopOnce(:final at, :final asAlarm):
            widget.db.updateLoopAt(log.id, at, alarm: asAlarm);
            await LoopNotifications.scheduleLoop(
              logId: log.id,
              body: log.content.trim().isEmpty
                  ? l10n.notifFallbackBody
                  : log.content,
              at: at,
              alarm: asAlarm,
              dbDir: widget.db.directory.path,
            );
          case LoopRepeat(:final draft):
            widget.db.insertRepeatRule(
              RepeatRule(
                id: widget.db.newId(),
                sourceLogId: log.id,
                kind: draft.kind,
                everyN: draft.everyN,
                timeOfDay: draft.timeOfDay,
                nextFireAt: draft.firstFireFrom(DateTime.now()),
                createdAt: DateTime.now(),
              ),
            );
            _reload(); // _syncRepeatNotifications 포함 — 알림 배치도 맞춰진다
            return;
          case LoopStop():
            if (rule != null) {
              await _stopRepeat(rule);
            }
            return; // _stopRepeat가 reload를 이미 함
          case LoopJump():
            // 원본이 있는 '날'로 이동 — 검색 점프와 같은 패턴.
            final source = rule == null
                ? null
                : widget.db.byId(rule.sourceLogId);
            if (source != null) {
              setState(() {
                _jumpAt = DateTime(
                  source.createdAt.year,
                  source.createdAt.month,
                  source.createdAt.day,
                );
              });
              _scroll.jumpTo(0);
            }
            _reload();
            return;
        }
      case LogMenuAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deleteLogTitle),
            content: Text(l10n.deleteLogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (ok == true) {
          await LoopNotifications.cancel(log.id);
          // 원본 삭제 시 그 원본의 반복 규칙도 멈춘다 (db.delete가 처리).
          final rule = _rulesBySource[log.id];
          if (rule != null) await LoopNotifications.cancelRepeat(rule.id);
          widget.db.delete(log.id);
        }
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: LoopColors.bg,
        centerTitle: false,
        title: const Text(
          'Loop',
          style: TextStyle(
            color: LoopColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showUpcoming,
            icon: const Icon(
              Icons.upcoming,
              size: 20,
              color: LoopColors.textDim,
            ),
            tooltip: l10n.upcomingTitle,
          ),
          IconButton(
            onPressed: _search,
            icon: const Icon(
              Icons.search_outlined,
              size: 20,
              color: LoopColors.textDim,
            ),
            tooltip: l10n.searchHint,
          ),
          IconButton(
            onPressed: _pickJumpDate,
            icon: const Icon(
              Icons.event_outlined,
              size: 20,
              color: LoopColors.textDim,
            ),
            tooltip: l10n.jumpToDate,
          ),
          IconButton(
            onPressed: () async {
              // 설정에서 가져오기했을 수 있으니 닫히면 화면을 다시 읽는다.
              await SettingsSheet.show(context, db: widget.db);
              _reload();
            },
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: LoopColors.textDim,
            ),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LoopColors.lavender,
        foregroundColor: LoopColors.bg,
        onPressed: () => _compose(),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: LoopColors.lavender),
            )
          else if (_logs.isEmpty)
            Center(
              child: Text(
                _jumpAt == null ? l10n.emptyTimeline : l10n.emptyAtDate,
                textAlign: TextAlign.center,
                style: const TextStyle(color: LoopColors.textDim, height: 1.6),
              ),
            )
          else
            ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _logs.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _logs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(LoopSpacing.m),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: LoopColors.lavender,
                      ),
                    ),
                  );
                }
                final log = _logs[i];
                return LogCard(
                  log: log,
                  parent: log.parentId == null ? null : _parents[log.parentId!],
                  imageSummary: _imageSummaries[log.id],
                  imagesLoader: () => widget.db.imagesFor(log.id),
                  onAction: (action) => _onAction(log, action),
                  activeRepeatAsSource: _rulesBySource[log.id],
                  activeRepeatAsFork: log.repeatRuleId == null
                      ? null
                      : _rulesById[log.repeatRuleId!],
                );
              },
            ),
          // 날짜 이동 중 표시 — 탭하면 최신으로 복귀.
          if (_jumpAt != null)
            Positioned(
              top: LoopSpacing.s,
              left: 0,
              right: 0,
              child: Center(child: _jumpPill(l10n)),
            ),
          // 루프 보기 중 표시 — 탭하면 전체 타임라인으로 복귀.
          if (_lineageId != null)
            Positioned(
              top: LoopSpacing.s,
              left: 0,
              right: 0,
              child: Center(child: _lineagePill(l10n)),
            ),
        ],
      ),
    );
  }

  Widget _jumpPill(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _exitJump,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoopSpacing.m,
          vertical: LoopSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: LoopColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LoopColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event, size: 13, color: LoopColors.mint),
            const SizedBox(width: 6),
            Text(
              '${MaterialLocalizations.of(context).formatFullDate(_jumpAt!)} · ${l10n.backToLatest}',
              style: const TextStyle(color: LoopColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 루프 보기 중 맨 위 필 — 사슬이 몇 단인지 보여주고, 탭하면 복귀.
  Widget _lineagePill(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _exitLineage,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoopSpacing.m,
          vertical: LoopSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: LoopColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LoopColors.lavender),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_tree,
              size: 13,
              color: LoopColors.lavender,
            ),
            const SizedBox(width: 6),
            Text(
              '${l10n.loopViewAction} · ${l10n.loopViewBack}',
              style: const TextStyle(color: LoopColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
