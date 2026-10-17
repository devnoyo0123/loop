import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// 저장 순간의 위치 캡처 결과.
class LocationCapture {
  const LocationCapture(this.latitude, this.longitude, this.place);

  final double latitude;
  final double longitude;

  /// 역지오코딩한 장소명. (예: "서울특별시 성동구") 실패 시 null.
  final String? place;
}

/// 로그 저장 시점 자동 위치 캡처. (docs/ui-design.md)
/// 어떤 단계가 실패해도 null을 돌려줄 뿐 — 로그 저장 자체는 막지 않는다.
class LocationService {
  /// 위치 자동 캡처 ON/OFF — 설정 시트의 스위치가 바꾼다. (기본 ON)
  /// 꺼져 있으면 장소뿐 아니라 날씨도 안 붙는다(_attachContext가 통째로 건너뜀).
  static bool enabled = true;

  static Future<LocationCapture?> capture() async {
    if (!enabled) return null;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // 로그용이라 대략적인 위치면 충분
          timeLimit: Duration(seconds: 5),
        ),
      );

      final place = await _placeName(position.latitude, position.longitude);
      return LocationCapture(position.latitude, position.longitude, place);
    } catch (_) {
      return null;
    }
  }

  /// 좌표 → "서울특별시 성동구" 식 장소명. OS 내장 역지오코딩 사용.
  static Future<String?> _placeName(double latitude, double longitude) async {
    try {
      final placemarks =
          await Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[];
      for (final part in [
        p.administrativeArea,
        p.locality,
        p.subLocality,
      ]) {
        if (part == null || part.isEmpty) continue;
        if (!parts.contains(part)) parts.add(part);
      }
      return parts.isEmpty ? null : parts.join(' ');
    } catch (_) {
      return null;
    }
  }
}
