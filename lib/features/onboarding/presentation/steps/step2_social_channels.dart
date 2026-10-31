import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../onboarding_notifier.dart';
import '../widgets/onboarding_form_widgets.dart';

class Step2SocialChannels extends ConsumerStatefulWidget {
  const Step2SocialChannels({super.key});
  @override
  ConsumerState<Step2SocialChannels> createState() =>
      _Step2SocialChannelsState();
}

class _Step2SocialChannelsState extends ConsumerState<Step2SocialChannels> {
  final _form = GlobalKey<FormState>();
  String? _validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.contains('.') &&
            !value.contains(' ')
        ? null
        : 'Enter a valid website URL, including https://.';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    void next() {
      FocusScope.of(context).unfocus();
      notifier.goToStep(3);
    }

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHero(
            title: 'DMs meet\norders.',
            subtitle: 'Bring your selling channels together.',
            icon: AppAssets.megaphone,
          ),
          _ChannelCard(
            title: 'WhatsApp Business',
            subtitle: 'Receive business messages',
            asset: AppAssets.whatsapp,
            color: AppColors.whatsapp,
            connected: draft.whatsappConnected,
            onTap: () => notifier.update(
              (s) => s.copyWith(whatsappConnected: !s.whatsappConnected),
            ),
          ),
          const SizedBox(height: 10),
          _ChannelCard(
            title: 'Instagram',
            subtitle: 'Professional account',
            asset: AppAssets.instagram,
            color: AppColors.instagram,
            connected: draft.instagramConnected,
            onTap: () => notifier.update(
              (s) => s.copyWith(instagramConnected: !s.instagramConnected),
            ),
          ),
          const SizedBox(height: 10),
          _ChannelCard(
            title: 'Facebook',
            subtitle: 'Page Messenger',
            asset: AppAssets.facebook,
            color: AppColors.facebook,
            connected: draft.facebookConnected,
            onTap: () => notifier.update(
              (s) => s.copyWith(facebookConnected: !s.facebookConnected),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEE9FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                AppSvgIcon(
                  assetPath: AppAssets.shieldCheck,
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Connect through Meta.\n',
                      style: TextStyle(fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: 'No social passwords needed.',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const OnboardingLabel('Website (optional)'),
          TextFormField(
            key: const Key('website'),
            initialValue: draft.website,
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: _validateWebsite,
            decoration: const InputDecoration(
              hintText: 'https://yourstore.com',
              prefixIcon: Padding(
                padding: EdgeInsets.all(14),
                child: AppSvgIcon(
                  assetPath: AppAssets.link,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(website: value)),
          ),
          const SizedBox(height: 18),
          const OnboardingLabel('Monthly orders (optional)'),
          DropdownButtonFormField<String>(
            key: const Key('monthlyOrders'),
            initialValue: draft.monthlyOrders.isEmpty
                ? null
                : draft.monthlyOrders,
            isExpanded: true,
            hint: const Text(
              'Select monthly orders',
              style: TextStyle(fontSize: 13),
            ),
            items: [
              for (final range in OnboardingNotifier.orderRanges)
                DropdownMenuItem(value: range, child: Text(range)),
            ],
            onChanged: (value) {
              if (value != null) {
                notifier.update((s) => s.copyWith(monthlyOrders: value));
              }
            },
          ),
          const SizedBox(height: 24),
          OnboardingContinueButton(
            onPressed: () {
              if (_form.currentState!.validate()) next();
            },
          ),
          Center(
            child: TextButton(
              onPressed: next,
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.color,
    required this.connected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String asset;
  final Color color;
  final bool connected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.1)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: AppSvgIcon(
            assetPath: asset,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Semantics(
          toggled: connected,
          label: title,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: connected
                  ? AppColors.accent
                  : const Color(0xFFEEE9FF),
              foregroundColor: connected
                  ? AppColors.accentText
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: onTap,
            child: Text(connected ? 'Connected' : 'Connect'),
          ),
        ),
      ],
    ),
  );
}
