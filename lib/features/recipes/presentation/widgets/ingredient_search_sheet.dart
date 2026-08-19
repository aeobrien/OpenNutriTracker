import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:uuid/uuid.dart';

class IngredientSearchSheet extends StatefulWidget {
  const IngredientSearchSheet({super.key});

  @override
  State<IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<IngredientSearchSheet> {
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _log = Logger('IngredientSearchSheet');
  static const _uuid = Uuid();

  List<_SearchResult> _results = [];
  bool _isSearching = false;
  _SearchResult? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _isSearching = true);

    try {
      // Show local results immediately
      final foodItemDao = locator<FoodItemDao>();
      final localResults = await foodItemDao.searchByName('${query.trim()}*');

      final results = localResults.map((item) => _SearchResult(
            name: item.name ?? 'Unknown',
            brand: item.brand,
            foodItemId: item.id,
            kcalPer100: item.kcalPer100 ?? 0,
            proteinPer100: item.proteinPer100 ?? 0,
            carbsPer100: item.carbsPer100 ?? 0,
            fatPer100: item.fatPer100 ?? 0,
          )).toList();

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = results.length < 5; // keep spinner if searching OFF
      });

      // If few local results, also search OFF in the background
      if (results.length < 5) {
        try {
          final offDataSource = locator<OFFDataSource>();
          final offResponse =
              await offDataSource.fetchSearchWordResults(query.trim());
          final products = offResponse.products;
          for (final product in products) {
            results.add(_SearchResult(
              name: product.product_name ?? 'Unknown',
              brand: product.brands,
              foodItemId: null,
              kcalPer100: _toDouble(product.nutriments.energy_kcal_100g),
              proteinPer100: _toDouble(product.nutriments.proteins_100g),
              carbsPer100: _toDouble(product.nutriments.carbohydrates_100g),
              fatPer100: _toDouble(product.nutriments.fat_100g),
            ));
          }
        } catch (e) {
          _log.fine('OFF search failed: $e');
        }
        if (!mounted) return;
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e, st) {
      _log.warning('Search failed', e, st);
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _confirm() {
    if (_selected == null) return;
    final grams = double.tryParse(_gramsController.text) ?? 100;
    final ingredient = RecipeIngredientEntity(
      id: _uuid.v4(),
      recipeId: '',
      foodItemId: _selected!.foodItemId,
      name: _selected!.name,
      grams: grams,
      kcalPer100: _selected!.kcalPer100,
      proteinPer100: _selected!.proteinPer100,
      carbsPer100: _selected!.carbsPer100,
      fatPer100: _selected!.fatPer100,
    );
    Navigator.of(context).pop(ingredient);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: S.of(context).searchIngredientsHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _results.length + (_isSearching ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _results.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _results[index];
                    final isSelected = _selected == item;
                    return ListTile(
                      selected: isSelected,
                      leading: Icon(
                        item.foodItemId != null
                            ? Icons.inventory_2
                            : Icons.cloud_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(item.name, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          Figures.per100(context, item.kcalPer100),
                          item.brand,
                        ].whereType<String>().join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () => setState(() => _selected = item),
                    );
                  },
                ),
              ),
              if (_selected != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_selected!.name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _gramsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: S.of(context).gramsShortLabel,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _confirm,
                          child: Text(S.of(context).addLabel),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class _SearchResult {
  final String name;
  final String? brand;
  final String? foodItemId;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  _SearchResult({
    required this.name,
    this.brand,
    this.foodItemId,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
  });
}
