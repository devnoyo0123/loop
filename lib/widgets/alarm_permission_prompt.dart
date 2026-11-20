import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/alarm_permission.dart';

/// "알람이 화면에 뜨려면 권한이 필요해요" — 조건은 [AlarmPermissionGuard]가
/// 정하고, 여기선 보여주고 고른 결과만 돌려준다.
class AlarmPermissionPrompt {
  AlarmPermissionPrompt._();

  /// 필요할 때만 띄운다. [설정 열기]면 설정으로, [나중에]면 유예.
  static Future<void> maybeShow(
    BuildContext context,
    AlarmPermissionGuard guard, {
    bool force = false,
    bool requirePending = true,
  }) async {
    if (!await guard.shouldPrompt(
      force: force,
      requirePending: requirePending,
    )) {
      return;
    }
    if (!context.mounted) return;
    guard.markShowing(true);
    final l10n = AppLocalizations.of(context);
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('alarm-permission-prompt'),
        icon: const Icon(Icons.alarm, color: LoopColors.lavender),
        title: Text(l10n.alarmPermTitle),
        content: Text(l10n.alarmPermBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.laterAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: LoopColors.lavender,
              foregroundColor: LoopColors.bg,
            ),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    guard.markShowing(false);
    if (open == true) {
      await guard.openSettings();
    } else {
      guard.dismiss();
    }
  }
}
