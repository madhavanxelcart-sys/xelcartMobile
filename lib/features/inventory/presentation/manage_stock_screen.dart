import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_product_image.dart';
import '../data/inventory_repository.dart';
import 'widgets/inventory_widgets.dart';

class ManageStockScreen extends ConsumerStatefulWidget {
  const ManageStockScreen({super.key, required this.productId});
  final String productId;
  @override
  ConsumerState<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends ConsumerState<ManageStockScreen> {
  final _quantity = TextEditingController(text: '10');
  late final TextEditingController _threshold;
  String? _sku;
  bool _remove = false;
  bool _saving = false;
  String _reason = 'Restock';
  @override
  void initState() {
    super.initState();
    final product = ref
        .read(inventoryRepositoryProvider)
        .where((p) => p.id == widget.productId)
        .firstOrNull;
    _threshold = TextEditingController(
      text: '${product?.lowStockThreshold ?? 5}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.inventory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref
        .watch(inventoryRepositoryProvider)
        .where((p) => p.id == widget.productId)
        .firstOrNull;
    if (product == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              InventoryTopBar(onBack: _back, trailing: const SizedBox.shrink()),
              const Expanded(child: Center(child: Text('Product not found'))),
              TextButton(
                onPressed: () => context.go(RouteNames.inventory),
                child: const Text('Back to inventory'),
              ),
            ],
          ),
        ),
      );
    }
    final sku = _sku ?? product.sku;
    final variant = product.variants.where((v) => v.sku == sku).firstOrNull;
    final onHand = variant?.onHand ?? product.onHand;
    final reserved = variant?.reserved ?? product.reserved;
    final available = onHand - reserved;
    final quantity = int.tryParse(_quantity.text) ?? 0;
    final threshold = int.tryParse(_threshold.text);
    final previewOnHand = onHand + (_remove ? -quantity : quantity);
    final previewAvailable = previewOnHand - reserved;
    final invalidRemoval = _remove && quantity > available;
    final canSave =
        !_saving &&
        quantity > 0 &&
        threshold != null &&
        threshold >= 0 &&
        !invalidRemoval;
    final history = product.history
        .where(
          (e) =>
              e.variantSku == sku || e.variantSku == null && sku == product.sku,
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InventoryTopBar(
                onBack: _back,
                trailing: IconButton(
                  tooltip: 'Edit product',
                  onPressed: () => context.pushNamed(
                    RouteNames.addProduct,
                    queryParameters: {'edit': product.id},
                  ),
                  icon: const InventorySvg(AppAssets.pencil),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Manage stock',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              InventoryCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 78,
                        height: 88,
                        child: AppProductImage(path: product.imageUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: const Key('stockVariant'),
                              value: sku,
                              isExpanded: true,
                              icon: const InventorySvg(
                                AppAssets.chevronDown,
                                size: 18,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                              items: product.variants.isEmpty
                                  ? [
                                      DropdownMenuItem(
                                        value: product.sku,
                                        child: Text(
                                          product.variantSummary.isEmpty
                                              ? 'Default variant'
                                              : product.variantSummary,
                                        ),
                                      ),
                                    ]
                                  : [
                                      for (final v in product.variants)
                                        DropdownMenuItem(
                                          value: v.sku,
                                          child: Text(
                                            v.variantSummary,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                              onChanged: (v) => setState(() => _sku = v),
                            ),
                          ),
                          Text(
                            'SKU $sku',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              StockNumbers(
                onHand: onHand,
                reserved: reserved,
                available: available,
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Available = On hand \u2013 Reserved',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              InventoryCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock adjustment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Add stock')),
                          ButtonSegment(
                            value: true,
                            label: Text('Remove stock'),
                          ),
                        ],
                        selected: {_remove},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? AppColors.primary
                                : const Color(0xFFF8F6FF),
                          ),
                          textStyle: WidgetStatePropertyAll(
                            Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontSize: 12),
                          ),
                        ),
                        onSelectionChanged: (v) => setState(() {
                          _remove = v.first;
                          _reason = _remove ? 'Damaged' : 'Restock';
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const InventoryLabel('Quantity'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Decrease quantity',
                          onPressed: quantity > 1
                              ? () => setState(
                                  () => _quantity.text = '${quantity - 1}',
                                )
                              : null,
                          icon: const InventorySvg(AppAssets.minus),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('stockQuantity'),
                            controller: _quantity,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              errorText: quantity <= 0
                                  ? 'Enter quantity'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Increase quantity',
                          onPressed: quantity < 999999
                              ? () => setState(
                                  () => _quantity.text = '${quantity + 1}',
                                )
                              : null,
                          icon: const InventorySvg(AppAssets.plus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const InventoryLabel('Reason', required: true),
                    DropdownButtonFormField<String>(
                      key: ValueKey('stockReason-$_reason'),
                      initialValue: _reason,
                      items: [
                        for (final reason in [
                          'Restock',
                          'Damaged',
                          'Manual count',
                          'Returned',
                        ])
                          DropdownMenuItem(value: reason, child: Text(reason)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _reason = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const InventoryLabel('Low-stock alert'),
                    TextField(
                      key: const Key('stockThreshold'),
                      controller: _threshold,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        suffixText: 'units',
                        errorText: threshold == null
                            ? 'Enter a threshold'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Get notified when stock goes at or below this quantity.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'After adjustment (preview)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StockNumbers(
                            onHand: previewOnHand,
                            reserved: reserved,
                            available: previewAvailable,
                            preview: true,
                          ),
                        ],
                      ),
                    ),
                    if (invalidRemoval)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Only $available available. Reserved stock cannot be removed.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InventoryAccordion(
                title: 'Stock history',
                subtitle: 'View changes and reasons',
                icon: AppAssets.history,
                children: history.isEmpty
                    ? [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No adjustments yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ]
                    : [
                        for (final entry in history)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${entry.changeQty > 0 ? '+' : ''}${entry.changeQty} \u00B7 ${entry.reason}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('saveStockAdjustment'),
                  onPressed: !canSave
                      ? null
                      : () {
                          setState(() => _saving = true);
                          try {
                            final repo = ref.read(
                              inventoryRepositoryProvider.notifier,
                            );
                            if (_remove) {
                              repo.removeStock(
                                product.id,
                                quantity: quantity,
                                reason: _reason,
                                lowStockThreshold: threshold,
                                variantSku: sku,
                              );
                            } else {
                              repo.addStock(
                                product.id,
                                quantity: quantity,
                                reason: _reason,
                                lowStockThreshold: threshold,
                                variantSku: sku,
                              );
                            }
                            _back();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock adjustment saved'),
                              ),
                            );
                          } catch (error) {
                            setState(() => _saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unable to save adjustment: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text('Save adjustment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
