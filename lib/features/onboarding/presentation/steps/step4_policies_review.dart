import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../onboarding_notifier.dart';
import '../widgets/onboarding_accordion.dart';
import '../widgets/onboarding_form_widgets.dart';

final onboardingLinkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class Step4PoliciesReview extends ConsumerWidget {
  const Step4PoliciesReview({super.key});

  Future<void> _openLink(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    try {
      final opened = await ref.read(onboardingLinkLauncherProvider)(
        Uri.parse(url),
      );
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open $url. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final storeName = draft.storeName.trim().isEmpty
        ? 'Your store'
        : draft.storeName.trim();
    final words = storeName.split(RegExp(r'\s+'));
    final initials = words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final ready = draft.agreeTerms && draft.confirmAgeAndAuth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingHero(
          title: 'Your store,\nalmost ready.',
          subtitle: 'Review the details before you start.',
          icon: AppAssets.store,
          image: AppAssets.onboardingStorefront,
        ),
        _ReviewCard(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8E2FF),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: storeName,
          subtitle:
              '${draft.selectedCategories.isEmpty ? 'Categories not selected' : draft.selectedCategories.join(', ')} \u00B7 ${draft.country}',
          onEdit: () => notifier.goToStep(1),
          editKey: 'editSellerProfile',
        ),
        const SizedBox(height: 10),
        _ReviewCard(
          leading: const AppSvgIcon(
            assetPath: AppAssets.fileText,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
          title: 'Business & delivery details',
          subtitle: 'Address, business type, delivery settings',
          onEdit: () => notifier.goToStep(3),
          editKey: 'editDeliveryDetails',
        ),
        const SizedBox(height: 16),
        OnboardingAccordion(
          title: 'Support & complaints',
          subtitle: 'Support contact and complaint handling',
          icon: AppAssets.headset,
          required: true,
          children: [
            _field(
              'Support email or phone',
              'supportContact',
              draft.supportContact,
              (v) => notifier.update((s) => s.copyWith(supportContact: v)),
            ),
            const SizedBox(height: 12),
            _field(
              'Complaint handling',
              'complaintHandling',
              draft.complaintHandling,
              (v) => notifier.update((s) => s.copyWith(complaintHandling: v)),
              multiline: true,
            ),
          ],
        ),
        OnboardingAccordion(
          title: 'Returns, refunds & delivery policies',
          subtitle: 'Set customer-facing policies',
          icon: AppAssets.history,
          required: true,
          children: [
            _field(
              'Returns policy',
              'returnsPolicy',
              draft.returnsPolicy,
              (v) => notifier.update((s) => s.copyWith(returnsPolicy: v)),
              multiline: true,
            ),
            const SizedBox(height: 12),
            _field(
              'Refund policy',
              'refundPolicy',
              draft.refundPolicy,
              (v) => notifier.update((s) => s.copyWith(refundPolicy: v)),
              multiline: true,
            ),
            const SizedBox(height: 12),
            _field(
              'Delivery policy',
              'deliveryPolicy',
              draft.deliveryPolicy,
              (v) => notifier.update((s) => s.copyWith(deliveryPolicy: v)),
              multiline: true,
            ),
          ],
        ),
        OnboardingAccordion(
          title: 'Tax & licences',
          subtitle: 'GST and category licences, if applicable \u00B7 Only where applicable',
          icon: AppAssets.fileCheck,
          children: [
            _field(
              'GST number (if applicable)',
              'gstNumber',
              draft.gstNumber,
              (v) => notifier.update((s) => s.copyWith(gstNumber: v)),
            ),
            const SizedBox(height: 12),
            _field(
              'Category licences (if applicable)',
              'licences',
              draft.licences,
              (v) => notifier.update((s) => s.copyWith(licences: v)),
            ),
          ],
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const AppSvgIcon(
            assetPath: AppAssets.lockKeyhole,
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
          title: const Text(
            'Read privacy notice',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text(
            'How Xelcart uses your data and how to request help',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: const AppSvgIcon(
            assetPath: AppAssets.externalLink,
            width: 17,
            height: 17,
            colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
          onTap: () => _openLink(context, ref, 'https://xelcart.com/privacy'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              key: const Key('agreeTerms'),
              activeColor: AppColors.primary,
              value: draft.agreeTerms,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(agreeTerms: v ?? false)),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('I agree to the ', style: TextStyle(fontSize: 12)),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        _openLink(context, ref, 'https://xelcart.com/terms'),
                    child: const Text(
                      'Terms of Service.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        CheckboxListTile(
          key: const Key('confirmAgeAndAuth'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          title: const Text(
            "I'm 18+ and authorized to represent this business.",
            style: TextStyle(fontSize: 12),
          ),
          value: draft.confirmAgeAndAuth,
          onChanged: (v) =>
              notifier.update((s) => s.copyWith(confirmAgeAndAuth: v ?? false)),
        ),
        CheckboxListTile(
          key: const Key('optInTips'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          title: const Text(
            'Send me tips and offers (optional).',
            style: TextStyle(fontSize: 12),
          ),
          value: draft.optInTips,
          onChanged: (v) =>
              notifier.update((s) => s.copyWith(optInTips: v ?? false)),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            key: const Key('createStore'),
            onPressed: !ready
                ? null
                : () {
                    if (!notifier.isSellerProfileValid ||
                        !notifier.isDeliveryValid) {
                      notifier.goToStep(notifier.isSellerProfileValid ? 3 : 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Complete required details to continue.',
                          ),
                        ),
                      );
                      return;
                    }
                    FocusScope.of(context).unfocus();
                    context.go(RouteNames.orders);
                  },
            child: const Row(
              children: [
                SizedBox(width: 20),
                Expanded(
                  child: Text('Create store', textAlign: TextAlign.center),
                ),
                AppSvgIcon(
                  assetPath: AppAssets.arrowRight,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Complete required details to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String fieldKey,
    String value,
    ValueChanged<String> onChanged, {
    bool multiline = false,
  }) => TextFormField(
    key: Key(fieldKey),
    initialValue: value,
    onChanged: onChanged,
    maxLines: multiline ? 3 : 1,
    decoration: InputDecoration(labelText: label),
    style: const TextStyle(fontSize: 13),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.editKey,
  });
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final String editKey;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          key: Key(editKey),
          onPressed: onEdit,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEEE9FF),
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const StadiumBorder(),
          ),
          child: const Text('Edit', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}
