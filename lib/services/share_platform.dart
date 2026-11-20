import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 공유가 OS에 묻는 것들의 경계 — 권한·기기 이름. 앱 로직(nearby_share.dart)은
/// 이 인터페이스만 알고, 테스트는 가짜 구현을 꽂는다.
abstract class SharePlatform {
  /// 근거리 공유를 지원하는 플랫폼인가 (v1: Android만).
  bool get supported;

  /// 필요한 권한이 이미 모두 허용됐는가 — 팝업 없이 상태만 본다.
  Future<bool> hasPermissions();

  /// 필요한 권한을 요청한다 — 하나라도 거부되면 false.
  Future<bool> requestPermissions();

  /// 표시명이 비었을 때 쓰는 기기 이름 ("민수의 Galaxy S25" 등).
  Future<String> deviceName();
}

/// Nearby Connections가 요구하는 런타임 권한 — API 레벨별.
/// (developers.google.com/nearby/connections/android/get-started 매니페스트 표)
///
/// - 33+ : 블루투스 3종 + NEARBY_WIFI_DEVICES (위치 불필요, neverForLocation)
/// - 31~32: 블루투스 3종 + 정밀 위치
/// - ~30 : 위치만 (BLUETOOTH/ADMIN은 일반 권한이라 요청 불필요)
///
/// NEARBY_WIFI_DEVICES를 32 이하에서 요청하면 permission_handler가 denied를
/// 돌려준다 — 그래서 무조건 목록에 넣으면 구형 폰에서 공유가 막힌다.
/// ACCESS_LOCAL_NETWORK(37+)는 targetSdk 37 앱의 WIFI_LAN 경로에만 필요하고
/// 현재 targetSdk는 36이라 제외. targetSdk를 올리면 여기에 추가할 것.
List<Permission> requiredSharePermissions(int sdkInt) {
  if (sdkInt >= 33) {
    return [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ];
  }
  if (sdkInt >= 31) {
    return [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }
  return [Permission.locationWhenInUse];
}

/// [SharePlatform]의 실제 구현 — permission_handler + 네이티브 채널.
class DeviceSharePlatform implements SharePlatform {
  DeviceSharePlatform();

  static const _ch = MethodChannel('app.loop/browser');

  Map<String, Object?>? _info;

  Future<Map<String, Object?>> _deviceInfo() async {
    if (_info != null) return _info!;
    try {
      final raw = await _ch.invokeMapMethod<String, Object?>('deviceInfo');
      _info = raw ?? const {};
    } catch (_) {
      _info = const {};
    }
    return _info!;
  }

  Future<List<Permission>> _required() async {
    final sdk = (await _deviceInfo())['sdkInt'] as int? ?? 0;
    // 모르면 가장 최신 기준 — 구형 기준(위치만)으로 가면 블루투스가 빠진다.
    return requiredSharePermissions(sdk == 0 ? 33 : sdk);
  }

  @override
  bool get supported => Platform.isAndroid;

  @override
  Future<bool> hasPermissions() async {
    for (final p in await _required()) {
      if (!await p.isGranted) return false;
    }
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    await (await _required()).request();
    // 요청 결과를 믿지 않고 상태를 다시 본다 — 위치 요청 결과는 COARSE
    // 기준이라 Android 12에서 "대략적 위치"만 골라도 granted로 오지만,
    // Nearby는 정밀 위치가 필요하다. 상태 확인은 가장 엄격한 쪽을 본다.
    return hasPermissions();
  }

  @override
  Future<String> deviceName() async {
    final info = await _deviceInfo();
    final name = (info['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final model = (info['model'] as String?)?.trim();
    return model == null || model.isEmpty ? 'Loop' : model;
  }
}
