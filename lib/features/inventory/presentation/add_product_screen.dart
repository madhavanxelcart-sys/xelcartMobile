import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_product_image.dart';
import '../data/inventory_repository.dart';
import '../domain/product_model.dart';
import 'product_draft_notifier.dart';
import 'widgets/inventory_widgets.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.productId});
  final String? productId;
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  bool _picking = false;
  bool _stockExpanded = false;
  bool _shippingExpanded = false;
  String? _error;
  String get _draftKey => widget.productId ?? 'new';
  bool get _editing => widget.productId != null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.inventory);
    }
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;
  String? _money(String? v, {bool optional = false}) {
    if (v == null || v.isEmpty) return optional ? null : 'Required';
    final n = double.tryParse(v);
    return RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v) &&
            n != null &&
            n.isFinite &&
            (optional ? n >= 0 : n > 0)
        ? null
        : 'Enter a valid price';
  }

  Future<void> _pickPhotos() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final photos = await ref.read(productPhotoPickerProvider)();
      if (!mounted) return;
      ref.read(productDraftProvider(_draftKey).notifier).addPhotos(photos);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to choose photos. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _publish() {
    final draft = ref.read(productDraftProvider(_draftKey));
    final stockError = !_editing
        ? ref.read(productDraftProvider(_draftKey).notifier).stockError
        : null;
    final shippingInvalid =
        [draft.weight, draft.length, draft.width, draft.height].any(
          (v) =>
              v.isNotEmpty &&
              (double.tryParse(v) == null ||
                  !double.parse(v).isFinite ||
                  double.parse(v) < 0),
        );
    final valid = _form.currentState!.validate();
    setState(() {
      _stockExpanded = stockError != null;
      _shippingExpanded = shippingInvalid;
      _error = draft.photos.isEmpty
          ? 'Add at least one product photo.'
          : stockError ??
                (shippingInvalid ? 'Check the shipping measurements.' : null);
    });
    if (!valid || _error != null) return;
    final products = ref.read(inventoryRepositoryProvider);
    final previous = products
        .where((p) => p.id == widget.productId)
        .firstOrNull;
    if (_editing && previous == null) return;
    var number = products.length + 1;
    while (products.any((p) => p.id == 'product-$number')) {
      number++;
    }
    final variants = _editing
        ? previous!.variants
        : [
            for (final v in draft.variants)
              ProductVariantStock(
                sku: v.sku.trim().toUpperCase(),
                variantSummary: v.label.trim().isEmpty
                    ? 'Default variant'
                    : v.label.trim(),
                onHand: int.parse(v.quantity),
                reserved: 0,
              ),
          ];
    final first = draft.variants.first;
    final product = ProductModel(
      id: previous?.id ?? 'product-$number',
      name: draft.name.trim(),
      sku: previous?.sku ?? first.sku.trim().toUpperCase(),
      category: draft.category,
      description: draft.description.trim(),
      sellingPrice: double.parse(draft.sellingPrice),
      costPrice: draft.costPrice.isEmpty ? null : double.parse(draft.costPrice),
      variantSummary:
          previous?.variantSummary ??
          (variants.length > 1
              ? '${variants.length} size variants'
              : first.label.trim()),
      onHand: previous?.onHand ?? int.parse(first.quantity),
      reserved: previous?.reserved ?? 0,
      lowStockThreshold: previous?.lowStockThreshold ?? 5,
      imageUrl: draft.photos.first,
      imageUrls: draft.photos,
      variants: variants,
      history: previous?.history ?? [],
      weightKg: double.tryParse(draft.weight) ?? 0,
      lengthCm: double.tryParse(draft.length) ?? 0,
      widthCm: double.tryParse(draft.width) ?? 0,
      heightCm: double.tryParse(draft.height) ?? 0,
    );
    try {
      final repo = ref.read(inventoryRepositoryProvider.notifier);
      if (_editing) {
        repo.updateProduct(product);
      } else {
        repo.addProduct(product);
      }
      ref.invalidate(productDraftProvider(_draftKey));
      _back();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? 'Product updated' : 'Product added')),
      );
    } on ArgumentError catch (error) {
      setState(
        () => _error =
            error.message?.toString() ??
            'Check the product details and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(productDraftProvider(_draftKey));
    final notifier = ref.read(productDraftProvider(_draftKey).notifier);
    final products = ref.watch(inventoryRepositoryProvider);
    if (_editing && !products.any((p) => p.id == widget.productId)) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              InventoryTopBar(onBack: _back, trailing: const SizedBox.shrink()),
              const Expanded(child: Center(child: Text('Product not found'))),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventoryTopBar(
                  onBack: _back,
                  trailing: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _back();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft saved for this session.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Save draft',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _editing ? 'Edit product' : 'Add product',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Make your next bestseller.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(
                      child: InventoryLabel('Product photos', required: true),
                    ),
                    Text(
                      'Up to 5 photos',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        draft.photos.length + (draft.photos.length < 5 ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      if (i == draft.photos.length) {
                        return SizedBox(
                          width: 116,
                          child: Material(
                            color: const Color(0xFFFCFBFF),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              key: const Key('addProductPhoto'),
                              onTap: _picking ? null : _pickPhotos,
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: const _DashedBorder(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_picking)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const InventorySvg(
                                        AppAssets.plus,
                                        size: 30,
                                      ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Add photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        width: 116,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppProductImage(path: draft.photos[i]),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton.filledTonal(
                                tooltip: 'Remove photo ${i + 1}',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => notifier.removePhoto(i),
                                icon: const InventorySvg(AppAssets.x, size: 16),
                              ),
                            ),
                            if (i == 0)
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Cover',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _field(
                  'Product name',
                  'productName',
                  draft.name,
                  (v) => notifier.update((s) => s.copyWith(name: v)),
                  hint: 'Blue cotton shirt',
                  required: true,
                ),
                const SizedBox(height: 16),
                const InventoryLabel('Category', required: true),
                DropdownButtonFormField<String>(
                  key: const Key('productCategory'),
                  initialValue: draft.category,
                  items: [
                    for (final category in [
                      'Fashion',
                      'Beauty',
                      'Food',
                      'Home',
                      'Other',
                    ])
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.update((s) => s.copyWith(category: v));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  'Description',
                  'productDescription',
                  draft.description,
                  (v) => notifier.update((s) => s.copyWith(description: v)),
                  hint: 'Soft cotton shirt for everyday wear.',
                  multiline: true,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        'Selling price (\u20B9)',
                        'sellingPrice',
                        draft.sellingPrice,
                        (v) =>
                            notifier.update((s) => s.copyWith(sellingPrice: v)),
                        hint: '749.50',
                        required: true,
                        numeric: true,
                        validator: _money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Cost price (\u20B9) (optional)',
                        'costPrice',
                        draft.costPrice,
                        (v) => notifier.update((s) => s.copyWith(costPrice: v)),
                        hint: '420.00',
                        numeric: true,
                        validator: (v) => _money(v, optional: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InventoryAccordion(
                  title: 'Variants & stock',
                  subtitle: 'Sizes, SKUs, opening quantities',
                  icon: AppAssets.box,
                  initiallyExpanded: _stockExpanded,
                  children: [
                    if (_editing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Use Manage stock to adjust quantities. Existing SKUs are kept with their history.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    for (var i = 0; i < draft.variants.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Variant ${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!_editing && draft.variants.length > 1)
                            IconButton(
                              tooltip: 'Remove variant ${i + 1}',
                              onPressed: () => notifier.removeVariant(i),
                              icon: const InventorySvg(AppAssets.x, size: 16),
                            ),
                        ],
                      ),
                      _field(
                        'Size / variant',
                        'variantLabel-${draft.variants[i].id}',
                        draft.variants[i].label,
                        (v) => notifier.updateVariant(
                          i,
                          (s) => s.copyWith(label: v),
                        ),
                        hint: 'Blue \u00B7 Size M',
                        readOnly: _editing,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        'SKU',
                        'variantSku-${draft.variants[i].id}',
                        draft.variants[i].sku,
                        (v) => notifier.updateVariant(
                          i,
                          (s) => s.copyWith(sku: v),
                        ),
                        hint: 'SHIRT-BLU-M',
                        readOnly: _editing,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        'Opening quantity',
                        'variantQuantity-${draft.variants[i].id}',
                        draft.variants[i].quantity,
                        (v) => notifier.updateVariant(
                          i,
                          (s) => s.copyWith(quantity: v),
                        ),
                        integer: true,
                        readOnly: _editing,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!_editing)
                      TextButton.icon(
                        onPressed: notifier.addVariant,
                        icon: const InventorySvg(AppAssets.plus, size: 16),
                        label: const Text('Add variant'),
                      ),
                  ],
                ),
                InventoryAccordion(
                  title: 'Shipping details',
                  subtitle: 'Weight and dimensions',
                  icon: AppAssets.truck,
                  initiallyExpanded: _shippingExpanded,
                  children: [
                    _field(
                      'Weight (kg)',
                      'productWeight',
                      draft.weight,
                      (v) => notifier.update((s) => s.copyWith(weight: v)),
                      numeric: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            'Length (cm)',
                            'productLength',
                            draft.length,
                            (v) =>
                                notifier.update((s) => s.copyWith(length: v)),
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            'Width (cm)',
                            'productWidth',
                            draft.width,
                            (v) => notifier.update((s) => s.copyWith(width: v)),
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            'Height (cm)',
                            'productHeight',
                            draft.height,
                            (v) =>
                                notifier.update((s) => s.copyWith(height: v)),
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    InventorySvg(AppAssets.info, size: 16),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Add stock details before publishing.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.dangerText,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('publishProduct'),
                    onPressed: _picking ? null : _publish,
                    child: Text(_editing ? 'Save product' : 'Add product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String fieldKey,
    String value,
    ValueChanged<String> onChanged, {
    String? hint,
    bool required = false,
    bool multiline = false,
    bool numeric = false,
    bool integer = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InventoryLabel(label, required: required),
      TextFormField(
        key: Key(fieldKey),
        initialValue: value,
        onChanged: onChanged,
        readOnly: readOnly,
        maxLines: multiline ? 3 : 1,
        style: const TextStyle(fontSize: 13),
        validator: validator ?? (required ? _required : null),
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : integer
            ? TextInputType.number
            : multiline
            ? TextInputType.multiline
            : TextInputType.text,
        inputFormatters: integer
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ]
            : numeric
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(12),
              ]
            : null,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    final paint = Paint()
      ..color = const Color(0xFFC4B5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 10) {
        canvas.drawPath(metric.extractPath(offset, offset + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) => false;
}
