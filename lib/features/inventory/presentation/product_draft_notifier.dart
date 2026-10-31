import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_assets.dart';
import '../data/inventory_repository.dart';

final productPhotoPickerProvider = Provider<Future<List<Uint8List>> Function()>(
  (ref) => () async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );
    return Future.wait(files.take(5).map((file) => file.readAsBytes()));
  },
);

class ProductVariantDraft {
  const ProductVariantDraft({
    this.id = 'primary',
    this.sku = '',
    this.label = '',
    this.quantity = '0',
    this.reserved = 0,
  });
  final String sku;
  final String id;
  final String label;
  final String quantity;
  final int reserved;
  ProductVariantDraft copyWith({
    String? sku,
    String? label,
    String? quantity,
  }) => ProductVariantDraft(
    id: id,
    sku: sku ?? this.sku,
    label: label ?? this.label,
    quantity: quantity ?? this.quantity,
    reserved: reserved,
  );
}

class ProductDraft {
  ProductDraft({
    this.name = '',
    this.category = 'Fashion',
    this.description = '',
    this.sellingPrice = '',
    this.costPrice = '',
    List<String> photos = const [AppAssets.blueCottonShirt],
    List<ProductVariantDraft> variants = const [ProductVariantDraft()],
    this.weight = '',
    this.length = '',
    this.width = '',
    this.height = '',
  }) : photos = List.unmodifiable(photos),
       variants = List.unmodifiable(variants);
  final String name;
  final String category;
  final String description;
  final String sellingPrice;
  final String costPrice;
  final List<String> photos;
  final List<ProductVariantDraft> variants;
  final String weight;
  final String length;
  final String width;
  final String height;
  ProductDraft copyWith({
    String? name,
    String? category,
    String? description,
    String? sellingPrice,
    String? costPrice,
    List<String>? photos,
    List<ProductVariantDraft>? variants,
    String? weight,
    String? length,
    String? width,
    String? height,
  }) => ProductDraft(
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    costPrice: costPrice ?? this.costPrice,
    photos: photos ?? this.photos,
    variants: variants ?? this.variants,
    weight: weight ?? this.weight,
    length: length ?? this.length,
    width: width ?? this.width,
    height: height ?? this.height,
  );
}

/// One session-local draft for a new product or each edited product ID.
final productDraftProvider =
    NotifierProvider.family<ProductDraftNotifier, ProductDraft, String>(
      ProductDraftNotifier.new,
    );

class ProductDraftNotifier extends Notifier<ProductDraft> {
  ProductDraftNotifier(this.draftKey);
  final String draftKey;
  int _variantCounter = 0;
  @override
  ProductDraft build() {
    final product = ref
        .read(inventoryRepositoryProvider)
        .where((p) => p.id == draftKey)
        .firstOrNull;
    if (product == null) return ProductDraft();
    final variants = product.variants.isEmpty
        ? [
            ProductVariantDraft(
              id: product.sku,
              sku: product.sku,
              label: product.variantSummary,
              quantity: '${product.onHand}',
              reserved: product.reserved,
            ),
          ]
        : [
            for (final variant in [
              ...product.variants.where((v) => v.sku == product.sku),
              ...product.variants.where((v) => v.sku != product.sku),
            ])
              ProductVariantDraft(
                id: variant.sku,
                sku: variant.sku,
                label: variant.variantSummary,
                quantity: '${variant.onHand}',
                reserved: variant.reserved,
              ),
          ];
    String measure(double n) => n == 0 ? '' : '$n';
    return ProductDraft(
      name: product.name,
      category: product.category,
      description: product.description,
      sellingPrice: product.sellingPrice.toStringAsFixed(2),
      costPrice: product.costPrice?.toStringAsFixed(2) ?? '',
      photos: product.imageUrls,
      variants: variants,
      weight: measure(product.weightKg),
      length: measure(product.lengthCm),
      width: measure(product.widthCm),
      height: measure(product.heightCm),
    );
  }

  void update(ProductDraft Function(ProductDraft) change) =>
      state = change(state);
  void updateVariant(
    int index,
    ProductVariantDraft Function(ProductVariantDraft) change,
  ) => state = state.copyWith(
    variants: [
      for (var i = 0; i < state.variants.length; i++)
        if (i == index) change(state.variants[i]) else state.variants[i],
    ],
  );
  void addVariant() => state = state.copyWith(
    variants: [
      ...state.variants,
      ProductVariantDraft(id: 'new-${_variantCounter++}'),
    ],
  );
  void removeVariant(int index) {
    if (state.variants.length > 1) {
      state = state.copyWith(variants: [...state.variants]..removeAt(index));
    }
  }

  void removePhoto(int index) =>
      state = state.copyWith(photos: [...state.photos]..removeAt(index));
  void addPhotos(List<Uint8List> bytes) => state = state.copyWith(
    photos: [
      ...state.photos,
      ...bytes
          .take(5 - state.photos.length)
          .map((data) => 'data:image/jpeg;base64,${base64Encode(data)}'),
    ],
  );

  String? get stockError {
    final skus = <String>{};
    for (final v in state.variants) {
      if (v.sku.trim().isEmpty) return 'Add a SKU for each variant.';
      if (!skus.add(v.sku.trim().toUpperCase())) {
        return 'Each variant needs a unique SKU.';
      }
      if (state.variants.length > 1 && v.label.trim().isEmpty) {
        return 'Name each size or variant.';
      }
      final quantity = int.tryParse(v.quantity);
      if (quantity == null || quantity < 0) {
        return 'Opening quantities must be zero or greater.';
      }
    }
    return null;
  }
}
