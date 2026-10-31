import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';

import '../domain/product_model.dart';

final inventoryRepositoryProvider =
    NotifierProvider<InventoryRepository, List<ProductModel>>(
      InventoryRepository.new,
    );

/// Injectable clock makes stock audit entries deterministic in tests.
final inventoryClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class InventoryRepository extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => List.unmodifiable([
    ProductModel(
      id: 'shirt-blue',
      name: 'Blue cotton shirt',
      sku: 'SHIRT-BLU-M',
      imageUrl: AppAssets.blueCottonShirt,
      category: 'Fashion',
      description: 'Soft cotton shirt for everyday wear.',
      sellingPrice: 749.50,
      costPrice: 420,
      variantSummary: '3 size variants',
      onHand: 12,
      reserved: 2,
      // The reference gives M = 10 and all sizes = 32 available.
      // The remaining 22 are mock allocations across S and L, not reference facts.
      variants: [
        ProductVariantStock(
          sku: 'SHIRT-BLU-S',
          variantSummary: 'Blue \u00B7 Size S',
          onHand: 12,
          reserved: 0,
        ),
        ProductVariantStock(
          sku: 'SHIRT-BLU-M',
          variantSummary: 'Blue \u00B7 Size M',
          onHand: 12,
          reserved: 2,
        ),
        ProductVariantStock(
          sku: 'SHIRT-BLU-L',
          variantSummary: 'Blue \u00B7 Size L',
          onHand: 10,
          reserved: 0,
        ),
      ],
    ),
    ProductModel(
      id: 'tote-natural',
      name: 'Canvas tote bag',
      sku: 'TOTE-NAT',
      imageUrl: AppAssets.canvasToteBag,
      category: 'Fashion',
      sellingPrice: 899,
      onHand: 4,
    ),
    ProductModel(
      id: 'dinner-ceramic',
      name: 'Ceramic dinner set',
      sku: 'DINNER-CRM',
      imageUrl: AppAssets.ceramicDinnerSet,
      category: 'Home',
      sellingPrice: 2450,
      onHand: 0,
    ),
  ]);

  void addProduct(ProductModel product) {
    if (product.id.trim().isEmpty ||
        product.name.trim().isEmpty ||
        product.sku.trim().isEmpty ||
        product.category.trim().isEmpty) {
      throw ArgumentError('Product ID, name, SKU and category are required');
    }
    final existingSkus = {
      for (final p in state) p.sku.toUpperCase(),
      for (final p in state) ...p.variants.map((v) => v.sku.toUpperCase()),
    };
    final incomingSkus = {
      product.sku.toUpperCase(),
      ...product.variants.map((v) => v.sku.toUpperCase()),
    };
    if (state.any((p) => p.id == product.id) ||
        incomingSkus.any(existingSkus.contains)) {
      throw ArgumentError('Product ID and SKUs must be unique');
    }
    state = List.unmodifiable([...state, product]);
  }

  void addStock(
    String productId, {
    required int quantity,
    required String reason,
    int? lowStockThreshold,
    String? variantSku,
  }) => _adjust(
    productId,
    quantity: quantity,
    reason: reason,
    threshold: lowStockThreshold,
    remove: false,
    variantSku: variantSku,
  );

  void removeStock(
    String productId, {
    required int quantity,
    required String reason,
    int? lowStockThreshold,
    String? variantSku,
  }) => _adjust(
    productId,
    quantity: quantity,
    reason: reason,
    threshold: lowStockThreshold,
    remove: true,
    variantSku: variantSku,
  );

  void _adjust(
    String productId, {
    required int quantity,
    required String reason,
    required int? threshold,
    required bool remove,
    String? variantSku,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'Required');
    }
    if (threshold != null && threshold < 0) {
      throw ArgumentError.value(
        threshold,
        'lowStockThreshold',
        'Must be non-negative',
      );
    }
    final index = state.indexWhere((p) => p.id == productId);
    if (index < 0) {
      throw ArgumentError.value(productId, 'productId', 'Product not found');
    }
    final product = state[index];
    final sku = variantSku ?? product.sku;
    final variant = product.variants.where((v) => v.sku == sku).firstOrNull;
    if (sku != product.sku && variant == null) {
      throw ArgumentError.value(sku, 'variantSku', 'Variant not found');
    }
    final available = variant?.available ?? product.available;
    if (remove && quantity > available) {
      throw StateError('Cannot remove reserved or unavailable stock');
    }
    final change = remove ? -quantity : quantity;
    final updated = product.copyWith(
      onHand: sku == product.sku ? product.onHand + change : null,
      variants: sku == product.sku
          ? null
          : [
              for (final v in product.variants)
                if (v.sku == sku) v.copyWith(onHand: v.onHand + change) else v,
            ],
      lowStockThreshold: threshold,
      history: [
        StockHistoryEntry(
          date: ref.read(inventoryClockProvider)(),
          changeQty: change,
          reason: reason.trim(),
          variantSku: sku,
        ),
        ...product.history,
      ],
    );
    state = List.unmodifiable([
      for (var i = 0; i < state.length; i++)
        if (i == index) updated else state[i],
    ]);
  }

  void updateProduct(ProductModel product) {
    final previous = state.where((p) => p.id == product.id).firstOrNull;
    if (previous == null) throw ArgumentError('Product not found');
    if (product.name.trim().isEmpty || product.category.trim().isEmpty) {
      throw ArgumentError('Name and category are required');
    }
    if (previous.sku != product.sku ||
        previous.onHand != product.onHand ||
        previous.reserved != product.reserved ||
        previous.variants.length != product.variants.length ||
        previous.variants.any(
          (v) => !product.variants.any(
            (next) =>
                next.sku == v.sku &&
                next.onHand == v.onHand &&
                next.reserved == v.reserved,
          ),
        )) {
      throw ArgumentError(
        'Use stock adjustments to change SKUs or stock quantities',
      );
    }
    // Product editing must not discard audit history that was updated elsewhere.
    state = List.unmodifiable([
      for (final p in state)
        if (p.id == product.id)
          product.copyWith(history: previous.history)
        else
          p,
    ]);
  }
}
