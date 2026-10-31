import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/router/route_names.dart';
import 'package:xelcart_mobile/core/theme/app_colors.dart';
import 'package:xelcart_mobile/features/orders/data/orders_repository.dart';
import 'package:xelcart_mobile/features/orders/domain/order_model.dart';
import 'package:xelcart_mobile/features/orders/presentation/order_details_screen.dart';

void main() {
  testWidgets(
    'Details, staged status changes, delivery navigation and WhatsApp',
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
      final opened = <Uri>[];
      final container = ProviderContainer(
        overrides: [
          orderExternalLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.goNamed(
        RouteNames.orderDetails,
        pathParameters: {'id': '#ORD-0128'},
      );
      final theme = ThemeData(fontFamily: font == null ? null : 'Preview');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const Key('preview'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: theme.copyWith(
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
            200,
            scrollable: find.byType(Scrollable).last,
          );
        }
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> preview(String name) async {
        if (font == null) return;
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('preview')));
          for (final asset in [
            'xelcart_logo',
            'blue_cotton_shirt',
            'delivery_truck',
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
          await File('build/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('#ORD-0128'), findsOneWidget);
      expect(find.text('Received 9 Oct, 10:42 AM'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const Key('orderDeliveryCard')), findsNothing);
      expect(find.text('Size M \u00B7 Qty 2'), findsOneWidget);
      await preview('order_details_preview');
      await tap(find.byKey(const Key('orderCustomer')));
      expect(
        find.text('42, 2nd Cross, Indiranagar\nBengaluru, Karnataka 560038'),
        findsOneWidget,
      );
      await tap(find.text('Close'));
      await tap(find.text('Open WhatsApp chat'));
      expect(opened.single, Uri.parse('https://wa.me/919876543210'));
      await tap(find.text('Update status'));
      await tap(find.byKey(const ValueKey('status-confirmed')));
      expect(
        container.read(ordersRepositoryProvider).first.status,
        OrderStatus.pending,
      );
      await preview('update_status_preview');
      await tap(find.byTooltip('Close status update'));
      expect(
        container.read(ordersRepositoryProvider).first.status,
        OrderStatus.pending,
      );
      await tap(find.text('Update status'));
      await tap(find.byKey(const ValueKey('status-shipped')));
      await tap(find.text('Save status'));
      expect(
        container.read(ordersRepositoryProvider).first.status,
        OrderStatus.shipped,
      );
      await tester.ensureVisible(find.byKey(const Key('orderDeliveryCard')));
      await preview('order_shipped_preview');
      await tap(find.text('View delivery details'));
      expect(router.state.pathParameters['id'], '#ORD-0128');
      expect(router.state.uri.fragment, isEmpty);
      expect(find.text('Delivery details'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      await tap(find.text('Update status'));
      await tap(find.byKey(const ValueKey('status-cancelled')));
      await tap(find.text('Save status'));
      expect(
        container.read(ordersRepositoryProvider).first.status,
        OrderStatus.cancelled,
      );
      expect(find.byKey(const Key('orderDeliveryCard')), findsNothing);
      await tap(find.text('Update status'));
      await tap(find.byKey(const ValueKey('status-delivered')));
      await tap(find.text('Save status'));
      expect(find.byKey(const Key('orderDeliveryCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.goNamed(
        RouteNames.orderDetails,
        pathParameters: {'id': '#ORD-0127'},
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Open WhatsApp chat'));
      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text('Open WhatsApp chat'),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      router.goNamed(
        RouteNames.orderDetails,
        pathParameters: {'id': 'missing'},
      );
      await tester.pumpAndSettle();
      expect(find.text('Order not found'), findsOneWidget);
      await tap(find.text('Back to orders'));
      expect(find.text('Your orders.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
