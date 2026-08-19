import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';

/// The photographs could not be turned into numbers. Not an error to shout
/// about: it is the ordinary case the hand-typed route exists for.
class LabelUnreadable implements Exception {
  final String message;

  LabelUnreadable(this.message);

  @override
  String toString() => 'LabelUnreadable: $message';
}

/// Asking the Mac Mini to read a photographed packet.
///
/// The Mini reads and answers; it saves nothing. What comes back is a draft
/// for somebody to look at, and the saving is a separate call made after they
/// have — which is the same call the hand-typed route makes, so typing a packet
/// in works exactly as well when the reading does not.
class HouseholdLabelReader {
  final HouseholdApi _api;

  /// How a file becomes the bytes that get sent. Replaceable so a test does not
  /// need real images on disk.
  final Future<List<int>> Function(String path) _readFile;

  HouseholdLabelReader(this._api,
      {Future<List<int>> Function(String path)? readFile})
      : _readFile = readFile ?? _readFromDisk;

  static Future<List<int>> _readFromDisk(String path) =>
      File(path).readAsBytes();

  /// Read the three photographs. Throws [LabelUnreadable] when nothing usable
  /// came back, and [HouseholdUnreachable] when the Mini could not be asked —
  /// two different things, because one means try typing it and the other means
  /// try again later.
  Future<FoodDraft> read(Map<String, String> shots) async {
    final encoded = <String, String>{};
    for (final entry in shots.entries) {
      encoded[entry.key] = base64Encode(await _readFile(entry.value));
    }
    final Map<String, dynamic> body;
    try {
      body = await _api.post('/household/label/read', {'shots': encoded},
          timeout: HouseholdApi.readingALabel);
    } on HouseholdRefused catch (e) {
      throw LabelUnreadable(e.message);
    }
    final candidate = body['candidate'];
    if (candidate is! Map<String, dynamic>) {
      throw LabelUnreadable('nothing readable came back from the photographs');
    }
    return FoodDraft.fromReading(
      candidate,
      unreadable: ((body['unreadable'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
