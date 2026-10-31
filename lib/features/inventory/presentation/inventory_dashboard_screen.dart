import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_product_image.dart';
import '../data/inventory_repository.dart';
import '../domain/product_model.dart';
import 'widgets/inventory_widgets.dart';

class InventoryDashboardScreen extends ConsumerStatefulWidget {
  const InventoryDashboardScreen({super.key});
  @override
  ConsumerState<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState
    extends ConsumerState<InventoryDashboardScreen> {
  final _search = TextEditingController();
  StockStatus? _filter;
  String? _category;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _search.clear();
    _filter = null;
    _category = null;
  });
  Future<void> _filters() async {
    var status = _filter;
    var category = _category;
    final categories =
        ref
            .read(inventoryRepositoryProvider)
            .map((p) => p.category)
            .toSet()
            .toList()
          ..sort();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, update) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter inventory',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<StockStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Stock status'),
                hint: const Text('All statuses'),
                items: [
                  const DropdownMenuItem<StockStatus>(
                    child: Text('All statuses'),
                  ),
                  for (final s in StockStatus.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(StockStatusBadge.label(s)),
                    ),
                ],
                onChanged: (v) => update(() => status = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                hint: const Text('All categories'),
                items: [
                  const DropdownMenuItem<String>(child: Text('All categories')),
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => update(() => category = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filter = status;
                      _category = category;
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Apply filters'),
                ),
              ),
              TextButton(
                onPressed: () {
                  _reset();
                  Navigator.pop(sheetContext);
                },
                child: const Text('Reset filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(inventoryRepositoryProvider);
    final query = _search.text.trim().toLowerCase();
    final products = all
        .where(
          (p) =>
              (_filter == null || p.catalogStockStatus == _filter) &&
              (_category == null || p.category == _category) &&
              (query.isEmpty ||
                  [
                    p.name,
                    p.sku,
                    ...p.variants.map((v) => v.sku),
                  ].any((s) => s.toLowerCase().contains(query))),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRect(
                          child: SizedBox(
                            width: 190,
                            height: 40,
                            child: OverflowBox(
                              minHeight: 64,
                              maxHeight: 64,
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                AppAssets.xelcartLogo,
                                width: 190,
                                height: 64,
                                fit: BoxFit.contain,
                                semanticLabel: 'Xelcart',
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 21,
                          backgroundColor: Color(0xFFEDE9FE),
                          child: Text(
                            'AR',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Your inventory.',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Image.asset(
                            AppAssets.inventoryBoxes,
                            width: 78,
                            height: 72,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Summary(
                              icon: AppAssets.box,
                              value: 48 - 3 + all.length,
                              label: 'Products',
                              color: AppColors.primary,
                              main: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Summary(
                              icon: AppAssets.square,
                              value:
                                  6 -
                                  1 +
                                  all
                                      .where(
                                        (p) =>
                                            p.catalogStockStatus ==
                                            StockStatus.lowStock,
                                      )
                                      .length,
                              label: 'Low stock',
                              color: AppColors.warningText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Summary(
                              icon: AppAssets.triangleAlert,
                              value:
                                  3 -
                                  1 +
                                  all
                                      .where(
                                        (p) =>
                                            p.catalogStockStatus ==
                                            StockStatus.outOfStock,
                                      )
                                      .length,
                              label: 'Out of stock',
                              color: AppColors.dangerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('inventorySearch'),
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search products or SKU',
                              filled: true,
                              fillColor: const Color(0xFFF3F2F8),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(14),
                                child: InventorySvg(
                                  AppAssets.search,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear product search',
                                      onPressed: () => setState(_search.clear),
                                      icon: const InventorySvg(AppAssets.x),
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _category == null
                                  ? AppColors.border
                                  : AppColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            tooltip: 'Filter inventory',
                            onPressed: _filters,
                            icon: const InventorySvg(
                              AppAssets.slidersHorizontal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('All', null),
                          const SizedBox(width: 8),
                          _chip('Low stock', StockStatus.lowStock),
                          const SizedBox(width: 8),
                          _chip('Out of stock', StockStatus.outOfStock),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.pushNamed(RouteNames.addProduct),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const InventorySvg(AppAssets.plus, size: 16),
                          label: const Text(
                            'Add product',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No products found',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ProductCard(product: products[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, StockStatus? value) => ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: _filter == value ? AppColors.white : AppColors.textPrimary,
      ),
    ),
    avatar: value == null
        ? null
        : Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value == StockStatus.lowStock
                  ? AppColors.warningText
                  : AppColors.dangerText,
            ),
          ),
    selected: _filter == value,
    showCheckmark: false,
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.white,
    side: BorderSide(
      color: _filter == value ? AppColors.primary : AppColors.border,
    ),
    shape: const StadiumBorder(),
    onSelected: (_) => setState(() => _filter = value),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.main = false,
  });
  final String icon;
  final int value;
  final String label;
  final Color color;
  final bool main;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
    decoration: BoxDecoration(
      color: main ? Colors.transparent : AppColors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        InventorySvg(icon, color: color, size: main ? 28 : 22),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: main ? 28 : 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ProductModel product;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('product-${product.id}'),
      onTap: () => context.pushNamed(
        RouteNames.manageStock,
        pathParameters: {'id': product.id},
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 74,
                height: 90,
                child: AppProductImage(path: product.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      StockStatusBadge(status: product.catalogStockStatus),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product.variants.length > 1 ? 'From ' : ''}${formatRupees(product.sellingPrice)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.variants.length > 1
                        ? product.variantSummary
                        : 'SKU ${product.sku}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const InventorySvg(
                        AppAssets.box,
                        size: 15,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${product.totalAvailable} available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const InventorySvg(AppAssets.chevronRight, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
