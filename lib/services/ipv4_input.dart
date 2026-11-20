import 'dart:io';

import 'package:flutter/services.dart';

/// 맥 주소 입력 보조 — PC 연결 화면의 호스트 칸. (포트는 앱에 고정)

/// 붙여넣은 주소에서 스킴·경로·포트를 떼고 호스트만 남긴다.
/// `http://192.168.35.8:8766/` → `192.168.35.8`. 콜론이 둘 이상(IPv6)이면 그대로.
String sanitizeHost(String raw) {
  var s = raw.trim();
  final scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').firstMatch(s);
  if (scheme != null) s = s.substring(scheme.end);
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(0, slash);
  if (':'.allMatches(s).length == 1) s = s.substring(0, s.indexOf(':'));
  return s.trim();
}

/// IPv4를 점 없이 칠 수 있게 — 옥텟이 확정되면 "."를 자동으로 넣는다.
/// 확정: 3자리, 다음 숫자를 붙이면 255 초과, 또는 "0"(앞자리 0 없음).
/// 글자가 섞이면(호스트명 `mac.local`) 손대지 않는다.
/// 커서가 끝에 있을 때만 정리하고, 중간 편집은 허용 문자만 거른다.
class Ipv4InputFormatter extends TextInputFormatter {
  const Ipv4InputFormatter();

  static final _letters = RegExp('[a-zA-Z]');
  static final _notIp = RegExp(r'[^0-9.]');
  static final _fullIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 미리 채운 서브넷 뒤에 전체 주소를 붙여넣으면 붙여넣은 것만 쓴다.
    final old = oldValue.text;
    final pasted = newValue.text.length > old.length + 1 &&
            newValue.text.startsWith(old)
        ? sanitizeHost(newValue.text.substring(old.length)).replaceAll(',', '.')
        : '';
    final text =
        _fullIp.hasMatch(pasted) ? pasted : sanitizeHost(newValue.text);
    if (_letters.hasMatch(text)) return newValue; // 호스트명

    final sel = newValue.selection;
    final atEnd = sel.isCollapsed && sel.baseOffset == newValue.text.length;
    if (!atEnd) {
      // 중간 편집 — 거르기만 하고 커서는 지운 만큼 당긴다.
      if (!_notIp.hasMatch(newValue.text)) return newValue;
      final raw = newValue.text.replaceAll(',', '.');
      final before = sel.baseOffset.clamp(0, raw.length);
      final head = raw.substring(0, before).replaceAll(_notIp, '');
      final all = raw.replaceAll(_notIp, '');
      return TextEditingValue(
        text: all,
        selection: TextSelection.collapsed(offset: head.length),
      );
    }

    final octets = _octets(text.replaceAll(',', '.').replaceAll(_notIp, ''));
    var out = octets.join('.');
    // 글자를 지우는 중이 아니면 확정된 옥텟 뒤에 바로 "."를 보여준다.
    // (지울 때 다시 붙이면 백스페이스가 점에 걸린다)
    final deleting = newValue.text.length < old.length;
    if (!deleting && octets.length < 4 && _complete(octets.last)) out += '.';
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  /// 숫자·점 문자열을 최대 4개 옥텟으로. 빈 옥텟 뒤 점(선행·연속)은 버리고,
  /// 4번째 옥텟이 차면 나머지는 버린다. 끝의 빈 옥텟은 수동 "."를 뜻한다.
  static List<String> _octets(String s) {
    final octets = <String>[''];
    for (final ch in s.split('')) {
      final cur = octets.last;
      if (ch == '.') {
        if (cur.isEmpty || octets.length == 4) continue;
        octets.add('');
      } else if (cur.isNotEmpty &&
          (_complete(cur) || int.parse(cur + ch) > 255)) {
        if (octets.length == 4) break;
        octets.add(ch);
      } else {
        octets[octets.length - 1] = cur + ch;
      }
    }
    return octets;
  }

  /// 어떤 숫자를 더 붙여도 유효한 옥텟이 될 수 없음.
  static bool _complete(String o) =>
      o.isNotEmpty && (o.length == 3 || o == '0' || int.parse(o) * 10 > 255);
}

/// 폰이 붙은 Wi-Fi의 서브넷 앞부분("192.168.35.")을 찾는다. 테스트는 가짜로 대체.
typedef SubnetPrefixLookup = Future<String?> Function();

/// 사설 IPv4 중 wlan* > 192.168 순으로 고른다. 셀룰러·VPN 인터페이스는 제외.
Future<String?> wifiSubnetPrefix() async {
  try {
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    String? best;
    var bestScore = -1;
    for (final i in ifaces) {
      final name = i.name.toLowerCase();
      if (RegExp(r'^(rmnet|ccmni|pdp|v4-|tun|ppp|dummy)').hasMatch(name)) {
        continue;
      }
      for (final a in i.addresses) {
        if (a.isLoopback) continue;
        final p = a.address.split('.').map(int.tryParse).toList();
        if (p.length != 4 || p.contains(null)) continue;
        final home = p[0] == 192 && p[1] == 168;
        final private = home ||
            p[0] == 10 ||
            (p[0] == 172 && p[1]! >= 16 && p[1]! <= 31);
        if (!private) continue;
        final score = (name.startsWith('wlan') ? 2 : 0) + (home ? 1 : 0);
        if (score > bestScore) {
          bestScore = score;
          best = '${p[0]}.${p[1]}.${p[2]}.';
        }
      }
    }
    return best;
  } catch (_) {
    return null;
  }
}
