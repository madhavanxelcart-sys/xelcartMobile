import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/domain/order_model.dart';

enum PrinterProtocol { tspl, escPos }

enum BlePrinterPhase { idle, scanning, pairing, ready, printing, failed }

class BlePrinterDevice {
  const BlePrinterDevice({
    required this.id,
    required this.name,
    this.dpi = 203,
    this.maxWidthDots = 832,
    this.protocols = const [PrinterProtocol.tspl],
  });
  final String id, name;
  final int dpi, maxWidthDots;
  final List<PrinterProtocol> protocols;
}

abstract interface class BlePrinterTransport {
  bool get isSimulated;
  int get maxWriteBytes;
  Future<List<BlePrinterDevice>> scan();
  Future<void> connect(BlePrinterDevice device);
  Future<void> write(Uint8List bytes);
  Future<void> disconnect();
}

class SimulatedBlePrinterTransport implements BlePrinterTransport {
  bool _connected = false;
  int _generation = 0;
  @override
  bool get isSimulated => true;
  @override
  int get maxWriteBytes => 512;
  @override
  Future<List<BlePrinterDevice>> scan() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      BlePrinterDevice(
        id: 'demo-4x6',
        name: 'Xelcart 4-inch BLE (Demo)',
        protocols: [PrinterProtocol.tspl, PrinterProtocol.escPos],
      ),
    ];
  }

  @override
  Future<void> connect(BlePrinterDevice device) async {
    final generation = ++_generation;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (generation != _generation) throw StateError('Pairing cancelled');
    _connected = true;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    if (!_connected) throw StateError('Printer is disconnected.');
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _connected = false;
  }
}

class GeneratedShippingLabel {
  GeneratedShippingLabel(Uint8List raster, Uint8List png)
    : darkBits = Uint8List.fromList(raster).asUnmodifiableView(),
      previewPng = Uint8List.fromList(png).asUnmodifiableView() {
    if (raster.length != bytesPerRow * heightDots) {
      throw ArgumentError('Invalid 4x6 raster dimensions.');
    }
  }
  static const widthDots = 812, heightDots = 1218, bytesPerRow = 102;

  /// MSB first, one means a dark dot. The four padding bits per row are white.
  final Uint8List darkBits;
  final Uint8List previewPng;
  Uint8List encode(PrinterProtocol protocol) {
    final builder = BytesBuilder(copy: false);
    if (protocol == PrinterProtocol.tspl) {
      builder.add(
        ascii.encode(
          'SIZE 101.6 mm,152.4 mm\r\nGAP 2 mm,0 mm\r\nDIRECTION 1\r\nCLS\r\nBITMAP 0,0,102,1218,0,',
        ),
      );
      // TSC TSPL BITMAP uses zero for a printed dot; ESC/POS uses one.
      builder.add(Uint8List.fromList(darkBits.map((v) => v ^ 0xff).toList()));
      builder.add(ascii.encode('\r\nPRINT 1,1\r\n'));
    } else {
      builder.add([0x1b, 0x40, 0x1b, 0x61, 0]);
      builder.add([
        0x1d,
        0x76,
        0x30,
        0,
        bytesPerRow & 255,
        bytesPerRow >> 8,
        heightDots & 255,
        heightDots >> 8,
      ]);
      builder.add(darkBits);
      // No automatic cutter command: label printers have differing hardware.
      builder.add([0x0a]);
    }
    return builder.takeBytes();
  }
}

