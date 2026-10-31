import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/features/orders/data/orders_repository.dart';
import 'package:xelcart_mobile/features/orders/domain/order_model.dart';
import 'package:xelcart_mobile/features/inventory/data/inventory_repository.dart';
import 'package:xelcart_mobile/features/inventory/domain/product_model.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('Order fixtures preserve reference totals, shipment, channels and descriptions', () {
    final orders = container.read(ordersRepositoryProvider);
    expect(orders.map((o) => o.id), ['#ORD-0128', '#ORD-0127', '#ORD-0126']);
    expect(orders.map((o) => o.customerName), [
      'Asha Sharma',
      'Riya Patel',
      'Arjun Mehta',
    ]);
    expect(orders.map((o) => o.totalAmount), [1499, 899, 2450]);
    for (final order in orders) {
      expect(
        order.items.fold<double>(0, (sum, item) => sum + item.totalPrice),
        order.totalAmount,
      );
    }
    final shipment = orders.first.shipment!;
    expect(shipment.courierName, 'Delhivery');
    expect(shipment.trackingNumber, 'DLV1234567890');
    expect(shipment.estimatedDelivery, '14 Oct 2026');
    expect(shipment.timeline.map((e) => e.title), [
      'In transit',
      'Picked up',
      'Shipment created',
    ]);
    expect(shipment.timeline.where((e) => e.isCurrent).length, 1);
    expect(
      shipment.timeline.first.timestamp.isAfter(shipment.timeline[1].timestamp),
      isTrue,
    );
    expect(OrderStatus.values.map((s) => s.description), [
      'Order received',
      'Order accepted',
      'Being prepared',
      'Dispatched',
      'Successfully delivered',
      'Order cancelled',
    ]);
    expect(() => orders.clear(), throwsUnsupportedError);
    expect(() => orders.first.items.clear(), throwsUnsupportedError);
    expect(() => shipment.timeline.clear(), throwsUnsupportedError);
  });

  test('Order filters compose and status updates emit immutable snapshots', () {
    final repo = container.read(ordersRepositoryProvider.notifier);
    final original = container.read(ordersRepositoryProvider);
    expect(
      repo.filterOrders(channel: SocialChannel.instagram).single.customerName,
      'Riya Patel',
    );
    expect(
      repo.filterOrders(status: OrderStatus.shipped).single.customerName,
      'Arjun Mehta',
    );
    expect(repo.filterOrders(searchQuery: '  ASHA ').single.id, '#ORD-0128');
    expect(
      repo
          .filterOrders(
            channel: SocialChannel.whatsapp,
            status: OrderStatus.pending,
            searchQuery: 'size m',
          )
          .length,
      1,
    );
    expect(
      repo.filterOrders(
        channel: SocialChannel.facebook,
        status: OrderStatus.pending,
      ),
      isEmpty,
    );
    var notifications = 0;
    final subscription = container.listen(
      ordersRepositoryProvider,
      (_, _) => notifications++,
    );
    addTearDown(subscription.close);
    repo.updateOrderStatus('#ORD-0128', OrderStatus.confirmed);
    expect(notifications, 1);
    expect(
      container.read(ordersRepositoryProvider).first.status,
      OrderStatus.confirmed,
    );
    expect(original.first.status, OrderStatus.pending);
    expect(
      identical(
        original.first.shipment,
        container.read(ordersRepositoryProvider).first.shipment,
      ),
      isTrue,
    );
    expect(
      () => repo.updateOrderStatus('missing', OrderStatus.delivered),
      throwsArgumentError,
    );
    expect(repo.filterOrders(status: OrderStatus.pending), isEmpty);
  });

  test('Inventory separates all-size availability from selected-SKU stock', () {
    final products = container.read(inventoryRepositoryProvider);
    expect(products.length, 3);
    final shirt = products.first;
    expect(shirt.sellingPrice, 749.50);
    expect(shirt.costPrice, 420);
    expect(shirt.variantSummary, '3 size variants');
    expect(shirt.sku, 'SHIRT-BLU-M');
    expect(
      [shirt.onHand, shirt.reserved, shirt.available, shirt.totalAvailable],
      [12, 2, 10, 32],
    );
    expect(products.map((p) => p.stockStatus), [
      StockStatus.inStock,
      StockStatus.lowStock,
      StockStatus.outOfStock,
    ]);
    expect(products[1].available, 4);
    expect(products[2].available, 0);
    expect(() => products.clear(), throwsUnsupportedError);
    expect(() => shirt.variants.clear(), throwsUnsupportedError);
  });

  test('Stock adjustments retain reservations, sync totals and prepend signed audit entries', () {
    final timestamp = DateTime.utc(2026, 10, 30, 10);
    final timedContainer = ProviderContainer(
      overrides: [inventoryClockProvider.overrideWithValue(() => timestamp)],
    );
    addTearDown(timedContainer.dispose);
    final repo = timedContainer.read(inventoryRepositoryProvider.notifier);
    final original = timedContainer.read(inventoryRepositoryProvider).first;
    repo.addStock(
      'shirt-blue',
      quantity: 10,
      reason: ' Restock ',
      lowStockThreshold: 5,
    );
    var shirt = timedContainer.read(inventoryRepositoryProvider).first;
    expect(
      [shirt.onHand, shirt.reserved, shirt.available, shirt.totalAvailable],
      [22, 2, 20, 42],
    );
    expect(shirt.history.single.date, timestamp);
    expect(shirt.history.single.changeQty, 10);
    expect(shirt.history.single.reason, 'Restock');
    expect(original.onHand, 12);
    repo.removeStock('shirt-blue', quantity: 20, reason: 'Damaged');
    shirt = timedContainer.read(inventoryRepositoryProvider).first;
    expect([shirt.onHand, shirt.reserved, shirt.available], [2, 2, 0]);
    expect(shirt.stockStatus, StockStatus.outOfStock);
    expect(shirt.totalAvailable, 22);
    expect(shirt.history.map((entry) => entry.changeQty), [-20, 10]);
    expect(() => shirt.history.clear(), throwsUnsupportedError);
    repo.addStock('shirt-blue', quantity: 5, reason: 'Restock');
    expect(
      timedContainer.read(inventoryRepositoryProvider).first.stockStatus,
      StockStatus.lowStock,
    );
  });

  test('Invalid stock mutations fail atomically', () {
    final repo = container.read(inventoryRepositoryProvider.notifier);
    final before = container.read(inventoryRepositoryProvider);
    expect(
      () => repo.removeStock('shirt-blue', quantity: 11, reason: 'Sale'),
      throwsStateError,
    );
    expect(
      () => repo.addStock('shirt-blue', quantity: 0, reason: 'Restock'),
      throwsArgumentError,
    );
    expect(
      () => repo.removeStock('shirt-blue', quantity: -1, reason: 'Sale'),
      throwsArgumentError,
    );
    expect(
      () => repo.addStock('shirt-blue', quantity: 1, reason: '  '),
      throwsArgumentError,
    );
    expect(
      () => repo.addStock(
        'shirt-blue',
        quantity: 1,
        reason: 'Restock',
        lowStockThreshold: -1,
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.addStock('missing', quantity: 1, reason: 'Restock'),
      throwsArgumentError,
    );
    expect(
      identical(before, container.read(inventoryRepositoryProvider)),
      isTrue,
    );
  });

  test('Product additions reject duplicate IDs and variant SKUs', () {
    final repo = container.read(inventoryRepositoryProvider.notifier);
    ProductModel product(String id, String sku) => ProductModel(
      id: id,
      name: 'New product',
      sku: sku,
      category: 'Home',
      sellingPrice: 100,
      onHand: 5,
    );
    repo.addProduct(product('new-product', 'NEW-SKU'));
    expect(container.read(inventoryRepositoryProvider).length, 4);
    expect(
      () => repo.addProduct(product('new-product', 'OTHER')),
      throwsArgumentError,
    );
    expect(
      () => repo.addProduct(product('other', 'shirt-blu-s')),
      throwsArgumentError,
    );
    expect(
      () => ProductModel(
        id: 'bad',
        name: 'Bad',
        sku: 'BAD',
        category: 'Home',
        sellingPrice: 1,
        onHand: 1,
        reserved: 2,
      ),
      throwsArgumentError,
    );
  });
}
