import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/theme/app_colors.dart';

void main() {
  testWidgets('Login validates phone and OTP, then navigates to onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final previewFont = Platform.environment['XELCART_PREVIEW_FONT'];
    if (previewFont != null) {
      await tester.runAsync(() async {
        final loader = FontLoader('Preview')
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(previewFont).readAsBytes()),
            ),
          );
        await loader.load();
      });
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: ThemeData(fontFamily: previewFont == null ? null : 'Preview')
                .copyWith(
                  scaffoldBackgroundColor: Colors.white,
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
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(const Key('preview')));
      await precacheImage(
        const AssetImage('assets/images/xelcart_logo.png'),
        context,
      );
      if (!context.mounted) return;
      await precacheImage(
        const AssetImage('assets/images/login_hero.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File('build/login_preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    await tester.ensureVisible(find.text('Send OTP'));
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
    expect(find.text('Verify your number'), findsNothing);

    await tester.enterText(find.byKey(const Key('mobileNumber')), '9876543210');
    await tester.ensureVisible(find.text('Send OTP'));
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your number'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Verify & continue'));
    await tester.tap(find.text('Verify & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('otpCode')), '000000');
    await tester.tap(find.text('Verify & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect code. Please try again.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');

    await tester.enterText(find.byKey(const Key('otpCode')), '123456');
    await tester.tap(find.text('Verify & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Build\nyour brand.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    expect(tester.takeException(), isNull);
  });
}
