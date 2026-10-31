import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:xelcart_mobile/core/router/app_router.dart';
import 'package:xelcart_mobile/core/router/route_names.dart';

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
    router = container.read(appRouterProvider);
  });

  tearDown(() => container.dispose());

  Future<void> mountRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Auth routes open outside the bottom navigation shell', (
    tester,
  ) async {
    await mountRouter(tester);
    expect(find.text("Let's get you in"), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    router.goNamed(RouteNames.otp);
    await tester.pumpAndSettle();
    expect(find.text('OTP'), findsOneWidget);

    router.goNamed(RouteNames.onboarding);
    await tester.pumpAndSettle();
    expect(find.text('Build\nyour brand.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    'Order detail pages hide tabs; inventory branch preserves its stack',
    (tester) async {
      await mountRouter(tester);
      router.goNamed(
        RouteNames.deliveryDetails,
        pathParameters: {'id': '#ORD-0128'},
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivery details'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      router.pushNamed(
        RouteNames.manageStock,
        pathParameters: {'id': 'shirt-blue'},
      );
      await tester.pumpAndSettle();
      expect(find.text('Manage stock'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Your inventory.'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.inventory,
      );
    },
  );
  testWidgets('Inventory children resolve IDs and return to inventory', (
    tester,
  ) async {
    await mountRouter(tester);
    router.goNamed(RouteNames.addProduct);
    await tester.pumpAndSettle();
    expect(find.text('Add product'), findsNWidgets(2));
    router.pop();
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.inventory,
    );

    router.goNamed(
      RouteNames.manageStock,
      pathParameters: {'id': 'shirt-blue'},
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage stock'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
