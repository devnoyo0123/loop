import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/utils/video_duration.dart';

List<int> _u32(int v) =>
    [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

List<int> _u64(int v) => [..._u32(v >> 32), ..._u32(v & 0xffffffff)];

List<int> _box(String type, List<int> payload) => [
  ..._u32(8 + payload.length),
  ...type.codeUnits,
  ...payload,
];

/// 64비트 largesize 박스 — size 필드에 1이고 type 다음 8바이트가 실제 크기.
List<int> _box64(String type, List<int> payload) => [
  ..._u32(1),
  ...type.codeUnits,
  ..._u64(16 + payload.length),
  ...payload,
];

/// mvhd 페이로드 수공 빌드 — version 0/1.
List<int> _mvhd({
  required int timescale,
  required int duration,
  bool v1 = false,
}) => v1
    ? [1, 0, 0, 0, ..._u64(0), ..._u64(0), ..._u32(timescale), ..._u64(duration)]
    : [0, 0, 0, 0, ..._u32(0), ..._u32(0), ..._u32(timescale), ..._u32(duration)];

Uint8List _bytes(List<int> list) => Uint8List.fromList(list);

void main() {
  group('mp4DurationSeconds', () {
    test('version 0 mvhd — ftyp/mdat/moov 순서', () {
      final mp4 = _bytes([
        ..._box('ftyp', [1, 2, 3, 4]),
        ..._box('mdat', List.filled(64, 0xaa)),
        ..._box('moov', _box('mvhd', _mvhd(timescale: 600, duration: 18000))), // 30초
      ]);
      expect(mp4DurationSeconds(mp4), 30.0);
    });

    test('version 1 mvhd — 64비트 duration', () {
      final mp4 = _bytes([
        ..._box('moov', _box('mvhd', _mvhd(timescale: 1000, duration: 65000, v1: true))),
      ]);
      expect(mp4DurationSeconds(mp4), 65.0);
    });

    test('64비트 largesize moov 박스', () {
      final mp4 = _bytes([
        ..._box64('moov', _box('mvhd', _mvhd(timescale: 600, duration: 37800))), // 63초
      ]);
      expect(mp4DurationSeconds(mp4), 63.0);
    });

    test('EOF 박스(size=0) — moov가 파일 끝까지', () {
      final mp4 = _bytes([
        ..._box('ftyp', [1, 2, 3, 4]),
        ..._u32(0),
        ...'moov'.codeUnits,
        ..._box('mvhd', _mvhd(timescale: 600, duration: 12000)), // 20초
      ]);
      expect(mp4DurationSeconds(mp4), 20.0);
    });

    test('moov 없음 → null', () {
      final mp4 = _bytes([..._box('ftyp', [1, 2, 3, 4])]);
      expect(mp4DurationSeconds(mp4), isNull);
    });

    test('mvhd 없는 moov → null', () {
      final mp4 = _bytes([..._box('moov', _box('trak', List.filled(8, 0)))]);
      expect(mp4DurationSeconds(mp4), isNull);
    });

    test('timescale 0 → null', () {
      final mp4 = _bytes([
        ..._box('moov', _box('mvhd', _mvhd(timescale: 0, duration: 18000))),
      ]);
      expect(mp4DurationSeconds(mp4), isNull);
    });

    test('손상 — 박스 크기가 남은 데이터보다 큼 → null', () {
      final mp4 = _bytes([
        ..._u32(0xffffffff),
        ...'moov'.codeUnits,
        ...List.filled(16, 0),
      ]);
      expect(mp4DurationSeconds(mp4), isNull);
    });

    test('빈 바이트·너무 짧은 바이트 → null', () {
      expect(mp4DurationSeconds(_bytes([])), isNull);
      expect(mp4DurationSeconds(_bytes([1, 2, 3])), isNull);
    });
  });

  group('videoExceedsLimit — 기본 상한 1분 + 여유 2초', () {
    Uint8List video({required int timescale, required int duration}) => _bytes(
      [..._box('moov', _box('mvhd', _mvhd(timescale: timescale, duration: duration)))],
    );

    test('30초 → 통과', () {
      expect(videoExceedsLimit(video(timescale: 600, duration: 18000)), isFalse);
    });

    test('61초 → 통과 (여유 2초 안)', () {
      expect(videoExceedsLimit(video(timescale: 600, duration: 36600)), isFalse);
    });

    test('63초 → 거절', () {
      expect(videoExceedsLimit(video(timescale: 600, duration: 37800)), isTrue);
    });

    test('400초(카메라가 제한 무시) → 거절', () {
      expect(videoExceedsLimit(video(timescale: 1000, duration: 400000)), isTrue);
    });

    test('파싱 불가 → 통과 (fail-open)', () {
      expect(videoExceedsLimit(_bytes([1, 2, 3, 4, 5])), isFalse);
      expect(videoExceedsLimit(Uint8List(0)), isFalse);
    });

    test('상한 오버라이드 — 30초 제한에 40초 → 거절', () {
      final mp4 = video(timescale: 600, duration: 24000);
      expect(videoExceedsLimit(mp4, limit: const Duration(seconds: 30)), isTrue);
    });
  });
}
