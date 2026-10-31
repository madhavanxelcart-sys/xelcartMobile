import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'app_svg_icon.dart';

/// Keeps each tab's navigator alive while switching destinations.
class MainBottomNavShell extends StatelessWidget {
  const MainBottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          _destination('Orders', AppAssets.package),
          _destination('Inventory', AppAssets.box),
          _destination('Settings', AppAssets.settings),
        ],
      ),
    ),
  );

  NavigationDestination _destination(
    String label,
    String assetPath,
  ) => NavigationDestination(
    label: label,
    icon: AppSvgIcon(
      assetPath: assetPath,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(AppColors.textMuted, BlendMode.srcIn),
    ),
    selectedIcon: AppSvgIcon(
      assetPath: assetPath,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    ),
  );
}
