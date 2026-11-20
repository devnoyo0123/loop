import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/nearby_share.dart';

/// 받는 쪽 알림 — 누가 보내는 중이면 하단에 진행 스낵바, 중단되면 알림.
/// 완료되면 치우고(받기 시트가 이어서 뜬다). 앱 어느 화면에 있든 보이도록
/// 루트 ScaffoldMessenger에 띄운다. (docs/share-design.md §6.3)
///
/// 상태는 [ShareReceiver.incoming]이 갖고, 이 클래스는 그리기만 한다.
class IncomingShareNotice {
  IncomingShareNotice({required this.receiver, required this.messenger});

  final ShareReceiver receiver;

  /// 루트 ScaffoldMessenger — 아직 앱이 안 그려졌으면 null.
  final ScaffoldMessengerState? Function() messenger;

  /// 진행 스낵바를 띄워 둔 상대 (없으면 null).
  String? _showingFor;

  void attach() => receiver.addListener(_changed);
  void detach() => receiver.removeListener(_changed);

  void _changed() {
    final inc = receiver.incoming;
    final m = messenger();
    if (inc == null || m == null) return;
    switch (inc.status) {
      case IncomingShareStatus.receiving:
        if (_showingFor == inc.endpointId) return; // 진행은 스낵바가 직접 갱신
        m.hideCurrentSnackBar();
        _showingFor = inc.endpointId;
        m.showSnackBar(
          SnackBar(
            key: const ValueKey('incoming-share-progress'),
            content: _IncomingProgress(receiver: receiver),
            // 끝날 때 이쪽에서 치운다 — 자동으로 사라지지 않게 넉넉히.
            duration: const Duration(hours: 1),
          ),
        );
      case IncomingShareStatus.completed:
        if (_showingFor != null) m.hideCurrentSnackBar();
        _showingFor = null;
        receiver.clearIncoming();
      case IncomingShareStatus.failed:
        if (_showingFor != null) m.hideCurrentSnackBar();
        _showingFor = null;
        m.showSnackBar(
          SnackBar(
            content: _IncomingFailed(name: inc.senderName),
            duration: const Duration(seconds: 4),
          ),
        );
        receiver.clearIncoming();
    }
  }
}

class _IncomingProgress extends StatelessWidget {
  const _IncomingProgress({required this.receiver});

  final ShareReceiver receiver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: receiver,
      builder: (context, _) {
        final inc = receiver.incoming;
        if (inc == null) return const SizedBox.shrink();
        final f = inc.fraction;
        final pct = f == null ? '' : ' · ${(f * 100).round()}%';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.receiveIncoming(inc.senderName)}$pct'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: f,
                minHeight: 4,
                color: LoopColors.mint,
                backgroundColor: LoopColors.surfaceHi,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IncomingFailed extends StatelessWidget {
  const _IncomingFailed({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) =>
      Text(AppLocalizations.of(context).receiveIncomingFailed(name));
}
