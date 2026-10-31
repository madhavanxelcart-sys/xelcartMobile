import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'onboarding_notifier.dart';
import 'steps/step1_seller_profile.dart';
import 'steps/step2_social_channels.dart';
import 'steps/step3_delivery_setup.dart';
import 'steps/step4_policies_review.dart';
import 'widgets/onboarding_header.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});
  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  int _previousStep = 1;
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingProvider.select((s) => s.currentStep));
    ref.listen(onboardingProvider.select((s) => s.currentStep), (
      previous,
      next,
    ) {
      FocusScope.of(context).unfocus();
    });
    if (step != _previousStep) {
      _forward = step > _previousStep;
      _previousStep = step;
    }
    void back() {
      if (step > 1) {
        ref.read(onboardingProvider.notifier).previousStep();
      } else {
        context.go(RouteNames.login);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OnboardingHeader(
                      currentStep: step,
                      onBack: back,
                      onSaveAndExit: () {
                        FocusScope.of(context).unfocus();
                        context.go(RouteNames.login);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Draft kept for this session. Sign in again to resume.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topCenter,
                              fit: StackFit.expand,
                              children: [
                                ...previousChildren.map(
                                  (child) => IgnorePointer(
                                    child: ExcludeSemantics(child: child),
                                  ),
                                ),
                                ?currentChild,
                              ],
                            ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(_forward ? 0.08 : -0.08, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: SingleChildScrollView(
                          key: ValueKey(step),
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: switch (step) {
                            1 => const Step1SellerProfile(),
                            2 => const Step2SocialChannels(),
                            3 => const Step3DeliverySetup(),
                            _ => const Step4PoliciesReview(),
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
