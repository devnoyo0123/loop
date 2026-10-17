import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/log_entry.dart';
import '../models/repeat_rule.dart';
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

/// 한 번 알림 예약.
class LoopOnce extends LoopResult {
  const LoopOnce(this.at, {this.asAlarm = false});

  final DateTime at;

  /// 알람처럼(무음 무시·꺼야 멈춤·전체화면) 울릴지. (2026-10-18)
  final bool asAlarm;
}

/// 반복 루프 생성 — 발화마다 이 로그의 이어쓰기가 자동 생성.
class LoopRepeat extends LoopResult {
  const LoopRepeat(this.draft);

  final RepeatDraft draft;
}

/// 진행 중인 루프 중지.
class LoopStop extends LoopResult {
  const LoopStop();
}

/// 원본 로그가 있는 날로 이동 (반복 발화 로그에서만 제공).
class LoopJump extends LoopResult {
  const LoopJump();
}

/// 한 번 알림의 시각을 고르는 전용 시트 — 작성창의 ⏰ 버튼이 쓴다.
/// (로그 메뉴의 알림은 통합 Loop 시트로 흡수됨)
class LoopOncePicker extends StatefulWidget {
  const LoopOncePicker({super.key, this.initial});

  /// 이미 예약돼 있던 시각. (다시 걸 때 초기값)
  final DateTime? initial;

  static Future<DateTime?> show(BuildContext context, {DateTime? initial}) =>
      showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        // 키보드가 올라오면 시트를 같이 올려 마지막 버튼이 가리지 않게.
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(child: LoopOncePicker(initial: initial)),
        ),
      );

  @override
  State<LoopOncePicker> createState() => _LoopOncePickerState();
}

class _LoopOncePickerState extends State<LoopOncePicker> {
  late DateTime _at =
      widget.initial ?? DateTime.now().add(const Duration(minutes: 10));

  /// 초기 선택 — 새로 예약이면 10분 후(기본값과 일치), 다시 걸기면 직접.
  late int _quick = widget.initial == null ? 0 : -1;

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

  void _pickQuick(int i) {
    setState(() {
      _quick = i;
      _at = DateTime.now().add(_quickDurations[i]);
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
    });
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
          const SizedBox(height: LoopSpacing.m),
          Wrap(
            spacing: LoopSpacing.s,
            runSpacing: LoopSpacing.s,
            children: [
              for (var i = 0; i < _quickDurations.length; i++)
                ChoiceChip(
                  label: Text(quickLabels[i]),
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
            ),
            onPressed: () => Navigator.pop(context, _at),
            child: Text(l10n.notifyAtThisTime),
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
      child: SingleChildScrollView(
        child: LoopSheet(
          log: log,
          source: source,
          rule: rule,
          canJump: canJump,
        ),
      ),
    ),
  );

  @override
  State<LoopSheet> createState() => _LoopSheetState();
}

class _LoopSheetState extends State<LoopSheet> {
  /// 반복 주기 프리셋 — kind가 null이면 "직접 입력" 마커. (라벨은 l10n으로)
  static const _presets = [
    (RepeatKind.minutes, 10),
    (RepeatKind.minutes, 30),
    (RepeatKind.hours, 1),
    (RepeatKind.hours, 3),
    (RepeatKind.hours, 6),
    (RepeatKind.daily, null),
    (RepeatKind.weekday, null), // 평일 — 토·일·공휴일 제외
    (null, null), // 주기 직접 입력
  ];

  String _presetLabel(AppLocalizations l10n, int i) => switch (i) {
    0 => l10n.preset10min,
    1 => l10n.preset30min,
    2 => l10n.preset1hour,
    3 => l10n.preset3hours,
    4 => l10n.preset6hours,
    5 => l10n.presetDaily,
    6 => l10n.presetWeekday,
    _ => l10n.custom,
  };

  // --- 거는 모드 상태 ---
  int _mode = 0; // 0 = 한 번, 1 = 반복 — 알림은 옵션이지만 기본은 한 번

