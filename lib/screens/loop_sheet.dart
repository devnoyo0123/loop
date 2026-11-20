import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
import '../services/loop_notifications.dart';
import '../utils/starters.dart';
import '../utils/time_format.dart';

/// Loop 시트의 결과 — 호출한 화면이 받아서 분기한다.
///
/// Loop = "이 로그로 다시 돌아오기". 지금 이어쓸 수도 있고,
/// 알림(한 번/반복)으로 나중에 돌아올 수도 있다. (사용자 결정: fork+반복 통합)
sealed class LoopResult {
  const LoopResult();
}

/// 지금 이어쓰기 — 작성창을 열어야 하므로 호출 쪽에서 처리.
class LoopWriteNow extends LoopResult {
  const LoopWriteNow();
}

/// 한 번 알림 예약. [attachId]는 예약이 걸릴 로그 — 기본은 사슬의 현재
/// 끝([LoopSheet.head]), 사용자가 "여기서부터"를 골랐으면 연 로그(분기).
class LoopOnce extends LoopResult {
  const LoopOnce(this.at, {this.asAlarm = false, required this.attachId});

  final DateTime at;

  /// 알람처럼(무음 무시·꺼야 멈춤·전체화면) 울릴지. (2026-10-18)
  final bool asAlarm;

  /// 루프가 걸리는(발화 포크가 매달리는) 로그.
  final String attachId;
}

/// 반복 루프 생성 — 발화마다 이어쓰기가 자동 생성. [attachId]는 반복의
/// 원본(규칙·칩이 붙는 로그) — 마찬가지로 기본은 사슬의 현재 끝.
class LoopRepeat extends LoopResult {
  const LoopRepeat(this.draft, {required this.attachId});

  final RepeatDraft draft;

  final String attachId;
}

/// 진행 중인 루프 중지.
class LoopStop extends LoopResult {
  const LoopStop();
}

/// 원본 로그가 있는 날로 이동 (반복 발화 로그에서만 제공).
class LoopJump extends LoopResult {
  const LoopJump();
}

/// 한 번 알림의 시각·방식(알림/알람)을 고르는 전용 시트 — 작성창의 ⏰ 버튼이 쓴다.
/// [loopCount]가 있으면 망각곡선 사다리의 N+1번째 간격을 기본 추천한다.
class LoopOncePicker extends StatefulWidget {
  const LoopOncePicker({
    super.key,
    this.initial,
    this.initialAsAlarm = false,
    this.loopCount = 0,
  });

  /// 이미 예약돼 있던 시각. (다시 걸 때 초기값)
  final DateTime? initial;
  final bool initialAsAlarm;

  /// 이 체인에서 지금까지 돌아온 횟수 — 망각곡선 추천 간격의 기준.
  final int loopCount;

  /// 취소하면 null.
  static Future<({DateTime at, bool asAlarm})?> show(
    BuildContext context, {
    DateTime? initial,
    bool initialAsAlarm = false,
    int loopCount = 0,
  }) => showModalBottomSheet<({DateTime at, bool asAlarm})>(
    context: context,
    isScrollControlled: true,
    // 키보드가 올라오면 시트를 같이 올려 마지막 버튼이 가리지 않게.
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      // 하단 제스처 바(내비게이션 바)에 버튼이 가려지지 않게 SafeArea.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: LoopOncePicker(
            initial: initial,
            initialAsAlarm: initialAsAlarm,
            loopCount: loopCount,
          ),
        ),
      ),
    ),
  );

  @override
  State<LoopOncePicker> createState() => _LoopOncePickerState();
}

class _LoopOncePickerState extends State<LoopOncePicker> {
  /// 망각곡선 추천 — 루프 횟수 N에 대해 사다리의 N+1번째 간격.
  /// (횟수가 늘 때마다 10분→1시간→내일→다음주→1달로 미끄러진다)
  late final int _recommended = LoopSheet.curveIndexFor(widget.loopCount);

  late DateTime _at =
      widget.initial ?? DateTime.now().add(LoopSheet.curve[_recommended]);
  bool _asAlarm = false;
  bool? _fullScreenAllowed;

  @override
  void initState() {
    super.initState();
    _asAlarm = widget.initialAsAlarm;
    if (_asAlarm) _checkFullScreenAllowed();
  }

  Future<void> _checkFullScreenAllowed() async {
    try {
      final ok = await const MethodChannel('app.loop/browser')
          .invokeMethod<bool>('fullScreenAllowed');
      if (mounted) setState(() => _fullScreenAllowed = ok ?? true);
    } catch (_) {
      if (mounted) setState(() => _fullScreenAllowed = true);
    }
  }

  /// 초기 선택 — 새로 예약이면 망각곡선 추천 간격, 다시 걸기면 직접.
  late int _quick = widget.initial == null ? _recommended : -1;

  /// 빠른 선택 칩 (라벨은 l10n으로).
  static const _quickDurations = [
    Duration(minutes: 10),
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];

  List<String> _quickLabels(AppLocalizations l10n) => [
    l10n.in10min,
    l10n.in1hour,
    l10n.tomorrow,
    l10n.nextWeek,
    l10n.in1month,
  ];

