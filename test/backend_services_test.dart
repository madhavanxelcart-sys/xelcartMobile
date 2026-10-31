import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xelcart_mobile/core/services/ai_order_parser_service.dart';
import 'package:xelcart_mobile/core/services/ble_printer_service.dart';
import 'package:xelcart_mobile/features/orders/data/orders_repository.dart';

Map<String, dynamic> validOrder() => {
  'recipient_name': 'Asha Sharma',
  'phone': '+91 98765 43210',
  'street_address': '42, 2nd Cross, Indiranagar',
  'landmark': 'Near park',
  'city': 'Bengaluru',
  'state': 'Karnataka',
  'pincode': '560038',
  'items': [
    {'name': 'Blue cotton shirt', 'variant': 'Size M', 'quantity': 2},
  ],
  'raw_amount': '₹1,499',
  'is_complete': true,
  'missing_fields': <String>[],
};
const conversation =
    'Name: Asha Sharma\nPhone: +91 98765 43210\nAddress: 42, 2nd Cross, Indiranagar\nCity: Bengaluru\nState: Karnataka\nPIN: 560038\nItem: Blue cotton shirt | Size M | 2\nTotal: 1499';

class FastLabelGenerator extends ShippingLabelGenerator {
  @override
  Future<GeneratedShippingLabel> generate({
    required String awb,
    required String recipientName,
    required String phone,
    required String address,
    String orderId = '',
  }) async {
    if (awb.isEmpty || address.isEmpty) {
      throw ArgumentError('Missing AWB/address');
    }
    return GeneratedShippingLabel(Uint8List(102 * 1218), Uint8List(0));
  }
}

class RecordingTransport implements BlePrinterTransport {
  RecordingTransport({this.failAfter});
  final int? failAfter;
  final chunks = <Uint8List>[];
  bool connected = false;
  int disconnects = 0;
  @override
  bool get isSimulated => true;
  @override
  int get maxWriteBytes => 4096;
  @override
  Future<List<BlePrinterDevice>> scan() async => const [
    BlePrinterDevice(
      id: 'test',
      name: 'Test 4-inch BLE',
      protocols: [PrinterProtocol.tspl, PrinterProtocol.escPos],
    ),
  ];
  @override
  Future<void> connect(BlePrinterDevice device) async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    disconnects++;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    if (!connected || failAfter != null && chunks.length >= failAfter!) {
      throw StateError('Write failed');
    }
    chunks.add(Uint8List.fromList(bytes));
  }
}

class BlockingTransport extends RecordingTransport {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> write(Uint8List bytes) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await super.write(bytes);
  }
}

