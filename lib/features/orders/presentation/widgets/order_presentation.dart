import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_product_image.dart';
import '../../../../core/theme/app_colors.dart';

import '../../domain/order_model.dart';

String formatOrderAmount(double amount) => formatRupees(amount);

(Color, Color) orderStatusColors(OrderStatus status) => switch (status) {
  OrderStatus.pending => (AppColors.pendingBackground, AppColors.pendingText),
  OrderStatus.confirmed => (AppColors.successBackground, AppColors.successText),
  OrderStatus.processing || OrderStatus.shipped => (
    AppColors.processingBackground,
    AppColors.processingText,
  ),
  OrderStatus.delivered => (const Color(0xFFF1F2F6), AppColors.textPrimary),
  OrderStatus.cancelled => (AppColors.dangerBackground, AppColors.dangerText),
};

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = orderStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

typedef OrderProductThumbnail = AppProductImage;
