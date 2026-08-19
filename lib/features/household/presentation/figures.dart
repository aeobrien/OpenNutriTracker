import 'package:flutter/material.dart';

/// Whether the person using this phone wants to see calorie figures.
///
/// One person in the household counts and one would rather not. The one who
/// would rather not still wants the plan, the diary and one-tap logging — she
/// simply does not want a number attached. So this is a display setting and
/// nothing else: the ledger underneath carries on counting, and turning the
/// figures back on shows a real history rather than a gap.
///
/// Placed near the root of the app, above everything that could show a figure.
/// Where it is absent — an isolated widget in a test, say — figures are on,
/// which is the safe default for a screen that has always shown them.
class FiguresScope extends InheritedWidget {
  final bool figuresOff;

  const FiguresScope({
    super.key,
    required this.figuresOff,
    required super.child,
  });

  static bool offIn(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FiguresScope>();
    return scope?.figuresOff ?? false;
  }

  @override
  bool updateShouldNotify(FiguresScope oldWidget) =>
      oldWidget.figuresOff != figuresOff;
}

/// The single place a calorie value becomes something a person can read.
///
/// Every calorie figure anywhere in the app goes through here. That is not
/// tidiness — it is the only way "turn every figure off" can stay true as
/// screens are added. A screen that formats its own number is a screen that
/// keeps showing it after the switch is thrown, and the person who asked not to
/// see calories finds one waiting on a portion sheet six months later. The
/// test at test/features/settings/figures_off_test.dart fails the build if a
/// calorie figure is assembled anywhere but here.
class Figures {
  const Figures._();

  static const label = 'kcal';

  /// The figure as text, or null when this person has them switched off.
  /// Callers that build a longer sentence use this and check for null.
  static String? kcal(BuildContext context, num? value, {int decimals = 0}) {
    if (value == null) return null;
    if (FiguresScope.offIn(context)) return null;
    return '${value.toStringAsFixed(decimals)} $label';
  }

  /// The figure on its own, ready to drop into a layout. Renders nothing at all
  /// when figures are off — not a blank, not a dash, not a gap where a number
  /// used to be.
  static Widget kcalText(
    BuildContext context,
    num? value, {
    TextStyle? style,
    int decimals = 0,
    TextAlign? textAlign,
    String? prefix,
    String? suffix,
  }) {
    final text = kcal(context, value, decimals: decimals);
    if (text == null) return const SizedBox.shrink();
    return Text('${prefix ?? ''}$text${suffix ?? ''}',
        style: style, textAlign: textAlign);
  }

  /// A figure that is part of a longer line ("320 kcal · 12g protein").
  /// Returns null when off so the caller can drop the whole segment rather than
  /// leaving a stray separator behind.
  static String? segment(BuildContext context, num? value, {int decimals = 0}) =>
      kcal(context, value, decimals: decimals);

  /// The "per 100g" form used on picker rows — the surface the review
  /// specifically expected to keep showing a figure after the switch was
  /// thrown, because it is easy to forget.
  static String? per100(BuildContext context, num? value) {
    if (value == null || FiguresScope.offIn(context)) return null;
    return '${value.round()} $label/100g';
  }

  static String per100WithSeparator(BuildContext context, num? value) {
    final text = per100(context, value);
    return text == null ? '' : '$text · ';
  }

  /// A calorie figure followed by the middle dot that separates it from what
  /// comes next, or an empty string when figures are off — so the line reads
  /// "P 12g · C 40g" rather than starting with an orphaned separator.
  static String segmentWithSeparator(BuildContext context, num? value,
      {int decimals = 0}) {
    final text = kcal(context, value, decimals: decimals);
    return text == null ? '' : '$text · ';
  }

  /// A calorie figure with no unit after it, for a place whose own label
  /// already says what the number is (the base / earned / eaten row under the
  /// ring). Still goes through here, so it disappears with everything else.
  static String bare(BuildContext context, num? value, {bool sign = false}) {
    if (value == null || FiguresScope.offIn(context)) return '';
    final rounded = value.round();
    final prefix = sign && rounded >= 0 ? '+' : '';
    return '$prefix$rounded';
  }

  /// True when this person has asked not to see figures. For the rare case
  /// where a whole block — a progress ring, a remaining-calories banner —
  /// should not be built at all.
  static bool off(BuildContext context) => FiguresScope.offIn(context);
}
