import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class OnboardingAccordion extends StatelessWidget {
  const OnboardingAccordion({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.required = false,
  });
  final String title;
  final String subtitle;
  final String icon;
  final List<Widget> children;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: const Color(0xFFF6F3FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE9E2FF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(title),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: AppSvgIcon(
          assetPath: icon,
          width: 26,
          height: 26,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
        title: Text.rich(
          TextSpan(
            text: title,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.dangerText),
                ),
            ],
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        children: children,
      ),
    ),
  );
}