void main() {
  test(
    'Disconnect cancels an in-flight print without stale completion',
    () async {
      final transport = BlockingTransport();
      final container = ProviderContainer(
        overrides: [
          blePrinterTransportProvider.overrideWithValue(transport),
          shippingLabelGeneratorProvider.overrideWithValue(
            FastLabelGenerator(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(blePrinterServiceProvider.notifier);
      await service.scan();
      await service.pair(
        container.read(blePrinterServiceProvider).devices.single,
      );
      final job = service.printTestLabel();
      await transport.started.future;
      await service.disconnect();
      transport.release.complete();
      expect(await job, isFalse);
      expect(
        container.read(blePrinterServiceProvider).phase,
        BlePrinterPhase.idle,
      );
      expect(container.read(blePrinterServiceProvider).connected, isFalse);
      expect(transport.chunks, isEmpty);
    },
  );
  test(
    'Disconnect cancels simulated pairing before it can reconnect',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(blePrinterServiceProvider.notifier);
      await service.scan();
      final pairing = service.pair(
        container.read(blePrinterServiceProvider).devices.single,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await service.disconnect();
      expect(await pairing, isFalse);
      expect(container.read(blePrinterServiceProvider).connected, isFalse);
    },
  );
  test('Parser normalizes phones and rejects invalid Indian numbers without trusting AI flags', () {
    for (final number in ['+91 98765 43210', '09876543210', '9876543210']) {
      final dto = ParsedOrderDto.fromJson({...validOrder(), 'phone': number});
      expect(dto.phone, '9876543210');
      expect(dto.isComplete, isTrue);
    }
    for (final number in [
      '1234567890',
      '+1 9876543210',
      '009876543210',
      '987654321',
      '98765a3210',
      '98765432100',
    ]) {
      final dto = ParsedOrderDto.fromJson({...validOrder(), 'phone': number});
      expect(dto.isComplete, isFalse, reason: number);
      expect(dto.missingFields, contains('phone'));
    }
  });
  test('Missing and malformed mandatory fields force incomplete and round-trip the contract', () {
    final dto = ParsedOrderDto.fromJson({
      ...validOrder(),
      'phone': '',
      'pincode': '012345',
      'street_address': '  ',
      'is_complete': true,
    });
    expect(dto.isComplete, isFalse);
    expect(
      dto.missingFields,
      containsAll(['phone', 'pincode', 'street_address']),
    );
    expect(
      dto.toJson().keys,
      containsAll(ParsedOrderDto.jsonSchema['required'] as List),
    );
    expect(
      ParsedOrderDto.fromJson(validOrder()).toJson()['is_complete'],
      isTrue,
    );
    expect(
      () => ParsedOrderDto.fromJson({
        ...validOrder(),
        'items': [
          {'name': 'Shirt', 'variant': 'M', 'quantity': 0},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ParsedOrderDto.fromJson({...validOrder(), 'is_complete': 'true'}),
      throwsFormatException,
    );
    expect(
      () => ParsedOrderDto.fromJson({...validOrder(), 'pincode': 560038}),
      throwsFormatException,
    );
  });
  test('Local parser extracts labelled DM data and refuses to invent missing address details', () async {
    final service = AiOrderParserService(LocalOrderExtractionBackend());
    final parsed = await service.parse(conversation);
    expect(parsed.recipientName, 'Asha Sharma');
    expect(parsed.phone, '9876543210');
    expect(parsed.pincode, '560038');
    expect(parsed.items.single.quantity, 2);
    expect(parsed.isComplete, isTrue);
    final missing = await service.parse('Hi, send 2 blue shirts in size M.');
    expect(missing.items.single.quantity, 2);
    expect(missing.isComplete, isFalse);
    expect(missing.missingFields, contains('street_address'));
    expect(() => service.parse('  '), throwsFormatException);
  });
  test(
    'HTTPS adapter sends schema to backend and validates the returned object',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map;
        expect(body['conversation'], conversation);
        expect(body['schema']['additionalProperties'], isFalse);
        return http.Response(
          jsonEncode(validOrder()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final parsed = await AiOrderParserService(
        HttpOrderExtractionBackend(
          Uri.parse('https://backend.example/parse'),
          client,
        ),
      ).parse(conversation);
      expect(parsed.isComplete, isTrue);
      expect(
        () => HttpOrderExtractionBackend(
          Uri.parse('http://backend.example/parse'),
          client,
        ),
        throwsArgumentError,
      );
      final failed = MockClient(
        (_) async => http.Response('private server error', 500),
      );
      addTearDown(failed.close);
      expect(
        () => AiOrderParserService(
          HttpOrderExtractionBackend(
            Uri.parse('https://backend.example/parse'),
            failed,
          ),
        ).parse(conversation),
        throwsFormatException,
      );
    },
  );
  test(
    'TSPL and ESC/POS encode opposite 1-bit polarity and correct 4x6 geometry',
    () {
      final raster = Uint8List(102 * 1218)..[0] = 0x80;
      final label = GeneratedShippingLabel(raster, Uint8List(0));
      final tspl = label.encode(PrinterProtocol.tspl);
      final header = ascii.encode(
        'SIZE 101.6 mm,152.4 mm\r\nGAP 2 mm,0 mm\r\nDIRECTION 1\r\nCLS\r\nBITMAP 0,0,102,1218,0,',
      );
      expect(tspl.take(header.length), header);
      expect(tspl[header.length], 0x7f);
      expect(tspl[header.length + 1], 0xff);
      expect(ascii.decode(tspl.sublist(tspl.length - 13)), '\r\nPRINT 1,1\r\n');
      final esc = label.encode(PrinterProtocol.escPos);
      expect(esc.sublist(5, 13), [0x1d, 0x76, 0x30, 0, 102, 0, 194, 4]);
      expect(esc[13], 0x80);
      expect(esc[14], 0);
    },
  );
  testWidgets('203 DPI renderer produces a one-bit address and barcode label', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final font = Platform.environment['XELCART_PREVIEW_FONT'];
      if (font != null) {
        final loader = FontLoader('LabelPreview')
          ..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          );
        await loader.load();
      }
      final label =
          await ShippingLabelGenerator(
            fontFamily: font == null ? null : 'LabelPreview',
          ).generate(
            awb: 'DLV1234567890',
            recipientName: 'Asha Sharma',
            phone: '+91 98765 43210',
            address: '42, 2nd Cross, Indiranagar\nBengaluru, Karnataka 560038',
            orderId: '#ORD-0128',
          );
      expect(label.darkBits.length, 124236);
      expect(label.darkBits.any((v) => v != 0), isTrue);
      for (var row = 0; row < 1218; row++) {
        expect(label.darkBits[row * 102 + 101] & 0x0f, 0);
      }
      final barcodeRow = label.darkBits.sublist(950 * 102, 951 * 102);
      expect(barcodeRow.any((v) => v != 0), isTrue);
      await Directory('build').create(recursive: true);
      await File('build/shipping_label_4x6.png').writeAsBytes(label.previewPng);
    });
  });
  test('BLE service pairs, chunks, reports completion, and stops after write failure', () async {
    final transport = RecordingTransport();
    final container = ProviderContainer(
      overrides: [
        blePrinterTransportProvider.overrideWithValue(transport),
        shippingLabelGeneratorProvider.overrideWithValue(FastLabelGenerator()),
      ],
    );
    addTearDown(container.dispose);
    final service = container.read(blePrinterServiceProvider.notifier);
    expect(await service.scan(), isTrue);
    expect(
      await service.pair(
        container.read(blePrinterServiceProvider).devices.single,
      ),
      isTrue,
    );
    expect(await service.printTestLabel(), isTrue);
    expect(
      transport.chunks.every((c) => c.length <= transport.maxWriteBytes),
      isTrue,
    );
    expect(container.read(blePrinterServiceProvider).progress, 1);
    expect(
      container.read(blePrinterServiceProvider).message,
      contains('no physical'),
    );
    final bad = RecordingTransport(failAfter: 2);
    final failing = ProviderContainer(
      overrides: [
        blePrinterTransportProvider.overrideWithValue(bad),
        shippingLabelGeneratorProvider.overrideWithValue(FastLabelGenerator()),
      ],
    );
    addTearDown(failing.dispose);
    final failingService = failing.read(blePrinterServiceProvider.notifier);
    await failingService.scan();
    await failingService.pair(
      failing.read(blePrinterServiceProvider).devices.single,
    );
    expect(await failingService.printTestLabel(), isFalse);
    expect(
      failing.read(blePrinterServiceProvider).phase,
      BlePrinterPhase.failed,
    );
    expect(failing.read(blePrinterServiceProvider).connected, isFalse);
    expect(bad.chunks.length, 2);
    expect(
      await failingService.printOrder(
        failing.read(ordersRepositoryProvider).first,
      ),
      isFalse,
    );
  });
}
