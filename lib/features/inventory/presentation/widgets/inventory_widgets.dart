import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../domain/product_model.dart';

class InventorySvg extends StatelessWidget {
  const InventorySvg(
    this.path, {
    super.key,
    this.color = AppColors.primary,
    this.size = 22,
  });
  final String path;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => AppSvgIcon(
    assetPath: path,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

class InventoryTopBar extends StatelessWidget {
  const InventoryTopBar({
    super.key,
    required this.onBack,
    required this.trailing,
  });
  final VoidCallback onBack;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 76,
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const InventorySvg(
              AppAssets.arrowLeft,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      Expanded(
        child: Center(
          child: ClipRect(
            child: SizedBox(
              width: 180,
              height: 40,
              child: OverflowBox(
                minHeight: 60,
                maxHeight: 60,
                child: Image.asset(
                  AppAssets.xelcartLogo,
                  width: 180,
                  height: 60,
                  fit: BoxFit.contain,
                  semanticLabel: 'Xelcart',
                ),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        width: 76,
        child: Align(alignment: Alignment.centerRight, child: trailing),
      ),
    ],
  );
}

class InventoryLabel extends StatelessWidget {
  const InventoryLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.dangerText),
            ),
        ],
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class InventoryCard extends StatelessWidget {
  const InventoryCard({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class InventoryAccordion extends StatelessWidget {
  const InventoryAccordion({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final String subtitle;
  final String icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('$title-$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        leading: InventorySvg(icon, size: 28),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        children: children,
      ),
    ),
  );
}

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});
  final StockStatus status;
  static String label(StockStatus status) => switch (status) {
    StockStatus.inStock => 'In stock',
    StockStatus.lowStock => 'Low stock',
    StockStatus.outOfStock => 'Out of stock',
  };
  @override
  Widget build(BuildContext context) {
    final (background, color) = switch (status) {
      StockStatus.inStock => (
        AppColors.successBackground,
        AppColors.successText,
      ),
      StockStatus.lowStock => (
        AppColors.warningBackground,
        AppColors.warningText,
      ),
      StockStatus.outOfStock => (
        AppColors.dangerBackground,
        AppColors.dangerText,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class StockNumbers extends StatelessWidget {
  const StockNumbers({
    super.key,
    required this.onHand,
    required this.reserved,
    required this.available,
    this.preview = false,
  });
  final int onHand;
  final int reserved;
  final int available;
  final bool preview;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StockMetric(
          value: onHand,
          label: 'On hand',
          icon: AppAssets.box,
          color: AppColors.primary,
          background: const Color(0xFFF3F0FF),
          metricKey: '${preview ? 'preview' : 'current'}OnHand',
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _StockMetric(
          value: reserved,
          label: 'Reserved',
          icon: AppAssets.lockKeyhole,
          color: AppColors.pendingText,
          background: const Color(0xFFFFF8E7),
          metricKey: '${preview ? 'preview' : 'current'}Reserved',
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: _StockMetric(
          value: available,
          label: 'Available',
          icon: AppAssets.circleCheck,
          color: available < 0 ? AppColors.dangerText : AppColors.successText,
          background: const Color(0xFFECFDF3),
          metricKey: '${preview ? 'preview' : 'current'}Available',
        ),
      ),
    ],
  );
}

class _StockMetric extends StatelessWidget {
  const _StockMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.metricKey,
  });
  final int value;
  final String label;
  final String icon;
  final Color color;
  final Color background;
  final String metricKey;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        InventorySvg(icon, color: color, size: 22),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  key: Key(metricKey),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: value < 0
                        ? AppColors.dangerText
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
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
        ),
      ],
    ),
  );
}
