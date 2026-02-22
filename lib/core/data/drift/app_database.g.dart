// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealQuantityMeta = const VerificationMeta(
    'mealQuantity',
  );
  @override
  late final GeneratedColumn<String> mealQuantity = GeneratedColumn<String>(
    'meal_quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealUnitMeta = const VerificationMeta(
    'mealUnit',
  );
  @override
  late final GeneratedColumn<String> mealUnit = GeneratedColumn<String>(
    'meal_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingQuantityMeta = const VerificationMeta(
    'servingQuantity',
  );
  @override
  late final GeneratedColumn<double> servingQuantity = GeneratedColumn<double>(
    'serving_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingUnitMeta = const VerificationMeta(
    'servingUnit',
  );
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
    'serving_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingSizeMeta = const VerificationMeta(
    'servingSize',
  );
  @override
  late final GeneratedColumn<String> servingSize = GeneratedColumn<String>(
    'serving_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalPer100Meta = const VerificationMeta(
    'kcalPer100',
  );
  @override
  late final GeneratedColumn<double> kcalPer100 = GeneratedColumn<double>(
    'kcal_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinPer100Meta = const VerificationMeta(
    'proteinPer100',
  );
  @override
  late final GeneratedColumn<double> proteinPer100 = GeneratedColumn<double>(
    'protein_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsPer100Meta = const VerificationMeta(
    'carbsPer100',
  );
  @override
  late final GeneratedColumn<double> carbsPer100 = GeneratedColumn<double>(
    'carbs_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatPer100Meta = const VerificationMeta(
    'fatPer100',
  );
  @override
  late final GeneratedColumn<double> fatPer100 = GeneratedColumn<double>(
    'fat_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fibrePer100Meta = const VerificationMeta(
    'fibrePer100',
  );
  @override
  late final GeneratedColumn<double> fibrePer100 = GeneratedColumn<double>(
    'fibre_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugarPer100Meta = const VerificationMeta(
    'sugarPer100',
  );
  @override
  late final GeneratedColumn<double> sugarPer100 = GeneratedColumn<double>(
    'sugar_per100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saturatedFatPer100Meta =
      const VerificationMeta('saturatedFatPer100');
  @override
  late final GeneratedColumn<double> saturatedFatPer100 =
      GeneratedColumn<double>(
        'saturated_fat_per100',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _thumbnailImageUrlMeta = const VerificationMeta(
    'thumbnailImageUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailImageUrl =
      GeneratedColumn<String>(
        'thumbnail_image_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mainImageUrlMeta = const VerificationMeta(
    'mainImageUrl',
  );
  @override
  late final GeneratedColumn<String> mainImageUrl = GeneratedColumn<String>(
    'main_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUsedGramsMeta = const VerificationMeta(
    'lastUsedGrams',
  );
  @override
  late final GeneratedColumn<double> lastUsedGrams = GeneratedColumn<double>(
    'last_used_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  @override
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favourite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    barcode,
    name,
    brand,
    mealQuantity,
    mealUnit,
    servingQuantity,
    servingUnit,
    servingSize,
    kcalPer100,
    proteinPer100,
    carbsPer100,
    fatPer100,
    fibrePer100,
    sugarPer100,
    saturatedFatPer100,
    thumbnailImageUrl,
    mainImageUrl,
    url,
    lastUsedAt,
    lastUsedGrams,
    favourite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('meal_quantity')) {
      context.handle(
        _mealQuantityMeta,
        mealQuantity.isAcceptableOrUnknown(
          data['meal_quantity']!,
          _mealQuantityMeta,
        ),
      );
    }
    if (data.containsKey('meal_unit')) {
      context.handle(
        _mealUnitMeta,
        mealUnit.isAcceptableOrUnknown(data['meal_unit']!, _mealUnitMeta),
      );
    }
    if (data.containsKey('serving_quantity')) {
      context.handle(
        _servingQuantityMeta,
        servingQuantity.isAcceptableOrUnknown(
          data['serving_quantity']!,
          _servingQuantityMeta,
        ),
      );
    }
    if (data.containsKey('serving_unit')) {
      context.handle(
        _servingUnitMeta,
        servingUnit.isAcceptableOrUnknown(
          data['serving_unit']!,
          _servingUnitMeta,
        ),
      );
    }
    if (data.containsKey('serving_size')) {
      context.handle(
        _servingSizeMeta,
        servingSize.isAcceptableOrUnknown(
          data['serving_size']!,
          _servingSizeMeta,
        ),
      );
    }
    if (data.containsKey('kcal_per100')) {
      context.handle(
        _kcalPer100Meta,
        kcalPer100.isAcceptableOrUnknown(data['kcal_per100']!, _kcalPer100Meta),
      );
    }
    if (data.containsKey('protein_per100')) {
      context.handle(
        _proteinPer100Meta,
        proteinPer100.isAcceptableOrUnknown(
          data['protein_per100']!,
          _proteinPer100Meta,
        ),
      );
    }
    if (data.containsKey('carbs_per100')) {
      context.handle(
        _carbsPer100Meta,
        carbsPer100.isAcceptableOrUnknown(
          data['carbs_per100']!,
          _carbsPer100Meta,
        ),
      );
    }
    if (data.containsKey('fat_per100')) {
      context.handle(
        _fatPer100Meta,
        fatPer100.isAcceptableOrUnknown(data['fat_per100']!, _fatPer100Meta),
      );
    }
    if (data.containsKey('fibre_per100')) {
      context.handle(
        _fibrePer100Meta,
        fibrePer100.isAcceptableOrUnknown(
          data['fibre_per100']!,
          _fibrePer100Meta,
        ),
      );
    }
    if (data.containsKey('sugar_per100')) {
      context.handle(
        _sugarPer100Meta,
        sugarPer100.isAcceptableOrUnknown(
          data['sugar_per100']!,
          _sugarPer100Meta,
        ),
      );
    }
    if (data.containsKey('saturated_fat_per100')) {
      context.handle(
        _saturatedFatPer100Meta,
        saturatedFatPer100.isAcceptableOrUnknown(
          data['saturated_fat_per100']!,
          _saturatedFatPer100Meta,
        ),
      );
    }
    if (data.containsKey('thumbnail_image_url')) {
      context.handle(
        _thumbnailImageUrlMeta,
        thumbnailImageUrl.isAcceptableOrUnknown(
          data['thumbnail_image_url']!,
          _thumbnailImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('main_image_url')) {
      context.handle(
        _mainImageUrlMeta,
        mainImageUrl.isAcceptableOrUnknown(
          data['main_image_url']!,
          _mainImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_used_grams')) {
      context.handle(
        _lastUsedGramsMeta,
        lastUsedGrams.isAcceptableOrUnknown(
          data['last_used_grams']!,
          _lastUsedGramsMeta,
        ),
      );
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      mealQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_quantity'],
      ),
      mealUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_unit'],
      ),
      servingQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_quantity'],
      ),
      servingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_unit'],
      ),
      servingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_size'],
      ),
      kcalPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_per100'],
      ),
      proteinPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100'],
      ),
      carbsPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100'],
      ),
      fatPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100'],
      ),
      fibrePer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fibre_per100'],
      ),
      sugarPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_per100'],
      ),
      saturatedFatPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saturated_fat_per100'],
      ),
      thumbnailImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_image_url'],
      ),
      mainImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}main_image_url'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      ),
      lastUsedGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_used_grams'],
      ),
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }
}

