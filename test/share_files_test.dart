import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:loop/services/share_files.dart';

/// 공유 파일 청소 — 앱 전용 폴더 share/ 하나만 관리한다. (share-design.md §6.5)
void main() {
  late Directory root;
  late Directory dir;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('share_files_test');
    dir = await ShareTempFiles.dir(() async => root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  final now = DateTime(2026, 11, 1, 12);

  File make(String name, {Duration age = Duration.zero, int size = 1}) {
    final f = File('${dir.path}/$name')..writeAsBytesSync(List.filled(size, 7));
    f.setLastModifiedSync(now.subtract(age));
    return f;
  }

  test('공유 폴더는 캐시 아래 share/ — 없으면 만든다', () {
    expect(dir.path, '${root.path}/share');
    expect(dir.existsSync(), isTrue);
  });

  group('sweep — 주기 청소', () {
    test('오래된 파일(보내기·받다 만 part·받은 것)은 지운다', () async {
      final files = [
        make('loop-chain-1.looplog', age: const Duration(hours: 2)),
        make('in-E1-42.part', age: const Duration(hours: 2)),
        make('in-E1-43.looplog', age: const Duration(hours: 2)),
      ];
      expect(await ShareTempFiles.sweep(dir, now: now), 3);
      expect(files.any((f) => f.existsSync()), isFalse);
    });

    test('방금 만든 것은 둔다 (hold 전 경쟁 방지)', () async {
      final young = make('in-E1-1.looplog', age: const Duration(minutes: 3));
      expect(await ShareTempFiles.sweep(dir, now: now), 0);
      expect(young.existsSync(), isTrue);
    });

    test('쓰는 중(hold)인 것은 오래돼도 둔다', () async {
      final busy = make('in-E1-2.part', age: const Duration(hours: 3));
      ShareTempFiles.hold(busy.path);
      addTearDown(() => ShareTempFiles.release(busy.path));
      expect(await ShareTempFiles.sweep(dir, now: now), 0);
      ShareTempFiles.release(busy.path);
      expect(await ShareTempFiles.sweep(dir, now: now), 1);
    });

    test('공유 폴더 밖(캐시의 다른 파일)은 건드리지 않는다', () async {
      final outside = File('${root.path}/share-card.png')..writeAsStringSync('x');
      outside.setLastModifiedSync(now.subtract(const Duration(days: 3)));
      await ShareTempFiles.sweep(dir, now: now);
      expect(outside.existsSync(), isTrue);
    });

    test('폴더가 없으면 0', () async {
      expect(await ShareTempFiles.sweep(Directory('${root.path}/none')), 0);
    });
  });

  group('clear / usage — 설정의 수동 정리', () {
    test('사용량은 쓰는 중을 뺀 개수·바이트', () async {
      make('a.part', size: 100);
      make('b.looplog', size: 50);
      final busy = make('c.part', size: 1000);
      ShareTempFiles.hold(busy.path);
      addTearDown(() => ShareTempFiles.release(busy.path));
      expect(await ShareTempFiles.usage(dir), (files: 2, bytes: 150));
    });

    test('정리는 나이와 무관하게 전부 — 쓰는 중만 남긴다', () async {
      final young = make('a.part', size: 100);
      final busy = make('b.part', size: 10);
      ShareTempFiles.hold(busy.path);
      addTearDown(() => ShareTempFiles.release(busy.path));
      expect(await ShareTempFiles.clear(dir), (files: 1, bytes: 100));
      expect(young.existsSync(), isFalse);
      expect(busy.existsSync(), isTrue);
      expect(await ShareTempFiles.usage(dir), (files: 0, bytes: 0));
    });
  });

  group('ShareJanitor — 주기 청소', () {
    test('공유 폴더를 청소한다', () async {
      final old = make('in-E-1.part', age: const Duration(hours: 1));
      old.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
      final j = ShareJanitor(shareDir: () async => dir);
      expect(await j.sweep(), 1);
      expect(old.existsSync(), isFalse);
    });

    test('겹쳐 불리면 한 번만 돈다', () async {
      final gate = Completer<Directory>();
      var opened = 0;
      final j = ShareJanitor(
        shareDir: () {
          opened++;
          return gate.future;
        },
      );
      final a = j.sweep();
      final b = j.sweep();
      gate.complete(dir);
      await Future.wait([a, b]);
      expect(opened, 1);
    });

    test('주기 실행 — 멈추면 더 안 돈다', () async {
      var opened = 0;
      final j = ShareJanitor(
        shareDir: () async {
          opened++;
          return dir;
        },
        interval: const Duration(milliseconds: 20),
      )..startPeriodic();
      await Future<void>.delayed(const Duration(milliseconds: 75));
      j.stop();
      final n = opened;
      expect(n, greaterThanOrEqualTo(2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(opened, n);
    });

    test('폴더를 못 열어도 앱을 막지 않는다', () async {
      final j = ShareJanitor(
        shareDir: () async => throw const FileSystemException('no cache'),
      );
      expect(await j.sweep(), 0);
    });
  });
}
