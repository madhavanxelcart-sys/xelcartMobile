import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_model.dart';
import 'order_presentation.dart';

class UpdateStatusBottomSheet extends ConsumerStatefulWidget {
  const UpdateStatusBottomSheet({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<UpdateStatusBottomSheet> createState() =>
      _UpdateStatusBottomSheetState();
}

class _UpdateStatusBottomSheetState
    extends ConsumerState<UpdateStatusBottomSheet> {
  late OrderStatus _selected;
  @override
  void initState() {
    super.initState();
    _selected =
        ref
            .read(ordersRepositoryProvider)
            .where((o) => o.id == widget.orderId)
            .firstOrNull
            ?.status ??
        OrderStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final order = ref
        .watch(ordersRepositoryProvider)
        .where((o) => o.id == widget.orderId)
        .firstOrNull;
    if (order == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Order no longer available.'),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFC4C2D5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Update status',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Close status update',
                  onPressed: () => Navigator.pop(context),
                  icon: const AppSvgIcon(
                    assetPath: AppAssets.x,
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                const Text(
                  'Current status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                OrderStatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: RadioGroup<OrderStatus>(
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
                child: Column(
                  children: [
                    for (final status in OrderStatus.values)
                      _StatusRow(
                        status: status,
                        selected: _selected == status,
                        onTap: () => setState(() => _selected = status),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                OrderStatusPill(status: order.status),
                const AppSvgIcon(
                  assetPath: AppAssets.arrowRight,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                OrderStatusPill(status: _selected),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('saveOrderStatus'),
                onPressed: () {
                  ref
                      .read(ordersRepositoryProvider.notifier)
                      .updateOrderStatus(widget.orderId, _selected);
                  Navigator.pop(context);
                },
                child: const Text('Save status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.selected,
    required this.onTap,
  });
  final OrderStatus status;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = orderStatusColors(status);
    final icon = switch (status) {
      OrderStatus.pending => AppAssets.clock3,
      OrderStatus.confirmed => AppAssets.circleCheck,
      OrderStatus.processing => AppAssets.settings,
      OrderStatus.shipped => AppAssets.truck,
      OrderStatus.delivered => AppAssets.package,
      OrderStatus.cancelled => AppAssets.x,
    };
    return Material(
      color: selected ? const Color(0xFFF0EAFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('status-${status.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: icon,
                    width: 25,
                    height: 25,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: status == OrderStatus.cancelled
                            ? AppColors.dangerText
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<OrderStatus>(value: status, activeColor: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
