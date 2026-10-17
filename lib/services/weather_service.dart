import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';

/// 저장 순간의 날씨 캡처 결과.
class WeatherCapture {
  const WeatherCapture({required this.code, required this.temperatureC});

  /// WMO weather code.
  final int code;

  /// 기온 ℃.
  final double temperatureC;
}

/// Open-Meteo 현재 날씨 조회 — 무료, API 키 불필요. (docs/ui-design.md)
/// 실패·타임아웃 시 null을 돌려줄 뿐, 로그 저장을 막지 않는다.
class WeatherService {
  static const _timeout = Duration(seconds: 3);

  static Future<WeatherCapture?> fetch({
    required double latitude,
    required double longitude,
  }) async {
    HttpClient? client;
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code',
      });

      client = HttpClient()..connectionTimeout = _timeout;
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body =
          await response.transform(utf8.decoder).join().timeout(_timeout);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      return WeatherCapture(
        code: (current['weather_code'] as num).toInt(),
        temperatureC: (current['temperature_2m'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }
}

/// WMO 코드의 표시 그룹 — 라벨 문자열은 다국어(l10n)로, 여기선 종류만.
enum WmoKind { clear, partly, cloudy, fog, drizzle, rain, snow, thunder, unknown }

/// WMO weather interpretation code → 화면 표시용 아이콘·종류·색.
abstract final class Wmo {
  static ({IconData icon, WmoKind kind, Color color}) describe(int code) {
    switch (code) {
      case 0:
      case 1:
        return (icon: Icons.wb_sunny, kind: WmoKind.clear, color: LoopColors.mint);
      case 2:
        return (
          icon: Icons.wb_cloudy,
          kind: WmoKind.partly,
          color: LoopColors.textDim
        );
      case 3:
        return (icon: Icons.cloud, kind: WmoKind.cloudy, color: LoopColors.textDim);
      case 45:
      case 48:
        return (icon: Icons.blur_on, kind: WmoKind.fog, color: LoopColors.textDim);
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return (
          icon: Icons.water_drop,
          kind: WmoKind.drizzle,
          color: LoopColors.lavender
        );
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return (icon: Icons.umbrella, kind: WmoKind.rain, color: LoopColors.lavender);
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return (icon: Icons.ac_unit, kind: WmoKind.snow, color: LoopColors.text);
      case 95:
      case 96:
      case 99:
        return (icon: Icons.bolt, kind: WmoKind.thunder, color: LoopColors.danger);
      default:
        return (
          icon: Icons.cloud,
          kind: WmoKind.unknown,
          color: LoopColors.textDim
        );
    }
  }

  /// 종류 → 다국어 라벨.
  static String label(AppLocalizations l10n, WmoKind kind) => switch (kind) {
        WmoKind.clear => l10n.wmoClear,
        WmoKind.partly => l10n.wmoPartly,
        WmoKind.cloudy => l10n.wmoCloudy,
        WmoKind.fog => l10n.wmoFog,
        WmoKind.drizzle => l10n.wmoDrizzle,
        WmoKind.rain => l10n.wmoRain,
        WmoKind.snow => l10n.wmoSnow,
        WmoKind.thunder => l10n.wmoThunder,
        WmoKind.unknown => l10n.wmoUnknown,
      };
}
