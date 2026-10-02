import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/label_scan/data/pending_label_scan_queue.dart';

void main() {
  late Directory tempDir;
  late PendingLabelScanQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pending_scan_test');
    queue = PendingLabelScanQueue(
        baseDirProvider: () async => Directory('${tempDir.path}/q'));
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Uint8List bytes(int n) => Uint8List.fromList(List.filled(n, 1));

  group('PendingLabelScanQueue', () {
    test('starts empty', () async {
      expect(await queue.count(), 0);
      expect(await queue.pending(), isEmpty);
    });

    test('enqueue persists image and records it in the manifest', () async {
      final entry = await queue.enqueue(bytes(10), 'image/jpeg');

      expect(await queue.count(), 1);
      expect(await File(entry.imagePath).exists(), isTrue);
      expect(entry.imagePath, endsWith('.jpg'));
      expect(entry.queuedAt.isUtc, isTrue);

      final pending = await queue.pending();
      expect(pending.single.id, entry.id);
      expect(pending.single.mimeType, 'image/jpeg');
    });

    test('enqueue uses the correct extension per mime type', () async {
      final png = await queue.enqueue(bytes(5), 'image/png');
      expect(png.imagePath, endsWith('.png'));
    });

    test('remove deletes the entry and its image file', () async {
      final a = await queue.enqueue(bytes(3), 'image/jpeg');
      final b = await queue.enqueue(bytes(3), 'image/png');
      expect(await queue.count(), 2);

      await queue.remove(a.id);

      expect(await queue.count(), 1);
      expect(await File(a.imagePath).exists(), isFalse);
      expect(await File(b.imagePath).exists(), isTrue);
      expect((await queue.pending()).single.id, b.id);
    });

    test('survives a fresh queue instance (persisted manifest)', () async {
      await queue.enqueue(bytes(4), 'image/jpeg');

      final reopened = PendingLabelScanQueue(
          baseDirProvider: () async => Directory('${tempDir.path}/q'));
      expect(await reopened.count(), 1);
    });
  });
}
