import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/printer_job_dialog.dart';
import '../data/orders_repository.dart';
import '../domain/order_model.dart';
import 'widgets/order_presentation.dart';
import 'widgets/update_status_bottom_sheet.dart';

final orderExternalLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.orders);
    }
  }

  void _updateStatus(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => UpdateStatusBottomSheet(orderId: orderId),
  );

  void _showCustomer(BuildContext context, OrderModel order) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(order.customerName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                order.customerPhone.isEmpty
                    ? 'No phone number supplied.'
                    : order.customerPhone,
              ),
              if (order.shipment != null || order.deliveryAddress != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  order.shipment?.recipientAddress ??
                      order.deliveryAddress!.formatted,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    String number,
  ) async {
    final uri = Uri.https('wa.me', '/${number.replaceAll(RegExp(r'\D'), '')}');
    try {
      if (await ref.read(orderExternalLauncherProvider)(uri)) return;
    } catch (_) {
      /* Display the same actionable message for platform failures. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open WhatsApp. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref
        .watch(ordersRepositoryProvider)
        .where((order) => order.id == orderId)
        .firstOrNull;
    final topBar = Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => _back(context),
          icon: const _Svg(AppAssets.arrowLeft),
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
        PopupMenuButton<String>(
          tooltip: 'More order actions',
          enabled: order != null,
          icon: const _Svg(AppAssets.ellipsisVertical),
          onSelected: (action) async {
            if (action == 'status') {
              _updateStatus(context);
              return;
            }
            if (action == 'print') {
              if (order != null) showPrinterJobDialog(context, order: order);
              return;
            }
            await Clipboard.setData(ClipboardData(text: orderId));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Order ID copied.')));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'copy', child: Text('Copy order ID')),
            PopupMenuItem(value: 'status', child: Text('Update status')),
            PopupMenuItem(
              value: 'print',
              enabled: order?.shipment?.trackingNumber.isNotEmpty ?? false,
              child: const Text('Print 4x6 Label'),
            ),
          ],
        ),
      ],
    );
    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              topBar,
              const Expanded(
                child: Center(
                  child: Text(
                    'Order not found',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.orders),
                child: const Text('Back to orders'),
              ),
            ],
          ),
        ),
      );
    }
    final (channelAsset, channelColor) = switch (order.channel) {
      SocialChannel.whatsapp => (AppAssets.whatsapp, AppColors.whatsapp),
      SocialChannel.instagram => (AppAssets.instagram, AppColors.instagram),
      SocialChannel.facebook => (AppAssets.facebook, AppColors.facebook),
    };
    final canChat = RegExp(r'^\d{10,15}$')
        .hasMatch(order.customerPhone.replaceAll(RegExp(r'\D'), ''));
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            topBar,
            const SizedBox(height: 20),
            const Text(
              'Order details',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              order.id,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.processingText,
              ),
            ),
            const SizedBox(height: 16),
            _BorderedCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: channelColor,
                          shape: BoxShape.circle,
                        ),
                        child: _Svg(
                          channelAsset,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          order.channel.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OrderStatusPill(status: order.status),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  InkWell(
                    key: const Key('orderCustomer'),
                    onTap: () => _showCustomer(context, order),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: const Color(0xFFEAE5FF),
                            child: Text(
                              order.customerInitials,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.customerPhone.isEmpty
                                      ? 'No phone number supplied'
                                      : order.customerPhone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.receivedAtDetailsLabel ??
                                      order.receivedAtLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _Svg(
                            AppAssets.chevronRight,
                            color: AppColors.processingText,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Products'),
            const SizedBox(height: 10),
            if (order.items.isEmpty) const Text('No products supplied.'),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BorderedCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 94,
                          height: 98,
                          child: OrderProductThumbnail(path: item.imageUrl),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.variant.isEmpty ? '' : '${item.variant} \u00B7 '}Qty ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              formatOrderAmount(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            const _SectionTitle('Customer message'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F0F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                order.customerMessage.isEmpty
                    ? 'No customer message supplied.'
                    : order.customerMessage,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            ),
            if (order.status == OrderStatus.shipped ||
                order.status == OrderStatus.delivered) ...[
              const SizedBox(height: 18),
              _DeliveryCard(order: order),
            ],
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text('Order total', style: TextStyle(fontSize: 16)),
                ),
                Text(
                  formatOrderAmount(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _updateStatus(context),
                child: const Row(
                  children: [
                    SizedBox(width: 20),
                    Expanded(
                      child: Text('Update status', textAlign: TextAlign.center),
                    ),
                    _Svg(AppAssets.chevronRight, color: AppColors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                key: const Key('printOrderLabel'),
                onPressed: order.shipment?.trackingNumber.isNotEmpty == true
                    ? () => showPrinterJobDialog(context, order: order)
                    : null,
                child: const Text('Print 4x6 Label'),
              ),
            ),
            if (order.shipment?.trackingNumber.isNotEmpty != true)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'A shipment AWB is required before printing.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canChat
                    ? () => _openWhatsApp(context, ref, order.customerPhone)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: AppColors.whatsapp,
                  side: BorderSide(
                    color: canChat ? AppColors.whatsapp : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Svg(
                      AppAssets.whatsapp,
                      color: AppColors.whatsapp,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Open WhatsApp chat',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});
  final OrderModel order;
  @override
  Widget build(BuildContext context) {
    final shipment = order.shipment;
    final arrival = shipment?.estimatedDelivery.replaceFirst(
      RegExp(r'\s+\d{4}$'),
      '',
    );
    return Material(
      color: const Color(0xFFF0EBFF),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('orderDeliveryCard'),
        onTap: shipment == null
            ? null
            : () => context.pushNamed(
                RouteNames.deliveryDetails,
                pathParameters: {'id': order.id},
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Image.asset(
                      AppAssets.deliveryTruck,
                      width: 74,
                      height: 74,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          arrival == null
                              ? 'Shipment details not yet available.'
                              : 'Estimated arrival: $arrival',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (shipment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shipment.statusLabel.toLowerCase().replaceFirstMapped(
                          RegExp(r'^.'),
                          (m) => m[0]!.toUpperCase(),
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentText,
                        ),
                      ),
                    ),
                ],
              ),
              if (shipment != null) ...[
                const Divider(color: Color(0xFFE1D9F7)),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'View delivery details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _Svg(AppAssets.chevronRight, color: AppColors.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );
}

class _BorderedCard extends StatelessWidget {
  const _BorderedCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Svg extends StatelessWidget {
  const _Svg(this.path, {this.color = AppColors.textPrimary, this.size = 22});
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
