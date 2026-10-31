import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/data/inventory_repository.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_model.dart';

/// Creates a session-local order; no checkout or stock mutation is performed.
class ManualOrderForm extends ConsumerStatefulWidget {
  const ManualOrderForm({super.key});
  @override
  ConsumerState<ManualOrderForm> createState() => _ManualOrderFormState();
}

class _ManualOrderFormState extends ConsumerState<ManualOrderForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  String? _productId;
  SocialChannel _channel = SocialChannel.whatsapp;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(inventoryRepositoryProvider);
    final selectedId = _productId ?? products.firstOrNull?.id;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add order', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('newOrderCustomer'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Customer name'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a customer name.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Product'),
              items: [
                for (final product in products)
                  DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  ),
              ],
              validator: (v) => v == null ? 'Select a product.' : null,
              onChanged: (v) => setState(() => _productId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('newOrderQuantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'Quantity'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Enter a positive quantity.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SocialChannel>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Channel'),
              items: [
                for (final channel in SocialChannel.values)
                  DropdownMenuItem(value: channel, child: Text(channel.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _channel = v);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  final product = products.firstWhere(
                    (p) => p.id == selectedId,
                  );
                  final quantity = int.parse(_quantity.text);
                  final orders = ref.read(ordersRepositoryProvider);
                  final number =
                      orders
                          .map(
                            (o) =>
                                int.tryParse(o.id.replaceFirst('#ORD-', '')) ??
                                0,
                          )
                          .fold(128, (a, b) => a > b ? a : b) +
                      1;
                  final name = _name.text.trim();
                  final initials = name
                      .split(RegExp(r'\s+'))
                      .take(2)
                      .map((part) => part.characters.first)
                      .join()
                      .toUpperCase();
                  final time = TimeOfDay.now().format(context);
                  final variant =
                      product.variants
                          .where((v) => v.sku == product.sku)
                          .firstOrNull
                          ?.variantSummary
                          .split(' \u00B7 ')
                          .last ??
                      '';
                  ref
                      .read(ordersRepositoryProvider.notifier)
                      .addOrder(
                        OrderModel(
                          id: '#ORD-${number.toString().padLeft(4, '0')}',
                          customerName: name,
                          customerInitials: initials,
                          channel: _channel,
                          status: OrderStatus.pending,
                          receivedAtLabel: 'Today, $time',
                          totalAmount: product.sellingPrice * quantity,
                          items: [
                            OrderItem(
                              productId: product.id,
                              name: product.name,
                              variant: variant,
                              quantity: quantity,
                              price: product.sellingPrice,
                              imageUrl: product.imageUrl,
                            ),
                          ],
                        ),
                      );
                  Navigator.pop(context, true);
                },
                child: const Text('Create order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
