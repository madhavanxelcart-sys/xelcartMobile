import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.onBack,
    required this.onSaveAndExit,
  });
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const AppSvgIcon(
                  assetPath: AppAssets.arrowLeft,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: Image.asset(
              AppAssets.xelcartLogo,
              height: 38,
              semanticLabel: 'Xelcart',
            ),
          ),
          SizedBox(
            width: 88,
            child: TextButton(
              onPressed: onSaveAndExit,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Save & exit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Onboarding step $currentStep of 4',
              child: Row(
                children: [
                  for (var step = 1; step <= 4; step++) ...[
                    if (step > 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: step <= currentStep
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step <= currentStep
                            ? AppColors.primary
                            : const Color(0xFFF1F2F6),
                      ),
                      alignment: Alignment.center,
                      child: step < currentStep
                          ? const AppSvgIcon(
                              assetPath: AppAssets.check,
                              width: 17,
                              height: 17,
                              colorFilter: ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            )
                          : Text(
                              '$step',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: step == currentStep
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'STEP $currentStep OF 4',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.accentText,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
