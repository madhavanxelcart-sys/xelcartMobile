import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/features/onboarding/presentation/onboarding_notifier.dart';

void main() {
  test(
    'Draft defaults, step bounds, immutability and all-step data preservation',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingProvider.notifier);
      final initial = container.read(onboardingProvider);
      expect(initial.mobileVerified, isTrue);
      expect(initial.mobileNumber, '+91 98765 43210');
      expect(initial.country, 'India');
      expect(initial.currency, 'INR \u20B9');
      expect(notifier.continueToChannels(), isFalse);
      expect(() => notifier.goToStep(0), throwsRangeError);
      expect(() => notifier.goToStep(5), throwsRangeError);
      notifier.update(
        (s) => s.copyWith(
          fullName: 'Priya',
          storeName: 'Closet',
          legalBusinessName: 'Priya Retail',
          businessType: OnboardingNotifier.businessTypes.first,
          addressLine1: '12 Main Road',
          city: 'Pune',
          postalCode: '411001',
          state: 'Maharashtra',
          agreeTerms: true,
          confirmAgeAndAuth: true,
        ),
      );
      notifier.toggleCategory('Fashion');
      expect(notifier.continueToChannels(), isTrue);
      final snapshot = container.read(onboardingProvider);
      expect(
        () => snapshot.selectedCategories.add('Food'),
        throwsUnsupportedError,
      );
      notifier.toggleCategory('Food');
      expect(snapshot.selectedCategories, {'Fashion'});
      notifier.goToStep(4);
      final finalDraft = container.read(onboardingProvider);
      expect(finalDraft.addressLine1, '12 Main Road');
      expect(finalDraft.agreeTerms, isTrue);
      expect(finalDraft.selectedCategories, {'Fashion', 'Food'});
    },
  );

  testWidgets(
    'Profile validates; channels toggle; back and save preserve the draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 960);
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
      router.go('/onboarding');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const Key('preview'),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: font == null ? null : 'Preview'),
              routerConfig: router,
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
      });
      await tester.pumpAndSettle();
      Future<void> preview(String name) async {
        if (font == null) return;
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('preview')),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await preview('onboarding_step1');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsNWidgets(4));
      expect(find.text('Select at least one category.'), findsOneWidget);
      for (final field in {
        'fullName': 'Priya Sharma',
        'storeName': "Priya's Closet",
        'legalBusinessName': 'Priya Retail',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key(field.key)));
        await tester.enterText(find.byKey(Key(field.key)), field.value);
      }
      await tester.ensureVisible(find.byKey(const Key('businessType')));
      await tester.tap(find.byKey(const Key('businessType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OnboardingNotifier.businessTypes.first).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fashion'));
      await tester.tap(find.text('Fashion'));
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 2 OF 4'), findsOneWidget);
      await preview('onboarding_step2');
      await tester.tap(find.text('Connect').first);
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
      expect(container.read(onboardingProvider).whatsappConnected, isTrue);
      await tester.ensureVisible(find.byKey(const Key('website')));
      await tester.enterText(find.byKey(const Key('website')), 'invalid');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid website URL, including https://.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('website')),
        'https://priya.example',
      );
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Ship your\nfirst win.'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('https://priya.example'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Priya Sharma'), findsOneWidget);
      await tester.tap(find.text('Save & exit'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(container.read(onboardingProvider).storeName, "Priya's Closet");
      router.go('/onboarding');
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
