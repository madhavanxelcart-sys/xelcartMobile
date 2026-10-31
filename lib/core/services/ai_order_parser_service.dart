import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ParsedOrderItemDto {
  ParsedOrderItemDto({
    required this.name,
    this.variant = '',
    required this.quantity,
  }) {
    if (name.trim().isEmpty || quantity <= 0) {
      throw const FormatException(
        'Each item needs a name and positive integer quantity.',
      );
    }
  }
  final String name;
  final String variant;
  final int quantity;
  factory ParsedOrderItemDto.fromJson(Map<String, dynamic> json) {
    if (json['quantity'] is! int ||
        json['name'] is! String ||
        json['variant'] is! String) {
      throw const FormatException('Invalid item contract.');
    }
    return ParsedOrderItemDto(
      name: (json['name'] as String).trim(),
      variant: (json['variant'] as String).trim(),
      quantity: json['quantity'] as int,
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'variant': variant,
    'quantity': quantity,
  };
}

/// Model output is untrusted. Completeness is recomputed after normalization.
class ParsedOrderDto {
  ParsedOrderDto._(
    this.recipientName,
    this.phone,
    this.streetAddress,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.items,
    this.rawAmount,
    this.missingFields,
  );
  final String recipientName,
      phone,
      streetAddress,
      landmark,
      city,
      state,
      pincode;
  final List<ParsedOrderItemDto> items;
  final String? rawAmount;
  final List<String> missingFields;
  bool get isComplete => missingFields.isEmpty;

  static String normalizePhone(String value) {
    var phone = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+91')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return phone;
  }

  static bool validPhone(String value) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(normalizePhone(value));
  static bool validPincode(String value) =>
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(value.trim());

  factory ParsedOrderDto.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value == null) return '';
      if (value is! String) throw FormatException('$key must be a string.');
      return value.trim();
    }

    final phone = normalizePhone(text('phone'));
    final pin = text('pincode');
    final street = text('street_address');
    final name = text('recipient_name');
    final rawItems = json['items'] ?? [];
    if (rawItems is! List || rawItems.length > 50) {
      throw const FormatException('Invalid items list.');
    }
    final items = <ParsedOrderItemDto>[];
    for (final item in rawItems) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid item.');
      }
      items.add(ParsedOrderItemDto.fromJson(item));
    }
    final missing = <String>{
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) 'phone',
      if (!validPincode(pin)) 'pincode',
      if (street.isEmpty) 'street_address',
      if (name.isEmpty) 'recipient_name',
      if (items.isEmpty) 'items',
    };
    final reported = json['missing_fields'];
    if (json.containsKey('is_complete') && json['is_complete'] is! bool) {
      throw const FormatException('is_complete must be boolean.');
    }
    if (reported != null &&
        (reported is! List || reported.any((v) => v is! String))) {
      throw const FormatException('Invalid missing_fields.');
    }
    // Preserve extra missing fields reported by the backend only while empty.
    for (final key in (reported as List? ?? []).whereType<String>()) {
      if (['city', 'state'].contains(key) && text(key).isEmpty) {
        missing.add(key);
      }
    }
    final amount = json['raw_amount'];
    if (amount != null && amount is! String && amount is! num) {
      throw const FormatException('Invalid raw_amount.');
    }
    return ParsedOrderDto._(
      name,
      phone,
      street,
      text('landmark'),
      text('city'),
      text('state'),
      pin,
      List.unmodifiable(items),
      amount?.toString(),
      List.unmodifiable(missing),
    );
  }
  Map<String, dynamic> toJson() => {
    'recipient_name': recipientName,
    'phone': phone,
    'street_address': streetAddress,
    'landmark': landmark,
    'city': city,
    'state': state,
    'pincode': pincode,
    'items': items.map((i) => i.toJson()).toList(),
    'raw_amount': rawAmount,
    'is_complete': isComplete,
    'missing_fields': missingFields,
  };
  static const jsonSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': [
      'recipient_name',
      'phone',
      'street_address',
      'landmark',
      'city',
      'state',
      'pincode',
      'items',
      'raw_amount',
      'is_complete',
      'missing_fields',
    ],
    'properties': {
      'recipient_name': {'type': 'string'},
      'phone': {'type': 'string'},
      'street_address': {'type': 'string'},
      'landmark': {'type': 'string'},
      'city': {'type': 'string'},
      'state': {'type': 'string'},
      'pincode': {'type': 'string'},
      'items': {
        'type': 'array',
        'maxItems': 50,
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['name', 'variant', 'quantity'],
          'properties': {
            'name': {'type': 'string', 'minLength': 1},
            'variant': {'type': 'string'},
            'quantity': {'type': 'integer', 'minimum': 1},
          },
        },
      },
      'raw_amount': {
        'type': ['string', 'number', 'null'],
      },
      'is_complete': {'type': 'boolean'},
      'missing_fields': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  };
}

abstract interface class OrderExtractionBackend {
  bool get isLocal;
  Future<Map<String, dynamic>> extract(String conversation);
}

