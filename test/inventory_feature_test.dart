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
import 'package:xelcart_mobile/features/inventory/data/inventory_repository.dart';
import 'package:xelcart_mobile/features/inventory/presentation/product_draft_notifier.dart';

void main() {
  test('Variant stock adjustments preserve main SKU and reservations', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(inventoryRepositoryProvider.notifier);
    repo.addStock(
      'shirt-blue',
      quantity: 3,
      reason: 'Restock',
      variantSku: 'SHIRT-BLU-S',
    );
    final shirt = container.read(inventoryRepositoryProvider).first;
    expect(
      [shirt.onHand, shirt.reserved, shirt.available, shirt.totalAvailable],
      [12, 2, 10, 35],
    );
    expect(shirt.variants.first.available, 15);
    expect(shirt.history.single.variantSku, 'SHIRT-BLU-S');
    expect(
      () => repo.removeStock(
        'shirt-blue',
        quantity: 16,
        reason: 'Damaged',
        variantSku: 'SHIRT-BLU-S',
      ),
      throwsStateError,
    );
    expect(
      () => repo.addStock(
        'shirt-blue',
        quantity: 1,
        reason: 'Restock',
        variantSku: 'MISSING',
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.updateProduct(shirt.copyWith(onHand: 13)),
      throwsArgumentError,
    );
  });

  test(
    'Drafts cap photos, retain immutable data, and preserve variant identities',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(productDraftProvider('new').notifier);
      final bytes = File('assets/images/blue_cotton_shirt.png')
          .readAsBytesSync();
      notifier.addPhotos(List.filled(9, bytes));
      expect(container.read(productDraftProvider('new')).photos.length, 5);
      notifier.addVariant();
      notifier.addVariant();
      final thirdId = container
          .read(productDraftProvider('new'))
          .variants
          .last
          .id;
      notifier.removeVariant(1);
      expect(
        container.read(productDraftProvider('new')).variants.last.id,
        thirdId,
      );
      expect(
        () => container.read(productDraftProvider('new')).photos.clear(),
        throwsUnsupportedError,
      );
      expect(notifier.stockError, isNotNull);
    },
  );

  testWidgets(
    'Inventory filters, product drafts/photos/publishing and stock workflow',
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
      final photo = File('assets/images/blue_cotton_shirt.png')
          .readAsBytesSync();
      final container = ProviderContainer(
        overrides: [
          productPhotoPickerProvider.overrideWithValue(() async => [photo]),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go(RouteNames.inventory);
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
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
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
                    textStyle: base.textTheme.labelLarge,
                    minimumSize: const Size(0, 52),
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
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String key, String text) async {
        final finder = find.byKey(Key(key));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
        await tester.pumpAndSettle();
      }

      Future<void> preview(String name) async {
        if (font == null) return;
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('preview')));
          for (final asset in [
            'xelcart_logo',
            'inventory_boxes',
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
          await File('build/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      expect(find.text('Your inventory.'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await preview('inventory_dashboard_preview');
      await tap(find.widgetWithText(ChoiceChip, 'Low stock'));
      expect(find.text('Canvas tote bag'), findsOneWidget);
      expect(find.text('Blue cotton shirt'), findsNothing);
      await tap(find.widgetWithText(ChoiceChip, 'All'));
      await enter('inventorySearch', 'SHIRT-BLU-S');
      expect(find.text('Blue cotton shirt'), findsOneWidget);
      expect(find.text('Canvas tote bag'), findsNothing);
      await tap(find.byTooltip('Clear product search'));
      await tap(find.byTooltip('Filter inventory'));
      await tap(find.byType(DropdownButtonFormField<String>));
      await tap(find.text('Home').last);
      await tap(find.text('Apply filters'));
      expect(find.text('Ceramic dinner set'), findsOneWidget);
      expect(find.text('Blue cotton shirt'), findsNothing);
      await tap(find.byTooltip('Filter inventory'));
      await tap(find.text('Reset filters'));
      await tap(find.text('Add product'));
      expect(find.byType(NavigationBar), findsNothing);
      await preview('add_product_preview');
      await tap(find.byKey(const Key('publishProduct')));
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Add a SKU for each variant.'), findsOneWidget);
      await enter('productName', 'Linen shirt');
      await enter('sellingPrice', '599.00');
      await enter('costPrice', '300.00');
      await enter('variantSku-primary', 'LINEN-M');
      await enter('variantLabel-primary', 'Natural \u00B7 Size M');
      await enter('variantQuantity-primary', '8');
      await tap(find.text('Add variant'));
      await enter('variantSku-new-0', 'LINEN-L');
      await enter('variantLabel-new-0', 'Natural \u00B7 Size L');
      await enter('variantQuantity-new-0', '4');
      await tap(find.text('Shipping details'));
      await enter('productWeight', '0.25');
      await enter('productLength', '30');
      await enter('productWidth', '20');
      await enter('productHeight', '4');
      await tap(find.byKey(const Key('addProductPhoto')));
      expect(container.read(productDraftProvider('new')).photos.length, 2);
      await tap(find.byTooltip('Remove photo 1'));
      expect(
        container
            .read(productDraftProvider('new'))
            .photos
            .single
            .startsWith('data:image/'),
        isTrue,
      );
      await tap(find.text('Save draft'));
      expect(container.read(inventoryRepositoryProvider).length, 3);
      await tap(find.text('Add product'));
      expect(find.text('Linen shirt'), findsOneWidget);
      await tap(find.byKey(const Key('publishProduct')));
      expect(container.read(inventoryRepositoryProvider).length, 4);
      final linen = container.read(inventoryRepositoryProvider).last;
      expect([linen.onHand, linen.totalAvailable], [8, 12]);
      expect(linen.weightKg, 0.25);
      expect(linen.lengthCm, 30);
      expect(linen.imageUrls.single.startsWith('data:image/'), isTrue);
      expect(find.text('49'), findsOneWidget);
      router.pushNamed(
        RouteNames.manageStock,
        pathParameters: {'id': 'shirt-blue'},
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('currentOnHand'))).data,
        '12',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('currentReserved'))).data,
        '2',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('currentAvailable'))).data,
        '10',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('previewOnHand'))).data,
        '22',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('previewAvailable'))).data,
        '20',
      );
      await preview('manage_stock_preview');
      await tap(find.byTooltip('Increase quantity'));
      expect(
        tester.widget<Text>(find.byKey(const Key('previewOnHand'))).data,
        '23',
      );
      await tap(find.byTooltip('Decrease quantity'));
      await tap(find.text('Remove stock'));
      await enter('stockQuantity', '11');
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('saveStockAdjustment')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Only 10 available. Reserved stock cannot be removed.'),
        findsOneWidget,
      );
      await tap(find.text('Add stock'));
      await enter('stockQuantity', '10');
      await enter('stockThreshold', '7');
      await tap(find.text('Save adjustment'));
      var shirt = container.read(inventoryRepositoryProvider).first;
      expect(
        [shirt.onHand, shirt.reserved, shirt.available, shirt.totalAvailable],
        [22, 2, 20, 42],
      );
      expect(shirt.history.single.reason, 'Restock');
      expect(shirt.lowStockThreshold, 7);
      router.pushNamed(
        RouteNames.manageStock,
        pathParameters: {'id': 'shirt-blue'},
      );
      await tester.pumpAndSettle();
      await tap(find.byKey(const Key('stockVariant')));
      await tap(find.text('Blue \u00B7 Size S').last);
      expect(
        tester.widget<Text>(find.byKey(const Key('currentOnHand'))).data,
        '12',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('currentReserved'))).data,
        '0',
      );
      await enter('stockQuantity', '3');
      await tap(find.text('Save adjustment'));
      shirt = container.read(inventoryRepositoryProvider).first;
      expect(shirt.totalAvailable, 45);
      expect(shirt.onHand, 22);
      expect(shirt.history.first.variantSku, 'SHIRT-BLU-S');
      router.pushNamed(
        RouteNames.manageStock,
        pathParameters: {'id': 'shirt-blue'},
      );
      await tester.pumpAndSettle();
      await tap(find.text('Stock history'));
      expect(find.text('+10 \u00B7 Restock'), findsOneWidget);
      await tap(find.byTooltip('Edit product'));
      expect(find.text('Edit product'), findsOneWidget);
      await enter('productName', 'Blue cotton shirt updated');
      await tap(find.text('Save product'));
      expect(
        container.read(inventoryRepositoryProvider).first.name,
        'Blue cotton shirt updated',
      );
      expect(container.read(inventoryRepositoryProvider).first.onHand, 22);
      expect(
        container.read(inventoryRepositoryProvider).first.history.length,
        2,
      );
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.goNamed(RouteNames.manageStock, pathParameters: {'id': 'missing'});
      await tester.pumpAndSettle();
      expect(find.text('Product not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
