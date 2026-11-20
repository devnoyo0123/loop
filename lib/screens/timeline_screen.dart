import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../data/loop_db.dart';
import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
import '../services/browser_service.dart';
import '../services/ads_service.dart';
import '../services/location_service.dart';
import '../services/image_store.dart';

import '../services/loop_notifications.dart';
import '../services/review_prompter.dart';
import '../services/pc_link.dart';
import '../services/video_opener.dart';
import '../services/video_store.dart';
import '../services/weather_service.dart';
import '../utils/ad_slots.dart';
import '../utils/coach_tour.dart';
import '../widgets/coach_mark.dart';
import '../utils/loop_stats.dart';
import '../utils/on_this_day.dart';
import '../utils/starters.dart';
import '../widgets/log_card.dart';
import '../widgets/pill_header_layout.dart';
import '../widgets/alarm_permission_prompt.dart';
import '../services/alarm_permission.dart';
import '../widgets/starter_list.dart';
import 'compose_sheet.dart';
import 'loop_sheet.dart';
import 'search_screen.dart';
import 'share_sheet.dart';
import 'settings_sheet.dart';
import 'stats_sheet.dart';
import 'upcoming_sheet.dart';
import '../widgets/native_ad_card.dart';

/// 타임라인 단일 화면 — 최신이 맨 위, 아래로 갈수록 과거.
/// 포크 로그는 시각 위치에 그대로 섞여 들어온다. (docs/ui-design.md)
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.db,
    required this.videos,
    required this.images,
    this.pcLink,
  });

  final LoopDb db;

  /// PC 연결 — 맥 브리지 클라이언트(ADR-002). 설정 시트로 넘긴다.
  final PcLinkController? pcLink;

  /// 동영상 파일 저장소 — 촬영 본문을 파일로 보관한다. (v9)
  final VideoStore videos;

  /// 이미지 파일 저장소 — 사진 본문을 파일로 보관한다. (v10)
  final ImageStore images;

  /// 공유 임포트 같은 외부 데이터 변경 — 시트가 닫힐 때 표식만 남기고,
  /// 타임라인이 리로드 훅으로 받아 잡아낸다. (share_sheet.dart)
  static final reloadHook = ValueNotifier<int>(0);

  /// [사슬 보기]로 진입 요청된 사슬 원본 id — 다음 리로드 때 소비된다.
  static String? _pendingLineageId;

  /// 공유 임포트 직후 — 데이터 재생성, [viewChainId]가 있으면 그 사슬로 진입.
  static void shareDataChanged({String? viewChainId}) {
    _pendingLineageId = viewChainId;
    reloadHook.value++;
  }

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with WidgetsBindingObserver {
  static const _pageSize = 100;

  final _scroll = ScrollController();
  final _parents = <String, LogEntry>{};
  final _imageSummaries = <String, LogImageSummary>{};
  final _videoCounts = <String, int>{};

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

  /// reloadHook 리스너 — dispose에서 지우기 위해 저장.
  VoidCallback? _reloadHookListener;

  /// 루프 보기 중이면 그 로그 id — 타임라인 대신 최상위 원본부터의
  /// 사슬(원본 → 루프 → 루프의 루프 → … → 이 로그)만 보여준다.
  String? _lineageId;

  /// 내 루프만 보기 — 공유받은 기록(author_id != null)을 뺀다.
  /// 내가 쓴 포크는 author_id가 null이라 공유받은 사슬 위에서도 보인다.
  bool _mineOnly = false;

  /// 광고 슬롯 배치 — 최신 화면에서만, 8~10장마다 1개(간격 랜덤).
  /// gaps는 세션 동안 유지돼 페이징해도 이미 정해진 자리가 흔들리지 않는다.
  final _adSlots = AdSlots();

  /// 그때의 나 예약 상태 — 하루 한 번(+설정 변경 때)만 다시 맞춘다.
  DateTime? _onThisDaySyncedDay;
  String? _onThisDaySyncedPref;

  /// [i]번째 리스트 아이템 앞에 끼어든 광고 개수 — 로그 인덱스 환산용.
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
    unawaited(AdsService.init()); // 광고 SDK + 동의 — 실패해도 앱엔 지장 없음
    // 네이티브 알람의 스누즈 기록을 DB에 반영한 뒤 정산·로드 —
    // 반영 전에 settle하면 옛 시각 기준으로 포크가 생겨버린다.
    unawaited(_applyNativeSnoozesThenReload());
    _settleTimer = Timer.periodic(const Duration(minutes: 1), (_) => _settle());
    // 공유 임포트 등 외부 데이터 변경 — 시트가 닫히면 여기서 잡는다.
    _reloadHookListener = () {
      if (mounted) _reload();
      // 공유로 받은 루프에 알람이 있을 수 있다.
      unawaited(_checkAlarmPermission());
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlarmPermission());
    TimelineScreen.reloadHook.addListener(_reloadHookListener!);
  }

  /// 스누즈 기록 적용 → 첫 로드. (네이티브 알람은 앱이 죽어 있어도
  /// 자체적으로 10분 뒤 알람을 다시 걸어두므로, 여기선 DB만 맞추면 된다)
  Future<void> _applyNativeSnoozesThenReload() async {
    try {
      final snoozes = await LoopNotifications.consumePendingSnoozes();
      for (final e in snoozes.entries) {
        widget.db.updateLoopAt(
          e.key,
          DateTime.fromMillisecondsSinceEpoch(e.value),
          alarm: true,
        );
      }
    } catch (_) {
      // 기록이 없거나 채널이 없으면 그냥 진행.
    }
    _reload();
    await _maybeOpenAlarmTarget();
  }

  /// 알람 화면 [확인]로 열어달라는 로그가 있으면 그 루프(사슬)로 진입.
  /// 시작 때와 복귀(resume) 때 각각 확인한다.
  Future<void> _maybeOpenAlarmTarget() async {
    final logId = await LoopNotifications.consumeAlarmOpen();
    if (logId == null || logId.isEmpty || !mounted) return;
    if (widget.db.byId(logId) == null) return; // 삭제된 루프 — 조용히 무시
    setState(() {
      _lineageId = logId;
      _jumpAt = null;
    });
    _reload(); // 정산(발화 포크 생성) 포함 — 사슬에 방금 돌아온 루프가 잡힌다
  }

  /// 다른 앱을 갔다가 돌아오면 — 그사이 발화한 루프를 몰아 생성하고,
  /// 알람 [확인]로 열어달라는 대상이 있으면 그 루프로 진입한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _settle();
      _maybeOpenAlarmTarget();
      _checkAlarmPermission(); // 설정에서 허용하고 돌아왔거나, 그새 꺼졌거나
    }
  }

  /// 알람 권한 점검 — 다가오는 알람 루프가 있는데 전체 화면 알림이 막혀
  /// 있으면 안내한다(시작·복귀·설정/받기 시트 닫힘 = 가져오기 직후 포함).
  /// 없으면 알람이 소리만 나고 화면엔 안 뜬다. (2026-11-01 실기기)
  // ── 첫 루프 투어(코치 마크 ①~④) + [Loop 걸기] 한 번짜리 안내(⑤) ──
  late final CoachTour _tour = CoachTour.decode(
    widget.db.getSetting(CoachTour.storeKey),
  );
  late final ValueNotifier<CoachStep> _tourStep = ValueNotifier(_tour.step);
  bool _tourChecked = false;
  final _fabKey = GlobalKey();
  final _tourCardKey = GlobalKey();
  final _armKey = GlobalKey();
  String? _tourLogId;
  String? _armLogId;

  /// ④를 잠시 미룬다 — 첫 저장 직후 뜨는 위치 권한 시스템 창이 닫힐 때까지.
  bool _tourHold = false;

  /// 설정의 [사용법 다시 보기] — 기록이 있어도 ①부터 띄운다.
  bool _tourReplay = false;

  /// 설정에서 투어를 되감았을 수 있다 — 저장값과 다르면 따라간다.
  void _syncTourFromStore() {
    final fresh = CoachTour.decode(widget.db.getSetting(CoachTour.storeKey));
    if (fresh.step == _tour.step) return;
    _tour.step = fresh.step;
    _tourReplay = fresh.step == CoachStep.write;
    _tourHold = false;
    _tourLogId = null;
    _tourStep.value = _tour.step;
    if (mounted) setState(() {});
  }

  void _tourSet(void Function() change) {
    change();
    widget.db.setSetting(CoachTour.storeKey, _tour.encode());
    _tourStep.value = _tour.step;
    if (mounted) setState(() {});
  }

  void _onCardExpanded(LogEntry log, bool open) {
    if (!open) {
      if (_armLogId == log.id) setState(() => _armLogId = null);
      return;
    }
    if (_tour.isDone &&
        _armLogId == null &&
        widget.db.getSetting(CoachTour.armHintKey) == null) {
      setState(() => _armLogId = log.id);
    }
  }

  void _armHintSeen() {
    widget.db.setSetting(CoachTour.armHintKey, '1');
    setState(() => _armLogId = null);
  }

  CoachSpec? _coachSpec(AppLocalizations l10n) {
    void skip() => _tourSet(_tour.skip);
    switch (_tour.step) {
      case CoachStep.write
          when (_logs.isEmpty || _tourReplay) &&
              !_loading &&
              _jumpAt == null &&
              _lineageId == null:
        return CoachSpec(
          target: _fabKey,
          number: 1,
          total: CoachTour.total,
          title: l10n.coachWriteTitle,
          body: l10n.coachWriteBody,
          skipLabel: l10n.coachSkip,
          onSkip: skip,
        );
      case CoachStep.returns when _tourLogId != null && !_tourHold:
        return CoachSpec(
          target: _tourCardKey,
          number: 4,
          total: CoachTour.total,
          title: l10n.coachReturnTitle,
          body: l10n.coachReturnBody,
          skipLabel: l10n.coachSkip,
          onSkip: skip,
          actionLabel: l10n.coachGotIt,
          onAction: () => _tourSet(_tour.acknowledge),
        );
      default:
        break;
    }
    if (_armLogId != null) {
      return CoachSpec(
        target: _armKey,
        title: l10n.coachArmTitle,
        body: l10n.coachArmBody,
        skipLabel: l10n.coachSkip,
        onSkip: _armHintSeen,
        actionLabel: l10n.coachGotIt,
        onAction: _armHintSeen,
      );
    }
    return null;
  }

  late final ReviewPrompter _review = ReviewPrompter(
    api: const PlayReviewApi(),
    store: _DbReviewStore(widget.db),
  );

  Future<void> _maybeAskReview(int chainReturns) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await _review.maybeAsk(
      chainReturns: chainReturns,
      usage: () {
        final s = LoopStats.fromTimestamps(
          widget.db.writtenLogTimestamps(),
          now: DateTime.now(),
          heatmapWeeks: 1,
        );
        return (totalLogs: s.totalLogs, activeDays: s.activeDays);
      },
    );
  }

  late final AlarmPermissionGuard _alarmGuard = AlarmPermissionGuard(
    db: widget.db,
  );

  Future<void> _checkAlarmPermission() async {
    if (!mounted) return;
    await AlarmPermissionPrompt.maybeShow(context, _alarmGuard);
  }

  @override
  void dispose() {
    _tourStep.dispose();
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_reloadHookListener != null) {
      TimelineScreen.reloadHook.removeListener(_reloadHookListener!);
    }
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
    // 외부(공유 임포트)가 사슬 진입을 요청했으면 이번 리로드에서 소비한다.
    final pending = TimelineScreen._pendingLineageId;
    if (pending != null) {
      TimelineScreen._pendingLineageId = null;
      if (widget.db.byId(pending) != null) {
        _lineageId = pending;
        _jumpAt = null;
      }
    }
    widget.db.settleExpiredLoops();
    widget.db.settleRepeats(); // 놓친 반복 발화를 발화 시각대로 몰아 생성
    _syncRepeatNotifications();
    _syncOneShotNotifications();
    _syncOnThisDay();
    // 루프 보기 중엔 사슬만 — 페이지 나눔·날짜 이동과는 무관하게 전체 사슬.
    final logs = _lineageId != null
        ? widget.db.lineage(_lineageId!)
        : widget.db.window(
            until: _jumpAt?.add(const Duration(days: 1)),
            limit: _pageSize,
            mineOnly: _mineOnly,
          );
    _cacheParents(logs);
    _cacheRules();
    setState(() {
      _logs = logs;
      _imageSummaries
        ..clear()
        ..addAll(widget.db.imageSummariesFor(logs.map((l) => l.id).toSet()));
      _videoCounts
        ..clear()
        ..addAll(widget.db.videoCountsFor(logs.map((l) => l.id).toSet()));
      _loading = false;
      _exhausted = _lineageId != null || logs.length < _pageSize; // 사슬은 페이지 없음
    });
    // 첫 로드에 이미 기록이 있으면(업데이트로 온 기존 사용자) 투어 대상 아님.
    if (!_tourChecked && _jumpAt == null && _lineageId == null) {
      _tourChecked = true;
      if (logs.isNotEmpty && _tour.step == CoachStep.write) {
        _tourSet(_tour.existingUser);
      }
    }
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
      // curve 사다리는 칸마다 간격이 다르고 칸 수도 정해져 있다 —
      // 남은 칸만큼만 걷는 워커로 예약한다 (버튼 한 번 = 끝까지 알림 자동).
      final isCurve = rule.kind == RepeatKind.curve;
      unawaited(
        LoopNotifications.scheduleRepeatFires(
          ruleId: rule.id,
          preview: content.isEmpty ? l10n.notifFallbackBody : content,
          firstAt: rule.nextFireAt,
          nextAfter: isCurve
              ? RepeatRule.curveWalker(
                  startRung: rule.fireCount, timeOfDay: rule.timeOfDay)
              : rule.nextFireAfter,
          // 남은 칸 수 — 16은 LoopNotifications._repeatSlots와 같은 상한.
          count: isCurve
              ? (RepeatRule.curveRungs - rule.fireCount).clamp(0, 16)
              : 12,
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
        ),
      );
    }
  }

  /// 그때의 나 — 오늘부터 며칠 치 아침 9시 알림을 다시 맞춘다. 각 날의
  /// 1주·1개월·1년 전 기록은 예약 시점에 이미 과거라 미리 계산해도 정확하다.
  /// 알림을 탭하면 payload(logId)의 날로 타임라인이 이동한다.
  /// 하루 한 번 + 설정 값이 바뀔 때만 돈다 — reload마다 8개를 예약 다시
  /// 걸지 않게 하는 가드.
  void _syncOnThisDay() {
    final pref = widget.db.getSetting(SettingsSheet.onThisDayKey) ?? '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_onThisDaySyncedDay == today && _onThisDaySyncedPref == pref) return;
    _onThisDaySyncedDay = today;
    _onThisDaySyncedPref = pref;

    if (pref == '0') {
      unawaited(LoopNotifications.cancelOnThisDay());
      return;
    }
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final items = <({DateTime at, String body})>[];
    for (var i = 0; i < LoopNotifications.onThisDaySlots; i++) {
      final date = DateTime(today.year, today.month, today.day + i);
      final d = onThisDayDatesFor(date);
      // 하루 하나의 알림 — 내용 전체는 기록 흐름 페이지(그때의 나 섹션)에서.
      // 대표 미리보기는 가장 먼 재회(1년→1개월→1주)를 건넨다.
      final pick = selectOnThisDay(
        weekAgo: widget.db.logsOnDay(d.week),
        monthAgo: widget.db.logsOnDay(d.month),
        yearAgo: widget.db.logsOnDay(d.year),
      );
      if (pick == null) continue;
      items.add((
        at: DateTime(date.year, date.month, date.day, 9),
        body: pick.notificationBody(l10n),
      ));
    }
    unawaited(LoopNotifications.scheduleOnThisDay(items));
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

  /// 내 루프만 보기 토글 — 필(알약)을 눌러도 같은 경로로 해제된다.
  void _toggleMineOnly() {
    setState(() => _mineOnly = !_mineOnly);
    if (_scroll.hasClients) _scroll.jumpTo(0);
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
    // 그때의 나 아침 알림 — 로그가 아니라 기록 흐름 페이지를 연다.
    if (logId == LoopNotifications.statsPayload) {
      unawaited(_showStats());
      return;
    }
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

  /// 기록 흐름 페이지 — 사슬을 고르면 루프 보기로, 그때의 나 기록을
  /// 고르면 그날 타임라인으로 이동한다.
  Future<void> _showStats() async {
    final pick = await StatsPage.show(context, db: widget.db);
    if (pick == null || !mounted) return;
    if (pick.chainLogId != null) {
      final log = widget.db.byId(pick.chainLogId!);
      if (log == null) return;
      _enterLineage(log);
      return;
    }
    final jump = pick.jumpLogId;
    if (jump != null) {
      final log = widget.db.byId(jump);
      if (log != null) _jumpToDayOf(log);
    }
  }

  /// keyset 페이징 — 마지막 로그를 앵커로 그 다음 100개.
  void _loadMore() {
    if (_loading || _loadingMore || _exhausted || _logs.isEmpty) return;
    final last = _logs.last;
    setState(() => _loadingMore = true);
    final more = widget.db.window(
      anchor: (time: last.createdAt, id: last.id),
      limit: _pageSize,
      mineOnly: _mineOnly,
    );
    _cacheParents(more);
    _imageSummaries.addAll(
      widget.db.imageSummariesFor(more.map((l) => l.id).toSet()),
    );
    _videoCounts.addAll(
      widget.db.videoCountsFor(more.map((l) => l.id).toSet()),
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

  Future<void> _compose({LogEntry? parent, Starter? starter}) async {
    final l10n = AppLocalizations.of(context);
    // 첫 루프 투어 ①에서 작성을 시작했다면 ②·③을 시트 안에서 이어간다.
    final touring = parent == null && _tour.step == CoachStep.write;
    if (touring) _tourSet(() => _tour.composeOpened(loopPreset: starter != null));
    final result = await ComposeSheet.show(
      context,
      parent: parent,
      banner: starter == null
          ? null
          : l10n.starterComposeBanner(starter.whenLabel(l10n)),
      coach: touring
          ? ComposeCoach(
              step: _tourStep,
              onLoopReserved: () => _tourSet(_tour.loopReserved),
              onLoopCleared: () => _tourSet(_tour.loopCleared),
              onSkip: () => _tourSet(_tour.skip),
            )
          : null,
    );
    if (result == null || !mounted) {
      if (touring && mounted) {
        _tourSet(() => _tour.composeClosed(saved: false, hasLoop: false));
      }
      return;
    }

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
      loopAlarm: result.loopAlarm,
      // 이어쓰기 포크도 체인 카운트를 이어받는다 — 안 그러면 이어쓰기 후
      // 루프 추천이 10분으로 리셋된다 (2026-10-24 사용자 지적).
      // 부모에게 대기 중인 루프가 있었다면 그 발화까지 반영해 +1.
      loopCount: parent == null
          ? 0
          : (parent.hasPendingLoop ? parent.loopCount + 1 : parent.loopCount),
    );
    widget.db.insert(entry);

    // 이미지는 같은 로그의 일부 — 개념상 인라인, 물리적으로 log_images.
    if (result.images.isNotEmpty) {
      widget.db.insertImages(id, result.images);
    }
    // 동영상은 파일로 보관하고 DB엔 메타만 (v9). 저장 실패(디스크 부족
    // 등)해도 로그는 살아 있어야 한다 — 첨부만 누락되는 것을 허용.
    if (result.video != null) {
      try {
        final fileName = widget.videos.save(id, result.video!);
        widget.db.insertVideo(id, fileName, result.video!.length);
        // 대표 프레임 — 유튜브 프리뷰식 카드 표시용. 실패해도 무방.
        await _makeVideoThumb(fileName);
      } catch (_) {}
    }

    // 첫 루프 스타터 — 첫 기록에 루프/반복을 자동으로 건다. 사용자가 직접
    // 예약(⏰)을 골랐다면 그 선택이 우선한다.
    DateTime? starterLoopAt;
    if (starter != null && result.loopAt == null) {
      switch (starter.kind) {
        case StarterKind.once:
          starterLoopAt = now.add(Duration(minutes: starter.everyN!));
          widget.db.updateLoopAt(id, starterLoopAt);
        case StarterKind.daily:
          widget.db.insertRepeatRule(
            RepeatRule(
              id: widget.db.newId(),
              sourceLogId: id,
              kind: RepeatKind.daily,
              timeOfDay: starter.timeOfDay,
              nextFireAt: nextDailyFire(starter.timeOfDay!, now),
              createdAt: now,
            ),
          );
      }
    }

    // 새 로그는 '지금'에 남는다 — 날짜 이동 중이었다면 최신 화면으로 복귀.
    _jumpAt = null;
    _reload(); // ← 바로 화면에 뜬다 (반복 예약 배치도 함께 맞춰진다)
    if (touring) {
      _tourLogId = id;
      _tourHold = true; // 위치 권한 창이 먼저 — 아래에서 끝나면 ④를 띄운다
      _tourSet(
        () => _tour.composeClosed(
          saved: true,
          hasLoop: result.loopAt != null || starter != null,
        ),
      );
    }

    if (result.loopAt != null) {
      await LoopNotifications.scheduleLoop(
        logId: id,
        body: result.content,
        at: result.loopAt!,
        alarm: result.loopAlarm,
      );
      // 알람을 방금 걸었다 — 화면에 뜰 수 없는 상태면 유예 없이 바로 안내.
      if (result.loopAlarm && mounted) {
        unawaited(AlarmPermissionPrompt.maybeShow(context, _alarmGuard, force: true));
      }
    } else if (starterLoopAt != null) {
      await LoopNotifications.scheduleLoop(
        logId: id,
        body: result.content,
        at: starterLoopAt,
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
      // 돌아온 생각을 이어 썼다 — 핵심 경험의 순간에만 별점을 조심스럽게
      // 묻는다(ReviewPolicy). 시트가 닫히고 카드가 뜬 뒤에 띄운다.
      unawaited(_maybeAskReview(entry.loopCount));
    }

    // 위치·날씨 캡처는 저장 뒤 뒤에서 조용히 — 실패해도 로그는 이미 있다.
    unawaited(_attachContext(id));

    // 투어 ④는 위치 권한 창(첫 저장 때 한 번)이 닫힌 뒤에 — 한 번에 하나만.
    if (_tourHold) {
      await LocationService.permissionSettled;
      if (mounted) setState(() => _tourHold = false);
    }
  }

  /// 동영상 대표 프레임 추출 — 카드에서 유튜브 프리뷰처럼 보여준다. (v10.2)
  Future<void> _makeVideoThumb(String fileName) async {
    try {
      final thumb = await VideoOpener.thumb(
        widget.videos.fileFor(fileName).path,
      );
      if (thumb != null) widget.videos.saveThumb(fileName, thumb);
    } catch (_) {
      // 썸네일 실패 — 카드는 아이콘 행으로 폴백
    }
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
        // 살아있는 반복의 도착이면 중지도 이 시트에서 바로 — 원본까지
        // 갈 필요 없이. (v10.1)
        final arrivalRule = log.repeatRuleId == null
            ? null
            : widget.db.repeatRuleById(log.repeatRuleId!);
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
                if (arrivalRule != null && arrivalRule.active)
                  ListTile(
                    leading: const Icon(
                      Icons.stop_circle_outlined,
                      color: LoopColors.danger,
                    ),
                    title: Text(
                      l10n.loopStop,
                      style: const TextStyle(color: LoopColors.danger),
                    ),
                    onTap: () =>
                        Navigator.pop(sheetContext, LogMenuAction.stopRepeat),
                  ),
              ],
            ),
          ),
        );
        if (choice == null || !mounted) return;
        if (choice == LogMenuAction.stopRepeat) {
          if (arrivalRule != null && arrivalRule.active) {
            await _stopRepeat(arrivalRule);
          }
          return;
        }
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
      case LogMenuAction.share:
        // 사슬 공유 — 원본 기준 전체 사슬이 페이로드. (share-design.md §1)
        await ShareSheet.open(
          context,
          db: widget.db,
          rootId: log.rootId ?? log.id,
          videos: widget.videos,
        );
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
        // 사슬의 현재 끝 — 보인 로그가 중간일 때만 전달한다(끝이면 null).
        // 루프는 기본적으로 끝에서 이어진다. (v8)
        LogEntry? head;
        if (rule == null) {
          final leaf = widget.db.latestLeafOf(log.id);
          if (leaf != null && leaf.id != log.id) head = leaf;
        }
        final result = await LoopSheet.open(
          context,
          log: log,
          head: head,
          source: rule == null ? null : widget.db.byId(rule.sourceLogId),
          rule: rule,
          canJump: log.isRepeatFork,
        );
        if (result == null || !mounted) return;
        switch (result) {
          case LoopWriteNow():
            await _compose(parent: log);
            return; // _compose가 reload를 이미 함
          case LoopOnce(:final at, :final asAlarm, :final attachId):
            widget.db.updateLoopAt(attachId, at, alarm: asAlarm);
            final target = attachId == log.id ? log : widget.db.byId(attachId);
            await LoopNotifications.scheduleLoop(
              logId: attachId,
              body: target == null || target.content.trim().isEmpty
                  ? l10n.notifFallbackBody
                  : target.content,
              at: at,
              alarm: asAlarm,
            );
            if (asAlarm && mounted) {
              unawaited(
                AlarmPermissionPrompt.maybeShow(context, _alarmGuard, force: true),
              );
            }
          case LoopRepeat(:final draft, :final attachId):
            widget.db.insertRepeatRule(
              RepeatRule(
                id: widget.db.newId(),
                // 반복의 원본 = 부착 대상(기본 사슬의 끝) — 칩·발화 줄기가
                // 거기서 시작한다.
                sourceLogId: attachId,
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
      case LogMenuAction.openVideo:
        final recs = widget.db.videosFor(log.id);
        for (final rec in recs) {
          await VideoOpener.open(widget.videos.fileFor(rec.fileName).path);
        }
        return; // 재생 이동 — 화면 갱신 불필요
      case LogMenuAction.stopRepeat:
        // 어디서 눌렀든 그 반복의 규칙을 바로 중지 — 확인 대화상자는
        // _stopRepeat가 이미 보여준다. (v10.1)
        final repeatRule =
            _rulesBySource[log.id] ??
            (log.repeatRuleId != null
                ? widget.db.repeatRuleById(log.repeatRuleId!)
                : null);
        if (repeatRule != null && repeatRule.active) {
          await _stopRepeat(repeatRule);
          return; // _stopRepeat가 reload를 이미 함
        }
        return;
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
          // 첨부 파일(이미지·동영상) 본문도 함께 치운다 — 메타는
          // db.delete가 연쇄 삭제한다. (v10)
          for (final rec in widget.db.videosFor(log.id)) {
            widget.videos.delete(rec.fileName);
          }
          for (final fileName in widget.db.imageFileNamesFor(log.id)) {
            widget.images.delete(fileName);
          }
          widget.db.delete(log.id);
        }
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CoachMarkLayer(
      spec: _coachSpec(l10n),
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
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
            onPressed: _toggleMineOnly,
            icon: Icon(
              _mineOnly ? Icons.person : Icons.person_outline,
              size: 20,
              color: _mineOnly ? LoopColors.lavender : LoopColors.textDim,
            ),
            tooltip: l10n.mineOnlyTitle,
          ),
          IconButton(
            onPressed: _showStats,
            icon: const Icon(
              Icons.insights_outlined,
              size: 20,
              color: LoopColors.textDim,
            ),
            tooltip: l10n.statsTitle,
          ),
          IconButton(
            onPressed: () async {
              // 설정에서 가져오기했을 수 있으니 닫히면 화면을 다시 읽는다.
              await SettingsSheet.show(
                context,
                db: widget.db,
                videos: widget.videos,
                images: widget.images,
                pcLink: widget.pcLink,
              );
              _reload();
              _syncTourFromStore();
              unawaited(_checkAlarmPermission()); // 가져오기로 알람이 들어왔을 수 있다
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
        key: _fabKey,
        backgroundColor: LoopColors.lavender,
        foregroundColor: LoopColors.bg,
        onPressed: () => _compose(),
        child: const Icon(Icons.add),
      ),
      // 상태 알약(날짜 이동·루프 보기)은 리스트 위의 고정 줄 — 예전엔 리스트
      // 위에 떠서(Positioned) 맨 위 카드의 날짜·장소를 가렸다 (2026-11-01).
      body: PillHeaderLayout(
        pills: [
          if (_jumpAt != null) _jumpPill(l10n),
          if (_lineageId != null) _lineagePill(l10n),
          if (_mineOnly) _mineOnlyPill(l10n),
        ],
        child: Stack(
          children: [
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: LoopColors.lavender),
              )
            else if (_logs.isEmpty)
              // 텅 빈 최신 화면 — 첫 루프 스타터로 핵심 사이클(쓰기 → 돌아옴)을
              // 바로 체감하게 한다. 날짜 이동 중의 빈 화면은 기존 안내만.
              _jumpAt == null
                  ? StarterList(
                      onPick: (s) => _compose(starter: s),
                      dayEnd: SettingsSheet.dayEndOf(widget.db),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(LoopSpacing.l),
                        child: Text(
                          l10n.emptyAtDate,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: LoopColors.textDim,
                            height: 1.6,
                          ),
                        ),
                      ),
                    )
            else
              Builder(
                builder: (context) {
                  // 넓은 화면(폴드 내부·태블릿)에서 읽기 편하도록 타임라인을
                  // 가운데 읽기 컬럼으로 묶는다. 폰 폭에서는 변화 없음 (2026-10-24).
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 광고 슬롯 — 최신 화면에서만. 날짜 이동·루프 보기(사슬)는
                          // 기록의 맥락을 건드리지 않도록 광고를 넣지 않는다.
                          // 간격은 화면 높이로 정한다 — 한 화면에 광고 최대 1개
                          // (2026-11-12). AdSlots가 인접 금지·맨 위 금지도 보장.
                          _adSlots.configureForViewport(
                            constraints.maxHeight,
                            textScale: MediaQuery.textScalerOf(
                              context,
                            ).scale(1.0),
                          );
                          // 루프 보기(사슬)만 제외 — 한 생각의 흐름을 따라 읽는 화면.
                          // 날짜 이동(캘린더·검색 결과로 이동)·내 기록만 보기에도
                          // 광고를 넣는다 (2026-11-16 사용자 결정).
                          final adsOn = _lineageId == null;
                          final adPositions = adsOn
                              ? _adSlots.listPositionsFor(_logs.length)
                              : const <int>[];
                          final adSet = adPositions.toSet();
                          final total = _logs.length + adPositions.length;
                          return ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: total + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= total) {
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
                              // 광고 자리 — i번째 아이템이 "i-앞의 광고 수"번째 로그.
                              if (adSet.contains(i)) {
                                return const NativeAdCard();
                              }
                              final log =
                                  _logs[i - AdSlots.adsBefore(adPositions, i)];
                              return LogCard(
                                key: log.id == _tourLogId &&
                                        _tour.step == CoachStep.returns
                                    ? _tourCardKey
                                    : null,
                                onExpandedChanged: (open) =>
                                    _onCardExpanded(log, open),
                                loopArmKey: log.id == _armLogId ? _armKey : null,
                                log: log,
                                parent: log.parentId == null
                                    ? null
                                    : _parents[log.parentId!],
                                resolveLog: widget.db.byId,
                                imageSummary: _imageSummaries[log.id],
                                videoCount: _videoCounts[log.id] ?? 0,
                                videoThumbLoader: () {
                                  final recs = widget.db.videosFor(log.id);
                                  return recs.isEmpty
                                      ? null
                                      : widget.videos.readThumb(
                                          recs.first.fileName,
                                        );
                                },
                                imagesLoader: () => widget.db.imagesFor(log.id),
                                onAction: (action) => _onAction(log, action),
                                activeRepeatAsSource: _rulesBySource[log.id],
                                activeRepeatAsFork: log.repeatRuleId == null
                                    ? null
                                    : _rulesById[log.repeatRuleId!],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
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

  /// 내 루프만 보기 필 — 누르면 필터 해제. 사슬 필(lavender)과 mint로 구분.
  Widget _mineOnlyPill(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _toggleMineOnly,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LoopSpacing.m,
          vertical: LoopSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: LoopColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LoopColors.mint),
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
              Icons.person,
              size: 13,
              color: LoopColors.mint,
            ),
            const SizedBox(width: 6),
            Text(
              '${l10n.mineOnlyTitle} · ${l10n.mineOnlyBack}',
              style: const TextStyle(color: LoopColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 별점 요청 기록을 앱 설정 테이블에 둔다.
class _DbReviewStore implements ReviewStore {
  _DbReviewStore(this.db);
  final LoopDb db;
  @override
  String? read(String key) => db.getSetting(key);
  @override
  void write(String key, String value) => db.setSetting(key, value);
}
