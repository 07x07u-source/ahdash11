enum StoreItemType { hint, cosmetic, booster, coinPack }

enum StoreCategory {
  player11Style,
  profileBackground,
  profileFrame,
  teamPattern,
  answerEffect,
  victoryEffect,
  lobbyBackground,
  nameplate;

  String get labelAr => switch (this) {
    StoreCategory.player11Style => 'شخصيات وألوان Player 11',
    StoreCategory.profileBackground => 'خلفيات الملف',
    StoreCategory.profileFrame => 'إطارات اللاعب',
    StoreCategory.teamPattern => 'أنماط الفريق',
    StoreCategory.answerEffect => 'مؤثرات الإجابة',
    StoreCategory.victoryEffect => 'مؤثرات الفوز',
    StoreCategory.lobbyBackground => 'خلفيات Lobby',
    StoreCategory.nameplate => 'لوحات الاسم',
  };

  String get locationAr => switch (this) {
    StoreCategory.player11Style => 'يظهر على شخصية Player 11',
    StoreCategory.profileBackground => 'يظهر خلف بطاقة ملفك',
    StoreCategory.profileFrame => 'يحيط بصورة اللاعب والبطاقة',
    StoreCategory.teamPattern => 'يظهر على راية الفريق',
    StoreCategory.answerEffect => 'يظهر بعد نتيجة الإجابة',
    StoreCategory.victoryEffect => 'يظهر في احتفال الفوز',
    StoreCategory.lobbyBackground => 'يظهر في غرفة الانتظار',
    StoreCategory.nameplate => 'يظهر خلف اسمك',
  };
}

enum StoreRarity {
  common,
  rare,
  epic,
  legendary;

  String get labelAr => switch (this) {
    StoreRarity.common => 'أساسي',
    StoreRarity.rare => 'نادر',
    StoreRarity.epic => 'ملحمي',
    StoreRarity.legendary => 'أسطوري',
  };
}

final class StoreItem {
  const StoreItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.priceCoins,
    required this.imageAsset,
    required this.previewAsset,
    required this.rarity,
    required this.assetRights,
    required this.sortOrder,
    this.iconName = '',
    this.imageUrl,
    this.isPremiumOnly = false,
    this.isFeatured = false,
    this.isNew = false,
    this.isAvailable = true,
    this.isOwned = false,
    this.isEquipped = false,
    this.createdAt,
  });

  factory StoreItem.fromJson(Map<String, Object?> json) {
    final metadata = json['metadata'] is Map<Object?, Object?>
        ? Map<String, Object?>.from(json['metadata']! as Map<Object?, Object?>)
        : const <String, Object?>{};
    final rawType = '${json['type'] ?? 'cosmetic'}';
    final category = StoreCategory.values.firstWhere(
      (value) => value.name == '${metadata['category'] ?? ''}',
      orElse: () => StoreCategory.profileFrame,
    );
    final rarity = StoreRarity.values.firstWhere(
      (value) => value.name == '${metadata['rarity'] ?? ''}',
      orElse: () => StoreRarity.common,
    );
    final sku = '${json['sku'] ?? json['id']}';
    final fallback = localAssetForSku(sku);
    return StoreItem(
      id: '${json['id']}',
      sku: sku,
      name: (json['name_ar'] as String?) ?? 'عنصر أحدعش',
      description: (json['description_ar'] as String?) ?? '',
      type: StoreItemType.values.firstWhere(
        (value) => value.name == rawType.replaceFirst('coin_pack', 'coinPack'),
        orElse: () => StoreItemType.cosmetic,
      ),
      category: category,
      priceCoins: (json['price_coins'] as num?)?.round() ?? 0,
      imageAsset: (metadata['image_asset'] as String?) ?? fallback,
      previewAsset:
          (metadata['preview_asset'] as String?) ??
          (metadata['image_asset'] as String?) ??
          fallback,
      imageUrl: json['image_url'] as String?,
      rarity: rarity,
      assetRights: '${metadata['asset_rights'] ?? 'original'}',
      iconName: '${metadata['icon_name'] ?? sku}',
      sortOrder: (json['sort_order'] as num?)?.round() ?? 0,
      isPremiumOnly: metadata['premium_only'] as bool? ?? false,
      isFeatured: metadata['featured'] as bool? ?? false,
      isNew: metadata['new'] as bool? ?? false,
      isAvailable: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  final String id;
  final String sku;
  final String name;
  final String description;
  final StoreItemType type;
  final StoreCategory category;
  final int priceCoins;
  final String imageAsset;
  final String previewAsset;
  final String? imageUrl;
  final StoreRarity rarity;
  final String assetRights;
  final String iconName;
  final int sortOrder;
  final bool isPremiumOnly;
  final bool isFeatured;
  final bool isNew;
  final bool isAvailable;
  final bool isOwned;
  final bool isEquipped;
  final DateTime? createdAt;

  bool get isCosmetic => type == StoreItemType.cosmetic;

  StoreItem copyWith({bool? isOwned, bool? isEquipped, bool? isAvailable}) =>
      StoreItem(
        id: id,
        sku: sku,
        name: name,
        description: description,
        type: type,
        category: category,
        priceCoins: priceCoins,
        imageAsset: imageAsset,
        previewAsset: previewAsset,
        imageUrl: imageUrl,
        rarity: rarity,
        assetRights: assetRights,
        iconName: iconName,
        sortOrder: sortOrder,
        isPremiumOnly: isPremiumOnly,
        isFeatured: isFeatured,
        isNew: isNew,
        isAvailable: isAvailable ?? this.isAvailable,
        isOwned: isOwned ?? this.isOwned,
        isEquipped: isEquipped ?? this.isEquipped,
        createdAt: createdAt,
      );

  static String localAssetForSku(String sku) =>
      'assets/images/store/products/$sku.webp';
}