  /// 실제 적용값도 곡선을 따른다 — 기본 _at은 추천 간격에서 시작.
  late DateTime _at = DateTime.now().add(
    LoopSheet.curve[LoopSheet.curveIndexFor(widget.log.loopCount)],
  );
  late int _quick = LoopSheet.curveIndexFor(widget.log.loopCount);
  int _selected = 0; // 반복 프리셋 — 10분 기본
  final _customController = TextEditingController();
  bool _customInHours = false;
  TimeOfDay _dailyTime = TimeOfDay.now();

  /// 이 루프를 알람처럼 울릴지 — "진짜 언제 알려줘라"용. (기본 알림)
  bool _asAlarm = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool get _isCustom => _presets[_selected].$1 == null;

  /// 매일·평일 — 발화 시각(timeOfDay)을 고르는 프리셋.
  bool get _isDailyLike {
    final kind = _presets[_selected].$1;
    return kind == RepeatKind.daily || kind == RepeatKind.weekday;
  }

  RepeatDraft? get _draft {
    final preset = _presets[_selected];
    final kind = preset.$1;
    if (kind != null) {
      return RepeatDraft(
        kind: kind,
        everyN: preset.$2,
        // "HH:mm" 완전한 형태여야 한다 — 시간만 넣으면 파싱에서 RangeError가 났다.
        timeOfDay: _isDailyLike
            ? '${_two(_dailyTime.hour)}:${_two(_dailyTime.minute)}'
            : null,
      );
    }
    // 직접 입력
    final n = int.tryParse(_customController.text.trim());
    if (n == null || n <= 0) return null;
    return RepeatDraft(
      kind: _customInHours ? RepeatKind.hours : RepeatKind.minutes,
      everyN: n,
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  void _pickQuick(int i) {
    setState(() {
      _quick = i;
      _at = DateTime.now().add(LoopSheet.curve[i]);
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
    });
  }

  Future<void> _pickDailyTime() async {
    final t = await showTimePicker(context: context, initialTime: _dailyTime);
    if (t != null) setState(() => _dailyTime = t);
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
              ? () => Navigator.pop(context, LoopOnce(_at, asAlarm: _asAlarm))
              : draft == null
              ? null
              : () => Navigator.pop(context, LoopRepeat(draft)),
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
    final curveIdx = LoopSheet.curveIndexFor(widget.log.loopCount);
    return [
      Text(
        l10n.loopCurveHint(widget.log.loopCount + 1, quickLabels[curveIdx]),
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
      const SizedBox(height: LoopSpacing.s),
      Wrap(
        spacing: LoopSpacing.s,
        runSpacing: LoopSpacing.s,
        children: [
          for (var i = 0; i < LoopSheet.curve.length; i++)
            ChoiceChip(
              label: Text(quickLabels[i]),
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
            onSelected: (_) => _pickCustomOnce(),
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
            child: _notifyModeCard(
              l10n,
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
              l10n,
              selected: _asAlarm,
              icon: Icons.alarm,
              title: l10n.modeAlarm,
              desc: l10n.modeAlarmDesc,
              onTap: () => setState(() => _asAlarm = true),
            ),
          ),
        ],
      ),
    ];
  }

  /// 알림/알람 선택 카드 — 루프마다 저장된다. (docs/mockups C안)
  Widget _notifyModeCard(
    AppLocalizations l10n, {
    required bool selected,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
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
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.unitMinutes)),
                ButtonSegment(value: true, label: Text(l10n.unitHours)),
              ],
              selected: {_customInHours},
              onSelectionChanged: (s) =>
                  setState(() => _customInHours = s.first),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(LoopColors.surfaceHi),
                foregroundColor: WidgetStatePropertyAll(LoopColors.textDim),
              ),
            ),
          ],
        ),
      ],
      if (_isDailyLike) ...[
        const SizedBox(height: LoopSpacing.m),
        Row(
          children: [
            Text(
              l10n.fireTime,
              style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
            ),
            const Spacer(),
            TextButton(
              onPressed: _pickDailyTime,
              child: Text(
                _dailyTime.format(context),
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
