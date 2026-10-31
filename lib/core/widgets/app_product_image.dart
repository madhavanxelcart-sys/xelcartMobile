import 'dart:convert';

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'app_svg_icon.dart';

/// Renders bundled, network, or session-picked (data URI) product photos.
class AppProductImage extends StatelessWidget {
  const AppProductImage({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(
          color: Color(0xFFF5F3FF),
          child: Center(
            child: AppSvgIcon(
              assetPath: AppAssets.package,
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
          ),
        );
    if (path.isEmpty) return fallback(context, '', null);
    if (path.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(path.substring(path.indexOf(',') + 1)),
          fit: BoxFit.cover,
          errorBuilder: fallback,
        );
      } catch (_) {
        return fallback(context, '', null);
      }
    }
    return path.startsWith('https://') || path.startsWith('http://')
        ? Image.network(path, fit: BoxFit.cover, errorBuilder: fallback)
        : Image.asset(path, fit: BoxFit.cover, errorBuilder: fallback);
  }
}
