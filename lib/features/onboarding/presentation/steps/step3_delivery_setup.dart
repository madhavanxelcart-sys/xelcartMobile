import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../onboarding_notifier.dart';
import '../widgets/onboarding_accordion.dart';
import '../widgets/onboarding_form_widgets.dart';

class Step3DeliverySetup extends ConsumerStatefulWidget {
  const Step3DeliverySetup({super.key});
  @override
  ConsumerState<Step3DeliverySetup> createState() => _Step3DeliverySetupState();
}

class _Step3DeliverySetupState extends ConsumerState<Step3DeliverySetup> {
  final _form = GlobalKey<FormState>();
  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

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
            title: 'Ship your\nfirst win.',
            subtitle: 'Set your delivery details.',
            subtitleColor: AppColors.primary,
            icon: AppAssets.package,
            image: AppAssets.onboardingParcel,
          ),
          const OnboardingLabel('Business address', required: true),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _addressField(
                  label: 'Address line 1',
                  fieldKey: 'addressLine1',
                  value: draft.addressLine1,
                  hint: 'House no., building, street, area',
                  icon: AppAssets.mapPin,
                  onChanged: (v) =>
                      notifier.update((s) => s.copyWith(addressLine1: v)),
                ),
                const SizedBox(height: 16),
                _addressField(
                  label: 'Address line 2 (optional)',
                  fieldKey: 'addressLine2',
                  value: draft.addressLine2,
                  hint: 'Apartment, suite, landmark',
                  icon: AppAssets.building2,
                  required: false,
                  onChanged: (v) =>
                      notifier.update((s) => s.copyWith(addressLine2: v)),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _addressField(
                        label: 'City',
                        fieldKey: 'city',
                        value: draft.city,
                        hint: 'City',
                        icon: AppAssets.house,
                        onChanged: (v) =>
                            notifier.update((s) => s.copyWith(city: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingLabel('Postal code', required: true),
                          TextFormField(
                            key: const Key('postalCode'),
                            initialValue: draft.postalCode,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'PIN code',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) =>
                                OnboardingNotifier.validPostalCode(value ?? '')
                                ? null
                                : 'Enter a valid PIN',
                            onChanged: (v) => notifier.update(
                              (s) => s.copyWith(postalCode: v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingLabel('State', required: true),
                          DropdownButtonFormField<String>(
                            key: const Key('deliveryState'),
                            initialValue: draft.state.isEmpty
                                ? null
                                : draft.state,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                            ),
                            hint: const Text(
                              'Select state',
                              style: TextStyle(fontSize: 12),
                            ),
                            items: [
                              for (final state
                                  in OnboardingNotifier.indianStates)
                                DropdownMenuItem(
                                  value: state,
                                  child: Text(
                                    state,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                            validator: _required,
                            onChanged: (v) {
                              if (v != null) {
                                notifier.update((s) => s.copyWith(state: v));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingLabel('Country', required: true),
                          DropdownButtonFormField<String>(
                            key: const Key('country'),
                            initialValue: draft.country,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'India',
                                child: Row(
                                  children: [
                                    _IndiaFlag(),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'India',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                notifier.update((s) => s.copyWith(country: v));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: const Key('useForPickupAndReturns'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Use this address for pickup and returns',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: draft.useForPickupAndReturns,
                  onChanged: (v) => notifier.update(
                    (s) => s.copyWith(useForPickupAndReturns: v ?? false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OnboardingAccordion(
            title: 'Pickup & return addresses',
            subtitle: 'Add fulfillment locations',
            icon: AppAssets.mapPin,
            children: draft.useForPickupAndReturns
                ? [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Using your business address for pickup and returns.\n${[draft.addressLine1, draft.addressLine2, draft.city, draft.postalCode].where((s) => s.trim().isNotEmpty).join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ]
                : [
                    _optionalField(
                      'Pickup address',
                      'pickupAddress',
                      draft.pickupAddress,
                      (v) =>
                          notifier.update((s) => s.copyWith(pickupAddress: v)),
                    ),
                    const SizedBox(height: 12),
                    _optionalField(
                      'Return address',
                      'returnAddress',
                      draft.returnAddress,
                      (v) =>
                          notifier.update((s) => s.copyWith(returnAddress: v)),
                    ),
                  ],
          ),
          OnboardingAccordion(
            title: 'Delivery & payment settings',
            subtitle: 'Regions, timelines, payment methods',
            icon: AppAssets.truck,
            children: [
              _optionalField(
                'Delivery regions',
                'deliveryRegions',
                draft.deliveryRegions,
                (v) => notifier.update((s) => s.copyWith(deliveryRegions: v)),
              ),
              const SizedBox(height: 12),
              _optionalField(
                'Delivery timelines',
                'deliveryTimeline',
                draft.deliveryTimeline,
                (v) => notifier.update((s) => s.copyWith(deliveryTimeline: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Prepaid payments',
                  style: TextStyle(fontSize: 13),
                ),
                value: draft.prepaidPayments,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(prepaidPayments: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Cash on delivery',
                  style: TextStyle(fontSize: 13),
                ),
                value: draft.cashOnDelivery,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(cashOnDelivery: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const OnboardingLabel('Currency', required: true),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('currency'),
                  initialValue: draft.currency,
                  items: const [
                    DropdownMenuItem(
                      value: 'INR \u20B9',
                      child: Text('\u20B9  INR \u20B9'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.update((s) => s.copyWith(currency: v));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OnboardingContinueButton(
            onPressed: () {
              if (_form.currentState!.validate() &&
                  notifier.continueToReview()) {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _addressField({
    required String label,
    required String fieldKey,
    required String value,
    required String hint,
    required String icon,
    required ValueChanged<String> onChanged,
    bool required = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OnboardingLabel(label, required: required),
      TextFormField(
        key: Key(fieldKey),
        initialValue: value,
        style: const TextStyle(fontSize: 13),
        textCapitalization: TextCapitalization.words,
        validator: required ? _required : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 6),
            child: AppSvgIcon(
              assetPath: icon,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 16,
          ),
        ),
      ),
    ],
  );

  Widget _optionalField(
    String label,
    String fieldKey,
    String value,
    ValueChanged<String> onChanged,
  ) => TextFormField(
    key: Key(fieldKey),
    initialValue: value,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label),
    style: const TextStyle(fontSize: 13),
  );
}

class _IndiaFlag extends StatelessWidget {
  const _IndiaFlag();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Indian flag',
    child: SizedBox(
      width: 18,
      height: 12,
      child: Column(
        children: [
          Expanded(child: Container(color: const Color(0xFFFF9933))),
          const Expanded(
            child: Center(
              child: Icon(Icons.circle, size: 4, color: Color(0xFF000080)),
            ),
          ),
          Expanded(child: Container(color: const Color(0xFF138808))),
        ],
      ),
    ),
  );
}