class ShippingLabelGenerator {
  ShippingLabelGenerator({this.fontFamily});
  final String? fontFamily;
  Future<GeneratedShippingLabel> generate({
    required String awb,
    required String recipientName,
    required String phone,
    required String address,
    String orderId = '',
  }) async {
    if (!RegExp(r'^[A-Za-z0-9-]{1,24}$').hasMatch(awb)) {
      throw ArgumentError(
        'A valid shipment AWB (up to 24 letters/digits) is required.',
      );
    }
    if (address.trim().isEmpty ||
        recipientName.trim().isEmpty ||
        address.length > 1000) {
      throw ArgumentError('A recipient and delivery address are required.');
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final black = ui.Paint()..color = const ui.Color(0xff000000);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 812, 1218),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    double text(
      String value,
      double x,
      double y,
      double size, {
      bool bold = false,
      double width = 732,
    }) {
      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontFamily: fontFamily,
                fontSize: size,
                fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
              ),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xff000000)))
            ..addText(value);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: width));
      canvas.drawParagraph(paragraph, ui.Offset(x, y));
      return paragraph.height;
    }

    text('XELCART  /  SHIPPING LABEL', 40, 35, 29, bold: true);
    canvas.drawRect(const ui.Rect.fromLTWH(40, 90, 732, 3), black);
    text('DELIVER TO', 40, 118, 25, bold: true);
    var y = 160.0;
    y += text(recipientName, 40, y, 34, bold: true) + 12;
    if (phone.isNotEmpty) y += text(phone, 40, y, 28) + 12;
    // Keep long addresses on-label rather than silently clipping any lines.
    ui.Paragraph addressParagraph(double fontSize) =>
        (ui.ParagraphBuilder(
                ui.ParagraphStyle(fontSize: fontSize, fontFamily: fontFamily),
              )
              ..pushStyle(ui.TextStyle(color: const ui.Color(0xff000000)))
              ..addText(address))
            .build()
          ..layout(const ui.ParagraphConstraints(width: 732));
    var paragraph = addressParagraph(30);
    if (y + paragraph.height > 820) paragraph = addressParagraph(22);
    if (y + paragraph.height > 820) {
      recorder.endRecording().dispose();
      throw ArgumentError('The address is too long for a readable 4x6 label.');
    }
    canvas.drawParagraph(paragraph, ui.Offset(40, y));
    text('AWB: $awb', 40, 850, 30, bold: true);
    // Crisp, integer-aligned Code 128 with quiet zones inside the label margin.
    for (final element in Barcode.code128().make(
      awb,
      width: 700,
      height: 140,
      drawText: false,
    )) {
      if (element is BarcodeBar && element.black) {
        final left = (56 + element.left).roundToDouble();
        final right = (56 + element.left + element.width).roundToDouble();
        canvas.drawRect(ui.Rect.fromLTRB(left, 910, right, 1050), black);
      }
    }
    text(awb, 40, 1070, 27);
    text(
      orderId.isEmpty
          ? '4 x 6 in  /  203 DPI'
          : '$orderId  /  4 x 6 in  /  203 DPI',
      40,
      1150,
      21,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(812, 1218);
    picture.dispose();
    try {
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final bits = Uint8List(
        GeneratedShippingLabel.bytesPerRow * GeneratedShippingLabel.heightDots,
      );
      for (var row = 0; row < 1218; row++) {
        for (var col = 0; col < 812; col++) {
          final offset = (row * 812 + col) * 4;
          if ((rgba[offset] * 299 +
                  rgba[offset + 1] * 587 +
                  rgba[offset + 2] * 114) <
              128000) {
            bits[row * 102 + (col >> 3)] |= 0x80 >> (col & 7);
          }
        }
      }
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      return GeneratedShippingLabel(bits, png);
    } finally {
      image.dispose();
    }
  }
}

class BlePrinterState {
  BlePrinterState({
    this.phase = BlePrinterPhase.idle,
    List<BlePrinterDevice> devices = const [],
    this.device,
    this.progress = 0,
    this.message = '',
    this.lastLabel,
    this.protocol = PrinterProtocol.tspl,
  }) : devices = List.unmodifiable(devices);
  final BlePrinterPhase phase;
  final List<BlePrinterDevice> devices;
  final BlePrinterDevice? device;
  final double progress;
  final String message;
  final GeneratedShippingLabel? lastLabel;
  final PrinterProtocol protocol;
  bool get busy => [
    BlePrinterPhase.scanning,
    BlePrinterPhase.pairing,
    BlePrinterPhase.printing,
  ].contains(phase);
  bool get connected =>
      device != null &&
      [BlePrinterPhase.ready, BlePrinterPhase.printing].contains(phase);
}

final blePrinterTransportProvider = Provider<BlePrinterTransport>(
  (ref) => SimulatedBlePrinterTransport(),
);
final shippingLabelGeneratorProvider = Provider<ShippingLabelGenerator>(
  (ref) => ShippingLabelGenerator(),
);
final blePrinterServiceProvider =
    NotifierProvider<BlePrinterService, BlePrinterState>(BlePrinterService.new);

class BlePrinterService extends Notifier<BlePrinterState> {
  int _epoch = 0;
  late BlePrinterTransport _transport;
  @override
  BlePrinterState build() {
    _transport = ref.watch(blePrinterTransportProvider);
    ref.onDispose(() {
      _epoch++;
      unawaited(_transport.disconnect().catchError((Object _) {}));
    });
    return BlePrinterState();
  }

  bool _current(int epoch) => ref.mounted && epoch == _epoch;
  Future<bool> scan() async {
    if (state.busy || state.connected) return false;
    final epoch = ++_epoch;
    state = BlePrinterState(
      phase: BlePrinterPhase.scanning,
      message: 'Scanning for 4-inch BLE printers…',
      protocol: state.protocol,
    );
    try {
      final devices = await _transport.scan();
      if (!_current(epoch)) return false;
      final compatible = devices
          .where((d) => d.dpi == 203 && d.maxWidthDots >= 816)
          .toList();
      state = BlePrinterState(
        devices: compatible,
        message: compatible.isEmpty
            ? 'No compatible printer found.'
            : 'Choose a printer to pair.',
        protocol: state.protocol,
      );
      return true;
    } catch (_) {
      if (_current(epoch)) {
        state = BlePrinterState(
          phase: BlePrinterPhase.failed,
          message: 'Unable to scan. Try again.',
        );
      }
      return false;
    }
  }

