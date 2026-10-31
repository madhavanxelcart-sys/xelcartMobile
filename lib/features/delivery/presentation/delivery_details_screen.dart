import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_model.dart';

/// Injectable boundary for opening the courier's public tracking website.
final deliveryLinkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

Uri? courierTrackingUrl(String courierName) =>
    switch (courierName.trim().toLowerCase()) {
      'delhivery' => Uri.https('www.delhivery.com', '/tracking'),
      _ => null,
    };

class DeliveryDetailsScreen extends ConsumerWidget {
  const DeliveryDetailsScreen({super.key, required this.orderId});
  final String orderId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.orderDetails, pathParameters: {'id': orderId});
    }
  }

  Future<void> _copyTracking(
    BuildContext context,
    String trackingNumber,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: trackingNumber));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tracking number copied')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to copy tracking number. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _track(BuildContext context, WidgetRef ref, Uri url) async {
    try {
      if (await ref.read(deliveryLinkLauncherProvider)(url)) return;
    } catch (_) {
      /* Platform errors use the same retry message. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open courier website. Please try again.'),
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
    final shipment = order?.shipment;
    final url = shipment == null
        ? null
        : courierTrackingUrl(shipment.courierName);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    tooltip: 'More delivery actions',
                    icon: const _Svg(AppAssets.ellipsisVertical),
                    enabled: shipment != null,
                    onSelected: (action) {
                      if (action == 'copy') {
                        _copyTracking(context, shipment!.trackingNumber);
                      } else if (url != null) {
                        _track(context, ref, url);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'copy',
                        enabled: shipment?.trackingNumber.isNotEmpty ?? false,
                        child: const Text('Copy tracking number'),
                      ),
                      PopupMenuItem(
                        value: 'track',
                        enabled: url != null,
                        child: const Text('Track on courier website'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Delivery details',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.processingText,
                ),
              ),
              const SizedBox(height: 18),
              if (order == null || shipment == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    order == null
                        ? 'Order not found'
                        : 'No shipment details available yet.',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _back(context),
                  child: const Text('Back to order'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EBFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Image.asset(
                          AppAssets.deliveryTruck,
                          width: 90,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                shipment.statusLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Estimated delivery',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shipment.estimatedDelivery,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              shipment.updatedAt,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Deliver to'),
                const SizedBox(height: 10),
                _Card(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFEAE5FF),
                        child: Text(
                          order.customerInitials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
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
                            const SizedBox(height: 5),
                            Text(
                              order.customerPhone.isEmpty
                                  ? 'No phone number supplied'
                                  : order.customerPhone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              shipment.recipientAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Shipment'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Courier',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              shipment.courierName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tracking number',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              shipment.trackingNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('copyTrackingNumber'),
                            tooltip: 'Copy tracking number',
                            onPressed: shipment.trackingNumber.isEmpty
                                ? null
                                : () => _copyTracking(
                                    context,
                                    shipment.trackingNumber,
                                  ),
                            icon: const _Svg(
                              AppAssets.copy,
                              color: AppColors.processingText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Tracking timeline'),
                const SizedBox(height: 10),
                _Card(
                  child: shipment.timeline.isEmpty
                      ? const Text(
                          'Tracking updates will appear here.',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < shipment.timeline.length; i++)
                              _TimelineRow(
                                event: shipment.timeline[i],
                                isLast: i == shipment.timeline.length - 1,
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('trackCourier'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    onPressed: url == null
                        ? null
                        : () => _track(context, ref, url),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Track on courier website',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 10),
                        _Svg(
                          AppAssets.externalLink,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});
  final TrackingEvent event;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Semantics(
    label: event.isCurrent
        ? 'Current tracking event'
        : event.isCompleted
        ? 'Completed tracking event'
        : 'Upcoming tracking event',
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: event.isCurrent
                        ? Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE7FF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: event.isCompleted
                                  ? AppColors.primary
                                  : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: event.isCompleted
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: event.isCompleted
                                ? const Center(
                                    child: _Svg(
                                      AppAssets.check,
                                      color: AppColors.white,
                                      size: 16,
                                    ),
                                  )
                                : null,
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 3, color: const Color(0xFFDDD6FE)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: isLast ? 4 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
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
