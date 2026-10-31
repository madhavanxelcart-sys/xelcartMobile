import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/delivery/presentation/delivery_details_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/inventory/presentation/inventory_dashboard_screen.dart';
import '../../features/inventory/presentation/add_product_screen.dart';
import '../../features/inventory/presentation/manage_stock_screen.dart';
import '../../features/orders/presentation/orders_dashboard_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/onboarding/presentation/onboarding_wizard_screen.dart';

import '../widgets/main_bottom_nav_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        name: RouteNames.otp,
        builder: (context, state) => const _PlaceholderScreen(title: 'OTP'),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainBottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.orders,
                name: RouteNames.orders,
                builder: (context, state) => const OrdersDashboardScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    name: RouteNames.orderDetails,
                    builder: (context, state) => OrderDetailsScreen(
                      orderId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'delivery',
                        parentNavigatorKey: rootNavigatorKey,
                        name: RouteNames.deliveryDetails,
                        builder: (context, state) => DeliveryDetailsScreen(
                          orderId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.inventory,
                name: RouteNames.inventory,
                builder: (context, state) => const InventoryDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    name: RouteNames.addProduct,
                    builder: (context, state) => AddProductScreen(
                      productId: state.uri.queryParameters['edit'],
                    ),
                  ),
                  GoRoute(
                    path: ':id/stock',
                    parentNavigatorKey: rootNavigatorKey,
                    name: RouteNames.manageStock,
                    builder: (context, state) => ManageStockScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const _PlaceholderScreen(title: 'Page not found'),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Replace route builders with feature screens as they are implemented.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const SizedBox.expand(),
  );
}
