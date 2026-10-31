import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../onboarding_notifier.dart';
import '../widgets/onboarding_form_widgets.dart';

class Step1SellerProfile extends ConsumerStatefulWidget {
  const Step1SellerProfile({super.key});
  @override
  ConsumerState<Step1SellerProfile> createState() => _Step1SellerProfileState();
}

class _Step1SellerProfileState extends ConsumerState<Step1SellerProfile> {
  final _form = GlobalKey<FormState>();
  bool _submitted = false;

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHero(
            title: 'Build\nyour brand.',
            subtitle: 'Start with ',
            highlight: 'the essentials.',
            icon: AppAssets.shoppingBag,
          ),
          const OnboardingLabel('Your full name', required: true),
          TextFormField(
            key: const Key('fullName'),
            initialValue: draft.fullName,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(hintText: 'Full name'),
            validator: _required,
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(fullName: value)),
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Mobile number'),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    draft.mobileNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (draft.mobileVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.accentText,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentText,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Store name', required: true),
          TextFormField(
            key: const Key('storeName'),
            initialValue: draft.storeName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your brand name'),
            validator: _required,
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(storeName: value)),
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Legal business name', required: true),
          TextFormField(
            key: const Key('legalBusinessName'),
            initialValue: draft.legalBusinessName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Your registered business name',
            ),
            validator: _required,
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(legalBusinessName: value)),
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Business type', required: true),
          DropdownButtonFormField<String>(
            key: const Key('businessType'),
            initialValue: draft.businessType.isEmpty
                ? null
                : draft.businessType,
            isExpanded: true,
            hint: const Text(
              'Select business type',
              style: TextStyle(fontSize: 13),
            ),
            items: [
              for (final type in OnboardingNotifier.businessTypes)
                DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(fontSize: 13)),
                ),
            ],
            validator: _required,
            onChanged: (value) {
              if (value != null) {
                notifier.update((s) => s.copyWith(businessType: value));
              }
            },
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Product categories', required: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (
                var i = 0;
                i < OnboardingNotifier.categories.length;
                i++
              ) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _CategoryCard(
                    label: OnboardingNotifier.categories[i],
                    asset: const [
                      AppAssets.shirt,
                      AppAssets.sprayCan,
                      AppAssets.utensils,
                      AppAssets.house,
                    ][i],
                    selected: draft.selectedCategories.contains(
                      OnboardingNotifier.categories[i],
                    ),
                    onTap: () => notifier.toggleCategory(
                      OnboardingNotifier.categories[i],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_submitted && draft.selectedCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Select at least one category.',
                style: TextStyle(fontSize: 12, color: AppColors.dangerText),
              ),
            ),
          const SizedBox(height: 24),
          OnboardingContinueButton(
            onPressed: () {
              setState(() => _submitted = true);
              final valid = _form.currentState!.validate();
              if (valid && notifier.continueToChannels()) {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: selected ? AppColors.primary : const Color(0xFFF7F4FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : const Color(0xFFE3DAFF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSvgIcon(
                        assetPath: asset,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          selected ? AppColors.white : AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    Icons.check_circle,
                    size: 13,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
