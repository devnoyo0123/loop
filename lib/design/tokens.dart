import 'package:flutter/material.dart';

/// Deep Night 테마의 색·간격 토큰. (docs/ui-design.md 참고)
abstract final class LoopColors {
  static const bg = Color(0xFF0B0D12);
  static const surface = Color(0xFF12151D);
  static const surfaceHi = Color(0xFF1A1E2A);
  static const text = Color(0xFFE8EAF2);
  static const textDim = Color(0xFF8B90A0);
  static const lavender = Color(0xFFA78BFA);
  static const mint = Color(0xFF7DE2C3);
  static const line = Color(0xFF262B3A);
  static const danger = Color(0xFFE5727F);
}

abstract final class LoopSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

/// Loop 앱 테마. 컴포넌트는 Material 3, 톤만 여기서 입힌다.
ThemeData buildLoopTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: LoopColors.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: LoopColors.bg,
      primary: LoopColors.lavender,
      onPrimary: LoopColors.bg,
      secondary: LoopColors.mint,
      onSecondary: LoopColors.bg,
      error: LoopColors.danger,
      onSurface: LoopColors.text,
      onSurfaceVariant: LoopColors.textDim,
      outlineVariant: LoopColors.line,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: LoopColors.text,
      displayColor: LoopColors.text,
    ),
    dividerColor: LoopColors.line,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LoopColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(backgroundColor: LoopColors.surfaceHi),
    timePickerTheme: TimePickerThemeData(backgroundColor: LoopColors.surfaceHi),
  );
}
