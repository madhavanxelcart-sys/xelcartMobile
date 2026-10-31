enum StockStatus { inStock, lowStock, outOfStock }

class StockHistoryEntry {
  const StockHistoryEntry({
    required this.date,
    required this.changeQty,
    required this.reason,
    this.variantSku,
  });
  final DateTime date;
  final int changeQty;
  final String reason;
  final String? variantSku;
}

/// Sibling SKU stock keeps the catalog total distinct from the selected SKU.
class ProductVariantStock {
  ProductVariantStock({
    required this.sku,
    required this.variantSummary,
    required this.onHand,
    required this.reserved,
  }) {
    if (onHand < 0 || reserved < 0 || reserved > onHand) {
      throw ArgumentError('Invalid variant stock quantities');
    }
  }
  final String sku;
  final String variantSummary;
  final int onHand;
  final int reserved;
  int get available => onHand - reserved;
  ProductVariantStock copyWith({int? onHand}) => ProductVariantStock(
    sku: sku,
    variantSummary: variantSummary,
    onHand: onHand ?? this.onHand,
    reserved: reserved,
  );
}

class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.description = '',
    required this.sellingPrice,
    this.costPrice,
    this.variantSummary = '',
    required this.onHand,
    this.reserved = 0,
    this.lowStockThreshold = 5,
    this.imageUrl = '',
    List<StockHistoryEntry> history = const [],
    List<ProductVariantStock> variants = const [],
    List<String> imageUrls = const [],
    this.weightKg = 0,
    this.lengthCm = 0,
    this.widthCm = 0,
    this.heightCm = 0,
  }) : history = List.unmodifiable(history),
       variants = List.unmodifiable(variants),
       imageUrls = List.unmodifiable(
         imageUrls.isEmpty && imageUrl.isNotEmpty ? [imageUrl] : imageUrls,
       ) {
    if (this.imageUrls.length > 5 ||
        [
          weightKg,
          lengthCm,
          widthCm,
          heightCm,
        ].any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError(
        'At most five photos and non-negative shipping measurements are allowed',
      );
    }
    if (onHand < 0 ||
        reserved < 0 ||
        reserved > onHand ||
        lowStockThreshold < 0) {
      throw ArgumentError('Invalid stock quantities or threshold');
    }
    if (!sellingPrice.isFinite ||
        sellingPrice < 0 ||
        (costPrice != null && (!costPrice!.isFinite || costPrice! < 0))) {
      throw ArgumentError('Prices must be finite and non-negative');
    }
    if (variants.map((v) => v.sku).toSet().length != variants.length) {
      throw ArgumentError('Variant SKUs must be unique');
    }
    if (variants.isNotEmpty) {
      final selected = variants.where((variant) => variant.sku == sku);
      if (selected.length != 1 ||
          selected.single.onHand != onHand ||
          selected.single.reserved != reserved) {
        throw ArgumentError('Selected SKU must match variant stock');
      }
    }
  }
  final String id;
  final String name;
  final String sku;
  final String category;
  final String description;
  final double sellingPrice;
  final double? costPrice;
  final String variantSummary;

  /// Stock for the selected SKU; the reference selects SHIRT-BLU-M.
  final int onHand;
  final int reserved;
  final int lowStockThreshold;

  /// Empty when no standalone photo is supplied; render a placeholder.
  final String imageUrl;
  final List<StockHistoryEntry> history;
  final List<ProductVariantStock> variants;
  final List<String> imageUrls;
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  int get available => onHand - reserved;
  int get totalAvailable => variants.isEmpty
      ? available
      : variants.fold(0, (sum, variant) => sum + variant.available);
  StockStatus get stockStatus => _status(available);
  StockStatus get catalogStockStatus => _status(totalAvailable);
  StockStatus _status(int quantity) => quantity <= 0
      ? StockStatus.outOfStock
      : quantity <= lowStockThreshold
      ? StockStatus.lowStock
      : StockStatus.inStock;

  /// Updating selected-SKU stock also updates its catalog variant entry.
  ProductModel copyWith({
    int? onHand,
    int? lowStockThreshold,
    List<StockHistoryEntry>? history,
    List<ProductVariantStock>? variants,
  }) => ProductModel(
    id: id,
    name: name,
    sku: sku,
    category: category,
    description: description,
    sellingPrice: sellingPrice,
    costPrice: costPrice,
    variantSummary: variantSummary,
    onHand: onHand ?? this.onHand,
    reserved: reserved,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    imageUrl: imageUrl,
    imageUrls: imageUrls,
    weightKg: weightKg,
    lengthCm: lengthCm,
    widthCm: widthCm,
    heightCm: heightCm,
    history: history ?? this.history,
    variants: [
      for (final variant in variants ?? this.variants)
        if (variant.sku == sku && onHand != null)
          variant.copyWith(onHand: onHand)
        else
          variant,
    ],
  );
}
