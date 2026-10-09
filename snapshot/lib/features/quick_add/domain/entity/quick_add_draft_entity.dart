import 'dart:convert';

import 'package:equatable/equatable.dart';

/// An in-progress quick-add entry that has not yet been saved.
///
/// Persisted as JSON so a half-filled quick-add form survives the app being
/// backgrounded or killed. Pure Dart — no framework dependencies.
class QuickAddDraftEntity extends Equatable {
  final String kcal;
  final String protein;
  final String carbs;
  final String fat;
  final String label;
  final String mealSlot;

  const QuickAddDraftEntity({
    this.kcal = '',
    this.protein = '',
    this.carbs = '',
    this.fat = '',
    this.label = '',
    this.mealSlot = 'snack',
  });

  /// True when nothing worth restoring has been entered. A draft with only a
  /// meal slot selected (which always has a value) is still considered empty.
  bool get isEmpty =>
      kcal.trim().isEmpty &&
      protein.trim().isEmpty &&
      carbs.trim().isEmpty &&
      fat.trim().isEmpty &&
      label.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'label': label,
        'mealSlot': mealSlot,
      };

  factory QuickAddDraftEntity.fromJson(Map<String, dynamic> json) =>
      QuickAddDraftEntity(
        kcal: json['kcal'] as String? ?? '',
        protein: json['protein'] as String? ?? '',
        carbs: json['carbs'] as String? ?? '',
        fat: json['fat'] as String? ?? '',
        label: json['label'] as String? ?? '',
        mealSlot: json['mealSlot'] as String? ?? 'snack',
      );

  String encode() => jsonEncode(toJson());

  /// Decodes a stored draft. Returns null on malformed input rather than
  /// throwing, so a corrupt value never blocks opening the quick-add screen.
  static QuickAddDraftEntity? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return QuickAddDraftEntity.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [kcal, protein, carbs, fat, label, mealSlot];
}
