import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_order_parser_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/domain/product_model.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_model.dart';

class ImportOrderForm extends ConsumerStatefulWidget {
  const ImportOrderForm({super.key});
  @override
  ConsumerState<ImportOrderForm> createState() => _ImportOrderFormState();
}

class _ImportOrderFormState extends ConsumerState<ImportOrderForm> {
  final _conversation = TextEditingController();
  final _fields = {
    for (final key in [
      'recipient_name',
      'phone',
      'street_address',
      'landmark',
      'city',
      'state',
      'pincode',
      'amount',
    ])
      key: TextEditingController(),
  };
  final _items = <_ItemFields>[];
  bool _busy = false;
  bool _hasResult = false;
  String? _error;
  SocialChannel _channel = SocialChannel.whatsapp;
  void _edited(String value) => setState(() => _error = null);
  @override
  void dispose() {
    _conversation.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  ProductModel? _match(String name) => ref
      .read(inventoryRepositoryProvider)
      .where(
        (p) =>
            p.name.toLowerCase().replaceFirst(RegExp(r's$'), '') ==
            name.trim().toLowerCase().replaceFirst(RegExp(r's$'), ''),
      )
      .firstOrNull;
  double? _rawAmount(String? raw) {
    if (raw == null) return null;
    final match = RegExp(
      r'^(?:₹|INR|Rs\.?)?\s*([0-9,]+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    final value = match == null
        ? null
        : double.tryParse(match.group(1)!.replaceAll(',', ''));
    return value != null && value.isFinite && value >= 0 ? value : null;
  }

  ParsedOrderDto? _preview() {
    try {
      return ParsedOrderDto.fromJson({
        for (final key in _fields.keys.where((key) => key != 'amount'))
          key: _fields[key]!.text,
        'items': [
          for (final item in _items)
            {
              'name': item.name.text,
              'variant': item.variant.text,
              'quantity': int.tryParse(item.quantity.text) ?? 0,
            },
        ],
        'raw_amount': _fields['amount']!.text,
        'missing_fields': <String>[],
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _parse() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(aiOrderParserServiceProvider)
          .parse(_conversation.text);
      if (!mounted) return;
      for (final item in _items) {
        item.dispose();
      }
      _items.clear();
      final json = result.toJson();
      for (final key in _fields.keys.where((k) => k != 'amount')) {
        _fields[key]!.text = json[key] as String;
      }
      final amount = _rawAmount(result.rawAmount);
      for (final item in result.items) {
        final product = _match(item.name);
        final price =
            product?.sellingPrice ??
            (result.items.length == 1 && amount != null
                ? amount / item.quantity
                : null);
        _items.add(
          _ItemFields(
            item.name,
            item.variant,
            '${item.quantity}',
            price?.toStringAsFixed(2) ?? '',
          ),
        );
      }
      final total =
          amount ??
          (_items.isNotEmpty &&
                  _items.every(
                    (item) => double.tryParse(item.price.text) != null,
                  )
              ? _items.fold<double>(
                  0,
                  (sum, item) =>
                      sum +
                      double.parse(item.price.text) *
                          int.parse(item.quantity.text),
                )
              : null);
      _fields['amount']!.text = total?.toStringAsFixed(2) ?? '';
      setState(() => _hasResult = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to extract this order. Check the conversation and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    final parsed = _preview();
    final amount = double.tryParse(_fields['amount']!.text);
    final pricesValid = _items.every((item) {
      final p = double.tryParse(item.price.text);
      return p != null && p.isFinite && p >= 0;
    });
    if (parsed == null ||
        !parsed.isComplete ||
        amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        !pricesValid) {
      setState(
        () => _error = 'Complete the missing fields, valid quantities and prices before saving.',
      );
      return;
    }
    final orders = ref.read(ordersRepositoryProvider);
    final next =
        orders
            .map((o) => int.tryParse(o.id.replaceFirst('#ORD-', '')) ?? 0)
            .fold(128, (a, b) => a > b ? a : b) +
        1;
    final id = '#ORD-${next.toString().padLeft(4, '0')}';
    final items = [
      for (var i = 0; i < parsed.items.length; i++)
        OrderItem(
          productId: _match(parsed.items[i].name)?.id ?? '$id-item-$i',
          name: parsed.items[i].name,
          variant: parsed.items[i].variant,
          quantity: parsed.items[i].quantity,
          price: double.parse(_items[i].price.text),
          imageUrl: _match(parsed.items[i].name)?.imageUrl ?? '',
        ),
    ];
    ref
        .read(ordersRepositoryProvider.notifier)
        .addOrder(
          OrderModel(
            id: id,
            customerName: parsed.recipientName,
            customerInitials: parsed.recipientName
                .split(RegExp(r'\s+'))
                .take(2)
                .map((s) => s.characters.first)
                .join()
                .toUpperCase(),
            customerPhone: '+91 ${parsed.phone}',
            channel: _channel,
            status: OrderStatus.pending,
            receivedAtLabel: 'Today, ${TimeOfDay.now().format(context)}',
            customerMessage: _conversation.text,
            items: items,
            totalAmount: amount,
            deliveryAddress: OrderDeliveryAddress(
              streetAddress: parsed.streetAddress,
              landmark: parsed.landmark,
              city: parsed.city,
              state: parsed.state,
              pincode: parsed.pincode,
            ),
          ),
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.watch(orderExtractionBackendProvider).isLocal;
    final parsed = _hasResult ? _preview() : null;
    return Padding(
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
          const Text(
            'Import an order',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            local
                ? 'Local extraction · review every field before saving.'
                : 'AI extraction · review every field before saving.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('rawOrderConversation'),
            controller: _conversation,
            enabled: !_busy,
            onChanged: (_) {
              if (_hasResult) {
                setState(() {
                  _hasResult = false;
                  _error = null;
                });
              }
            },
            minLines: 4,
            maxLines: 8,
            maxLength: 30000,
            decoration: const InputDecoration(
              labelText: 'Paste WhatsApp / Instagram conversation',
              hintText: 'Name: Asha Sharma\nPhone: +91 98765 43210\nAddress: 42, 2nd Cross, Indiranagar\nCity: Bengaluru\nState: Karnataka\nPIN: 560038\nItem: Blue cotton shirt | Size M | 2\nTotal: 1499',
            ),
          ),
          DropdownButtonFormField<SocialChannel>(
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'Channel'),
            items: [
              for (final c in SocialChannel.values)
                DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    if (v != null) setState(() => _channel = v);
                  },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _parse,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Parse conversation'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.dangerText,
                  fontSize: 12,
                ),
              ),
            ),
          if (_hasResult) ...[
            const SizedBox(height: 20),
            const Text(
              'Review extracted order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (parsed == null || !parsed.isComplete)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Missing or invalid: ${parsed?.missingFields.join(', ') ?? 'item names / quantities'}',
                    style: const TextStyle(
                      color: AppColors.warningText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            for (final entry in {
              'recipient_name': 'Recipient name',
              'phone': 'Phone (10 digits)',
              'street_address': 'Street address',
              'landmark': 'Landmark (optional)',
              'city': 'City',
              'state': 'State',
              'pincode': 'PIN code',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  key: Key('parsed-${entry.key}'),
                  controller: _fields[entry.key],
                  onChanged: _edited,
                  decoration: InputDecoration(labelText: entry.value),
                  keyboardType: ['phone', 'pincode'].contains(entry.key)
                      ? TextInputType.phone
                      : TextInputType.text,
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Items and unit prices',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (var i = 0; i < _items.length; i++)
              Padding(
                key: ObjectKey(_items[i]),
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Remove item ${i + 1}',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          final removed = _items[i];
                          setState(() => _items.removeAt(i));
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => removed.dispose(),
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: _items[i].name,
                      onChanged: _edited,
                      decoration: InputDecoration(
                        labelText: 'Item ${i + 1} name',
                      ),
                    ),
                    TextField(
                      controller: _items[i].variant,
                      onChanged: _edited,
                      decoration: const InputDecoration(labelText: 'Variant'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _items[i].quantity,
                            onChanged: _edited,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _items[i].price,
                            onChanged: _edited,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Unit price (₹)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            TextButton(
              onPressed: _items.length >= 50
                  ? null
                  : () => setState(
                      () => _items.add(_ItemFields('', '', '1', '')),
                    ),
              child: const Text('Add item'),
            ),
            TextField(
              key: const Key('parsed-amount'),
              controller: _fields['amount'],
              onChanged: _edited,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Order total (₹)',
                helperText:
                    'Review any delivery charges or discounts in the total.',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('saveParsedOrder'),
                onPressed: _busy ? null : _save,
                child: const Text('Save order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemFields {
  _ItemFields(String n, String v, String q, String p)
    : name = TextEditingController(text: n),
      variant = TextEditingController(text: v),
      quantity = TextEditingController(text: q),
      price = TextEditingController(text: p);
  final TextEditingController name, variant, quantity, price;
  void dispose() {
    name.dispose();
    variant.dispose();
    quantity.dispose();
    price.dispose();
  }
}
