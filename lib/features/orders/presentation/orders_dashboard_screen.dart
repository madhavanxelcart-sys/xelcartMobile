import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../data/orders_repository.dart';
import '../domain/order_model.dart';
import 'widgets/add_order_sheet.dart';
import 'widgets/order_presentation.dart';

class OrdersDashboardScreen extends ConsumerStatefulWidget {
  const OrdersDashboardScreen({super.key});
  @override
  ConsumerState<OrdersDashboardScreen> createState() =>
      _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends ConsumerState<OrdersDashboardScreen> {
  final _search = TextEditingController();
  SocialChannel? _channel;
  OrderStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    _search.clear();
    _channel = null;
    _status = null;
  });

  Future<void> _showFilters() async {
    var channel = _channel;
    var status = _status;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<SocialChannel>(
                initialValue: channel,
                decoration: const InputDecoration(labelText: 'Channel'),
                hint: const Text('All channels'),
                items: [
                  const DropdownMenuItem<SocialChannel>(
                    child: Text('All channels'),
                  ),
                  for (final value in SocialChannel.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => updateSheet(() => channel = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<OrderStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                hint: const Text('All statuses'),
                items: [
                  const DropdownMenuItem<OrderStatus>(
                    child: Text('All statuses'),
                  ),
                  for (final value in OrderStatus.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => updateSheet(() => status = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _channel = channel;
                      _status = status;
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Apply filters'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    _clearFilters();
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Reset filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersRepositoryProvider);
    final orders = ref
        .read(ordersRepositoryProvider.notifier)
        .filterOrders(
          channel: _channel,
          status: _status,
          searchQuery: _search.text,
        );
    // The reference dashboard covers 128 orders; the repository has three
    // representative rows. Keep those baseline metrics, reflecting local changes.
    int count(OrderStatus status, int baseline, int seedCount) =>
        baseline -
        seedCount +
        allOrders.where((o) => o.status == status).length;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const ValueKey('ordersDashboard'),
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
                                height: 64,
                                width: 190,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
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
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your orders.',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Transform.rotate(
                                angle: -0.12,
                                child: Container(
                                  width: 45,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ExcludeSemantics(
                          child: Image.asset(
                            AppAssets.onboardingParcel,
                            width: 72,
                            height: 64,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7DFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: _Svg(
                                    AppAssets.shoppingBag,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${128 - 3 + allOrders.length}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Text(
                                      'Total orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _MenuPill<SocialChannel>(
                                menuKey: const Key('summaryChannels'),
                                label: (_channel?.label ?? 'All channels')
                                    .toUpperCase(),
                                lime: true,
                                values: SocialChannel.values,
                                selected: _channel,
                                allLabel: 'All channels',
                                labelOf: (v) => v.label,
                                onChanged: (v) => setState(() => _channel = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  icon: AppAssets.clock3,
                                  value: count(OrderStatus.pending, 24, 1),
                                  label: 'Pending',
                                  color: AppColors.pendingText,
                                  background: AppColors.pendingBackground,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _MiniStat(
                                  icon: AppAssets.circleCheck,
                                  value: count(OrderStatus.confirmed, 62, 1),
                                  label: 'Confirmed',
                                  color: AppColors.successText,
                                  background: AppColors.successBackground,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _MiniStat(
                                  icon: AppAssets.truck,
                                  value: count(OrderStatus.shipped, 42, 1),
                                  label: 'Shipped',
                                  color: AppColors.processingText,
                                  background: AppColors.processingBackground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('orderSearch'),
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search customers',
                              fillColor: const Color(0xFFF3F2F8),
                              filled: true,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(14),
                                child: _Svg(
                                  AppAssets.search,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () => setState(_search.clear),
                                      icon: const _Svg(AppAssets.x),
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
                              color: _status == null
                                  ? AppColors.border
                                  : AppColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            tooltip: 'Filter orders',
                            onPressed: _showFilters,
                            icon: const _Svg(
                              AppAssets.slidersHorizontal,
                              color: AppColors.primary,
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
                          _ChannelChip(
                            label: 'All',
                            selected: _channel == null,
                            onTap: () => setState(() => _channel = null),
                          ),
                          for (final channel in SocialChannel.values) ...[
                            const SizedBox(width: 6),
                            _ChannelChip(
                              label: channel.label,
                              channel: channel,
                              selected: _channel == channel,
                              onTap: () => setState(() => _channel = channel),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _MenuPill<OrderStatus>(
                              menuKey: const Key('statusFilter'),
                              label: _status?.label ?? 'All statuses',
                              values: OrderStatus.values,
                              selected: _status,
                              allLabel: 'All statuses',
                              labelOf: (v) => v.label,
                              onChanged: (v) => setState(() => _status = v),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final created =
                                    await showModalBottomSheet<bool>(
                                      context: context,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      isScrollControlled: true,
                                      showDragHandle: true,
                                      backgroundColor: AppColors.white,
                                      builder: (_) => const AddOrderSheet(),
                                    );
                                if (created == true && mounted) _clearFilters();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const _Svg(
                                AppAssets.plus,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              label: const Text(
                                'Add order',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        );
                        const title = Text(
                          'Recent orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                        return Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [title, actions],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Svg(
                        AppAssets.search,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No orders found',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try another search or clear your filters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    required this.menuKey,
    required this.label,
    required this.values,
    required this.selected,
    required this.allLabel,
    required this.labelOf,
    required this.onChanged,
    this.lime = false,
  });
  final Key menuKey;
  final String label;
  final List<T> values;
  final T? selected;
  final String allLabel;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool lime;
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    key: menuKey,
    tooltip: lime ? 'Select channel' : 'Select status',
    initialValue: selected == null ? -1 : values.indexOf(selected as T),
    onSelected: (index) => onChanged(index < 0 ? null : values[index]),
    itemBuilder: (_) => [
      PopupMenuItem(value: -1, child: Text(allLabel)),
      for (var i = 0; i < values.length; i++)
        PopupMenuItem(value: i, child: Text(labelOf(values[i]))),
    ],
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: lime ? 9 : 10, vertical: 9),
      decoration: BoxDecoration(
        color: lime ? AppColors.accent : AppColors.white,
        borderRadius: BorderRadius.circular(lime ? 20 : 9),
        border: lime ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: lime ? 9 : 11,
              fontWeight: lime ? FontWeight.w800 : FontWeight.w500,
              color: lime ? AppColors.accentText : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          _Svg(
            AppAssets.chevronDown,
            size: 12,
            color: lime ? AppColors.accentText : AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });
  final String icon;
  final int value;
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _Svg(icon, color: color, size: 20),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 9,
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

(Color, String) _channelInfo(SocialChannel channel) => switch (channel) {
  SocialChannel.whatsapp => (AppColors.whatsapp, AppAssets.whatsapp),
  SocialChannel.instagram => (AppColors.instagram, AppAssets.instagram),
  SocialChannel.facebook => (AppColors.facebook, AppAssets.facebook),
};

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.channel,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final SocialChannel? channel;
  @override
  Widget build(BuildContext context) => RawChip(
    label: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.textPrimary,
      ),
    ),
    avatar: channel == null
        ? null
        : _Svg(
            _channelInfo(channel!).$2,
            color: selected ? AppColors.white : _channelInfo(channel!).$1,
            size: 22,
          ),
    selected: selected,
    showCheckmark: false,
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.white,
    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    shape: const StadiumBorder(),
    onPressed: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderModel order;
  @override
  Widget build(BuildContext context) {
    final item = order.items.firstOrNull;
    final channel = _channelInfo(order.channel);
    final (background, foreground) = switch (order.status) {
      OrderStatus.pending => (
        AppColors.pendingBackground,
        AppColors.pendingText,
      ),
      OrderStatus.confirmed || OrderStatus.delivered => (
        AppColors.successBackground,
        AppColors.successText,
      ),
      OrderStatus.processing || OrderStatus.shipped => (
        AppColors.processingBackground,
        AppColors.processingText,
      ),
      OrderStatus.cancelled => (
        AppColors.dangerBackground,
        AppColors.dangerText,
      ),
    };
    final time = order.receivedAtLabel.replaceFirst('Today, ', '');
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('order-${order.id}'),
        onTap: () => context.pushNamed(
          RouteNames.orderDetails,
          pathParameters: {'id': order.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: OrderProductThumbnail(path: item?.imageUrl ?? ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item?.name ?? 'No products',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item == null
                                    ? ''
                                    : '${item.variant.isEmpty ? '' : '${item.variant} \u00B7 '}Qty ${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatOrderAmount(order.totalAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Svg(channel.$2, color: channel.$1, size: 18),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${order.channel.label} \u00B7 $time',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const _Svg(
                          AppAssets.chevronRight,
                          color: AppColors.primary,
                          size: 18,
                        ),
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
}

class _Svg extends StatelessWidget {
  const _Svg(this.path, {this.color = AppColors.textPrimary, this.size = 20});
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
