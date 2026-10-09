import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:path_provider/path_provider.dart';

/// A label-scan photo captured while the device was offline, persisted to disk
/// so it can be processed once connectivity returns.
class PendingLabelScan {
  final String id;
  final String imagePath;
  final String mimeType;
  final DateTime queuedAt;

  const PendingLabelScan({
    required this.id,
    required this.imagePath,
    required this.mimeType,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'mimeType': mimeType,
        // Stored UTC for consistency with the rest of the app's timestamps.
        'queuedAt': queuedAt.toUtc().toIso8601String(),
      };

  factory PendingLabelScan.fromJson(Map<String, dynamic> json) =>
      PendingLabelScan(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        mimeType: json['mimeType'] as String,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );
}

/// File-based queue of label-scan photos that could not be processed because
/// the device was offline. Images are written to a dedicated directory with a
/// JSON manifest alongside, so they survive app restarts.
///
/// The base directory is injectable so the queue can be unit-tested without
/// touching the real application-documents directory.
class PendingLabelScanQueue {
  final _log = Logger('PendingLabelScanQueue');
  final Future<Directory> Function() _baseDirProvider;

  PendingLabelScanQueue({Future<Directory> Function()? baseDirProvider})
      : _baseDirProvider =
            baseDirProvider ?? _defaultBaseDirProvider;

  static Future<Directory> _defaultBaseDirProvider() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/pending_label_scans');
  }

  Future<Directory> _ensureDir() async {
    final dir = await _baseDirProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _manifestFile(Directory dir) => File('${dir.path}/manifest.json');

  /// Persists a captured image and records it in the manifest. Returns the
  /// queued entry.
  Future<PendingLabelScan> enqueue(
      Uint8List imageBytes, String mimeType) async {
    final dir = await _ensureDir();
    final id = IdGenerator.getUniqueID();
    final ext = _extensionForMime(mimeType);
    final imageFile = File('${dir.path}/$id$ext');
    await imageFile.writeAsBytes(imageBytes, flush: true);

    final entry = PendingLabelScan(
      id: id,
      imagePath: imageFile.path,
      mimeType: mimeType,
      queuedAt: DateTime.now().toUtc(),
    );

    final entries = await _readManifest(dir)..add(entry);
    await _writeManifest(dir, entries);
    _log.fine('Queued offline label scan $id (${imageBytes.length} bytes)');
    return entry;
  }

  /// All currently-queued scans, oldest first.
  Future<List<PendingLabelScan>> pending() async {
    final dir = await _ensureDir();
    return _readManifest(dir);
  }

  Future<int> count() async => (await pending()).length;

  /// Removes a processed scan from the queue and deletes its image file.
  Future<void> remove(String id) async {
    final dir = await _ensureDir();
    final entries = await _readManifest(dir);
    final match = entries.where((e) => e.id == id).toList();
    entries.removeWhere((e) => e.id == id);
    await _writeManifest(dir, entries);
    for (final e in match) {
      final f = File(e.imagePath);
      if (await f.exists()) await f.delete();
    }
    _log.fine('Removed queued label scan $id');
  }

  Future<List<PendingLabelScan>> _readManifest(Directory dir) async {
    final file = _manifestFile(dir);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingLabelScan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _log.severe('Failed to read pending-scan manifest', e, st);
      return [];
    }
  }

  Future<void> _writeManifest(
      Directory dir, List<PendingLabelScan> entries) async {
    final file = _manifestFile(dir);
    await file.writeAsString(
        jsonEncode(entries.map((e) => e.toJson()).toList()),
        flush: true);
  }

  String _extensionForMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }
}
