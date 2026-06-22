/// Helpers for parsing values out of Mealie's API JSON.
///
/// Mealie stores nutrition fields as strings (it coerces numbers to strings on
/// the way out), and real-world values can be null, empty, a plain number
/// ("250", "12.5"), use a comma decimal, or carry a trailing unit ("12.5 g").
/// [mealieToDouble] tolerates all of these and returns null when no number can
/// be read, so a missing or malformed field never throws.
double? mealieToDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final normalised = raw.replaceAll(',', '.');
  final direct = double.tryParse(normalised);
  if (direct != null) return direct;

  // Tolerate a leading number with trailing text, e.g. "12.5 g".
  final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(normalised);
  if (match != null) return double.tryParse(match.group(0)!);

  return null;
}
