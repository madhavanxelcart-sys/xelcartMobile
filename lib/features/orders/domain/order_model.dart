/// The originating social selling channel.
enum SocialChannel {
  whatsapp('WhatsApp'),
  instagram('Instagram'),
  facebook('Facebook');

  const SocialChannel(this.label);
  final String label;
}

enum OrderStatus {
  pending('Pending', 'Order received'),
  confirmed('Confirmed', 'Order accepted'),
  processing('Processing', 'Being prepared'),
  shipped('Shipped', 'Dispatched'),
  delivered('Delivered', 'Successfully delivered'),
  cancelled('Cancelled', 'Order cancelled');

  const OrderStatus(this.label, this.description);
  final String label;
  final String description;
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    this.variant = '',
    required this.quantity,
    required this.price,
    this.imageUrl = '',
  }) : assert(quantity > 0),
       assert(price >= 0);
  final String productId;
  final String name;
  final String variant;
  final int quantity;

  /// Unit price in INR. The line total is quantity * price.
  final double price;

  /// Empty when no standalone photo is supplied; render a placeholder.
  final String imageUrl;
  double get totalPrice => quantity * price;
}

class TrackingEvent {
  const TrackingEvent({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isCompleted,
    this.isCurrent = false,
  });
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;
}

class ShipmentInfo {
  ShipmentInfo({
    required this.courierName,
    required this.trackingNumber,
    required this.statusLabel,
    required this.estimatedDelivery,
    required this.updatedAt,
    required this.recipientAddress,
    required List<TrackingEvent> timeline,
  }) : timeline = List.unmodifiable(timeline);
  final String courierName;
  final String trackingNumber;
  final String statusLabel;

  /// Presentation labels preserve the reference's date and time formatting.
  final String estimatedDelivery;
  final String updatedAt;
  final String recipientAddress;
  final List<TrackingEvent> timeline;
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerInitials,
    this.customerPhone = '',
    required this.channel,
    required this.status,
    required this.receivedAtLabel,
    this.receivedAtDetailsLabel,
    this.customerMessage = '',
    required List<OrderItem> items,
    required this.totalAmount,
    this.shipment,
    this.deliveryAddress,
  }) : items = List.unmodifiable(items);
  final String id;
  final String customerName;
  final String customerInitials;
  final String customerPhone;
  final SocialChannel channel;
  final OrderStatus status;
  final String receivedAtLabel;
  final String? receivedAtDetailsLabel;
  final String customerMessage;
  final List<OrderItem> items;
  final double totalAmount;
  final ShipmentInfo? shipment;
  final OrderDeliveryAddress? deliveryAddress;

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
    id: id,
    customerName: customerName,
    customerInitials: customerInitials,
    customerPhone: customerPhone,
    channel: channel,
    status: status ?? this.status,
    receivedAtLabel: receivedAtLabel,
    receivedAtDetailsLabel: receivedAtDetailsLabel,
    customerMessage: customerMessage,
    items: items,
    totalAmount: totalAmount,
    shipment: shipment,
    deliveryAddress: deliveryAddress,
  );
}

class OrderDeliveryAddress {
  const OrderDeliveryAddress({
    required this.streetAddress,
    this.landmark = '',
    this.city = '',
    this.state = '',
    required this.pincode,
  });
  final String streetAddress, landmark, city, state, pincode;
  String get formatted => [
    streetAddress,
    landmark,
    [city, state, pincode].where((v) => v.isNotEmpty).join(', '),
  ].where((v) => v.isNotEmpty).join('\n');
}
