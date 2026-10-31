import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/theme/app_colors.dart';
import 'package:xelcart_mobile/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:xelcart_mobile/features/onboarding/presentation/steps/step4_policies_review.dart';

void main() {
  test('Delivery requires a full address and valid six-digit PIN', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingProvider.notifier);
    notifier.goToStep(3);
    expect(notifier.continueToReview(), isFalse);
    for (final pin in ['', '12345', '1234567', '012345', '12345x']) {
      expect(OnboardingNotifier.validPostalCode(pin), isFalse);
    }
    notifier.update(
      (s) => s.copyWith(
        addressLine1: '12 Main Road',
        city: 'Pune',
        postalCode: '411001',
        state: 'Maharashtra',
      ),
    );
    expect(notifier.continueToReview(), isTrue);
    expect(container.read(onboardingProvider).currentStep, 4);
  });

  testWidgets(
    'Complete delivery, review edits, legal links, consent and create store',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
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
          onboardingLinkLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(onboardingProvider.notifier);
      notifier.update(
        (s) => s.copyWith(
          currentStep: 3,
          fullName: 'Priya Sharma',
          storeName: "Priya's Closet",
          legalBusinessName: 'Priya Retail',
          businessType: OnboardingNotifier.businessTypes.first,
          selectedCategories: {'Fashion'},
          state: 'Maharashtra',
        ),
      );
      final router = container.read(appRouterProvider);
      router.go('/onboarding');
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
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    textStyle: theme.textTheme.labelLarge,
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
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
      Future<void> tapVisible(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> preview(String name) async {
        if (font == null) return;
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('preview')));
          await precacheImage(
            AssetImage(
              name == 'onboarding_step3'
                  ? 'assets/images/onboarding_parcel.png'
                  : 'assets/images/onboarding_storefront.png',
            ),
            context,
          );
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('preview')),
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await preview('onboarding_step3');
      await tapVisible(find.text('Continue'));
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Enter a valid PIN'), findsOneWidget);
      for (final field in {
        'addressLine1': '12 Main Road',
        'addressLine2': 'Suite 4',
        'city': 'Pune',
        'postalCode': '41100',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key(field.key)));
        await tester.enterText(find.byKey(Key(field.key)), field.value);
      }
      await tapVisible(find.text('Continue'));
      expect(container.read(onboardingProvider).currentStep, 3);
      await tester.ensureVisible(find.byKey(const Key('postalCode')));
      await tester.enterText(find.byKey(const Key('postalCode')), '4110017');
      expect(container.read(onboardingProvider).postalCode, '411001');
      await tapVisible(find.byKey(const Key('useForPickupAndReturns')));
      expect(container.read(onboardingProvider).useForPickupAndReturns, isTrue);
      await tapVisible(find.text('Pickup & return addresses'));
      expect(
        find.textContaining('Using your business address'),
        findsOneWidget,
      );
      await tapVisible(find.text('Delivery & payment settings'));
      await tester.ensureVisible(find.byKey(const Key('deliveryTimeline')));
      await tester.enterText(
        find.byKey(const Key('deliveryTimeline')),
        '2 to 5 days',
      );
      await tapVisible(find.text('Cash on delivery'));
      expect(container.read(onboardingProvider).cashOnDelivery, isTrue);
      await tapVisible(find.text('Continue'));
      expect(find.text('STEP 4 OF 4'), findsOneWidget);
      expect(find.text("Priya's Closet"), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      await preview('onboarding_step4');
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('createStore')))
            .onPressed,
        isNull,
      );
      await tapVisible(find.byKey(const Key('editSellerProfile')));
      expect(find.text('Priya Sharma'), findsOneWidget);
      notifier.goToStep(4);
      await tester.pumpAndSettle();
      await tapVisible(find.byKey(const Key('editDeliveryDetails')));
      expect(find.text('12 Main Road'), findsOneWidget);
      expect(
        container.read(onboardingProvider).deliveryTimeline,
        '2 to 5 days',
      );
      await tapVisible(find.text('Continue'));
      await tapVisible(find.text('Support & complaints *'));
      await tester.enterText(
        find.byKey(const Key('supportContact')),
        'support@example.com',
      );
      await tapVisible(find.text('Read privacy notice'));
      await tapVisible(find.text('Terms of Service.'));
      expect(opened, [
        Uri.parse('https://xelcart.com/privacy'),
        Uri.parse('https://xelcart.com/terms'),
      ]);
      await tapVisible(find.byKey(const Key('agreeTerms')));
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('createStore')))
            .onPressed,
        isNull,
      );
      await tapVisible(find.byKey(const Key('confirmAgeAndAuth')));
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('createStore')))
            .onPressed,
        isNotNull,
      );
      expect(container.read(onboardingProvider).optInTips, isFalse);
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(find.byKey(const Key('createStore')));
      expect(router.routeInformationProvider.value.uri.path, '/orders');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        container.read(onboardingProvider).supportContact,
        'support@example.com',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