/// Calls your server, which owns the model credentials and authorization.
/// Never put model provider API keys in a Flutter build.
class HttpOrderExtractionBackend implements OrderExtractionBackend {
  HttpOrderExtractionBackend(this.endpoint, this.client) {
    if (endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty) {
      throw ArgumentError('Parser endpoint must be HTTPS.');
    }
  }
  final Uri endpoint;
  final http.Client client;
  @override
  bool get isLocal => false;
  @override
  Future<Map<String, dynamic>> extract(String conversation) async {
    final response = await client
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'conversation': conversation,
            'schema': ParsedOrderDto.jsonSchema,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FormatException('Order extraction failed. Please retry.');
    }
    if (response.bodyBytes.length > 1024 * 1024) {
      throw const FormatException('Parser response is too large.');
    }
    final value = jsonDecode(utf8.decode(response.bodyBytes));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Parser response must be an object.');
    }
    return value;
  }
}

/// Conservative offline fallback: labelled fields and common order phrases.
/// It does not invent addresses, prices, recipients or missing item details.
class LocalOrderExtractionBackend implements OrderExtractionBackend {
  @override
  bool get isLocal => true;
  @override
  Future<Map<String, dynamic>> extract(String conversation) async {
    if (conversation.trimLeft().startsWith('{')) {
      final json = jsonDecode(conversation);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Paste an order object or conversation.');
      }
      return json;
    }
    String field(String labels) =>
        RegExp(
          '^(?:$labels)\\s*[:=]\\s*(.+)\$',
          caseSensitive: false,
          multiLine: true,
        ).firstMatch(conversation)?.group(1)?.trim() ??
        '';
    final phone = field('phone|mobile|contact').isNotEmpty
        ? field('phone|mobile|contact')
        : RegExp(r'(?<!\d)(?:\+91[ ]*|0)?[6-9](?:[ ]*\d){9}(?!\d)')
                  .firstMatch(conversation)
                  ?.group(0) ??
              '';
    final pin = field('pin(?:code)?|postal code').isNotEmpty
        ? field('pin(?:code)?|postal code')
        : RegExp(r'\b[1-9][0-9]{5}\b').firstMatch(conversation)?.group(0) ?? '';
    final items = <Map<String, dynamic>>[];
    for (final match in RegExp(
      r'^item\s*:\s*(.+)$',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(conversation)) {
      final parts = match.group(1)!.split('|').map((v) => v.trim()).toList();
      final qty = parts.length > 2 ? int.tryParse(parts[2]) : 1;
      if (parts.first.isNotEmpty && qty != null && qty > 0) {
        items.add({
          'name': parts.first,
          'variant': parts.length > 1 ? parts[1] : '',
          'quantity': qty,
        });
      }
    }
    if (items.isEmpty) {
      final match = RegExp(
        r'(?:order|send|buy|want|need)\s+(\d+)\s+([^.!\n]+)',
        caseSensitive: false,
      ).firstMatch(conversation);
      if (match != null && int.parse(match.group(1)!) > 0) {
        final phrase = match.group(2)!.trim();
        final variant = RegExp(
          r'(?:in\s+)?size\s+([\w-]+)',
          caseSensitive: false,
        ).firstMatch(phrase);
        final name = phrase
            .replaceFirst(
              RegExp(r'[, ]*(?:in\s+)?size\s+[\w-]+.*$', caseSensitive: false),
              '',
            )
            .trim();
        if (name.isNotEmpty) {
          items.add({
            'name': name,
            'variant': variant == null ? '' : 'Size ${variant.group(1)}',
            'quantity': int.parse(match.group(1)!),
          });
        }
      }
    }
    return {
      'recipient_name': field('recipient(?:_name)?|name|deliver to'),
      'phone': phone,
      'street_address': field('street_address|street address|address'),
      'landmark': field('landmark'),
      'city': field('city'),
      'state': field('state'),
      'pincode': pin,
      'items': items,
      'raw_amount': field('total|amount|raw_amount').isEmpty
          ? null
          : field('total|amount|raw_amount'),
      'is_complete': false,
      'missing_fields': <String>[],
    };
  }
}

final parserHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
final orderExtractionBackendProvider = Provider<OrderExtractionBackend>((ref) {
  const endpoint = String.fromEnvironment('AI_ORDER_PARSER_URL');
  return endpoint.isEmpty
      ? LocalOrderExtractionBackend()
      : HttpOrderExtractionBackend(
          Uri.parse(endpoint),
          ref.watch(parserHttpClientProvider),
        );
});
final aiOrderParserServiceProvider = Provider<AiOrderParserService>(
  (ref) => AiOrderParserService(ref.watch(orderExtractionBackendProvider)),
);

class AiOrderParserService {
  AiOrderParserService(this.backend);
  final OrderExtractionBackend backend;
  Future<ParsedOrderDto> parse(String conversation) async {
    if (conversation.trim().isEmpty || conversation.length > 30000) {
      throw const FormatException(
        'Paste a conversation of up to 30,000 characters.',
      );
    }
    return ParsedOrderDto.fromJson(await backend.extract(conversation));
  }
}
