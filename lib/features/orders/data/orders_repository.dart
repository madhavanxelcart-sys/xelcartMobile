import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';

import '../domain/order_model.dart';

final ordersRepositoryProvider =
    NotifierProvider<OrdersRepository, List<OrderModel>>(OrdersRepository.new);

/// Session-local mock data. Status changes do not fabricate courier events.
class OrdersRepository extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() => List.unmodifiable([
    OrderModel(
      id: '#ORD-0128',
      customerName: 'Asha Sharma',
      customerInitials: 'AS',
      customerPhone: '+91 98765 43210',
      channel: SocialChannel.whatsapp,
      status: OrderStatus.pending,
      receivedAtLabel: 'Today, 10:42 AM',
      receivedAtDetailsLabel: 'Received 9 Oct, 10:42 AM',
      customerMessage: 'Hi! I would like to order 2 blue shirts in size M. Please deliver to Bengaluru. Let me know the total.',
      items: const [
        OrderItem(
          productId: 'shirt-blue',
          name: 'Blue cotton shirt',
          variant: 'Size M',
          quantity: 2,
          price: 749.50,
          imageUrl: AppAssets.blueCottonShirt,
        ),
      ],
      totalAmount: 1499,
      shipment: ShipmentInfo(
        courierName: 'Delhivery',
        trackingNumber: 'DLV1234567890',
        statusLabel: 'IN TRANSIT',
        estimatedDelivery: '14 Oct 2026',
        updatedAt: 'Updated 11 Oct, 2:30 PM',
        recipientAddress:
            '42, 2nd Cross, Indiranagar\nBengaluru, Karnataka 560038',
        timeline: [
          TrackingEvent(
            title: 'In transit',
            subtitle: 'Bengaluru hub \u00B7 11 Oct, 2:30 PM',
            timestamp: DateTime.parse('2026-10-11T14:30:00+05:30'),
            isCompleted: false,
            isCurrent: true,
          ),
          TrackingEvent(
            title: 'Picked up',
            subtitle: '10 Oct, 4:15 PM',
            timestamp: DateTime.parse('2026-10-10T16:15:00+05:30'),
            isCompleted: true,
          ),
          TrackingEvent(
            title: 'Shipment created',
            subtitle: '10 Oct, 9:00 AM',
            timestamp: DateTime.parse('2026-10-10T09:00:00+05:30'),
            isCompleted: true,
          ),
        ],
      ),
    ),
    OrderModel(
      id: '#ORD-0127',
      customerName: 'Riya Patel',
      customerInitials: 'RP',
      channel: SocialChannel.instagram,
      status: OrderStatus.confirmed,
      receivedAtLabel: 'Today, 10:18 AM',
      items: const [
        OrderItem(
          productId: 'tote-natural',
          name: 'Canvas tote bag',
          quantity: 1,
          price: 899,
          imageUrl: AppAssets.canvasToteBag,
        ),
      ],
      totalAmount: 899,
    ),
    OrderModel(
      id: '#ORD-0126',
      customerName: 'Arjun Mehta',
      customerInitials: 'AM',
      channel: SocialChannel.facebook,
      status: OrderStatus.shipped,
      receivedAtLabel: 'Yesterday',
      items: const [
        OrderItem(
          productId: 'dinner-ceramic',
          name: 'Ceramic dinner set',
          quantity: 1,
          price: 2450,
          imageUrl: AppAssets.ceramicDinnerSet,
        ),
      ],
      totalAmount: 2450,
    ),
  ]);

  /// Filters compose (AND); search matches customer, phone, order ID or item.
  /// Watch [ordersRepositoryProvider] in consumers to rebuild after changes.
  List<OrderModel> filterOrders({
    SocialChannel? channel,
    OrderStatus? status,
    String searchQuery = '',
  }) {
    final query = searchQuery.trim().toLowerCase();
    return List.unmodifiable(
      state.where(
        (order) =>
            (channel == null || order.channel == channel) &&
            (status == null || order.status == status) &&
            (query.isEmpty ||
                [
                  order.id,
                  order.customerName,
                  order.customerPhone,
                  ...order.items.map((item) => '${item.name} ${item.variant}'),
                ].any((value) => value.toLowerCase().contains(query))),
      ),
    );
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    if (!state.any((order) => order.id == orderId)) {
      throw ArgumentError.value(orderId, 'orderId', 'Order not found');
    }
    state = List.unmodifiable([
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: newStatus) else order,
    ]);
  }

  void addOrder(OrderModel order) {
    if (order.id.trim().isEmpty ||
        order.customerName.trim().isEmpty ||
        order.items.isEmpty ||
        !order.totalAmount.isFinite ||
        order.totalAmount < 0) {
      throw ArgumentError(
        'A valid order ID, customer, items and total are required',
      );
    }
    if (state.any((existing) => existing.id == order.id)) {
      throw ArgumentError('Order ID already exists');
    }
    state = List.unmodifiable([order, ...state]);
  }
}
