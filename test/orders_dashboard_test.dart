import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/theme/app_colors.dart';
import 'package:xelcart_mobile/features/orders/data/orders_repository.dart';
import 'package:xelcart_mobile/features/orders/domain/order_model.dart';

void main() {
  testWidgets(
    'Dashboard search, channel/status filters, reactive updates and encoded details route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1050);
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
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go('/orders');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const Key('preview'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: font == null ? null : 'Preview')
                  .copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('128'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Asha Sharma'), findsOneWidget);
      expect(find.text('Riya Patel'), findsOneWidget);
      expect(container.read(ordersRepositoryProvider).length, 3);
      if (font != null) {
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('preview')));
          for (final asset in [
            'xelcart_logo',
            'onboarding_parcel',
            'blue_cotton_shirt',
            'canvas_tote_bag',
            'ceramic_dinner_set',
          ]) {
            if (!context.mounted) return;
            await precacheImage(
              AssetImage('assets/images/$asset.png'),
              context,
            );
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('preview')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/orders_dashboard_preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('orderSearch')), 'riya');
      await tester.pumpAndSettle();
      expect(find.text('Asha Sharma'), findsNothing);
      expect(find.text('Riya Patel'), findsOneWidget);
      await tap(find.byTooltip('Clear search'));
      await tap(find.widgetWithText(RawChip, 'WhatsApp'));
      expect(find.text('Asha Sharma'), findsOneWidget);
      expect(find.text('Riya Patel'), findsNothing);
      await tap(find.byKey(const Key('summaryChannels')));
      await tap(find.text('Instagram').last);
      expect(find.text('Riya Patel'), findsOneWidget);
      expect(find.text('Asha Sharma'), findsNothing);
      await tap(find.widgetWithText(RawChip, 'All'));
      await tap(find.byKey(const Key('statusFilter')));
      await tap(find.text('Pending').last);
      expect(find.text('Asha Sharma'), findsOneWidget);
      container
          .read(ordersRepositoryProvider.notifier)
          .updateOrderStatus('#ORD-0128', OrderStatus.confirmed);
      await tester.pumpAndSettle();
      expect(find.text('No orders found'), findsOneWidget);
      await tap(find.text('Clear filters'));
      await tap(find.byTooltip('Filter orders'));
      expect(find.text('Apply filters'), findsOneWidget);
      await tap(find.text('Reset filters'));
      await tap(find.byKey(const ValueKey('order-#ORD-0128')));
      expect(router.state.uri.path, '/orders/%23ORD-0128');
      expect(router.state.pathParameters['id'], '#ORD-0128');
      expect(router.state.uri.fragment, isEmpty);
      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('#ORD-0128'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(find.text('Add order'));
      await tap(find.text('Enter manually'));
      await tap(find.text('Create order'));
      expect(find.text('Enter a customer name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('newOrderCustomer')),
        'Nina Rao',
      );
      await tester.enterText(find.byKey(const Key('newOrderQuantity')), '2');
      await tap(find.text('Create order'));
      expect(
        container.read(ordersRepositoryProvider).first.customerName,
        'Nina Rao',
      );
      expect(container.read(ordersRepositoryProvider).first.totalAmount, 1499);
      expect(find.text('129'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