class FoodItem extends DataClass implements Insertable<FoodItem> {
  final String id;
  final String source;
  final String? barcode;
  final String? name;
  final String? brand;
  final String? mealQuantity;
  final String? mealUnit;
  final double? servingQuantity;
  final String? servingUnit;
  final String? servingSize;
  final double? kcalPer100;
  final double? proteinPer100;
  final double? carbsPer100;
  final double? fatPer100;
  final double? fibrePer100;
  final double? sugarPer100;
  final double? saturatedFatPer100;
  final String? thumbnailImageUrl;
  final String? mainImageUrl;
  final String? url;
  final int? lastUsedAt;
  final double? lastUsedGrams;
  final bool favourite;
  const FoodItem({
    required this.id,
    required this.source,
    this.barcode,
    this.name,
    this.brand,
    this.mealQuantity,
    this.mealUnit,
    this.servingQuantity,
    this.servingUnit,
    this.servingSize,
    this.kcalPer100,
    this.proteinPer100,
    this.carbsPer100,
    this.fatPer100,
    this.fibrePer100,
    this.sugarPer100,
    this.saturatedFatPer100,
    this.thumbnailImageUrl,
    this.mainImageUrl,
    this.url,
    this.lastUsedAt,
    this.lastUsedGrams,
    required this.favourite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || mealQuantity != null) {
      map['meal_quantity'] = Variable<String>(mealQuantity);
    }
    if (!nullToAbsent || mealUnit != null) {
      map['meal_unit'] = Variable<String>(mealUnit);
    }
    if (!nullToAbsent || servingQuantity != null) {
      map['serving_quantity'] = Variable<double>(servingQuantity);
    }
    if (!nullToAbsent || servingUnit != null) {
      map['serving_unit'] = Variable<String>(servingUnit);
    }
    if (!nullToAbsent || servingSize != null) {
      map['serving_size'] = Variable<String>(servingSize);
    }
    if (!nullToAbsent || kcalPer100 != null) {
      map['kcal_per100'] = Variable<double>(kcalPer100);
    }
    if (!nullToAbsent || proteinPer100 != null) {
      map['protein_per100'] = Variable<double>(proteinPer100);
    }
    if (!nullToAbsent || carbsPer100 != null) {
      map['carbs_per100'] = Variable<double>(carbsPer100);
    }
    if (!nullToAbsent || fatPer100 != null) {
      map['fat_per100'] = Variable<double>(fatPer100);
    }
    if (!nullToAbsent || fibrePer100 != null) {
      map['fibre_per100'] = Variable<double>(fibrePer100);
    }
    if (!nullToAbsent || sugarPer100 != null) {
      map['sugar_per100'] = Variable<double>(sugarPer100);
    }
    if (!nullToAbsent || saturatedFatPer100 != null) {
      map['saturated_fat_per100'] = Variable<double>(saturatedFatPer100);
    }
    if (!nullToAbsent || thumbnailImageUrl != null) {
      map['thumbnail_image_url'] = Variable<String>(thumbnailImageUrl);
    }
    if (!nullToAbsent || mainImageUrl != null) {
      map['main_image_url'] = Variable<String>(mainImageUrl);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<int>(lastUsedAt);
    }
    if (!nullToAbsent || lastUsedGrams != null) {
      map['last_used_grams'] = Variable<double>(lastUsedGrams);
    }
    map['favourite'] = Variable<bool>(favourite);
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      source: Value(source),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      mealQuantity: mealQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(mealQuantity),
      mealUnit: mealUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(mealUnit),
      servingQuantity: servingQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(servingQuantity),
      servingUnit: servingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(servingUnit),
      servingSize: servingSize == null && nullToAbsent
          ? const Value.absent()
          : Value(servingSize),
      kcalPer100: kcalPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(kcalPer100),
      proteinPer100: proteinPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinPer100),
      carbsPer100: carbsPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsPer100),
      fatPer100: fatPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fatPer100),
      fibrePer100: fibrePer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fibrePer100),
      sugarPer100: sugarPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarPer100),
      saturatedFatPer100: saturatedFatPer100 == null && nullToAbsent
          ? const Value.absent()
          : Value(saturatedFatPer100),
      thumbnailImageUrl: thumbnailImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailImageUrl),
      mainImageUrl: mainImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mainImageUrl),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      lastUsedGrams: lastUsedGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedGrams),
      favourite: Value(favourite),
    );
  }

  factory FoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItem(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String?>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      mealQuantity: serializer.fromJson<String?>(json['mealQuantity']),
      mealUnit: serializer.fromJson<String?>(json['mealUnit']),
      servingQuantity: serializer.fromJson<double?>(json['servingQuantity']),
      servingUnit: serializer.fromJson<String?>(json['servingUnit']),
      servingSize: serializer.fromJson<String?>(json['servingSize']),
      kcalPer100: serializer.fromJson<double?>(json['kcalPer100']),
      proteinPer100: serializer.fromJson<double?>(json['proteinPer100']),
      carbsPer100: serializer.fromJson<double?>(json['carbsPer100']),
      fatPer100: serializer.fromJson<double?>(json['fatPer100']),
      fibrePer100: serializer.fromJson<double?>(json['fibrePer100']),
      sugarPer100: serializer.fromJson<double?>(json['sugarPer100']),
      saturatedFatPer100: serializer.fromJson<double?>(
        json['saturatedFatPer100'],
      ),
      thumbnailImageUrl: serializer.fromJson<String?>(
        json['thumbnailImageUrl'],
      ),
      mainImageUrl: serializer.fromJson<String?>(json['mainImageUrl']),
      url: serializer.fromJson<String?>(json['url']),
      lastUsedAt: serializer.fromJson<int?>(json['lastUsedAt']),
      lastUsedGrams: serializer.fromJson<double?>(json['lastUsedGrams']),
      favourite: serializer.fromJson<bool>(json['favourite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String?>(name),
      'brand': serializer.toJson<String?>(brand),
      'mealQuantity': serializer.toJson<String?>(mealQuantity),
      'mealUnit': serializer.toJson<String?>(mealUnit),
      'servingQuantity': serializer.toJson<double?>(servingQuantity),
      'servingUnit': serializer.toJson<String?>(servingUnit),
      'servingSize': serializer.toJson<String?>(servingSize),
      'kcalPer100': serializer.toJson<double?>(kcalPer100),
      'proteinPer100': serializer.toJson<double?>(proteinPer100),
      'carbsPer100': serializer.toJson<double?>(carbsPer100),
      'fatPer100': serializer.toJson<double?>(fatPer100),
      'fibrePer100': serializer.toJson<double?>(fibrePer100),
      'sugarPer100': serializer.toJson<double?>(sugarPer100),
      'saturatedFatPer100': serializer.toJson<double?>(saturatedFatPer100),
      'thumbnailImageUrl': serializer.toJson<String?>(thumbnailImageUrl),
      'mainImageUrl': serializer.toJson<String?>(mainImageUrl),
      'url': serializer.toJson<String?>(url),
      'lastUsedAt': serializer.toJson<int?>(lastUsedAt),
      'lastUsedGrams': serializer.toJson<double?>(lastUsedGrams),
      'favourite': serializer.toJson<bool>(favourite),
    };
  }

  FoodItem copyWith({
    String? id,
    String? source,
    Value<String?> barcode = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> mealQuantity = const Value.absent(),
    Value<String?> mealUnit = const Value.absent(),
    Value<double?> servingQuantity = const Value.absent(),
    Value<String?> servingUnit = const Value.absent(),
    Value<String?> servingSize = const Value.absent(),
    Value<double?> kcalPer100 = const Value.absent(),
    Value<double?> proteinPer100 = const Value.absent(),
    Value<double?> carbsPer100 = const Value.absent(),
    Value<double?> fatPer100 = const Value.absent(),
    Value<double?> fibrePer100 = const Value.absent(),
    Value<double?> sugarPer100 = const Value.absent(),
    Value<double?> saturatedFatPer100 = const Value.absent(),
    Value<String?> thumbnailImageUrl = const Value.absent(),
    Value<String?> mainImageUrl = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<int?> lastUsedAt = const Value.absent(),
    Value<double?> lastUsedGrams = const Value.absent(),
    bool? favourite,
  }) => FoodItem(
    id: id ?? this.id,
    source: source ?? this.source,
    barcode: barcode.present ? barcode.value : this.barcode,
    name: name.present ? name.value : this.name,
    brand: brand.present ? brand.value : this.brand,
    mealQuantity: mealQuantity.present ? mealQuantity.value : this.mealQuantity,
    mealUnit: mealUnit.present ? mealUnit.value : this.mealUnit,
    servingQuantity: servingQuantity.present
        ? servingQuantity.value
        : this.servingQuantity,
    servingUnit: servingUnit.present ? servingUnit.value : this.servingUnit,
    servingSize: servingSize.present ? servingSize.value : this.servingSize,
    kcalPer100: kcalPer100.present ? kcalPer100.value : this.kcalPer100,
    proteinPer100: proteinPer100.present
        ? proteinPer100.value
        : this.proteinPer100,
    carbsPer100: carbsPer100.present ? carbsPer100.value : this.carbsPer100,
    fatPer100: fatPer100.present ? fatPer100.value : this.fatPer100,
    fibrePer100: fibrePer100.present ? fibrePer100.value : this.fibrePer100,
    sugarPer100: sugarPer100.present ? sugarPer100.value : this.sugarPer100,
    saturatedFatPer100: saturatedFatPer100.present
        ? saturatedFatPer100.value
        : this.saturatedFatPer100,
    thumbnailImageUrl: thumbnailImageUrl.present
        ? thumbnailImageUrl.value
        : this.thumbnailImageUrl,
    mainImageUrl: mainImageUrl.present ? mainImageUrl.value : this.mainImageUrl,
    url: url.present ? url.value : this.url,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    lastUsedGrams: lastUsedGrams.present
        ? lastUsedGrams.value
        : this.lastUsedGrams,
    favourite: favourite ?? this.favourite,
  );
  FoodItem copyWithCompanion(FoodItemsCompanion data) {
    return FoodItem(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      mealQuantity: data.mealQuantity.present
          ? data.mealQuantity.value
          : this.mealQuantity,
      mealUnit: data.mealUnit.present ? data.mealUnit.value : this.mealUnit,
      servingQuantity: data.servingQuantity.present
          ? data.servingQuantity.value
          : this.servingQuantity,
      servingUnit: data.servingUnit.present
          ? data.servingUnit.value
          : this.servingUnit,
      servingSize: data.servingSize.present
          ? data.servingSize.value
          : this.servingSize,
      kcalPer100: data.kcalPer100.present
          ? data.kcalPer100.value
          : this.kcalPer100,
      proteinPer100: data.proteinPer100.present
          ? data.proteinPer100.value
          : this.proteinPer100,
      carbsPer100: data.carbsPer100.present
          ? data.carbsPer100.value
          : this.carbsPer100,
      fatPer100: data.fatPer100.present ? data.fatPer100.value : this.fatPer100,
      fibrePer100: data.fibrePer100.present
          ? data.fibrePer100.value
          : this.fibrePer100,
      sugarPer100: data.sugarPer100.present
          ? data.sugarPer100.value
          : this.sugarPer100,
      saturatedFatPer100: data.saturatedFatPer100.present
          ? data.saturatedFatPer100.value
          : this.saturatedFatPer100,
      thumbnailImageUrl: data.thumbnailImageUrl.present
          ? data.thumbnailImageUrl.value
          : this.thumbnailImageUrl,
      mainImageUrl: data.mainImageUrl.present
          ? data.mainImageUrl.value
          : this.mainImageUrl,
      url: data.url.present ? data.url.value : this.url,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      lastUsedGrams: data.lastUsedGrams.present
          ? data.lastUsedGrams.value
          : this.lastUsedGrams,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItem(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('mealQuantity: $mealQuantity, ')
          ..write('mealUnit: $mealUnit, ')
          ..write('servingQuantity: $servingQuantity, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('servingSize: $servingSize, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('carbsPer100: $carbsPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('fibrePer100: $fibrePer100, ')
          ..write('sugarPer100: $sugarPer100, ')
          ..write('saturatedFatPer100: $saturatedFatPer100, ')
          ..write('thumbnailImageUrl: $thumbnailImageUrl, ')
          ..write('mainImageUrl: $mainImageUrl, ')
          ..write('url: $url, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('lastUsedGrams: $lastUsedGrams, ')
          ..write('favourite: $favourite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    source,
    barcode,
    name,
    brand,
    mealQuantity,
    mealUnit,
    servingQuantity,
    servingUnit,
    servingSize,
    kcalPer100,
    proteinPer100,
    carbsPer100,
    fatPer100,
    fibrePer100,
    sugarPer100,
    saturatedFatPer100,
    thumbnailImageUrl,
    mainImageUrl,
    url,
    lastUsedAt,
    lastUsedGrams,
    favourite,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == this.id &&
          other.source == this.source &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.mealQuantity == this.mealQuantity &&
          other.mealUnit == this.mealUnit &&
          other.servingQuantity == this.servingQuantity &&
          other.servingUnit == this.servingUnit &&
          other.servingSize == this.servingSize &&
          other.kcalPer100 == this.kcalPer100 &&
          other.proteinPer100 == this.proteinPer100 &&
          other.carbsPer100 == this.carbsPer100 &&
          other.fatPer100 == this.fatPer100 &&
          other.fibrePer100 == this.fibrePer100 &&
          other.sugarPer100 == this.sugarPer100 &&
          other.saturatedFatPer100 == this.saturatedFatPer100 &&
          other.thumbnailImageUrl == this.thumbnailImageUrl &&
          other.mainImageUrl == this.mainImageUrl &&
          other.url == this.url &&
          other.lastUsedAt == this.lastUsedAt &&
          other.lastUsedGrams == this.lastUsedGrams &&
          other.favourite == this.favourite);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItem> {
  final Value<String> id;
  final Value<String> source;
  final Value<String?> barcode;
  final Value<String?> name;
  final Value<String?> brand;
  final Value<String?> mealQuantity;
  final Value<String?> mealUnit;
  final Value<double?> servingQuantity;
  final Value<String?> servingUnit;
  final Value<String?> servingSize;
  final Value<double?> kcalPer100;
  final Value<double?> proteinPer100;
  final Value<double?> carbsPer100;
  final Value<double?> fatPer100;
  final Value<double?> fibrePer100;
  final Value<double?> sugarPer100;
  final Value<double?> saturatedFatPer100;
  final Value<String?> thumbnailImageUrl;
  final Value<String?> mainImageUrl;
  final Value<String?> url;
  final Value<int?> lastUsedAt;
  final Value<double?> lastUsedGrams;
  final Value<bool> favourite;
  final Value<int> rowid;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.mealQuantity = const Value.absent(),
    this.mealUnit = const Value.absent(),
    this.servingQuantity = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.kcalPer100 = const Value.absent(),
    this.proteinPer100 = const Value.absent(),
    this.carbsPer100 = const Value.absent(),
    this.fatPer100 = const Value.absent(),
    this.fibrePer100 = const Value.absent(),
    this.sugarPer100 = const Value.absent(),
    this.saturatedFatPer100 = const Value.absent(),
    this.thumbnailImageUrl = const Value.absent(),
    this.mainImageUrl = const Value.absent(),
    this.url = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.lastUsedGrams = const Value.absent(),
    this.favourite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    required String id,
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.mealQuantity = const Value.absent(),
    this.mealUnit = const Value.absent(),
    this.servingQuantity = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.kcalPer100 = const Value.absent(),
    this.proteinPer100 = const Value.absent(),
    this.carbsPer100 = const Value.absent(),
    this.fatPer100 = const Value.absent(),
    this.fibrePer100 = const Value.absent(),
    this.sugarPer100 = const Value.absent(),
    this.saturatedFatPer100 = const Value.absent(),
    this.thumbnailImageUrl = const Value.absent(),
    this.mainImageUrl = const Value.absent(),
    this.url = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.lastUsedGrams = const Value.absent(),
    this.favourite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<FoodItem> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? mealQuantity,
    Expression<String>? mealUnit,
    Expression<double>? servingQuantity,
    Expression<String>? servingUnit,
    Expression<String>? servingSize,
    Expression<double>? kcalPer100,
    Expression<double>? proteinPer100,
    Expression<double>? carbsPer100,
    Expression<double>? fatPer100,
    Expression<double>? fibrePer100,
    Expression<double>? sugarPer100,
    Expression<double>? saturatedFatPer100,
    Expression<String>? thumbnailImageUrl,
    Expression<String>? mainImageUrl,
    Expression<String>? url,
    Expression<int>? lastUsedAt,
    Expression<double>? lastUsedGrams,
    Expression<bool>? favourite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (mealQuantity != null) 'meal_quantity': mealQuantity,
      if (mealUnit != null) 'meal_unit': mealUnit,
      if (servingQuantity != null) 'serving_quantity': servingQuantity,
      if (servingUnit != null) 'serving_unit': servingUnit,
      if (servingSize != null) 'serving_size': servingSize,
      if (kcalPer100 != null) 'kcal_per100': kcalPer100,
      if (proteinPer100 != null) 'protein_per100': proteinPer100,
      if (carbsPer100 != null) 'carbs_per100': carbsPer100,
      if (fatPer100 != null) 'fat_per100': fatPer100,
      if (fibrePer100 != null) 'fibre_per100': fibrePer100,
      if (sugarPer100 != null) 'sugar_per100': sugarPer100,
      if (saturatedFatPer100 != null)
        'saturated_fat_per100': saturatedFatPer100,
      if (thumbnailImageUrl != null) 'thumbnail_image_url': thumbnailImageUrl,
      if (mainImageUrl != null) 'main_image_url': mainImageUrl,
      if (url != null) 'url': url,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (lastUsedGrams != null) 'last_used_grams': lastUsedGrams,
      if (favourite != null) 'favourite': favourite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? source,
    Value<String?>? barcode,
    Value<String?>? name,
    Value<String?>? brand,
    Value<String?>? mealQuantity,
    Value<String?>? mealUnit,
    Value<double?>? servingQuantity,
    Value<String?>? servingUnit,
    Value<String?>? servingSize,
    Value<double?>? kcalPer100,
    Value<double?>? proteinPer100,
    Value<double?>? carbsPer100,
    Value<double?>? fatPer100,
    Value<double?>? fibrePer100,
    Value<double?>? sugarPer100,
    Value<double?>? saturatedFatPer100,
    Value<String?>? thumbnailImageUrl,
    Value<String?>? mainImageUrl,
    Value<String?>? url,
    Value<int?>? lastUsedAt,
    Value<double?>? lastUsedGrams,
    Value<bool>? favourite,
    Value<int>? rowid,
  }) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      mealQuantity: mealQuantity ?? this.mealQuantity,
      mealUnit: mealUnit ?? this.mealUnit,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      servingSize: servingSize ?? this.servingSize,
      kcalPer100: kcalPer100 ?? this.kcalPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      fibrePer100: fibrePer100 ?? this.fibrePer100,
      sugarPer100: sugarPer100 ?? this.sugarPer100,
      saturatedFatPer100: saturatedFatPer100 ?? this.saturatedFatPer100,
      thumbnailImageUrl: thumbnailImageUrl ?? this.thumbnailImageUrl,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      url: url ?? this.url,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lastUsedGrams: lastUsedGrams ?? this.lastUsedGrams,
      favourite: favourite ?? this.favourite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (mealQuantity.present) {
      map['meal_quantity'] = Variable<String>(mealQuantity.value);
    }
    if (mealUnit.present) {
      map['meal_unit'] = Variable<String>(mealUnit.value);
    }
    if (servingQuantity.present) {
      map['serving_quantity'] = Variable<double>(servingQuantity.value);
    }
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
    }
    if (servingSize.present) {
      map['serving_size'] = Variable<String>(servingSize.value);
    }
    if (kcalPer100.present) {
      map['kcal_per100'] = Variable<double>(kcalPer100.value);
    }
    if (proteinPer100.present) {
      map['protein_per100'] = Variable<double>(proteinPer100.value);
    }
    if (carbsPer100.present) {
      map['carbs_per100'] = Variable<double>(carbsPer100.value);
    }
    if (fatPer100.present) {
      map['fat_per100'] = Variable<double>(fatPer100.value);
    }
    if (fibrePer100.present) {
      map['fibre_per100'] = Variable<double>(fibrePer100.value);
    }
    if (sugarPer100.present) {
      map['sugar_per100'] = Variable<double>(sugarPer100.value);
    }
    if (saturatedFatPer100.present) {
      map['saturated_fat_per100'] = Variable<double>(saturatedFatPer100.value);
    }
    if (thumbnailImageUrl.present) {
      map['thumbnail_image_url'] = Variable<String>(thumbnailImageUrl.value);
    }
    if (mainImageUrl.present) {
      map['main_image_url'] = Variable<String>(mainImageUrl.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (lastUsedGrams.present) {
      map['last_used_grams'] = Variable<double>(lastUsedGrams.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('mealQuantity: $mealQuantity, ')
          ..write('mealUnit: $mealUnit, ')
          ..write('servingQuantity: $servingQuantity, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('servingSize: $servingSize, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('carbsPer100: $carbsPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('fibrePer100: $fibrePer100, ')
          ..write('sugarPer100: $sugarPer100, ')
          ..write('saturatedFatPer100: $saturatedFatPer100, ')
          ..write('thumbnailImageUrl: $thumbnailImageUrl, ')
          ..write('mainImageUrl: $mainImageUrl, ')
          ..write('url: $url, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('lastUsedGrams: $lastUsedGrams, ')
          ..write('favourite: $favourite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealSlotMeta = const VerificationMeta(
    'mealSlot',
  );
  @override
  late final GeneratedColumn<String> mealSlot = GeneratedColumn<String>(
    'meal_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodItemIdMeta = const VerificationMeta(
    'foodItemId',
  );
  @override
  late final GeneratedColumn<String> foodItemId = GeneratedColumn<String>(
    'food_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES food_items (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotKcalMeta = const VerificationMeta(
    'snapshotKcal',
  );
  @override
  late final GeneratedColumn<double> snapshotKcal = GeneratedColumn<double>(
    'snapshot_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _snapshotProteinMeta = const VerificationMeta(
    'snapshotProtein',
  );
  @override
  late final GeneratedColumn<double> snapshotProtein = GeneratedColumn<double>(
    'snapshot_protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _snapshotCarbsMeta = const VerificationMeta(
    'snapshotCarbs',
  );
  @override
  late final GeneratedColumn<double> snapshotCarbs = GeneratedColumn<double>(
    'snapshot_carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _snapshotFatMeta = const VerificationMeta(
    'snapshotFat',
  );
  @override
  late final GeneratedColumn<double> snapshotFat = GeneratedColumn<double>(
    'snapshot_fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    mealSlot,
    foodItemId,
    amount,
    unit,
    snapshotKcal,
    snapshotProtein,
    snapshotCarbs,
    snapshotFat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('meal_slot')) {
      context.handle(
        _mealSlotMeta,
        mealSlot.isAcceptableOrUnknown(data['meal_slot']!, _mealSlotMeta),
      );
    } else if (isInserting) {
      context.missing(_mealSlotMeta);
    }
    if (data.containsKey('food_item_id')) {
      context.handle(
        _foodItemIdMeta,
        foodItemId.isAcceptableOrUnknown(
          data['food_item_id']!,
          _foodItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodItemIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('snapshot_kcal')) {
      context.handle(
        _snapshotKcalMeta,
        snapshotKcal.isAcceptableOrUnknown(
          data['snapshot_kcal']!,
          _snapshotKcalMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_protein')) {
      context.handle(
        _snapshotProteinMeta,
        snapshotProtein.isAcceptableOrUnknown(
          data['snapshot_protein']!,
          _snapshotProteinMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_carbs')) {
      context.handle(
        _snapshotCarbsMeta,
        snapshotCarbs.isAcceptableOrUnknown(
          data['snapshot_carbs']!,
          _snapshotCarbsMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_fat')) {
      context.handle(
        _snapshotFatMeta,
        snapshotFat.isAcceptableOrUnknown(
          data['snapshot_fat']!,
          _snapshotFatMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      mealSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_slot'],
      )!,
      foodItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_item_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      snapshotKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snapshot_kcal'],
      )!,
      snapshotProtein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snapshot_protein'],
      )!,
      snapshotCarbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snapshot_carbs'],
      )!,
      snapshotFat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snapshot_fat'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final String id;
  final int timestamp;
  final String mealSlot;
  final String foodItemId;
  final double amount;
  final String unit;
  final double snapshotKcal;
  final double snapshotProtein;
  final double snapshotCarbs;
  final double snapshotFat;
  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.mealSlot,
    required this.foodItemId,
    required this.amount,
    required this.unit,
    required this.snapshotKcal,
    required this.snapshotProtein,
    required this.snapshotCarbs,
    required this.snapshotFat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<int>(timestamp);
    map['meal_slot'] = Variable<String>(mealSlot);
    map['food_item_id'] = Variable<String>(foodItemId);
    map['amount'] = Variable<double>(amount);
    map['unit'] = Variable<String>(unit);
    map['snapshot_kcal'] = Variable<double>(snapshotKcal);
    map['snapshot_protein'] = Variable<double>(snapshotProtein);
    map['snapshot_carbs'] = Variable<double>(snapshotCarbs);
    map['snapshot_fat'] = Variable<double>(snapshotFat);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      mealSlot: Value(mealSlot),
      foodItemId: Value(foodItemId),
      amount: Value(amount),
      unit: Value(unit),
      snapshotKcal: Value(snapshotKcal),
      snapshotProtein: Value(snapshotProtein),
      snapshotCarbs: Value(snapshotCarbs),
      snapshotFat: Value(snapshotFat),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      mealSlot: serializer.fromJson<String>(json['mealSlot']),
      foodItemId: serializer.fromJson<String>(json['foodItemId']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String>(json['unit']),
      snapshotKcal: serializer.fromJson<double>(json['snapshotKcal']),
      snapshotProtein: serializer.fromJson<double>(json['snapshotProtein']),
      snapshotCarbs: serializer.fromJson<double>(json['snapshotCarbs']),
      snapshotFat: serializer.fromJson<double>(json['snapshotFat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<int>(timestamp),
      'mealSlot': serializer.toJson<String>(mealSlot),
      'foodItemId': serializer.toJson<String>(foodItemId),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String>(unit),
      'snapshotKcal': serializer.toJson<double>(snapshotKcal),
      'snapshotProtein': serializer.toJson<double>(snapshotProtein),
      'snapshotCarbs': serializer.toJson<double>(snapshotCarbs),
      'snapshotFat': serializer.toJson<double>(snapshotFat),
    };
  }

  LogEntry copyWith({
    String? id,
    int? timestamp,
    String? mealSlot,
    String? foodItemId,
    double? amount,
    String? unit,
    double? snapshotKcal,
    double? snapshotProtein,
    double? snapshotCarbs,
    double? snapshotFat,
  }) => LogEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    mealSlot: mealSlot ?? this.mealSlot,
    foodItemId: foodItemId ?? this.foodItemId,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    snapshotKcal: snapshotKcal ?? this.snapshotKcal,
    snapshotProtein: snapshotProtein ?? this.snapshotProtein,
    snapshotCarbs: snapshotCarbs ?? this.snapshotCarbs,
    snapshotFat: snapshotFat ?? this.snapshotFat,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      mealSlot: data.mealSlot.present ? data.mealSlot.value : this.mealSlot,
      foodItemId: data.foodItemId.present
          ? data.foodItemId.value
          : this.foodItemId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      snapshotKcal: data.snapshotKcal.present
          ? data.snapshotKcal.value
          : this.snapshotKcal,
      snapshotProtein: data.snapshotProtein.present
          ? data.snapshotProtein.value
          : this.snapshotProtein,
      snapshotCarbs: data.snapshotCarbs.present
          ? data.snapshotCarbs.value
          : this.snapshotCarbs,
      snapshotFat: data.snapshotFat.present
          ? data.snapshotFat.value
          : this.snapshotFat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('mealSlot: $mealSlot, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('snapshotKcal: $snapshotKcal, ')
          ..write('snapshotProtein: $snapshotProtein, ')
          ..write('snapshotCarbs: $snapshotCarbs, ')
          ..write('snapshotFat: $snapshotFat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    mealSlot,
    foodItemId,
    amount,
    unit,
    snapshotKcal,
    snapshotProtein,
    snapshotCarbs,
    snapshotFat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.mealSlot == this.mealSlot &&
          other.foodItemId == this.foodItemId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.snapshotKcal == this.snapshotKcal &&
          other.snapshotProtein == this.snapshotProtein &&
          other.snapshotCarbs == this.snapshotCarbs &&
          other.snapshotFat == this.snapshotFat);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<String> id;
  final Value<int> timestamp;
  final Value<String> mealSlot;
  final Value<String> foodItemId;
  final Value<double> amount;
  final Value<String> unit;
  final Value<double> snapshotKcal;
  final Value<double> snapshotProtein;
  final Value<double> snapshotCarbs;
  final Value<double> snapshotFat;
  final Value<int> rowid;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.mealSlot = const Value.absent(),
    this.foodItemId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.snapshotKcal = const Value.absent(),
    this.snapshotProtein = const Value.absent(),
    this.snapshotCarbs = const Value.absent(),
    this.snapshotFat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    required String id,
    required int timestamp,
    required String mealSlot,
    required String foodItemId,
    required double amount,
    required String unit,
    this.snapshotKcal = const Value.absent(),
    this.snapshotProtein = const Value.absent(),
    this.snapshotCarbs = const Value.absent(),
    this.snapshotFat = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       mealSlot = Value(mealSlot),
       foodItemId = Value(foodItemId),
       amount = Value(amount),
       unit = Value(unit);
  static Insertable<LogEntry> custom({
    Expression<String>? id,
    Expression<int>? timestamp,
    Expression<String>? mealSlot,
    Expression<String>? foodItemId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<double>? snapshotKcal,
    Expression<double>? snapshotProtein,
    Expression<double>? snapshotCarbs,
    Expression<double>? snapshotFat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (mealSlot != null) 'meal_slot': mealSlot,
      if (foodItemId != null) 'food_item_id': foodItemId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (snapshotKcal != null) 'snapshot_kcal': snapshotKcal,
      if (snapshotProtein != null) 'snapshot_protein': snapshotProtein,
      if (snapshotCarbs != null) 'snapshot_carbs': snapshotCarbs,
      if (snapshotFat != null) 'snapshot_fat': snapshotFat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? timestamp,
    Value<String>? mealSlot,
    Value<String>? foodItemId,
    Value<double>? amount,
    Value<String>? unit,
    Value<double>? snapshotKcal,
    Value<double>? snapshotProtein,
    Value<double>? snapshotCarbs,
    Value<double>? snapshotFat,
    Value<int>? rowid,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mealSlot: mealSlot ?? this.mealSlot,
      foodItemId: foodItemId ?? this.foodItemId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      snapshotKcal: snapshotKcal ?? this.snapshotKcal,
      snapshotProtein: snapshotProtein ?? this.snapshotProtein,
      snapshotCarbs: snapshotCarbs ?? this.snapshotCarbs,
      snapshotFat: snapshotFat ?? this.snapshotFat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (mealSlot.present) {
      map['meal_slot'] = Variable<String>(mealSlot.value);
    }
    if (foodItemId.present) {
      map['food_item_id'] = Variable<String>(foodItemId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (snapshotKcal.present) {
      map['snapshot_kcal'] = Variable<double>(snapshotKcal.value);
    }
    if (snapshotProtein.present) {
      map['snapshot_protein'] = Variable<double>(snapshotProtein.value);
    }
    if (snapshotCarbs.present) {
      map['snapshot_carbs'] = Variable<double>(snapshotCarbs.value);
    }
    if (snapshotFat.present) {
      map['snapshot_fat'] = Variable<double>(snapshotFat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('mealSlot: $mealSlot, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('snapshotKcal: $snapshotKcal, ')
          ..write('snapshotProtein: $snapshotProtein, ')
          ..write('snapshotCarbs: $snapshotCarbs, ')
          ..write('snapshotFat: $snapshotFat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTable extends DailyStats
    with TableInfo<$DailyStatsTable, DailyStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calorieGoalMeta = const VerificationMeta(
    'calorieGoal',
  );
  @override
  late final GeneratedColumn<double> calorieGoal = GeneratedColumn<double>(
    'calorie_goal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesTrackedMeta = const VerificationMeta(
    'caloriesTracked',
  );
  @override
  late final GeneratedColumn<double> caloriesTracked = GeneratedColumn<double>(
    'calories_tracked',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _carbsGoalMeta = const VerificationMeta(
    'carbsGoal',
  );
  @override
  late final GeneratedColumn<double> carbsGoal = GeneratedColumn<double>(
    'carbs_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsTrackedMeta = const VerificationMeta(
    'carbsTracked',
  );
  @override
  late final GeneratedColumn<double> carbsTracked = GeneratedColumn<double>(
    'carbs_tracked',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGoalMeta = const VerificationMeta(
    'fatGoal',
  );
  @override
  late final GeneratedColumn<double> fatGoal = GeneratedColumn<double>(
    'fat_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatTrackedMeta = const VerificationMeta(
    'fatTracked',
  );
  @override
  late final GeneratedColumn<double> fatTracked = GeneratedColumn<double>(
    'fat_tracked',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGoalMeta = const VerificationMeta(
    'proteinGoal',
  );
  @override
  late final GeneratedColumn<double> proteinGoal = GeneratedColumn<double>(
    'protein_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinTrackedMeta = const VerificationMeta(
    'proteinTracked',
  );
  @override
  late final GeneratedColumn<double> proteinTracked = GeneratedColumn<double>(
    'protein_tracked',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeCaloriesBurnedMeta =
      const VerificationMeta('activeCaloriesBurned');
  @override
  late final GeneratedColumn<double> activeCaloriesBurned =
      GeneratedColumn<double>(
        'active_calories_burned',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _activeCaloriesUpdatedAtMeta =
      const VerificationMeta('activeCaloriesUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> activeCaloriesUpdatedAt =
      GeneratedColumn<DateTime>(
        'active_calories_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    calorieGoal,
    caloriesTracked,
    carbsGoal,
    carbsTracked,
    fatGoal,
    fatTracked,
    proteinGoal,
    proteinTracked,
    activeCaloriesBurned,
    activeCaloriesUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('calorie_goal')) {
      context.handle(
        _calorieGoalMeta,
        calorieGoal.isAcceptableOrUnknown(
          data['calorie_goal']!,
          _calorieGoalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calorieGoalMeta);
    }
    if (data.containsKey('calories_tracked')) {
      context.handle(
        _caloriesTrackedMeta,
        caloriesTracked.isAcceptableOrUnknown(
          data['calories_tracked']!,
          _caloriesTrackedMeta,
        ),
      );
    }
    if (data.containsKey('carbs_goal')) {
      context.handle(
        _carbsGoalMeta,
        carbsGoal.isAcceptableOrUnknown(data['carbs_goal']!, _carbsGoalMeta),
      );
    }
    if (data.containsKey('carbs_tracked')) {
      context.handle(
        _carbsTrackedMeta,
        carbsTracked.isAcceptableOrUnknown(
          data['carbs_tracked']!,
          _carbsTrackedMeta,
        ),
      );
    }
    if (data.containsKey('fat_goal')) {
      context.handle(
        _fatGoalMeta,
        fatGoal.isAcceptableOrUnknown(data['fat_goal']!, _fatGoalMeta),
      );
    }
    if (data.containsKey('fat_tracked')) {
      context.handle(
        _fatTrackedMeta,
        fatTracked.isAcceptableOrUnknown(data['fat_tracked']!, _fatTrackedMeta),
      );
    }
    if (data.containsKey('protein_goal')) {
      context.handle(
        _proteinGoalMeta,
        proteinGoal.isAcceptableOrUnknown(
          data['protein_goal']!,
          _proteinGoalMeta,
        ),
      );
    }
    if (data.containsKey('protein_tracked')) {
      context.handle(
        _proteinTrackedMeta,
        proteinTracked.isAcceptableOrUnknown(
          data['protein_tracked']!,
          _proteinTrackedMeta,
        ),
      );
    }
    if (data.containsKey('active_calories_burned')) {
      context.handle(
        _activeCaloriesBurnedMeta,
        activeCaloriesBurned.isAcceptableOrUnknown(
          data['active_calories_burned']!,
          _activeCaloriesBurnedMeta,
        ),
      );
    }
    if (data.containsKey('active_calories_updated_at')) {
      context.handle(
        _activeCaloriesUpdatedAtMeta,
        activeCaloriesUpdatedAt.isAcceptableOrUnknown(
          data['active_calories_updated_at']!,
          _activeCaloriesUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStat(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      calorieGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calorie_goal'],
      )!,
      caloriesTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_tracked'],
      )!,
      carbsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_goal'],
      ),
      carbsTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_tracked'],
      ),
      fatGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_goal'],
      ),
      fatTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_tracked'],
      ),
      proteinGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_goal'],
      ),
      proteinTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_tracked'],
      ),
      activeCaloriesBurned: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}active_calories_burned'],
      )!,
      activeCaloriesUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}active_calories_updated_at'],
      ),
    );
  }

  @override
  $DailyStatsTable createAlias(String alias) {
    return $DailyStatsTable(attachedDatabase, alias);
  }
}

class DailyStat extends DataClass implements Insertable<DailyStat> {
  final String date;
  final double calorieGoal;
  final double caloriesTracked;
  final double? carbsGoal;
  final double? carbsTracked;
  final double? fatGoal;
  final double? fatTracked;
  final double? proteinGoal;
  final double? proteinTracked;
  final double activeCaloriesBurned;
  final DateTime? activeCaloriesUpdatedAt;
  const DailyStat({
    required this.date,
    required this.calorieGoal,
    required this.caloriesTracked,
    this.carbsGoal,
    this.carbsTracked,
    this.fatGoal,
    this.fatTracked,
    this.proteinGoal,
    this.proteinTracked,
    required this.activeCaloriesBurned,
    this.activeCaloriesUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['calorie_goal'] = Variable<double>(calorieGoal);
    map['calories_tracked'] = Variable<double>(caloriesTracked);
    if (!nullToAbsent || carbsGoal != null) {
      map['carbs_goal'] = Variable<double>(carbsGoal);
    }
    if (!nullToAbsent || carbsTracked != null) {
      map['carbs_tracked'] = Variable<double>(carbsTracked);
    }
    if (!nullToAbsent || fatGoal != null) {
      map['fat_goal'] = Variable<double>(fatGoal);
    }
    if (!nullToAbsent || fatTracked != null) {
      map['fat_tracked'] = Variable<double>(fatTracked);
    }
    if (!nullToAbsent || proteinGoal != null) {
      map['protein_goal'] = Variable<double>(proteinGoal);
    }
    if (!nullToAbsent || proteinTracked != null) {
      map['protein_tracked'] = Variable<double>(proteinTracked);
    }
    map['active_calories_burned'] = Variable<double>(activeCaloriesBurned);
    if (!nullToAbsent || activeCaloriesUpdatedAt != null) {
      map['active_calories_updated_at'] = Variable<DateTime>(
        activeCaloriesUpdatedAt,
      );
    }
    return map;
  }

  DailyStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsCompanion(
      date: Value(date),
      calorieGoal: Value(calorieGoal),
      caloriesTracked: Value(caloriesTracked),
      carbsGoal: carbsGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsGoal),
      carbsTracked: carbsTracked == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsTracked),
      fatGoal: fatGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(fatGoal),
      fatTracked: fatTracked == null && nullToAbsent
          ? const Value.absent()
          : Value(fatTracked),
      proteinGoal: proteinGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinGoal),
      proteinTracked: proteinTracked == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinTracked),
      activeCaloriesBurned: Value(activeCaloriesBurned),
      activeCaloriesUpdatedAt: activeCaloriesUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activeCaloriesUpdatedAt),
    );
  }

  factory DailyStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStat(
      date: serializer.fromJson<String>(json['date']),
      calorieGoal: serializer.fromJson<double>(json['calorieGoal']),
      caloriesTracked: serializer.fromJson<double>(json['caloriesTracked']),
      carbsGoal: serializer.fromJson<double?>(json['carbsGoal']),
      carbsTracked: serializer.fromJson<double?>(json['carbsTracked']),
      fatGoal: serializer.fromJson<double?>(json['fatGoal']),
      fatTracked: serializer.fromJson<double?>(json['fatTracked']),
      proteinGoal: serializer.fromJson<double?>(json['proteinGoal']),
      proteinTracked: serializer.fromJson<double?>(json['proteinTracked']),
      activeCaloriesBurned: serializer.fromJson<double>(
        json['activeCaloriesBurned'],
      ),
      activeCaloriesUpdatedAt: serializer.fromJson<DateTime?>(
        json['activeCaloriesUpdatedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'calorieGoal': serializer.toJson<double>(calorieGoal),
      'caloriesTracked': serializer.toJson<double>(caloriesTracked),
      'carbsGoal': serializer.toJson<double?>(carbsGoal),
      'carbsTracked': serializer.toJson<double?>(carbsTracked),
      'fatGoal': serializer.toJson<double?>(fatGoal),
      'fatTracked': serializer.toJson<double?>(fatTracked),
      'proteinGoal': serializer.toJson<double?>(proteinGoal),
      'proteinTracked': serializer.toJson<double?>(proteinTracked),
      'activeCaloriesBurned': serializer.toJson<double>(activeCaloriesBurned),
      'activeCaloriesUpdatedAt': serializer.toJson<DateTime?>(
        activeCaloriesUpdatedAt,
      ),
    };
  }

  DailyStat copyWith({
    String? date,
    double? calorieGoal,
    double? caloriesTracked,
    Value<double?> carbsGoal = const Value.absent(),
    Value<double?> carbsTracked = const Value.absent(),
    Value<double?> fatGoal = const Value.absent(),
    Value<double?> fatTracked = const Value.absent(),
    Value<double?> proteinGoal = const Value.absent(),
    Value<double?> proteinTracked = const Value.absent(),
    double? activeCaloriesBurned,
    Value<DateTime?> activeCaloriesUpdatedAt = const Value.absent(),
  }) => DailyStat(
    date: date ?? this.date,
    calorieGoal: calorieGoal ?? this.calorieGoal,
    caloriesTracked: caloriesTracked ?? this.caloriesTracked,
    carbsGoal: carbsGoal.present ? carbsGoal.value : this.carbsGoal,
    carbsTracked: carbsTracked.present ? carbsTracked.value : this.carbsTracked,
    fatGoal: fatGoal.present ? fatGoal.value : this.fatGoal,
    fatTracked: fatTracked.present ? fatTracked.value : this.fatTracked,
    proteinGoal: proteinGoal.present ? proteinGoal.value : this.proteinGoal,
    proteinTracked: proteinTracked.present
        ? proteinTracked.value
        : this.proteinTracked,
    activeCaloriesBurned: activeCaloriesBurned ?? this.activeCaloriesBurned,
    activeCaloriesUpdatedAt: activeCaloriesUpdatedAt.present
        ? activeCaloriesUpdatedAt.value
        : this.activeCaloriesUpdatedAt,
  );
  DailyStat copyWithCompanion(DailyStatsCompanion data) {
    return DailyStat(
      date: data.date.present ? data.date.value : this.date,
      calorieGoal: data.calorieGoal.present
          ? data.calorieGoal.value
          : this.calorieGoal,
      caloriesTracked: data.caloriesTracked.present
          ? data.caloriesTracked.value
          : this.caloriesTracked,
      carbsGoal: data.carbsGoal.present ? data.carbsGoal.value : this.carbsGoal,
      carbsTracked: data.carbsTracked.present
          ? data.carbsTracked.value
          : this.carbsTracked,
      fatGoal: data.fatGoal.present ? data.fatGoal.value : this.fatGoal,
      fatTracked: data.fatTracked.present
          ? data.fatTracked.value
          : this.fatTracked,
      proteinGoal: data.proteinGoal.present
          ? data.proteinGoal.value
          : this.proteinGoal,
      proteinTracked: data.proteinTracked.present
          ? data.proteinTracked.value
          : this.proteinTracked,
      activeCaloriesBurned: data.activeCaloriesBurned.present
          ? data.activeCaloriesBurned.value
          : this.activeCaloriesBurned,
      activeCaloriesUpdatedAt: data.activeCaloriesUpdatedAt.present
          ? data.activeCaloriesUpdatedAt.value
          : this.activeCaloriesUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStat(')
          ..write('date: $date, ')
          ..write('calorieGoal: $calorieGoal, ')
          ..write('caloriesTracked: $caloriesTracked, ')
          ..write('carbsGoal: $carbsGoal, ')
          ..write('carbsTracked: $carbsTracked, ')
          ..write('fatGoal: $fatGoal, ')
          ..write('fatTracked: $fatTracked, ')
          ..write('proteinGoal: $proteinGoal, ')
          ..write('proteinTracked: $proteinTracked, ')
          ..write('activeCaloriesBurned: $activeCaloriesBurned, ')
          ..write('activeCaloriesUpdatedAt: $activeCaloriesUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    calorieGoal,
    caloriesTracked,
    carbsGoal,
    carbsTracked,
    fatGoal,
    fatTracked,
    proteinGoal,
    proteinTracked,
    activeCaloriesBurned,
    activeCaloriesUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStat &&
          other.date == this.date &&
          other.calorieGoal == this.calorieGoal &&
          other.caloriesTracked == this.caloriesTracked &&
          other.carbsGoal == this.carbsGoal &&
          other.carbsTracked == this.carbsTracked &&
          other.fatGoal == this.fatGoal &&
          other.fatTracked == this.fatTracked &&
          other.proteinGoal == this.proteinGoal &&
          other.proteinTracked == this.proteinTracked &&
          other.activeCaloriesBurned == this.activeCaloriesBurned &&
          other.activeCaloriesUpdatedAt == this.activeCaloriesUpdatedAt);
}

class DailyStatsCompanion extends UpdateCompanion<DailyStat> {
  final Value<String> date;
  final Value<double> calorieGoal;
  final Value<double> caloriesTracked;
  final Value<double?> carbsGoal;
  final Value<double?> carbsTracked;
  final Value<double?> fatGoal;
  final Value<double?> fatTracked;
  final Value<double?> proteinGoal;
  final Value<double?> proteinTracked;
  final Value<double> activeCaloriesBurned;
  final Value<DateTime?> activeCaloriesUpdatedAt;
  final Value<int> rowid;
  const DailyStatsCompanion({
    this.date = const Value.absent(),
    this.calorieGoal = const Value.absent(),
    this.caloriesTracked = const Value.absent(),
    this.carbsGoal = const Value.absent(),
    this.carbsTracked = const Value.absent(),
    this.fatGoal = const Value.absent(),
    this.fatTracked = const Value.absent(),
    this.proteinGoal = const Value.absent(),
    this.proteinTracked = const Value.absent(),
    this.activeCaloriesBurned = const Value.absent(),
    this.activeCaloriesUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStatsCompanion.insert({
    required String date,
    required double calorieGoal,
    this.caloriesTracked = const Value.absent(),
    this.carbsGoal = const Value.absent(),
    this.carbsTracked = const Value.absent(),
    this.fatGoal = const Value.absent(),
    this.fatTracked = const Value.absent(),
    this.proteinGoal = const Value.absent(),
    this.proteinTracked = const Value.absent(),
    this.activeCaloriesBurned = const Value.absent(),
    this.activeCaloriesUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       calorieGoal = Value(calorieGoal);
  static Insertable<DailyStat> custom({
    Expression<String>? date,
    Expression<double>? calorieGoal,
    Expression<double>? caloriesTracked,
    Expression<double>? carbsGoal,
    Expression<double>? carbsTracked,
    Expression<double>? fatGoal,
    Expression<double>? fatTracked,
    Expression<double>? proteinGoal,
    Expression<double>? proteinTracked,
    Expression<double>? activeCaloriesBurned,
    Expression<DateTime>? activeCaloriesUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (calorieGoal != null) 'calorie_goal': calorieGoal,
      if (caloriesTracked != null) 'calories_tracked': caloriesTracked,
      if (carbsGoal != null) 'carbs_goal': carbsGoal,
      if (carbsTracked != null) 'carbs_tracked': carbsTracked,
      if (fatGoal != null) 'fat_goal': fatGoal,
      if (fatTracked != null) 'fat_tracked': fatTracked,
      if (proteinGoal != null) 'protein_goal': proteinGoal,
      if (proteinTracked != null) 'protein_tracked': proteinTracked,
      if (activeCaloriesBurned != null)
        'active_calories_burned': activeCaloriesBurned,
      if (activeCaloriesUpdatedAt != null)
        'active_calories_updated_at': activeCaloriesUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStatsCompanion copyWith({
    Value<String>? date,
    Value<double>? calorieGoal,
    Value<double>? caloriesTracked,
    Value<double?>? carbsGoal,
    Value<double?>? carbsTracked,
    Value<double?>? fatGoal,
    Value<double?>? fatTracked,
    Value<double?>? proteinGoal,
    Value<double?>? proteinTracked,
    Value<double>? activeCaloriesBurned,
    Value<DateTime?>? activeCaloriesUpdatedAt,
    Value<int>? rowid,
  }) {
    return DailyStatsCompanion(
      date: date ?? this.date,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      caloriesTracked: caloriesTracked ?? this.caloriesTracked,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      carbsTracked: carbsTracked ?? this.carbsTracked,
      fatGoal: fatGoal ?? this.fatGoal,
      fatTracked: fatTracked ?? this.fatTracked,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      proteinTracked: proteinTracked ?? this.proteinTracked,
      activeCaloriesBurned: activeCaloriesBurned ?? this.activeCaloriesBurned,
      activeCaloriesUpdatedAt:
          activeCaloriesUpdatedAt ?? this.activeCaloriesUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (calorieGoal.present) {
      map['calorie_goal'] = Variable<double>(calorieGoal.value);
    }
    if (caloriesTracked.present) {
      map['calories_tracked'] = Variable<double>(caloriesTracked.value);
    }
    if (carbsGoal.present) {
      map['carbs_goal'] = Variable<double>(carbsGoal.value);
    }
    if (carbsTracked.present) {
      map['carbs_tracked'] = Variable<double>(carbsTracked.value);
    }
    if (fatGoal.present) {
      map['fat_goal'] = Variable<double>(fatGoal.value);
    }
    if (fatTracked.present) {
      map['fat_tracked'] = Variable<double>(fatTracked.value);
    }
    if (proteinGoal.present) {
      map['protein_goal'] = Variable<double>(proteinGoal.value);
    }
    if (proteinTracked.present) {
      map['protein_tracked'] = Variable<double>(proteinTracked.value);
    }
    if (activeCaloriesBurned.present) {
      map['active_calories_burned'] = Variable<double>(
        activeCaloriesBurned.value,
      );
    }
    if (activeCaloriesUpdatedAt.present) {
      map['active_calories_updated_at'] = Variable<DateTime>(
        activeCaloriesUpdatedAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsCompanion(')
          ..write('date: $date, ')
          ..write('calorieGoal: $calorieGoal, ')
          ..write('caloriesTracked: $caloriesTracked, ')
          ..write('carbsGoal: $carbsGoal, ')
          ..write('carbsTracked: $carbsTracked, ')
          ..write('fatGoal: $fatGoal, ')
          ..write('fatTracked: $fatTracked, ')
          ..write('proteinGoal: $proteinGoal, ')
          ..write('proteinTracked: $proteinTracked, ')
          ..write('activeCaloriesBurned: $activeCaloriesBurned, ')
          ..write('activeCaloriesUpdatedAt: $activeCaloriesUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigTable extends Config with TableInfo<$ConfigTable, ConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ConfigTable createAlias(String alias) {
    return $ConfigTable(attachedDatabase, alias);
  }
}

class ConfigData extends DataClass implements Insertable<ConfigData> {
  final String key;
  final String value;
  const ConfigData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ConfigCompanion toCompanion(bool nullToAbsent) {
    return ConfigCompanion(key: Value(key), value: Value(value));
  }

  factory ConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ConfigData copyWith({String? key, String? value}) =>
      ConfigData(key: key ?? this.key, value: value ?? this.value);
  ConfigData copyWithCompanion(ConfigCompanion data) {
    return ConfigData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigData &&
          other.key == this.key &&
          other.value == this.value);
}

class ConfigCompanion extends UpdateCompanion<ConfigData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ConfigCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ConfigData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ConfigCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<int> birthday = GeneratedColumn<int>(
    'birthday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _palMeta = const VerificationMeta('pal');
  @override
  late final GeneratedColumn<String> pal = GeneratedColumn<String>(
    'pal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    birthday,
    heightCm,
    weightKg,
    gender,
    goal,
    pal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    } else if (isInserting) {
      context.missing(_birthdayMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('pal')) {
      context.handle(
        _palMeta,
        pal.isAcceptableOrUnknown(data['pal']!, _palMeta),
      );
    } else if (isInserting) {
      context.missing(_palMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birthday'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      pal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pal'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final int id;
  final int birthday;
  final double heightCm;
  final double weightKg;
  final String gender;
  final String goal;
  final String pal;
  const UserProfileData({
    required this.id,
    required this.birthday,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.goal,
    required this.pal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['birthday'] = Variable<int>(birthday);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    map['gender'] = Variable<String>(gender);
    map['goal'] = Variable<String>(goal);
    map['pal'] = Variable<String>(pal);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      birthday: Value(birthday),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      gender: Value(gender),
      goal: Value(goal),
      pal: Value(pal),
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<int>(json['id']),
      birthday: serializer.fromJson<int>(json['birthday']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      gender: serializer.fromJson<String>(json['gender']),
      goal: serializer.fromJson<String>(json['goal']),
      pal: serializer.fromJson<String>(json['pal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birthday': serializer.toJson<int>(birthday),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'gender': serializer.toJson<String>(gender),
      'goal': serializer.toJson<String>(goal),
      'pal': serializer.toJson<String>(pal),
    };
  }

  UserProfileData copyWith({
    int? id,
    int? birthday,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? goal,
    String? pal,
  }) => UserProfileData(
    id: id ?? this.id,
    birthday: birthday ?? this.birthday,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    gender: gender ?? this.gender,
    goal: goal ?? this.goal,
    pal: pal ?? this.pal,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      gender: data.gender.present ? data.gender.value : this.gender,
      goal: data.goal.present ? data.goal.value : this.goal,
      pal: data.pal.present ? data.pal.value : this.pal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('birthday: $birthday, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('gender: $gender, ')
          ..write('goal: $goal, ')
          ..write('pal: $pal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, birthday, heightCm, weightKg, gender, goal, pal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.birthday == this.birthday &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.gender == this.gender &&
          other.goal == this.goal &&
          other.pal == this.pal);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<int> id;
  final Value<int> birthday;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<String> gender;
  final Value<String> goal;
  final Value<String> pal;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.birthday = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.gender = const Value.absent(),
    this.goal = const Value.absent(),
    this.pal = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    required int birthday,
    required double heightCm,
    required double weightKg,
    required String gender,
    required String goal,
    required String pal,
  }) : birthday = Value(birthday),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       gender = Value(gender),
       goal = Value(goal),
       pal = Value(pal);
  static Insertable<UserProfileData> custom({
    Expression<int>? id,
    Expression<int>? birthday,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? gender,
    Expression<String>? goal,
    Expression<String>? pal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birthday != null) 'birthday': birthday,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (gender != null) 'gender': gender,
      if (goal != null) 'goal': goal,
      if (pal != null) 'pal': pal,
    });
  }

  UserProfileCompanion copyWith({
    Value<int>? id,
    Value<int>? birthday,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<String>? gender,
    Value<String>? goal,
    Value<String>? pal,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      birthday: birthday ?? this.birthday,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      pal: pal ?? this.pal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<int>(birthday.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (pal.present) {
      map['pal'] = Variable<String>(pal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('birthday: $birthday, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('gender: $gender, ')
          ..write('goal: $goal, ')
          ..write('pal: $pal')
          ..write(')'))
        .toString();
  }
}

class $UserActivitiesTable extends UserActivities
    with TableInfo<$UserActivitiesTable, UserActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _burnedKcalMeta = const VerificationMeta(
    'burnedKcal',
  );
  @override
  late final GeneratedColumn<double> burnedKcal = GeneratedColumn<double>(
    'burned_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityCodeMeta = const VerificationMeta(
    'activityCode',
  );
  @override
  late final GeneratedColumn<String> activityCode = GeneratedColumn<String>(
    'activity_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityNameMeta = const VerificationMeta(
    'activityName',
  );
  @override
  late final GeneratedColumn<String> activityName = GeneratedColumn<String>(
    'activity_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityDescriptionMeta =
      const VerificationMeta('activityDescription');
  @override
  late final GeneratedColumn<String> activityDescription =
      GeneratedColumn<String>(
        'activity_description',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _activityMetsMeta = const VerificationMeta(
    'activityMets',
  );
  @override
  late final GeneratedColumn<double> activityMets = GeneratedColumn<double>(
    'activity_mets',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    duration,
    burnedKcal,
    activityCode,
    activityName,
    activityDescription,
    activityMets,
    activityType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('burned_kcal')) {
      context.handle(
        _burnedKcalMeta,
        burnedKcal.isAcceptableOrUnknown(data['burned_kcal']!, _burnedKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_burnedKcalMeta);
    }
    if (data.containsKey('activity_code')) {
      context.handle(
        _activityCodeMeta,
        activityCode.isAcceptableOrUnknown(
          data['activity_code']!,
          _activityCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityCodeMeta);
    }
    if (data.containsKey('activity_name')) {
      context.handle(
        _activityNameMeta,
        activityName.isAcceptableOrUnknown(
          data['activity_name']!,
          _activityNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityNameMeta);
    }
    if (data.containsKey('activity_description')) {
      context.handle(
        _activityDescriptionMeta,
        activityDescription.isAcceptableOrUnknown(
          data['activity_description']!,
          _activityDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('activity_mets')) {
      context.handle(
        _activityMetsMeta,
        activityMets.isAcceptableOrUnknown(
          data['activity_mets']!,
          _activityMetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityMetsMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserActivity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      )!,
      burnedKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}burned_kcal'],
      )!,
      activityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_code'],
      )!,
      activityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_name'],
      )!,
      activityDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_description'],
      )!,
      activityMets: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}activity_mets'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
    );
  }

  @override
  $UserActivitiesTable createAlias(String alias) {
    return $UserActivitiesTable(attachedDatabase, alias);
  }
}

class UserActivity extends DataClass implements Insertable<UserActivity> {
  final String id;
  final int date;
  final double duration;
  final double burnedKcal;
  final String activityCode;
  final String activityName;
  final String activityDescription;
  final double activityMets;
  final String activityType;
  const UserActivity({
    required this.id,
    required this.date,
    required this.duration,
    required this.burnedKcal,
    required this.activityCode,
    required this.activityName,
    required this.activityDescription,
    required this.activityMets,
    required this.activityType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<int>(date);
    map['duration'] = Variable<double>(duration);
    map['burned_kcal'] = Variable<double>(burnedKcal);
    map['activity_code'] = Variable<String>(activityCode);
    map['activity_name'] = Variable<String>(activityName);
    map['activity_description'] = Variable<String>(activityDescription);
    map['activity_mets'] = Variable<double>(activityMets);
    map['activity_type'] = Variable<String>(activityType);
    return map;
  }

  UserActivitiesCompanion toCompanion(bool nullToAbsent) {
    return UserActivitiesCompanion(
      id: Value(id),
      date: Value(date),
      duration: Value(duration),
      burnedKcal: Value(burnedKcal),
      activityCode: Value(activityCode),
      activityName: Value(activityName),
      activityDescription: Value(activityDescription),
      activityMets: Value(activityMets),
      activityType: Value(activityType),
    );
  }

  factory UserActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserActivity(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      duration: serializer.fromJson<double>(json['duration']),
      burnedKcal: serializer.fromJson<double>(json['burnedKcal']),
      activityCode: serializer.fromJson<String>(json['activityCode']),
      activityName: serializer.fromJson<String>(json['activityName']),
      activityDescription: serializer.fromJson<String>(
        json['activityDescription'],
      ),
      activityMets: serializer.fromJson<double>(json['activityMets']),
      activityType: serializer.fromJson<String>(json['activityType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<int>(date),
      'duration': serializer.toJson<double>(duration),
      'burnedKcal': serializer.toJson<double>(burnedKcal),
      'activityCode': serializer.toJson<String>(activityCode),
      'activityName': serializer.toJson<String>(activityName),
      'activityDescription': serializer.toJson<String>(activityDescription),
      'activityMets': serializer.toJson<double>(activityMets),
      'activityType': serializer.toJson<String>(activityType),
    };
  }

  UserActivity copyWith({
    String? id,
    int? date,
    double? duration,
    double? burnedKcal,
    String? activityCode,
    String? activityName,
    String? activityDescription,
    double? activityMets,
    String? activityType,
  }) => UserActivity(
    id: id ?? this.id,
    date: date ?? this.date,
    duration: duration ?? this.duration,
    burnedKcal: burnedKcal ?? this.burnedKcal,
    activityCode: activityCode ?? this.activityCode,
    activityName: activityName ?? this.activityName,
    activityDescription: activityDescription ?? this.activityDescription,
    activityMets: activityMets ?? this.activityMets,
    activityType: activityType ?? this.activityType,
  );
  UserActivity copyWithCompanion(UserActivitiesCompanion data) {
    return UserActivity(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      duration: data.duration.present ? data.duration.value : this.duration,
      burnedKcal: data.burnedKcal.present
          ? data.burnedKcal.value
          : this.burnedKcal,
      activityCode: data.activityCode.present
          ? data.activityCode.value
          : this.activityCode,
      activityName: data.activityName.present
          ? data.activityName.value
          : this.activityName,
      activityDescription: data.activityDescription.present
          ? data.activityDescription.value
          : this.activityDescription,
      activityMets: data.activityMets.present
          ? data.activityMets.value
          : this.activityMets,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserActivity(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('duration: $duration, ')
          ..write('burnedKcal: $burnedKcal, ')
          ..write('activityCode: $activityCode, ')
          ..write('activityName: $activityName, ')
          ..write('activityDescription: $activityDescription, ')
          ..write('activityMets: $activityMets, ')
          ..write('activityType: $activityType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    duration,
    burnedKcal,
    activityCode,
    activityName,
    activityDescription,
    activityMets,
    activityType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserActivity &&
          other.id == this.id &&
          other.date == this.date &&
          other.duration == this.duration &&
          other.burnedKcal == this.burnedKcal &&
          other.activityCode == this.activityCode &&
          other.activityName == this.activityName &&
          other.activityDescription == this.activityDescription &&
          other.activityMets == this.activityMets &&
          other.activityType == this.activityType);
}

class UserActivitiesCompanion extends UpdateCompanion<UserActivity> {
  final Value<String> id;
  final Value<int> date;
  final Value<double> duration;
  final Value<double> burnedKcal;
  final Value<String> activityCode;
  final Value<String> activityName;
  final Value<String> activityDescription;
  final Value<double> activityMets;
  final Value<String> activityType;
  final Value<int> rowid;
  const UserActivitiesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.duration = const Value.absent(),
    this.burnedKcal = const Value.absent(),
    this.activityCode = const Value.absent(),
    this.activityName = const Value.absent(),
    this.activityDescription = const Value.absent(),
    this.activityMets = const Value.absent(),
    this.activityType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserActivitiesCompanion.insert({
    required String id,
    required int date,
    required double duration,
    required double burnedKcal,
    required String activityCode,
    required String activityName,
    this.activityDescription = const Value.absent(),
    required double activityMets,
    required String activityType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       duration = Value(duration),
       burnedKcal = Value(burnedKcal),
       activityCode = Value(activityCode),
       activityName = Value(activityName),
       activityMets = Value(activityMets),
       activityType = Value(activityType);
  static Insertable<UserActivity> custom({
    Expression<String>? id,
    Expression<int>? date,
    Expression<double>? duration,
    Expression<double>? burnedKcal,
    Expression<String>? activityCode,
    Expression<String>? activityName,
    Expression<String>? activityDescription,
    Expression<double>? activityMets,
    Expression<String>? activityType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (duration != null) 'duration': duration,
      if (burnedKcal != null) 'burned_kcal': burnedKcal,
      if (activityCode != null) 'activity_code': activityCode,
      if (activityName != null) 'activity_name': activityName,
      if (activityDescription != null)
        'activity_description': activityDescription,
      if (activityMets != null) 'activity_mets': activityMets,
      if (activityType != null) 'activity_type': activityType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserActivitiesCompanion copyWith({
    Value<String>? id,
    Value<int>? date,
    Value<double>? duration,
    Value<double>? burnedKcal,
    Value<String>? activityCode,
    Value<String>? activityName,
    Value<String>? activityDescription,
    Value<double>? activityMets,
    Value<String>? activityType,
    Value<int>? rowid,
  }) {
    return UserActivitiesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      burnedKcal: burnedKcal ?? this.burnedKcal,
      activityCode: activityCode ?? this.activityCode,
      activityName: activityName ?? this.activityName,
      activityDescription: activityDescription ?? this.activityDescription,
      activityMets: activityMets ?? this.activityMets,
      activityType: activityType ?? this.activityType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (burnedKcal.present) {
      map['burned_kcal'] = Variable<double>(burnedKcal.value);
    }
    if (activityCode.present) {
      map['activity_code'] = Variable<String>(activityCode.value);
    }
    if (activityName.present) {
      map['activity_name'] = Variable<String>(activityName.value);
    }
    if (activityDescription.present) {
      map['activity_description'] = Variable<String>(activityDescription.value);
    }
    if (activityMets.present) {
      map['activity_mets'] = Variable<double>(activityMets.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('duration: $duration, ')
          ..write('burnedKcal: $burnedKcal, ')
          ..write('activityCode: $activityCode, ')
          ..write('activityName: $activityName, ')
          ..write('activityDescription: $activityDescription, ')
          ..write('activityMets: $activityMets, ')
          ..write('activityType: $activityType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $DailyStatsTable dailyStats = $DailyStatsTable(this);
  late final $ConfigTable config = $ConfigTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $UserActivitiesTable userActivities = $UserActivitiesTable(this);
  late final FoodItemDao foodItemDao = FoodItemDao(this as AppDatabase);
  late final LogEntryDao logEntryDao = LogEntryDao(this as AppDatabase);
  late final DailyStatsDao dailyStatsDao = DailyStatsDao(this as AppDatabase);
  late final ConfigDao configDao = ConfigDao(this as AppDatabase);
  late final UserProfileDao userProfileDao = UserProfileDao(
    this as AppDatabase,
  );
  late final UserActivityDao userActivityDao = UserActivityDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodItems,
    logEntries,
    dailyStats,
    config,
    userProfile,
    userActivities,
  ];
}

typedef $$FoodItemsTableCreateCompanionBuilder =
    FoodItemsCompanion Function({
      required String id,
      Value<String> source,
      Value<String?> barcode,
      Value<String?> name,
      Value<String?> brand,
      Value<String?> mealQuantity,
      Value<String?> mealUnit,
      Value<double?> servingQuantity,
      Value<String?> servingUnit,
      Value<String?> servingSize,
      Value<double?> kcalPer100,
      Value<double?> proteinPer100,
      Value<double?> carbsPer100,
      Value<double?> fatPer100,
      Value<double?> fibrePer100,
      Value<double?> sugarPer100,
      Value<double?> saturatedFatPer100,
      Value<String?> thumbnailImageUrl,
      Value<String?> mainImageUrl,
      Value<String?> url,
      Value<int?> lastUsedAt,
      Value<double?> lastUsedGrams,
      Value<bool> favourite,
      Value<int> rowid,
    });
typedef $$FoodItemsTableUpdateCompanionBuilder =
    FoodItemsCompanion Function({
      Value<String> id,
      Value<String> source,
      Value<String?> barcode,
      Value<String?> name,
      Value<String?> brand,
      Value<String?> mealQuantity,
      Value<String?> mealUnit,
      Value<double?> servingQuantity,
      Value<String?> servingUnit,
      Value<String?> servingSize,
      Value<double?> kcalPer100,
      Value<double?> proteinPer100,
      Value<double?> carbsPer100,
      Value<double?> fatPer100,
      Value<double?> fibrePer100,
      Value<double?> sugarPer100,
      Value<double?> saturatedFatPer100,
      Value<String?> thumbnailImageUrl,
      Value<String?> mainImageUrl,
      Value<String?> url,
      Value<int?> lastUsedAt,
      Value<double?> lastUsedGrams,
      Value<bool> favourite,
      Value<int> rowid,
    });

final class $$FoodItemsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem> {
  $$FoodItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LogEntriesTable, List<LogEntry>>
  _logEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: $_aliasNameGenerator(db.foodItems.id, db.logEntries.foodItemId),
  );

  $$LogEntriesTableProcessedTableManager get logEntriesRefs {
    final manager = $$LogEntriesTableTableManager(
      $_db,
      $_db.logEntries,
    ).filter((f) => f.foodItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealQuantity => $composableBuilder(
    column: $table.mealQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealUnit => $composableBuilder(
    column: $table.mealUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingQuantity => $composableBuilder(
    column: $table.servingQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fibrePer100 => $composableBuilder(
    column: $table.fibrePer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailImageUrl => $composableBuilder(
    column: $table.thumbnailImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastUsedGrams => $composableBuilder(
    column: $table.lastUsedGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($$LogEntriesTableFilterComposer f) f,
  ) {
    final $$LogEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.foodItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealQuantity => $composableBuilder(
    column: $table.mealQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealUnit => $composableBuilder(
    column: $table.mealUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingQuantity => $composableBuilder(
    column: $table.servingQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fibrePer100 => $composableBuilder(
    column: $table.fibrePer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailImageUrl => $composableBuilder(
    column: $table.thumbnailImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastUsedGrams => $composableBuilder(
    column: $table.lastUsedGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get mealQuantity => $composableBuilder(
    column: $table.mealQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mealUnit =>
      $composableBuilder(column: $table.mealUnit, builder: (column) => column);

  GeneratedColumn<double> get servingQuantity => $composableBuilder(
    column: $table.servingQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100 =>
      $composableBuilder(column: $table.fatPer100, builder: (column) => column);

  GeneratedColumn<double> get fibrePer100 => $composableBuilder(
    column: $table.fibrePer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailImageUrl => $composableBuilder(
    column: $table.thumbnailImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastUsedGrams => $composableBuilder(
    column: $table.lastUsedGrams,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favourite =>
      $composableBuilder(column: $table.favourite, builder: (column) => column);

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($$LogEntriesTableAnnotationComposer a) f,
  ) {
    final $$LogEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.foodItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemsTable,
          FoodItem,
          $$FoodItemsTableFilterComposer,
          $$FoodItemsTableOrderingComposer,
          $$FoodItemsTableAnnotationComposer,
          $$FoodItemsTableCreateCompanionBuilder,
          $$FoodItemsTableUpdateCompanionBuilder,
          (FoodItem, $$FoodItemsTableReferences),
          FoodItem,
          PrefetchHooks Function({bool logEntriesRefs})
        > {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> mealQuantity = const Value.absent(),
                Value<String?> mealUnit = const Value.absent(),
                Value<double?> servingQuantity = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<String?> servingSize = const Value.absent(),
                Value<double?> kcalPer100 = const Value.absent(),
                Value<double?> proteinPer100 = const Value.absent(),
                Value<double?> carbsPer100 = const Value.absent(),
                Value<double?> fatPer100 = const Value.absent(),
                Value<double?> fibrePer100 = const Value.absent(),
                Value<double?> sugarPer100 = const Value.absent(),
                Value<double?> saturatedFatPer100 = const Value.absent(),
                Value<String?> thumbnailImageUrl = const Value.absent(),
                Value<String?> mainImageUrl = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<double?> lastUsedGrams = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion(
                id: id,
                source: source,
                barcode: barcode,
                name: name,
                brand: brand,
                mealQuantity: mealQuantity,
                mealUnit: mealUnit,
                servingQuantity: servingQuantity,
                servingUnit: servingUnit,
                servingSize: servingSize,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                carbsPer100: carbsPer100,
                fatPer100: fatPer100,
                fibrePer100: fibrePer100,
                sugarPer100: sugarPer100,
                saturatedFatPer100: saturatedFatPer100,
                thumbnailImageUrl: thumbnailImageUrl,
                mainImageUrl: mainImageUrl,
                url: url,
                lastUsedAt: lastUsedAt,
                lastUsedGrams: lastUsedGrams,
                favourite: favourite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> mealQuantity = const Value.absent(),
                Value<String?> mealUnit = const Value.absent(),
                Value<double?> servingQuantity = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<String?> servingSize = const Value.absent(),
                Value<double?> kcalPer100 = const Value.absent(),
                Value<double?> proteinPer100 = const Value.absent(),
                Value<double?> carbsPer100 = const Value.absent(),
                Value<double?> fatPer100 = const Value.absent(),
                Value<double?> fibrePer100 = const Value.absent(),
                Value<double?> sugarPer100 = const Value.absent(),
                Value<double?> saturatedFatPer100 = const Value.absent(),
                Value<String?> thumbnailImageUrl = const Value.absent(),
                Value<String?> mainImageUrl = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<double?> lastUsedGrams = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion.insert(
                id: id,
                source: source,
                barcode: barcode,
                name: name,
                brand: brand,
                mealQuantity: mealQuantity,
                mealUnit: mealUnit,
                servingQuantity: servingQuantity,
                servingUnit: servingUnit,
                servingSize: servingSize,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                carbsPer100: carbsPer100,
                fatPer100: fatPer100,
                fibrePer100: fibrePer100,
                sugarPer100: sugarPer100,
                saturatedFatPer100: saturatedFatPer100,
                thumbnailImageUrl: thumbnailImageUrl,
                mainImageUrl: mainImageUrl,
                url: url,
                lastUsedAt: lastUsedAt,
                lastUsedGrams: lastUsedGrams,
                favourite: favourite,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoodItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({logEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (logEntriesRefs) db.logEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (logEntriesRefs)
                    await $_getPrefetchedData<
                      FoodItem,
                      $FoodItemsTable,
                      LogEntry
                    >(
                      currentTable: table,
                      referencedTable: $$FoodItemsTableReferences
                          ._logEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FoodItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).logEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.foodItemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemsTable,
      FoodItem,
      $$FoodItemsTableFilterComposer,
      $$FoodItemsTableOrderingComposer,
      $$FoodItemsTableAnnotationComposer,
      $$FoodItemsTableCreateCompanionBuilder,
      $$FoodItemsTableUpdateCompanionBuilder,
      (FoodItem, $$FoodItemsTableReferences),
      FoodItem,
      PrefetchHooks Function({bool logEntriesRefs})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder =
    LogEntriesCompanion Function({
      required String id,
      required int timestamp,
      required String mealSlot,
      required String foodItemId,
      required double amount,
      required String unit,
      Value<double> snapshotKcal,
      Value<double> snapshotProtein,
      Value<double> snapshotCarbs,
      Value<double> snapshotFat,
      Value<int> rowid,
    });
typedef $$LogEntriesTableUpdateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<String> id,
      Value<int> timestamp,
      Value<String> mealSlot,
      Value<String> foodItemId,
      Value<double> amount,
      Value<String> unit,
      Value<double> snapshotKcal,
      Value<double> snapshotProtein,
      Value<double> snapshotCarbs,
      Value<double> snapshotFat,
      Value<int> rowid,
    });

final class $$LogEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry> {
  $$LogEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodItemsTable _foodItemIdTable(_$AppDatabase db) =>
      db.foodItems.createAlias(
        $_aliasNameGenerator(db.logEntries.foodItemId, db.foodItems.id),
      );

  $$FoodItemsTableProcessedTableManager get foodItemId {
    final $_column = $_itemColumn<String>('food_item_id')!;

    final manager = $$FoodItemsTableTableManager(
      $_db,
      $_db.foodItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealSlot => $composableBuilder(
    column: $table.mealSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snapshotKcal => $composableBuilder(
    column: $table.snapshotKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snapshotProtein => $composableBuilder(
    column: $table.snapshotProtein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snapshotCarbs => $composableBuilder(
    column: $table.snapshotCarbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snapshotFat => $composableBuilder(
    column: $table.snapshotFat,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodItemsTableFilterComposer get foodItemId {
    final $$FoodItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodItemId,
      referencedTable: $db.foodItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodItemsTableFilterComposer(
            $db: $db,
            $table: $db.foodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealSlot => $composableBuilder(
    column: $table.mealSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snapshotKcal => $composableBuilder(
    column: $table.snapshotKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snapshotProtein => $composableBuilder(
    column: $table.snapshotProtein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snapshotCarbs => $composableBuilder(
    column: $table.snapshotCarbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snapshotFat => $composableBuilder(
    column: $table.snapshotFat,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodItemsTableOrderingComposer get foodItemId {
    final $$FoodItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodItemId,
      referencedTable: $db.foodItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodItemsTableOrderingComposer(
            $db: $db,
            $table: $db.foodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get mealSlot =>
      $composableBuilder(column: $table.mealSlot, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get snapshotKcal => $composableBuilder(
    column: $table.snapshotKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get snapshotProtein => $composableBuilder(
    column: $table.snapshotProtein,
    builder: (column) => column,
  );

  GeneratedColumn<double> get snapshotCarbs => $composableBuilder(
    column: $table.snapshotCarbs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get snapshotFat => $composableBuilder(
    column: $table.snapshotFat,
    builder: (column) => column,
  );

  $$FoodItemsTableAnnotationComposer get foodItemId {
    final $$FoodItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodItemId,
      referencedTable: $db.foodItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.foodItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, $$LogEntriesTableReferences),
          LogEntry,
          PrefetchHooks Function({bool foodItemId})
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String> mealSlot = const Value.absent(),
                Value<String> foodItemId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> snapshotKcal = const Value.absent(),
                Value<double> snapshotProtein = const Value.absent(),
                Value<double> snapshotCarbs = const Value.absent(),
                Value<double> snapshotFat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                timestamp: timestamp,
                mealSlot: mealSlot,
                foodItemId: foodItemId,
                amount: amount,
                unit: unit,
                snapshotKcal: snapshotKcal,
                snapshotProtein: snapshotProtein,
                snapshotCarbs: snapshotCarbs,
                snapshotFat: snapshotFat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int timestamp,
                required String mealSlot,
                required String foodItemId,
                required double amount,
                required String unit,
                Value<double> snapshotKcal = const Value.absent(),
                Value<double> snapshotProtein = const Value.absent(),
                Value<double> snapshotCarbs = const Value.absent(),
                Value<double> snapshotFat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                timestamp: timestamp,
                mealSlot: mealSlot,
                foodItemId: foodItemId,
                amount: amount,
                unit: unit,
                snapshotKcal: snapshotKcal,
                snapshotProtein: snapshotProtein,
                snapshotCarbs: snapshotCarbs,
                snapshotFat: snapshotFat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LogEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (foodItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodItemId,
                                referencedTable: $$LogEntriesTableReferences
                                    ._foodItemIdTable(db),
                                referencedColumn: $$LogEntriesTableReferences
                                    ._foodItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, $$LogEntriesTableReferences),
      LogEntry,
      PrefetchHooks Function({bool foodItemId})
    >;
typedef $$DailyStatsTableCreateCompanionBuilder =
    DailyStatsCompanion Function({
      required String date,
      required double calorieGoal,
      Value<double> caloriesTracked,
      Value<double?> carbsGoal,
      Value<double?> carbsTracked,
      Value<double?> fatGoal,
      Value<double?> fatTracked,
      Value<double?> proteinGoal,
      Value<double?> proteinTracked,
      Value<double> activeCaloriesBurned,
      Value<DateTime?> activeCaloriesUpdatedAt,
      Value<int> rowid,
    });
typedef $$DailyStatsTableUpdateCompanionBuilder =
    DailyStatsCompanion Function({
      Value<String> date,
      Value<double> calorieGoal,
      Value<double> caloriesTracked,
      Value<double?> carbsGoal,
      Value<double?> carbsTracked,
      Value<double?> fatGoal,
      Value<double?> fatTracked,
      Value<double?> proteinGoal,
      Value<double?> proteinTracked,
      Value<double> activeCaloriesBurned,
      Value<DateTime?> activeCaloriesUpdatedAt,
      Value<int> rowid,
    });

class $$DailyStatsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calorieGoal => $composableBuilder(
    column: $table.calorieGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesTracked => $composableBuilder(
    column: $table.caloriesTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsGoal => $composableBuilder(
    column: $table.carbsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsTracked => $composableBuilder(
    column: $table.carbsTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatGoal => $composableBuilder(
    column: $table.fatGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatTracked => $composableBuilder(
    column: $table.fatTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinTracked => $composableBuilder(
    column: $table.proteinTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get activeCaloriesBurned => $composableBuilder(
    column: $table.activeCaloriesBurned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get activeCaloriesUpdatedAt => $composableBuilder(
    column: $table.activeCaloriesUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calorieGoal => $composableBuilder(
    column: $table.calorieGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesTracked => $composableBuilder(
    column: $table.caloriesTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsGoal => $composableBuilder(
    column: $table.carbsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsTracked => $composableBuilder(
    column: $table.carbsTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatGoal => $composableBuilder(
    column: $table.fatGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatTracked => $composableBuilder(
    column: $table.fatTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinTracked => $composableBuilder(
    column: $table.proteinTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get activeCaloriesBurned => $composableBuilder(
    column: $table.activeCaloriesBurned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activeCaloriesUpdatedAt => $composableBuilder(
    column: $table.activeCaloriesUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get calorieGoal => $composableBuilder(
    column: $table.calorieGoal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caloriesTracked => $composableBuilder(
    column: $table.caloriesTracked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsGoal =>
      $composableBuilder(column: $table.carbsGoal, builder: (column) => column);

  GeneratedColumn<double> get carbsTracked => $composableBuilder(
    column: $table.carbsTracked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatGoal =>
      $composableBuilder(column: $table.fatGoal, builder: (column) => column);

  GeneratedColumn<double> get fatTracked => $composableBuilder(
    column: $table.fatTracked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinGoal => $composableBuilder(
    column: $table.proteinGoal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinTracked => $composableBuilder(
    column: $table.proteinTracked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get activeCaloriesBurned => $composableBuilder(
    column: $table.activeCaloriesBurned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get activeCaloriesUpdatedAt => $composableBuilder(
    column: $table.activeCaloriesUpdatedAt,
    builder: (column) => column,
  );
}

class $$DailyStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStatsTable,
          DailyStat,
          $$DailyStatsTableFilterComposer,
          $$DailyStatsTableOrderingComposer,
          $$DailyStatsTableAnnotationComposer,
          $$DailyStatsTableCreateCompanionBuilder,
          $$DailyStatsTableUpdateCompanionBuilder,
          (
            DailyStat,
            BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStat>,
          ),
          DailyStat,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableManager(_$AppDatabase db, $DailyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<double> calorieGoal = const Value.absent(),
                Value<double> caloriesTracked = const Value.absent(),
                Value<double?> carbsGoal = const Value.absent(),
                Value<double?> carbsTracked = const Value.absent(),
                Value<double?> fatGoal = const Value.absent(),
                Value<double?> fatTracked = const Value.absent(),
                Value<double?> proteinGoal = const Value.absent(),
                Value<double?> proteinTracked = const Value.absent(),
                Value<double> activeCaloriesBurned = const Value.absent(),
                Value<DateTime?> activeCaloriesUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion(
                date: date,
                calorieGoal: calorieGoal,
                caloriesTracked: caloriesTracked,
                carbsGoal: carbsGoal,
                carbsTracked: carbsTracked,
                fatGoal: fatGoal,
                fatTracked: fatTracked,
                proteinGoal: proteinGoal,
                proteinTracked: proteinTracked,
                activeCaloriesBurned: activeCaloriesBurned,
                activeCaloriesUpdatedAt: activeCaloriesUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required double calorieGoal,
                Value<double> caloriesTracked = const Value.absent(),
                Value<double?> carbsGoal = const Value.absent(),
                Value<double?> carbsTracked = const Value.absent(),
                Value<double?> fatGoal = const Value.absent(),
                Value<double?> fatTracked = const Value.absent(),
                Value<double?> proteinGoal = const Value.absent(),
                Value<double?> proteinTracked = const Value.absent(),
                Value<double> activeCaloriesBurned = const Value.absent(),
                Value<DateTime?> activeCaloriesUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion.insert(
                date: date,
                calorieGoal: calorieGoal,
                caloriesTracked: caloriesTracked,
                carbsGoal: carbsGoal,
                carbsTracked: carbsTracked,
                fatGoal: fatGoal,
                fatTracked: fatTracked,
                proteinGoal: proteinGoal,
                proteinTracked: proteinTracked,
                activeCaloriesBurned: activeCaloriesBurned,
                activeCaloriesUpdatedAt: activeCaloriesUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStatsTable,
      DailyStat,
      $$DailyStatsTableFilterComposer,
      $$DailyStatsTableOrderingComposer,
      $$DailyStatsTableAnnotationComposer,
      $$DailyStatsTableCreateCompanionBuilder,
      $$DailyStatsTableUpdateCompanionBuilder,
      (DailyStat, BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStat>),
      DailyStat,
      PrefetchHooks Function()
    >;
typedef $$ConfigTableCreateCompanionBuilder =
    ConfigCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ConfigTableUpdateCompanionBuilder =
    ConfigCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ConfigTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigTable> {
  $$ConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigTable,
          ConfigData,
          $$ConfigTableFilterComposer,
          $$ConfigTableOrderingComposer,
          $$ConfigTableAnnotationComposer,
          $$ConfigTableCreateCompanionBuilder,
          $$ConfigTableUpdateCompanionBuilder,
          (ConfigData, BaseReferences<_$AppDatabase, $ConfigTable, ConfigData>),
          ConfigData,
          PrefetchHooks Function()
        > {
  $$ConfigTableTableManager(_$AppDatabase db, $ConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  ConfigCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigTable,
      ConfigData,
      $$ConfigTableFilterComposer,
      $$ConfigTableOrderingComposer,
      $$ConfigTableAnnotationComposer,
      $$ConfigTableCreateCompanionBuilder,
      $$ConfigTableUpdateCompanionBuilder,
      (ConfigData, BaseReferences<_$AppDatabase, $ConfigTable, ConfigData>),
      ConfigData,
      PrefetchHooks Function()
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      required int birthday,
      required double heightCm,
      required double weightKg,
      required String gender,
      required String goal,
      required String pal,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<int> birthday,
      Value<double> heightCm,
      Value<double> weightKg,
      Value<String> gender,
      Value<String> goal,
      Value<String> pal,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pal => $composableBuilder(
    column: $table.pal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pal => $composableBuilder(
    column: $table.pal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get pal =>
      $composableBuilder(column: $table.pal, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileData,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileData,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
          ),
          UserProfileData,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> birthday = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String> pal = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                birthday: birthday,
                heightCm: heightCm,
                weightKg: weightKg,
                gender: gender,
                goal: goal,
                pal: pal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int birthday,
                required double heightCm,
                required double weightKg,
                required String gender,
                required String goal,
                required String pal,
              }) => UserProfileCompanion.insert(
                id: id,
                birthday: birthday,
                heightCm: heightCm,
                weightKg: weightKg,
                gender: gender,
                goal: goal,
                pal: pal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileData,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileData,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
      ),
      UserProfileData,
      PrefetchHooks Function()
    >;
typedef $$UserActivitiesTableCreateCompanionBuilder =
    UserActivitiesCompanion Function({
      required String id,
      required int date,
      required double duration,
      required double burnedKcal,
      required String activityCode,
      required String activityName,
      Value<String> activityDescription,
      required double activityMets,
      required String activityType,
      Value<int> rowid,
    });
typedef $$UserActivitiesTableUpdateCompanionBuilder =
    UserActivitiesCompanion Function({
      Value<String> id,
      Value<int> date,
      Value<double> duration,
      Value<double> burnedKcal,
      Value<String> activityCode,
      Value<String> activityName,
      Value<String> activityDescription,
      Value<double> activityMets,
      Value<String> activityType,
      Value<int> rowid,
    });

class $$UserActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $UserActivitiesTable> {
  $$UserActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get burnedKcal => $composableBuilder(
    column: $table.burnedKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityDescription => $composableBuilder(
    column: $table.activityDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get activityMets => $composableBuilder(
    column: $table.activityMets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserActivitiesTable> {
  $$UserActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get burnedKcal => $composableBuilder(
    column: $table.burnedKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityDescription => $composableBuilder(
    column: $table.activityDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get activityMets => $composableBuilder(
    column: $table.activityMets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserActivitiesTable> {
  $$UserActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<double> get burnedKcal => $composableBuilder(
    column: $table.burnedKcal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityDescription => $composableBuilder(
    column: $table.activityDescription,
    builder: (column) => column,
  );

  GeneratedColumn<double> get activityMets => $composableBuilder(
    column: $table.activityMets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );
}

class $$UserActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserActivitiesTable,
          UserActivity,
          $$UserActivitiesTableFilterComposer,
          $$UserActivitiesTableOrderingComposer,
          $$UserActivitiesTableAnnotationComposer,
          $$UserActivitiesTableCreateCompanionBuilder,
          $$UserActivitiesTableUpdateCompanionBuilder,
          (
            UserActivity,
            BaseReferences<_$AppDatabase, $UserActivitiesTable, UserActivity>,
          ),
          UserActivity,
          PrefetchHooks Function()
        > {
  $$UserActivitiesTableTableManager(
    _$AppDatabase db,
    $UserActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<double> duration = const Value.absent(),
                Value<double> burnedKcal = const Value.absent(),
                Value<String> activityCode = const Value.absent(),
                Value<String> activityName = const Value.absent(),
                Value<String> activityDescription = const Value.absent(),
                Value<double> activityMets = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserActivitiesCompanion(
                id: id,
                date: date,
                duration: duration,
                burnedKcal: burnedKcal,
                activityCode: activityCode,
                activityName: activityName,
                activityDescription: activityDescription,
                activityMets: activityMets,
                activityType: activityType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int date,
                required double duration,
                required double burnedKcal,
                required String activityCode,
                required String activityName,
                Value<String> activityDescription = const Value.absent(),
                required double activityMets,
                required String activityType,
                Value<int> rowid = const Value.absent(),
              }) => UserActivitiesCompanion.insert(
                id: id,
                date: date,
                duration: duration,
                burnedKcal: burnedKcal,
                activityCode: activityCode,
                activityName: activityName,
                activityDescription: activityDescription,
                activityMets: activityMets,
                activityType: activityType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserActivitiesTable,
      UserActivity,
      $$UserActivitiesTableFilterComposer,
      $$UserActivitiesTableOrderingComposer,
      $$UserActivitiesTableAnnotationComposer,
      $$UserActivitiesTableCreateCompanionBuilder,
      $$UserActivitiesTableUpdateCompanionBuilder,
      (
        UserActivity,
        BaseReferences<_$AppDatabase, $UserActivitiesTable, UserActivity>,
      ),
      UserActivity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$DailyStatsTableTableManager get dailyStats =>
      $$DailyStatsTableTableManager(_db, _db.dailyStats);
  $$ConfigTableTableManager get config =>
      $$ConfigTableTableManager(_db, _db.config);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$UserActivitiesTableTableManager get userActivities =>
      $$UserActivitiesTableTableManager(_db, _db.userActivities);
}