  Future<bool> pair(BlePrinterDevice device) async {
    if (state.busy ||
        !state.devices.any((d) => d.id == device.id) ||
        !device.protocols.contains(state.protocol)) {
      return false;
    }
    final epoch = ++_epoch;
    state = BlePrinterState(
      phase: BlePrinterPhase.pairing,
      devices: state.devices,
      message: 'Pairing with ${device.name}…',
      protocol: state.protocol,
    );
    try {
      await _transport.connect(device);
      if (!_current(epoch)) return false;
      state = BlePrinterState(
        phase: BlePrinterPhase.ready,
        devices: state.devices,
        device: device,
        message: _transport.isSimulated
            ? 'Simulated printer connected'
            : 'Printer connected',
        protocol: state.protocol,
      );
      return true;
    } catch (_) {
      if (_current(epoch)) {
        state = BlePrinterState(
          phase: BlePrinterPhase.failed,
          message: 'Pairing failed. Try again.',
        );
      }
      return false;
    }
  }

  void setProtocol(PrinterProtocol value) {
    if (state.busy ||
        state.device != null && !state.device!.protocols.contains(value)) {
      return;
    }
    state = BlePrinterState(
      phase: state.phase,
      devices: state.devices,
      device: state.device,
      protocol: value,
      message: state.message,
    );
  }

  Future<void> disconnect() async {
    _epoch++;
    state = BlePrinterState(
      protocol: state.protocol,
      message: 'Printer disconnected',
    );
    await _transport.disconnect().catchError((Object _) {});
  }

  Future<bool> printOrder(OrderModel order) {
    final awb = order.shipment?.trackingNumber ?? '';
    final address =
        order.shipment?.recipientAddress ??
        order.deliveryAddress?.formatted ??
        '';
    return _print(
      awb: awb,
      recipient: order.customerName,
      phone: order.customerPhone,
      address: address,
      orderId: order.id,
    );
  }

  Future<bool> printTestLabel() => _print(
    awb: 'TEST0000001',
    recipient: 'Xelcart test label',
    phone: '+91 98765 43210',
    address: '42, 2nd Cross, Indiranagar\nBengaluru, Karnataka 560038',
    orderId: 'TEST',
  );
  Future<bool> _print({
    required String awb,
    required String recipient,
    required String phone,
    required String address,
    required String orderId,
  }) async {
    if (!state.connected || state.busy) return false;
    final device = state.device!;
    final protocol = state.protocol;
    final epoch = ++_epoch;
    state = BlePrinterState(
      phase: BlePrinterPhase.printing,
      device: device,
      protocol: protocol,
      message: 'Generating 203 DPI monochrome label…',
    );
    try {
      if (_transport.maxWriteBytes <= 0) {
        throw StateError('Invalid BLE write limit');
      }
      final label = await ref
          .read(shippingLabelGeneratorProvider)
          .generate(
            awb: awb,
            recipientName: recipient,
            phone: phone,
            address: address,
            orderId: orderId,
          );
      if (!_current(epoch)) return false;
      final bytes = label.encode(protocol);
      for (
        var offset = 0;
        offset < bytes.length;
        offset += _transport.maxWriteBytes
      ) {
        if (!_current(epoch)) return false;
        final end = (offset + _transport.maxWriteBytes).clamp(0, bytes.length);
        await _transport.write(Uint8List.sublistView(bytes, offset, end));
        if (!_current(epoch)) return false;
        state = BlePrinterState(
          phase: BlePrinterPhase.printing,
          device: device,
          protocol: protocol,
          progress: end / bytes.length,
          message: 'Sending label: ${(end * 100 / bytes.length).round()}%',
          lastLabel: label,
        );
      }
      state = BlePrinterState(
        phase: BlePrinterPhase.ready,
        device: device,
        protocol: protocol,
        progress: 1,
        message: _transport.isSimulated
            ? 'Simulation complete — no physical label printed.'
            : 'Label sent. Confirm output on the printer.',
        lastLabel: label,
      );
      return true;
    } catch (_) {
      if (_current(epoch)) {
        await _transport.disconnect().catchError((Object _) {});
        if (_current(epoch)) {
          state = BlePrinterState(
            phase: BlePrinterPhase.failed,
            protocol: protocol,
            message:
                'Print failed. Check the label and reconnect before retrying.',
          );
        }
      }
      return false;
    }
  }
}
