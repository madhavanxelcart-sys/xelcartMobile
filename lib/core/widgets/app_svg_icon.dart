import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An SVG asset with optional sizing and tinting.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.colorFilter,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    assetPath,
    width: width,
    height: height,
    colorFilter: colorFilter,
  );
}