  /// 골라진 시각이 이미 지났는지 — 지났으면 안내를 보여주고 예약을 막는다.
  bool get _past => !_at.isAfter(DateTime.now());

  /// 하루 마무리 시각("오늘 저녁") 칩 — 간격이 아니라 절대 시각을 찍는다.
  /// 지났으면 내일 저녁. 초기 예약값이 딱 저녁이면 선택된 것으로 보인다.
  static const _dayEnd = -2;

  void _pickQuick(int i) {
    setState(() {
      _quick = i;
      _at = i == _dayEnd
          ? nextDayEnd(dayEndDefault, DateTime.now())
          : DateTime.now().add(_quickDurations[i]);
    });
  }

  /// 직접 — 달력으로 날짜, 시계로 시각.
  Future<void> _pickCustom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (time == null || !mounted) return;
    setState(() {
      _quick = -1;
      _at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      // 과거 시각을 골랐으면 조용히 보정하지 않는다 — 안내 문구와 잠긴
      // 적용 버튼으로 직접 다시 고르게 한다. (즉시 발화 사고 방지)
    });
  }

  /// 적용 — 과거 시각이면 닫지 않고 안내만 갱신한다.
  void _confirmOnce() {
    if (!_at.isAfter(DateTime.now())) {
      setState(() {});
      return;
    }
    Navigator.pop(context, (at: _at, asAlarm: _asAlarm));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quickLabels = _quickLabels(l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.m,
        LoopSpacing.l,
        LoopSpacing.m,
        LoopSpacing.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.alarmTitle,
            style: const TextStyle(
              color: LoopColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LoopSpacing.m),
          // 큰 시각 표시를 탭하면 데이트피커 → 타임피커로 정밀 조정.
          GestureDetector(
            onTap: _pickCustom,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: LoopSpacing.m,
                horizontal: LoopSpacing.m,
              ),
              decoration: BoxDecoration(
                color: LoopColors.surfaceHi,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    formatMixed(_at, DateTime.now(), l10n.yesterday),
                    style: const TextStyle(
                      color: LoopColors.mint,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tapToChangeTime,
                    style: const TextStyle(
                      color: LoopColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 이미 지난 시각 — 알려주고 적용 버튼을 잠근다.
          if (_past) ...[
            const SizedBox(height: LoopSpacing.s),
            Text(
              l10n.pastTimeHint,
              style: const TextStyle(color: LoopColors.danger, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: LoopSpacing.s),
          // 망각곡선 추천 — 루프 횟수에 따라 추천 간격이 미끄러진다.
          Text(
            l10n.loopCurveHint(widget.loopCount + 1, quickLabels[_recommended]),
            style: const TextStyle(color: LoopColors.mint, fontSize: 12),
          ),
          const SizedBox(height: LoopSpacing.s),
          Wrap(
            spacing: LoopSpacing.s,
            runSpacing: LoopSpacing.s,
            children: [
              // 시간순 배치 — 오늘 저녁은 1시간과 내일 사이. (루프 시트와 동일)
              for (var i = 0; i < 2; i++)
                ChoiceChip(
                  label: i == _recommended
                      ? recommendedChipLabel(quickLabels[i], l10n)
                      : Text(quickLabels[i]),
                  selected: _quick == i,
                  onSelected: (_) => _pickQuick(i),
                  selectedColor: LoopColors.mint,
                  backgroundColor: LoopColors.surfaceHi,
                  side: BorderSide(
                    color: _quick == i ? LoopColors.mint : LoopColors.line,
                  ),
                  labelStyle: TextStyle(
                    color: _quick == i ? LoopColors.bg : LoopColors.textDim,
                    fontSize: 13,
                  ),
                ),
              ChoiceChip(
                label: Text(l10n.todayEvening),
                selected: _quick == _dayEnd,
                onSelected: (_) => _pickQuick(_dayEnd),
                selectedColor: LoopColors.mint,
                backgroundColor: LoopColors.surfaceHi,
                side: BorderSide(
                  color: _quick == _dayEnd ? LoopColors.mint : LoopColors.line,
                ),
                labelStyle: TextStyle(
                  color: _quick == _dayEnd ? LoopColors.bg : LoopColors.textDim,
                  fontSize: 13,
                ),
              ),
              for (var i = 2; i < _quickDurations.length; i++)
                ChoiceChip(
                  label: i == _recommended
                      ? recommendedChipLabel(quickLabels[i], l10n)
                      : Text(quickLabels[i]),
                  selected: _quick == i,
                  onSelected: (_) => _pickQuick(i),
                  selectedColor: LoopColors.mint,
                  backgroundColor: LoopColors.surfaceHi,
                  side: BorderSide(
                    color: _quick == i ? LoopColors.mint : LoopColors.line,
                  ),
                  labelStyle: TextStyle(
                    color: _quick == i ? LoopColors.bg : LoopColors.textDim,
                    fontSize: 13,
                  ),
                ),
              ChoiceChip(
                label: Text(l10n.custom),
                selected: _quick == -1,
                onSelected: (_) => _pickCustom(),
                selectedColor: LoopColors.mint,
                backgroundColor: LoopColors.surfaceHi,
                side: BorderSide(
                  color: _quick == -1 ? LoopColors.mint : LoopColors.line,
                ),
                labelStyle: TextStyle(
                  color: _quick == -1 ? LoopColors.bg : LoopColors.textDim,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: LoopSpacing.m),
          Text(
            l10n.howNotify,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: LoopSpacing.s),
          Row(
            children: [
              Expanded(
                child: LoopModeCard(
                  selected: !_asAlarm,
                  icon: Icons.notifications_active_outlined,
                  title: l10n.modeNotif,
                  desc: l10n.modeNotifDesc,
                  onTap: () => setState(() => _asAlarm = false),
                ),
              ),
              const SizedBox(width: LoopSpacing.s),
              Expanded(
                child: LoopModeCard(
                  selected: _asAlarm,
                  icon: Icons.alarm,
                  title: l10n.modeAlarm,
                  desc: l10n.modeAlarmDesc,
                  onTap: () {
                    setState(() => _asAlarm = true);
                    _checkFullScreenAllowed();
                  },
                ),
              ),
            ],
          ),
          if (_asAlarm && _fullScreenAllowed == false) ...[
            const SizedBox(height: LoopSpacing.s),
            _fullScreenHint(context),
          ],
          const SizedBox(height: LoopSpacing.m),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
            ),
            // 과거 시각이면 잠긴다 — 시트가 오래 열려 있던 사이 시각이 지난
            // 경우도 누르는 순간 다시 판정해 닫히지 않게 한다.
            onPressed: _past ? null : _confirmOnce,
            child: Text(l10n.notifyAtThisTime),
          ),
        ],
      ),
    );
  }

  /// 전체화면 권한 안내 — 설정 전용 페이지로 바로 데려다준다.
  Widget _fullScreenHint(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.s + 2,
        LoopSpacing.s,
        LoopSpacing.s,
        LoopSpacing.s,
      ),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LoopColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, size: 15, color: LoopColors.textDim),
          const SizedBox(width: LoopSpacing.s),
          Expanded(
            child: Text(
              l10n.fullScreenHint,
              style: const TextStyle(
                color: LoopColors.textDim,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: LoopSpacing.s),
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () async {
              try {
                await const MethodChannel('app.loop/browser')
                    .invokeMethod('openFullScreenSettings');
              } catch (_) {}
              if (mounted) _checkFullScreenAllowed();
            },
            child: Text(
              l10n.openSettings,
              style: const TextStyle(
                color: LoopColors.mint,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 통합 Loop 시트 — 로그 하나로 돌아오기의 전부.
///
/// - 루프가 없으면: [↩ 지금 이어쓰기] + "다시 알려줘"(한 번/반복)를 한 장에서
/// - 루프가 있으면: 상태(주기·N회째·다음 발화) + 원본 이동 + 이어쓰기 + 중지
class LoopSheet extends StatefulWidget {
  const LoopSheet({
    super.key,
    required this.log,
    this.head,
    this.source,
    this.rule,
    this.canJump = false,
  });

  /// 망각곡선 간격 사다리 — 돌아올 때마다 다음 간격을 제안한다.
  /// (에빙하우스 복습 주기를 앱의 빠른 선택 칩에 맞춘 5단계)
  static const curve = [
    Duration(minutes: 10),
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];

  /// 망각곡선 기본 칩 — N번 돌아온 로그면 N+1번째(인덱스 N) 간격이 기본.
  /// 사다리 끝(1달)에 도달하면 그대로 유지한다.
  static int curveIndexFor(int loopCount) {
    if (loopCount <= 0) return 0;
    if (loopCount >= curve.length) return curve.length - 1;
    return loopCount;
  }

  /// 이 시트를 연 로그. (원본이면 원본, 반복 발화 로그면 그 포크)
  final LogEntry log;

  /// 사슬의 현재 끝(가장 최근 하위 기록) — 보인 로그가 사슬 중간일 때만
  /// 전달되며, 루프는 기본적으로 여기에 건다. (v8 — 사슬의 끝에서 이어짐)
  /// null이면 [log] 자신이 끝이라는 뜻(부착 선택지 없음).
  final LogEntry? head;

  /// 루프의 원본 로그 — 정보 모드에서 미리보기로 보여준다. (없으면 log 사용)
  final LogEntry? source;

  /// 이 로그에 걸린 루프 규칙. null이면 "거는" 모드.
  /// 종료된 규칙도 들어올 수 있다 (상태는 "종료"로 표시).
  final RepeatRule? rule;

  /// [원본으로 이동] 버튼 — 반복 발화 로그에서만 true.
  final bool canJump;

  static Future<LoopResult?> open(
    BuildContext context, {
    required LogEntry log,
    LogEntry? head,
    LogEntry? source,
    RepeatRule? rule,
    bool canJump = false,
  }) => showModalBottomSheet<LoopResult>(
    context: context,
    isScrollControlled: true,
    // 키보드가 올라와도(직접 입력) [Loop 걸기]가 가리지 않게 —
    // 시트를 키보드 높이만큼 올리고 넘치면 스크롤.
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      // 하단 제스처 바에 [Loop 걸기] 버튼이 가려지지 않게 SafeArea.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: LoopSheet(
            log: log,
            head: head,
            source: source,
            rule: rule,
            canJump: canJump,
          ),
        ),
      ),
    ),
  );

  @override
  State<LoopSheet> createState() => _LoopSheetState();
}

class _LoopSheetState extends State<LoopSheet> with WidgetsBindingObserver {
  /// 반복 주기 프리셋 — kind가 null이면 "직접 입력" 마커. (라벨은 l10n으로)
  static const _presets = [
    (RepeatKind.curve, null), // 사다리 — 10분→1시간→저녁→내일→1주→1개월 자동
    (RepeatKind.minutes, 10),
    (RepeatKind.minutes, 30),
    (RepeatKind.hours, 1),
    (RepeatKind.hours, 3),
    (RepeatKind.hours, 6),
    (RepeatKind.daily, null),
    (RepeatKind.weekday, null), // 평일 — 토·일·공휴일 제외
    (RepeatKind.monthly, null), // 매달 — 발화일의 '일'을 유지
    (RepeatKind.yearly, null), // 매년 — 발화일(월·일)을 유지
    (null, null), // 주기 직접 입력
  ];

  String _presetLabel(AppLocalizations l10n, int i) => switch (i) {
    0 => l10n.presetLadder,
    1 => l10n.preset10min,
    2 => l10n.preset30min,
    3 => l10n.preset1hour,
    4 => l10n.preset3hours,
    5 => l10n.preset6hours,
    6 => l10n.presetDaily,
    7 => l10n.presetWeekday,
    8 => l10n.presetMonthly,
    9 => l10n.presetYearly,
    _ => l10n.custom,
  };

  // --- 거는 모드 상태 ---
  int _mode = 0; // 0 = 한 번, 1 = 반복 — 알림은 옵션이지만 기본은 한 번

  /// 거는 위치 — false(기본)=사슬의 끝(head), true=지금 보인 로그에서 분기.
  bool _attachHere = false;

  /// 루프가 실제로 걸릴 로그 — 곡선 회차·반복 원본의 기준이 된다.
  LogEntry get _attach => (!_attachHere || widget.head == null)
      ? (widget.head ?? widget.log)
      : widget.log;

  /// 실제 적용값도 곡선을 따른다 — 기본 _at은 추천 간격에서 시작.
  late DateTime _at = DateTime.now().add(
    LoopSheet.curve[LoopSheet.curveIndexFor(_attach.loopCount)],
  );
  late int _quick = LoopSheet.curveIndexFor(_attach.loopCount);
  int _selected = 1; // 반복 프리셋 — 10분 기본 (0은 사다리)
  final _customController = TextEditingController();

  /// 직접 입력 단위 — 0 분, 1 시간, 2 개월, 3 년.
  int _customUnit = 0;
  TimeOfDay _dailyTime = TimeOfDay.now();

  /// 매달·매년의 앵커 발화일 — 기본은 오늘. 매달은 '일'만, 매년은
  /// 월·일까지 유지된다.
  DateTime _anchorDate = DateTime.now();

  /// 이 루프를 알람처럼 울릴지 — "진짜 언제 알려줘라"용. (기본 알림)
  bool _asAlarm = false;

  /// 전체화면 알람 특별권한. null = 미확인(안드로이드 외/조회 실패) — 안내 숨김.
  bool? _fullScreenAllowed;

  static const _browserCh = MethodChannel('app.loop/browser');

  Future<void> _checkFullScreenAllowed() async {
    try {
      final ok = await _browserCh.invokeMethod<bool>('fullScreenAllowed');
      if (mounted) setState(() => _fullScreenAllowed = ok ?? true);
    } catch (_) {
      // 안드로이드 외 환경(채널 없음) — 안내 없이 통과.
      if (mounted) setState(() => _fullScreenAllowed = true);
    }
  }

  Future<void> _openFullScreenSettings() async {
    try {
      await _browserCh.invokeMethod('openFullScreenSettings');
    } catch (_) {
      // 열리지 않는 환경 — 조용히 무시.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_asAlarm) _checkFullScreenAllowed();
  }

  /// 설정 화면에서 돌아오면 권한을 다시 확인해 안내를 갱신한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _asAlarm) {
      _checkFullScreenAllowed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customController.dispose();
    super.dispose();
  }

  /// 골라진 시각이 이미 지났는지 — 지났으면 안내를 보여주고 예약을 막는다.
  bool get _past => !_at.isAfter(DateTime.now());

  bool get _isCustom => _presets[_selected].$1 == null;

  /// 사다리 프리셋 — 발화 때마다 다음 칸으로 자동 전진.
  bool get _isCurve => _presets[_selected].$1 == RepeatKind.curve;

  /// 매일·평일 — 발화 시각(timeOfDay)을 고르는 프리셋.
  bool get _isDailyLike {
    final kind = _presets[_selected].$1;
    return kind == RepeatKind.daily || kind == RepeatKind.weekday;
  }

  /// 매달·매년 — 발화일(날짜+시각)을 앵커로 고르는 주기. 직접 입력의
  /// 개월·년 단위도 같은 앵커를 쓴다.
  bool get _isAnchored {
    final kind = _presets[_selected].$1;
    if (kind == RepeatKind.monthly || kind == RepeatKind.yearly) return true;
    return kind == null && _customUnit >= 2;
  }

  /// 앵커 발화일 → timeOfDay 저장 형식 "MM-dd HH:mm".
  String get _anchorCode =>
      '${_two(_anchorDate.month)}-${_two(_anchorDate.day)} '
      '${_two(_anchorDate.hour)}:${_two(_anchorDate.minute)}';

  /// 앵커 발화일 사람용 표기 — "10.24(토) · 오전 9:00".
  String _anchorLabel(BuildContext context) {
    final wd = MaterialLocalizations.of(context)
        .narrowWeekdays[_anchorDate.weekday % 7];
    return '${_anchorDate.month}.${_anchorDate.day}($wd) · '
        '${TimeOfDay.fromDateTime(_anchorDate).format(context)}';
  }

  RepeatDraft? get _draft {
    final preset = _presets[_selected];
    final kind = preset.$1;
    if (kind != null) {
      return RepeatDraft(
        kind: kind,
        everyN: preset.$2,
        // "HH:mm"·"MM-dd HH:mm" 완전한 형태여야 한다 — 시간만 넣으면
        // 파싱에서 RangeError가 났다.
        timeOfDay: switch (kind) {
          RepeatKind.daily || RepeatKind.weekday =>
            '${_two(_dailyTime.hour)}:${_two(_dailyTime.minute)}',
          RepeatKind.monthly || RepeatKind.yearly => _anchorCode,
          // 사다리의 저녁 칸 앵커 — "오늘 저녁" 칩과 같은 하루 마무리 시각.
          RepeatKind.curve => dayEndDefault,
          _ => null,
        },
      );
    }
    // 직접 입력
    final n = int.tryParse(_customController.text.trim());
    if (n == null || n <= 0) return null;
    return switch (_customUnit) {
      0 => RepeatDraft(kind: RepeatKind.minutes, everyN: n),
      1 => RepeatDraft(kind: RepeatKind.hours, everyN: n),
      2 => RepeatDraft(
        kind: RepeatKind.monthly,
        everyN: n,
        timeOfDay: _anchorCode,
      ),
      _ => RepeatDraft(
        kind: RepeatKind.yearly,
        everyN: n,
        timeOfDay: _anchorCode,
      ),
    };
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 하루 마무리 시각("오늘 저녁") 칩 — 간격이 아니라 절대 시각. (기본 21:00,
  /// 지났으면 내일 저녁) 초기 예약값이 딱 저녁이면 선택된 것으로 보인다.
  static const _dayEnd = -2;

  void _pickQuick(int i) {
    setState(() {
      _quick = i;
      _at = i == _dayEnd
          ? nextDayEnd(dayEndDefault, DateTime.now())
          : DateTime.now().add(LoopSheet.curve[i]);
    });
  }

  /// 한 번 — 직접: 달력으로 날짜, 시계로 시각.
  Future<void> _pickCustomOnce() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (time == null || !mounted) return;
    setState(() {
      _quick = -1;
      _at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      // 과거 시각을 골랐으면 조용히 보정하지 않는다 — 안내 문구와 잠긴
      // 적용 버튼으로 직접 다시 고르게 한다. (즉시 발화 사고 방지)
    });
  }

  Future<void> _pickDailyTime() async {
    final t = await showTimePicker(context: context, initialTime: _dailyTime);
    if (t != null) setState(() => _dailyTime = t);
  }

  /// 매달·매년 — 달력으로 발화일, 시계로 시각. (한 번 직접 입력과 같은 흐름)
  Future<void> _pickAnchorDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_anchorDate),
    );
    if (time == null || !mounted) return;
    setState(() {
      _anchorDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// 부착 위치 전환 — 곡선 제안도 새 기준의 회차로 다시 맞춘다.
  /// 사용자가 직접 고른 시각(_quick == -1)은 그대로 존중한다.
  void _toggleAttach() {
    setState(() {
      _attachHere = !_attachHere;
      if (_quick >= 0) {
        _quick = LoopSheet.curveIndexFor(_attach.loopCount);
        _at = DateTime.now().add(LoopSheet.curve[_quick]);
      }
    });
  }

  /// 한 번 적용 — 과거 시각이면 닫지 않고 안내만 갱신한다.
  Future<void> _armOnce() async {
    if (!_at.isAfter(DateTime.now())) {
      setState(() {});
      return;
    }
    // 알람 모드면 다른 앱 위 화면 표시 권한을 미리 물어본다 — 없으면
    // 발화 때 다른 앱 위로 전체화면을 덮지 못한다(One UI 특성).
    if (_asAlarm && !await LoopNotifications.canDrawOverlays()) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.overlayPermTitle),
          content: Text(l10n.overlayPermBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.overlayPermOpen),
            ),
          ],
        ),
      );
      if (go == true) {
        await LoopNotifications.requestDrawOverlays();
      }
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      LoopOnce(_at, asAlarm: _asAlarm, attachId: _attach.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.m,
        LoopSpacing.l,
        LoopSpacing.m,
        LoopSpacing.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.repeatTitle,
            style: const TextStyle(
              color: LoopColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LoopSpacing.m),
          _preview(l10n),
          if (widget.rule == null) ...[
            const SizedBox(height: LoopSpacing.m),
            _armMode(l10n),
          ] else ...[
            const SizedBox(height: LoopSpacing.m),
            _infoMode(l10n),
          ],
        ],
      ),
    );
  }

  /// 곡선 칩 — 추천 칩이면 라벨에 추천 마크.
  Widget _curveChip(AppLocalizations l10n, List<String> quickLabels, int i) {
    final curveIdx = LoopSheet.curveIndexFor(_attach.loopCount);
    return ChoiceChip(
      label: i == curveIdx
          ? recommendedChipLabel(quickLabels[i], l10n)
          : Text(quickLabels[i]),
      selected: _quick == i,
      onSelected: (_) => _pickQuick(i),
      selectedColor: LoopColors.mint,
      backgroundColor: LoopColors.surfaceHi,
      side: BorderSide(color: _quick == i ? LoopColors.mint : LoopColors.line),
      labelStyle: TextStyle(
        color: _quick == i ? LoopColors.bg : LoopColors.textDim,
        fontSize: 13,
      ),
    );
  }

  /// "오늘 저녁" 칩 — 간격이 아니라 마무리 시각의 절대 시각을 찍는다.
  Widget _eveningChip(AppLocalizations l10n) => ChoiceChip(
    label: Text(l10n.todayEvening),
    selected: _quick == _dayEnd,
    onSelected: (_) => _pickQuick(_dayEnd),
    selectedColor: LoopColors.mint,
    backgroundColor: LoopColors.surfaceHi,
    side: BorderSide(
      color: _quick == _dayEnd ? LoopColors.mint : LoopColors.line,
    ),
    labelStyle: TextStyle(
      color: _quick == _dayEnd ? LoopColors.bg : LoopColors.textDim,
      fontSize: 13,
    ),
  );

  /// "직접" 칩 — 달력·시계 피커.
  Widget _customChip(AppLocalizations l10n) => ChoiceChip(
    label: Text(l10n.custom),
    selected: _quick == -1,
    onSelected: (_) => _pickCustomOnce(),
    selectedColor: LoopColors.mint,
    backgroundColor: LoopColors.surfaceHi,
    side: BorderSide(color: _quick == -1 ? LoopColors.mint : LoopColors.line),
    labelStyle: TextStyle(
      color: _quick == -1 ? LoopColors.bg : LoopColors.textDim,
      fontSize: 13,
    ),
  );

  /// 이어짐 위치 행 — 보인 로그가 사슬 중간일 때만. 기본은 사슬의 끝에서
  /// 이어지고, "여기서부터"를 고르면 보인 로그에서 분기한다.
  Widget _attachRow(AppLocalizations l10n) {
    final target = _attach;
    final preview = target.content.trim().isEmpty
        ? l10n.noContent
        : target.content.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.m,
        LoopSpacing.s,
        LoopSpacing.xs,
        LoopSpacing.s,
      ),
      decoration: BoxDecoration(
        color: LoopColors.surfaceHi,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: LoopColors.lavender,
          ),
          const SizedBox(width: LoopSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachHere
                      ? l10n.loopAttachHereLabel
                      : l10n.loopAttachHeadLabel,
                  style: const TextStyle(
                    color: LoopColors.mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LoopColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggleAttach,
            style: TextButton.styleFrom(
              foregroundColor: LoopColors.lavender,
              padding: const EdgeInsets.symmetric(horizontal: LoopSpacing.s),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text(
              _attachHere
                  ? l10n.loopAttachHeadAction
                  : l10n.loopAttachHereAction,
            ),
          ),
        ],
      ),
    );
  }

  /// 루프의 대상 로그 미리보기 — 정보 모드에선 원본을 보여준다.
  Widget _preview(AppLocalizations l10n) {
    final log = widget.source ?? widget.log;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoopSpacing.m),
      decoration: BoxDecoration(
        color: LoopColors.surfaceHi,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.content.trim().isEmpty ? l10n.emptyWriteHint : log.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LoopColors.text,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMixed(log.createdAt, DateTime.now(), l10n.yesterday),
            style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 거는 모드 — [지금 이어쓰기] + 다시 알려줘(한 번/반복).
  Widget _armMode(AppLocalizations l10n) {
    final draft = _draft;
    final first = draft?.firstFireFrom(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: LoopColors.lavender,
            side: const BorderSide(color: LoopColors.lavender),
          ),
          onPressed: () => Navigator.pop(context, const LoopWriteNow()),
          icon: const Icon(Icons.reply, size: 18),
          label: Text(l10n.loopWriteNow),
        ),
        const SizedBox(height: LoopSpacing.m),
        Text(
          l10n.loopAgain,
          style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
        ),
        const SizedBox(height: LoopSpacing.s),
        // 이어짐 위치 — 보인 로그가 사슬 중간일 때만. 기본은 사슬의 끝.
        if (widget.head != null) ...[
          _attachRow(l10n),
          const SizedBox(height: LoopSpacing.m),
        ],
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(l10n.loopModeOnce)),
            ButtonSegment(value: 1, label: Text(l10n.loopModeRepeat)),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(LoopColors.surfaceHi),
            foregroundColor: WidgetStatePropertyAll(LoopColors.textDim),
          ),
        ),
        const SizedBox(height: LoopSpacing.m),
        if (_mode == 0) ..._oncePanel(l10n),
        if (_mode == 1) ..._repeatPanel(l10n, first),
        const SizedBox(height: LoopSpacing.m),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LoopColors.lavender,
            foregroundColor: LoopColors.bg,
          ),
          onPressed: _mode == 0
              ? (_past ? null : _armOnce)
              : draft == null
              ? null
              : () => Navigator.pop(
                  context,
                  LoopRepeat(draft, attachId: _attach.id),
                ),
          child: Text(l10n.loopArm),
        ),
      ],
    );
  }

  List<Widget> _oncePanel(AppLocalizations l10n) {
    final quickLabels = [
      l10n.in10min,
      l10n.in1hour,
      l10n.tomorrow,
      l10n.nextWeek,
      l10n.in1month,
    ];
    // 망각곡선 추천 칩 — 버튼(칩)과 실제 적용값(_at)이 함께 곡선을 따른다.
    // 회차는 "이번이 몇 번째 복습인지"라서 카운트 +1로 표시한다.
    // 부착 대상(사슬의 끝)의 회차를 따른다 — 거기서 곡선이 이어지니까.
    final curveIdx = LoopSheet.curveIndexFor(_attach.loopCount);
    return [
      Text(
        l10n.loopCurveHint(_attach.loopCount + 1, quickLabels[curveIdx]),
        style: const TextStyle(color: LoopColors.mint, fontSize: 12),
      ),
      const SizedBox(height: LoopSpacing.s),
      // 큰 시각 표시를 탭하면 데이트피커 → 타임피커로 정밀 조정.
      GestureDetector(
        onTap: _pickCustomOnce,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: LoopSpacing.m),
          decoration: BoxDecoration(
            color: LoopColors.surfaceHi,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                formatMixed(_at, DateTime.now(), l10n.yesterday),
                style: const TextStyle(
                  color: LoopColors.mint,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.tapToChangeTime,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      // 이미 지난 시각 — 알려주고 적용 버튼을 잠근다.
      if (_past) ...[
        const SizedBox(height: LoopSpacing.s),
        Text(
          l10n.pastTimeHint,
          style: const TextStyle(color: LoopColors.danger, fontSize: 11.5),
        ),
      ],
      const SizedBox(height: LoopSpacing.s),
      Wrap(
        spacing: LoopSpacing.s,
        runSpacing: LoopSpacing.s,
        children: [
          // 시간순 배치 — 오늘 저녁은 1시간과 내일 사이. (v10.1 사용자 결정)
          _curveChip(l10n, quickLabels, 0),
          _curveChip(l10n, quickLabels, 1),
          _eveningChip(l10n),
          for (var i = 2; i < LoopSheet.curve.length; i++)
            _curveChip(l10n, quickLabels, i),
          _customChip(l10n),
        ],
      ),
      const SizedBox(height: LoopSpacing.m),
      Text(
        l10n.howNotify,
        style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
      ),
      const SizedBox(height: LoopSpacing.s),
      Row(
        children: [
          Expanded(
            child: _notifyModeCard(
              selected: !_asAlarm,
              icon: Icons.notifications_active_outlined,
              title: l10n.modeNotif,
              desc: l10n.modeNotifDesc,
              onTap: () => setState(() => _asAlarm = false),
            ),
          ),
          const SizedBox(width: LoopSpacing.s),
          Expanded(
            child: _notifyModeCard(
              selected: _asAlarm,
              icon: Icons.alarm,
              title: l10n.modeAlarm,
              desc: l10n.modeAlarmDesc,
              onTap: () {
                setState(() => _asAlarm = true);
                _checkFullScreenAllowed();
              },
            ),
          ),
        ],
      ),
      if (_asAlarm && _fullScreenAllowed == false) ...[
        const SizedBox(height: LoopSpacing.s),
        _fullScreenHint(l10n),
      ],
    ];
  }

  /// 전체화면 권한 안내 — 설정 전용 페이지로 바로 데려다준다.
  /// (Android 14+는 기본 거부라 한 번 허용이 필요)
  Widget _fullScreenHint(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LoopSpacing.s + 2,
        LoopSpacing.s,
        LoopSpacing.s,
        LoopSpacing.s,
      ),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LoopColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, size: 15, color: LoopColors.textDim),
          const SizedBox(width: LoopSpacing.s),
          Expanded(
            child: Text(
              l10n.fullScreenHint,
              style: const TextStyle(
                color: LoopColors.textDim,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: LoopSpacing.s),
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: _openFullScreenSettings,
            child: Text(
              l10n.openSettings,
              style: const TextStyle(
                color: LoopColors.mint,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 알림/알람 선택 카드 — 루프마다 저장된다. (docs/mockups C안)
  Widget _notifyModeCard({
    required bool selected,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return LoopModeCard(
      selected: selected,
      icon: icon,
      title: title,
      desc: desc,
      onTap: onTap,
    );
  }

  List<Widget> _repeatPanel(AppLocalizations l10n, DateTime? first) {
    final draft = _draft;
    return [
      Text(
        l10n.repeatDesc,
        style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
      ),
      const SizedBox(height: LoopSpacing.s),
      Wrap(
        spacing: LoopSpacing.s,
        runSpacing: LoopSpacing.s,
        children: [
          for (var i = 0; i < _presets.length; i++)
            ChoiceChip(
              label: Text(_presetLabel(l10n, i)),
              selected: _selected == i,
              onSelected: (_) => setState(() => _selected = i),
              selectedColor: LoopColors.lavender,
              backgroundColor: LoopColors.surfaceHi,
              side: BorderSide(
                color: _selected == i ? LoopColors.lavender : LoopColors.line,
              ),
              labelStyle: TextStyle(
                color: _selected == i ? LoopColors.bg : LoopColors.textDim,
                fontSize: 13,
              ),
            ),
        ],
      ),
      if (_isCurve) ...[
        const SizedBox(height: LoopSpacing.s),
        Text(
          l10n.curveSteps,
          style: const TextStyle(color: LoopColors.mint, fontSize: 12),
        ),
      ],
      if (_isCustom) ...[
        const SizedBox(height: LoopSpacing.m),
        Row(
          children: [
            SizedBox(
              width: 72,
              child: TextField(
                controller: _customController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: LoopColors.text, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '30',
                  hintStyle: TextStyle(color: LoopColors.textDim),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(l10n.unitMinutes)),
                  ButtonSegment(value: 1, label: Text(l10n.unitHours)),
                  ButtonSegment(value: 2, label: Text(l10n.unitMonths)),
                  ButtonSegment(value: 3, label: Text(l10n.unitYears)),
                ],
                selected: {_customUnit},
                onSelectionChanged: (s) =>
                    setState(() => _customUnit = s.first),
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(LoopColors.surfaceHi),
                  foregroundColor: WidgetStatePropertyAll(LoopColors.textDim),
                ),
              ),
            ),
          ],
        ),
      ],
      if (_isDailyLike || _isAnchored) ...[
        const SizedBox(height: LoopSpacing.m),
        Row(
          children: [
            Text(
              _isAnchored ? l10n.fireDate : l10n.fireTime,
              style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
            ),
            const Spacer(),
            TextButton(
              onPressed: _isAnchored ? _pickAnchorDate : _pickDailyTime,
              child: Text(
                _isAnchored
                    ? _anchorLabel(context)
                    : _dailyTime.format(context),
                style: const TextStyle(
                  color: LoopColors.lavender,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
      if (first != null) ...[
        const SizedBox(height: LoopSpacing.s),
        Text(
          l10n.nextFire(
            formatMixed(first, DateTime.now(), l10n.yesterday),
            draft!.label(l10n),
          ),
          style: const TextStyle(color: LoopColors.mint, fontSize: 12),
        ),
      ],
    ];
  }

  /// 정보 모드 — 루프 상태 + 원본 이동 + 이어쓰기 + 중지.
  Widget _infoMode(AppLocalizations l10n) {
    final rule = widget.rule!;
    final active = rule.stoppedAt == null && rule.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상태 — 주기 · N회째 · 다음 발화 (종료면 종료 문구)
        Row(
          children: [
            const Icon(Icons.repeat, size: 15, color: LoopColors.mint),
            const SizedBox(width: 6),
            Text(
              rule.label(l10n),
              style: const TextStyle(
                color: LoopColors.mint,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: LoopSpacing.s),
        if (active) ...[
          Text(
            l10n.loopNextShort(
              formatMixed(rule.nextFireAt, DateTime.now(), l10n.yesterday),
            ),
            style: const TextStyle(color: LoopColors.text, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.loopFireCount(rule.fireCount),
            style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
          ),
        ] else
          Text(
            l10n.loopEndedInfo,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
        const SizedBox(height: LoopSpacing.m),
        if (widget.canJump)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: LoopColors.mint,
              side: const BorderSide(color: LoopColors.mint),
            ),
            onPressed: () => Navigator.pop(context, const LoopJump()),
            icon: const Icon(Icons.undo, size: 18),
            label: Text(l10n.loopJump),
          ),
        if (widget.canJump) const SizedBox(height: LoopSpacing.s),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LoopColors.lavender,
            foregroundColor: LoopColors.bg,
          ),
          onPressed: () => Navigator.pop(context, const LoopWriteNow()),
          child: Text(l10n.loopWriteNow),
        ),
        if (active) ...[
          const SizedBox(height: LoopSpacing.s),
          TextButton(
            onPressed: () => Navigator.pop(context, const LoopStop()),
            child: Text(
              l10n.loopStop,
              style: const TextStyle(color: LoopColors.danger, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

/// 알림/알람 선택 카드 — Loop 시트와 작성창 예약 시트가 공유한다.
/// (docs/mockups C안, 2026-10-18)
class LoopModeCard extends StatelessWidget {
  const LoopModeCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(LoopSpacing.s + 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AA78BFA) : LoopColors.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? LoopColors.lavender : LoopColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? LoopColors.lavender : LoopColors.textDim,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? LoopColors.lavender : LoopColors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              style: const TextStyle(
                color: LoopColors.textDim,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 추천 칩 라벨 — 간격 옆에 작은 "추천" 배지를 얹어 망각곡선 추천을
/// 눈에 보이게 한다. (2026-10-19 사용자 요청)
Widget recommendedChipLabel(String label, AppLocalizations l10n) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: LoopColors.mint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          l10n.recommended,
          style: const TextStyle(
            color: LoopColors.bg,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
