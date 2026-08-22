import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/food_shares.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/who_was_it_for.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailBottomSheet extends StatefulWidget {
  /// The words for a whole pack and for one of them, and the weight beside
  /// each. The weight is part of the label rather than a caption underneath
  /// because "1 pack" on its own is not an amount anybody can check — a person
  /// picking it deserves to see what they are agreeing to before they add it.
  static String packLabel(double grams) => 'pack (${_grams(grams)})';

  static String itemLabel(double grams) => 'one (${_grams(grams)})';

  static String _grams(double g) =>
      g == g.roundToDouble() ? '${g.toInt()} g' : '${g.toStringAsFixed(1)} g';

  final MealEntity product;
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;

  /// Where the figure the box opened on came from, so the screen can say so.
  /// Null when nothing was suggested.
  final DefaultPortion? portion;
  final MealDetailBloc mealDetailBloc;

  final String selectedUnit;

  final Function(String?, String?) onQuantityOrUnitChanged;

  /// Only so a test can hand in a household without a locator. The running app
  /// leaves it null and the sheet fetches its own.
  final HouseholdRepository? household;

  const MealDetailBottomSheet(
      {super.key,
      required this.product,
      required this.day,
      required this.intakeTypeEntity,
      required this.quantityTextController,
      this.portion,
      required this.onQuantityOrUnitChanged,
      required this.mealDetailBloc,
      required this.selectedUnit,
      this.household});

  @override
  State<MealDetailBottomSheet> createState() => _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends State<MealDetailBottomSheet> {
  MealEntity get product => widget.product;
  DateTime get day => widget.day;
  IntakeTypeEntity get intakeTypeEntity => widget.intakeTypeEntity;
  TextEditingController get quantityTextController =>
      widget.quantityTextController;
  MealDetailBloc get mealDetailBloc => widget.mealDetailBloc;
  String get selectedUnit => widget.selectedUnit;
  Function(String?, String?) get onQuantityOrUnitChanged =>
      widget.onQuantityOrUnitChanged;

  /// The other person and the amount they typed, or nulls while this is just
  /// mine. Converted only at the moment of adding, through the same arithmetic
  /// as my own.
  HouseholdPerson? _other;
  double? _theirs;

  @override
  Widget build(BuildContext context) {
    final productMissingRequiredInfo = _hasRequiredProductInfoMissing();
    return BottomSheet(
        elevation: 10,
        onClosing: () {},
        enableDrag: false,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !productMissingRequiredInfo,
                              controller: quantityTextController
                                ..addListener(() {
                                  onQuantityOrUnitChanged(
                                      quantityTextController.text,
                                      selectedUnit);
                                }),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+([.,]\d{0,2})?$'))
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).quantityLabel,
                                // Only while the figure is still the one we
                                // put there. The moment they type their own
                                // amount the sentence would be describing a
                                // number no longer on the screen, and a caption
                                // that quietly stops being true is worse than
                                // no caption at all.
                                helperText: quantityTextController.text ==
                                        widget.portion?.amount
                                    ? widget.portion?.explanation
                                    : null,
                                helperMaxLines: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                              child: DropdownButtonFormField(
                                  isExpanded: true,
                                  value: selectedUnit,
                                  decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: S.of(context).unitLabel),
                                  items: <DropdownMenuItem<String>>[
                                    if (product.hasServingValues)
                                      _getServingDropdownItem(context),
                                    // Above the weights on purpose: the way a
                                    // person thinks of a pie is "a pie", and
                                    // the grams are what they fall back to.
                                    if (product.hasItemValues)
                                      _getItemDropdownItem(),
                                    if (product.hasPackValues)
                                      _getPackDropdownItem(),
                                    if (product.isSolid ||
                                        !product.isLiquid && !product.isSolid)
                                      ..._getSolidUnitDropdownItems(context),
                                    if (product.isLiquid ||
                                        !product.isLiquid && !product.isSolid)
                                      ..._getLiquidUnitDropdownItems(context),
                                    ..._getOtherDropdownItems(context)
                                  ],
                                  onChanged: (value) {
                                    onQuantityOrUnitChanged(
                                        quantityTextController.text, value);
                                  }))
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      _IncrementChips(
                        product: product,
                        quantityTextController: quantityTextController,
                        selectedUnit: selectedUnit,
                        onQuantityOrUnitChanged: onQuantityOrUnitChanged,
                      ),
                      const SizedBox(height: 8.0),
                      WhoWasItFor(
                        myAmount: quantityTextController,
                        household: widget.household,
                        onChanged: (other, theirs) {
                          _other = other;
                          _theirs = theirs;
                        },
                      ),
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton.icon(
                            onPressed: !productMissingRequiredInfo
                                ? () {
                                    onAddButtonPressed(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ).copyWith(
                                elevation: ButtonStyleButton.allOrNull(0.0)),
                            icon: const Icon(Icons.add_outlined),
                            label: Text(S.of(context).addLabel)),
                      ),
                      productMissingRequiredInfo
                          ? Text(S.of(context).missingProductInfo,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error))
                          : const SizedBox()
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  /// The other person's share, in the unit the ledger keeps.
  ///
  /// Worked out from what they had, never from what I had — the two figures
  /// stay independent all the way to the server, which is the difference
  /// between one meal on two days and one meal halved.
  List<FoodShare> _shares() {
    final other = _other;
    final theirs = _theirs;
    if (other == null || theirs == null) return const [];
    return [
      FoodShare(
          personId: other.id,
          quantity: MealDetailBloc.convertQuantity(
              product, theirs, mealDetailBloc.state.selectedUnit)),
    ];
  }

  bool _hasRequiredProductInfoMissing() {
    final productNutriments = product.nutriments;
    if (productNutriments.energyKcal100 == null ||
        productNutriments.carbohydrates100 == null ||
        productNutriments.fat100 == null ||
        productNutriments.proteins100 == null) {
      return true;
    } else {
      return false;
    }
  }

  void onAddButtonPressed(BuildContext context) {
    mealDetailBloc.addIntake(
        context,
        mealDetailBloc.state.selectedUnit,
        mealDetailBloc.state.totalQuantityConverted,
        intakeTypeEntity,
        product,
        day,
        alsoFor: _shares());

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }

  DropdownMenuItem<String> _getServingDropdownItem(BuildContext context) {
    return DropdownMenuItem(
      value: UnitDropdownItem.serving.toString(),
      child: Text(
          product.servingSize ??
              '${S.of(context).servingLabel} (${product.servingQuantity} ${product.servingUnit})',
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    );
  }

  DropdownMenuItem<String> _getPackDropdownItem() => DropdownMenuItem(
        value: UnitDropdownItem.pack.toString(),
        child: Text(MealDetailBottomSheet.packLabel(product.packGrams!),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      );

  DropdownMenuItem<String> _getItemDropdownItem() => DropdownMenuItem(
        value: UnitDropdownItem.item.toString(),
        child: Text(MealDetailBottomSheet.itemLabel(product.itemGrams!),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      );

  List<DropdownMenuItem<String>> _getSolidUnitDropdownItems(
      BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.g.toString(),
          child: Text(S.of(context).gramUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
      DropdownMenuItem(
          value: UnitDropdownItem.oz.toString(),
          child: Text(S.of(context).ozUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
    ];
  }

  List<DropdownMenuItem<String>> _getLiquidUnitDropdownItems(
      BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.ml.toString(),
          child: Text(S.of(context).milliliterUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
      DropdownMenuItem(
          value: UnitDropdownItem.flOz.toString(),
          child: Text(S.of(context).flOzUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
    ];
  }

  List<DropdownMenuItem<String>> _getOtherDropdownItems(BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.gml.toString(),
          child: Text(
              "${S.of(context).notAvailableLabel} (${S.of(context).gramMilliliterUnit})",
              overflow: TextOverflow.ellipsis,
              maxLines: 1)),
    ];
  }
}

class _IncrementChips extends StatelessWidget {
  final MealEntity product;
  final TextEditingController quantityTextController;
  final String selectedUnit;
  final Function(String?, String?) onQuantityOrUnitChanged;

  const _IncrementChips({
    required this.product,
    required this.quantityTextController,
    required this.selectedUnit,
    required this.onQuantityOrUnitChanged,
  });

  void _changeAmount(double delta) {
    final current =
        double.tryParse(quantityTextController.text.replaceAll(',', '.')) ??
            0.0;
    final newVal = (current + delta).clamp(0.0, double.infinity);
    final text = newVal == newVal.roundToDouble()
        ? newVal.toInt().toString()
        : newVal.toStringAsFixed(1);
    quantityTextController.text = text;
    onQuantityOrUnitChanged(text, selectedUnit);
  }

  void _setAmount(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    quantityTextController.text = text;
    onQuantityOrUnitChanged(text, selectedUnit);
  }

  @override
  Widget build(BuildContext context) {
    final isServing = selectedUnit == UnitDropdownItem.serving.toString();
    // Packs and single items are counted, not weighed. A "+50" chip beside a
    // box holding "1 pack" would offer to add fifty packs of biscuits, so the
    // counted units take the same small steps a serving does.
    final isCounted = isServing ||
        selectedUnit == UnitDropdownItem.pack.toString() ||
        selectedUnit == UnitDropdownItem.item.toString();
    final stepSuffix = isServing ? ' srv' : '';
    final isLiquid = product.isLiquid;
    final unitLabel = isLiquid ? 'ml' : 'g';
    final hasServing = product.hasServingValues && product.servingQuantity != null;

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        if (!isCounted) ...[
          ActionChip(
            label: Text('+10$unitLabel'),
            onPressed: () => _changeAmount(10),
          ),
          ActionChip(
            label: Text('+50$unitLabel'),
            onPressed: () => _changeAmount(50),
          ),
          if (hasServing) ...[
            ActionChip(
              label: const Text('\u00BD srv'),
              onPressed: () =>
                  _setAmount(product.servingQuantity! * 0.5),
            ),
            ActionChip(
              label: const Text('1 srv'),
              onPressed: () => _setAmount(product.servingQuantity!),
            ),
          ],
        ],
        if (isCounted) ...[
          ActionChip(
            label: Text('+0.5$stepSuffix'),
            onPressed: () => _changeAmount(0.5),
          ),
          ActionChip(
            label: Text('+1$stepSuffix'),
            onPressed: () => _changeAmount(1),
          ),
        ],
      ],
    );
  }
}
