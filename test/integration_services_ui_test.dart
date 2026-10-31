import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/router/route_names.dart';
import 'package:xelcart_mobile/core/services/ble_printer_service.dart';
import 'package:xelcart_mobile/core/services/integration_settings_service.dart';
import 'package:xelcart_mobile/core/theme/app_colors.dart';
import 'package:xelcart_mobile/features/orders/data/orders_repository.dart';
import 'package:xelcart_mobile/features/inventory/presentation/product_draft_notifier.dart';

import 'backend_services_test.dart'
    show RecordingTransport, FastLabelGenerator, conversation;

void main() {
  testWidgets(
    'DM review, missing-field guard, order creation, simulated printing, settings and sign out',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = Platform.environment['XELCART_PREVIEW_FONT'];
      if (font != null) {
        await tester.runAsync(() async {
          final loader = FontLoader('Preview')
            ..addFont(
              Future.value(
                ByteData.sublistView(await File(font).readAsBytes()),
              ),
            );
          await loader.load();
        });
      }
      final transport = RecordingTransport();
      final container = ProviderContainer(
        overrides: [
          blePrinterTransportProvider.overrideWithValue(transport),
          shippingLabelGeneratorProvider.overrideWithValue(
            FastLabelGenerator(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go(RouteNames.orders);
      final base = ThemeData(fontFamily: font == null ? null : 'Preview');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const Key('preview'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: base.copyWith(
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    textStyle: base.textTheme.labelLarge,
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        if (font == null) return;
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('preview')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tap(find.text('Add order'));
      expect(find.text('Import an order'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('rawOrderConversation')),
        conversation.replaceFirst('PIN: 560038\n', ''),
      );
      await tap(find.text('Parse conversation'));
      expect(
        find.textContaining('Missing or invalid: pincode'),
        findsOneWidget,
      );
      await tap(find.text('Save order'));
      expect(container.read(ordersRepositoryProvider).length, 3);
      await tester.ensureVisible(find.byKey(const Key('parsed-pincode')));
      await tester.enterText(find.byKey(const Key('parsed-pincode')), '560038');
      await tester.pumpAndSettle();
      await capture('parsed_order_review');
      await tap(find.text('Save order'));
      expect(container.read(ordersRepositoryProvider).length, 4);
      final added = container.read(ordersRepositoryProvider).first;
      expect(added.customerPhone, '+91 9876543210');
      expect(added.totalAmount, 1499);
      expect(added.items.single.quantity, 2);
      expect(added.deliveryAddress!.pincode, '560038');
      expect(added.customerMessage, contains('Item: Blue cotton shirt'));
      router.goNamed(
        RouteNames.orderDetails,
        pathParameters: {'id': '#ORD-0128'},
      );
      await tester.pumpAndSettle();
      await tap(find.byKey(const Key('printOrderLabel')));
      await tap(find.text('Scan for printers'));
      await tap(find.text('Pair & print'));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'Simulation complete — no physical label printed.',
          ),
        ),
        findsOneWidget,
      );
      expect(transport.chunks, isNotEmpty);
      await tap(find.text('Close'));
      router.go(RouteNames.settings);
      await tester.pumpAndSettle();
      expect(find.text("Priya's Closet"), findsOneWidget);
      expect(find.textContaining('Simulated BLE transport'), findsOneWidget);
      await capture('settings_hardware');
      await tap(find.byKey(const Key('testPrintLabel')));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'Simulation complete — no physical label printed.',
          ),
        ),
        findsOneWidget,
      );
      await tap(find.text('Close'));
      final razorpay = find.ancestor(
        of: find.text('Razorpay UPI links'),
        matching: find.byType(ListTile),
      );
      await tap(
        find.descendant(of: razorpay, matching: find.text('Configure')),
      );
      await tester.enterText(
        find.byKey(const Key('integrationEndpoint')),
        'http://backend.example/payment',
      );
      await tap(find.text('Save configuration'));
      expect(find.text('Enter a valid HTTPS backend URL.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('integrationEndpoint')),
        'https://backend.example/payment',
      );
      await tap(find.text('Save configuration'));
      expect(
        container.read(integrationSettingsProvider).containsKey('razorpay'),
        isTrue,
      );
      expect(find.textContaining('Configured · not verified'), findsOneWidget);
      container
          .read(productDraftProvider('new').notifier)
          .update((d) => d.copyWith(name: 'Private draft'));
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(find.byKey(const Key('signOut')));
      expect(router.state.uri.path, '/login');
      expect(find.text("Let's get you in"), findsOneWidget);
      expect(container.read(ordersRepositoryProvider).length, 3);
      expect(container.read(integrationSettingsProvider), isEmpty);
      expect(container.read(blePrinterServiceProvider).connected, isFalse);
      expect(container.read(productDraftProvider('new')).name, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
