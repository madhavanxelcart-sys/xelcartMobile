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
import 'package:xelcart_mobile/features/delivery/presentation/delivery_details_screen.dart';

void main() {
  test('Courier URL uses the supported official tracking site', () {
    expect(
      courierTrackingUrl(' Delhivery '),
      Uri.parse('https://www.delhivery.com/tracking'),
    );
    expect(courierTrackingUrl('Unknown courier'), isNull);
  });

  testWidgets(
    'Delivery renders shipment, copies AWB, tracks externally and handles empty data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1050);
      final semantics = tester.ensureSemantics();
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
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return call.method == 'Clipboard.getData' ? {'text': copied} : null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final opened = <Uri>[];
      var launchSucceeds = true;
      final container = ProviderContainer(
        overrides: [
          deliveryLinkLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return launchSucceeds;
          }),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.goNamed(
        RouteNames.deliveryDetails,
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
      expect(find.text('Delivery details'), findsOneWidget);
      expect(find.text('#ORD-0128'), findsOneWidget);
      expect(find.text('IN TRANSIT'), findsOneWidget);
      expect(find.text('14 Oct 2026'), findsOneWidget);
      expect(find.text('Updated 11 Oct, 2:30 PM'), findsOneWidget);
      expect(find.text('Asha Sharma'), findsOneWidget);
      expect(
        find.text('42, 2nd Cross, Indiranagar\nBengaluru, Karnataka 560038'),
        findsOneWidget,
      );
      expect(find.text('Delhivery'), findsOneWidget);
      expect(find.text('DLV1234567890'), findsOneWidget);
      expect(find.text('Bengaluru hub \u00B7 11 Oct, 2:30 PM'), findsOneWidget);
      expect(find.text('Picked up'), findsOneWidget);
      expect(find.text('Shipment created'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('Current tracking event')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Completed tracking event')),
        findsNWidgets(2),
      );
      if (font != null) {
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('preview')));
          await precacheImage(
            const AssetImage('assets/images/delivery_truck.png'),
            context,
          );
          if (!context.mounted) return;
          await precacheImage(
            const AssetImage('assets/images/xelcart_logo.png'),
            context,
          );
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('preview')),
              )
              .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/delivery_details_preview.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.byKey(const Key('copyTrackingNumber')));
      expect(copied, 'DLV1234567890');
      expect(find.text('Tracking number copied'), findsOneWidget);
      await tap(find.byKey(const Key('trackCourier')));
      expect(opened.single, Uri.parse('https://www.delhivery.com/tracking'));
      launchSucceeds = false;
      await tap(find.byKey(const Key('trackCourier')));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to open courier website. Please try again.'),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 2000),
      );
      await tester.pumpAndSettle();
      await tap(find.byTooltip('Back'));
      expect(find.text('Order details'), findsOneWidget);
      router.goNamed(
        RouteNames.deliveryDetails,
        pathParameters: {'id': '#ORD-0127'},
      );
      await tester.pumpAndSettle();
      expect(find.text('No shipment details available yet.'), findsOneWidget);
      expect(find.byKey(const Key('trackCourier')), findsNothing);
      router.goNamed(
        RouteNames.deliveryDetails,
        pathParameters: {'id': 'missing'},
      );
      await tester.pumpAndSettle();
      expect(find.text('Order not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
