import 'dart:typed_data';

/// 동영상 녹화 상한. 카메라 인텐트(EXTRA_DURATION_LIMIT)와 앱 측 재검증
/// ([videoExceedsLimit])이 같은 값을 쓴다 — 두 군데가 어긋나면 허점이 생긴다.
const videoMaxDuration = Duration(minutes: 1);

/// 카메라가 제한을 살짝 넘게 기록하는 편차(세그먼트 경계, 마지막 프레임)를
/// 흡수한다. 60초 정확히 아니라도 61초 영상을 버리면 억울하다.
const _tolerance = Duration(seconds: 2);

/// mp4 본문에서 영화 헤더(moov→mvhd)를 찾아 길이(초)를 읽는다.
/// moov가 없거나 손상돼 읽을 수 없으면 null — 호출 쪽에서 fail-open 한다.
double? mp4DurationSeconds(Uint8List bytes) {
  final moov = _findBox(bytes, 0, bytes.length, 'moov');
  if (moov == null) return null;
  final mvhd = _findBox(
    bytes,
    moov.payloadStart,
    moov.end,
    'mvhd',
  );
  if (mvhd == null) return null;
  return _mvhdSeconds(bytes, mvhd.payloadStart, mvhd.end);
}

/// 받은 동영상이 상한([videoMaxDuration] + 여유 2초)을 넘는지.
/// 카메라 인텐트 제한을 무시하는 서드파티 카메라 앱이 있어서 받아서 한 번
/// 더 검문한다. 헤더를 못 읽는 형식은 통과 — 정상 영상을 버리는 쪽이 더
/// 나쁘다(fail-open).
bool videoExceedsLimit(
  Uint8List bytes, {
  Duration limit = videoMaxDuration,
}) {
  final seconds = mp4DurationSeconds(bytes);
  if (seconds == null) return false;
  final maxSeconds = (limit + _tolerance).inMicroseconds / 1e6;
  return seconds > maxSeconds;
}

class _Box {
  const _Box(this.start, this.headerSize, this.end);

  final int start;
  final int headerSize;

  /// 끝(배타).
  final int end;

  int get payloadStart => start + headerSize;
}

/// [from, to) 범위에서 최상위/자식 박스를 걸어가며 [type]을 찾는다.
/// mdat처럼 큰 박스는 내용을 읽지 않고 크기로만 건너뛴다.
_Box? _findBox(Uint8List b, int from, int to, String type) {
  var off = from;
  while (off + 8 <= to) {
    final size = _u32(b, off);
    var header = 8;
    var actual = size;
    if (size == 1) {
      if (off + 16 > to) return null;
      actual = _u64(b, off + 8); // largesize
      header = 16;
    } else if (size == 0) {
      actual = to - off; // EOF 박스
    }
    if (actual < header || off + actual > to) return null; // 손상
    if (_typeAt(b, off + 4) == type) return _Box(off, header, off + actual);
    off += actual;
  }
  return null;
}

/// mvhd 페이로드: version(1)+flags(3) 다음에 version 0은
/// creation(4)·modification(4)·timescale(4)·duration(4), version 1은
/// creation(8)·modification(8)·timescale(4)·duration(8).
double? _mvhdSeconds(Uint8List b, int payload, int end) {
  if (payload + 4 > end) return null;
  final version = b[payload];
  int timescale;
  int duration;
  if (version == 1) {
    if (payload + 28 > end) return null;
    timescale = _u32(b, payload + 20);
    duration = _u64(b, payload + 24);
  } else {
    if (payload + 20 > end) return null;
    timescale = _u32(b, payload + 12);
    duration = _u32(b, payload + 16);
  }
  if (timescale == 0) return null;
  return duration / timescale;
}

int _u32(Uint8List b, int off) =>
    (b[off] << 24) | (b[off + 1] << 16) | (b[off + 2] << 8) | b[off + 3];

int _u64(Uint8List b, int off) => (_u32(b, off) << 32) | _u32(b, off + 4);

String _typeAt(Uint8List b, int off) =>
    String.fromCharCodes(b.sublist(off, off + 4));
