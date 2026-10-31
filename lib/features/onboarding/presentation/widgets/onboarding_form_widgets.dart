import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.highlight,
    this.image,
    this.subtitleColor = AppColors.textSecondary,
  });
  final String title;
  final String subtitle;
  final String icon;
  final String? highlight;
  final String? image;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: subtitle,
                  children: [
                    if (highlight != null)
                      TextSpan(
                        text: highlight,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                  ],
                ),
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (image != null)
          ExcludeSemantics(
            child: Image.asset(
              image!,
              width: 94,
              height: 104,
              fit: BoxFit.contain,
            ),
          )
        else
          ExcludeSemantics(
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 78,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF1E9FF),
                      Color(0xFFAF8CF3),
                      Color(0xFF7653CD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: icon,
                    width: 46,
                    height: 46,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class OnboardingLabel extends StatelessWidget {
  const OnboardingLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.dangerText),
            ),
        ],
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class OnboardingContinueButton extends StatelessWidget {
  const OnboardingContinueButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      child: const Row(
        children: [
          SizedBox(width: 20),
          Expanded(child: Text('Continue', textAlign: TextAlign.center)),
          AppSvgIcon(
            assetPath: AppAssets.arrowRight,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
          ),
        ],
      ),
    ),
  );
}
