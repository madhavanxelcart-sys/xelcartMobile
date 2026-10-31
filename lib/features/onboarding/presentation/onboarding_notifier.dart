import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/onboarding_state.dart';

/// Kept alive so Save & exit preserves the draft within the current session.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

class OnboardingNotifier extends Notifier<OnboardingState> {
  static const indianStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static bool validPostalCode(String value) =>
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(value);

  bool get isDeliveryValid =>
      state.addressLine1.trim().isNotEmpty &&
      state.city.trim().isNotEmpty &&
      validPostalCode(state.postalCode) &&
      indianStates.contains(state.state) &&
      state.country == 'India' &&
      state.currency == 'INR \u20B9';

  bool continueToReview() {
    if (!isDeliveryValid) return false;
    goToStep(4);
    return true;
  }

  static const categories = ['Fashion', 'Beauty', 'Food', 'Home'];
  static const businessTypes = [
    'Individual / Sole proprietor',
    'Partnership',
    'Private limited company',
    'Other',
  ];
  static const orderRanges = [
    'Just starting',
    '1–50',
    '51–200',
    '201–500',
    '500+',
  ];

  @override
  OnboardingState build() => OnboardingState();

  void update(OnboardingState Function(OnboardingState) change) =>
      state = change(state);

  void setVerifiedMobile(String number) =>
      state = state.copyWith(mobileNumber: number, mobileVerified: true);

  void goToStep(int step) {
    if (step < 1 || step > 4) throw RangeError.range(step, 1, 4, 'step');
    state = state.copyWith(currentStep: step);
  }

  void previousStep() {
    if (state.currentStep > 1) goToStep(state.currentStep - 1);
  }

  bool get isSellerProfileValid =>
      state.fullName.trim().isNotEmpty &&
      state.storeName.trim().isNotEmpty &&
      state.legalBusinessName.trim().isNotEmpty &&
      businessTypes.contains(state.businessType) &&
      state.selectedCategories.isNotEmpty &&
      state.mobileVerified;

  bool continueToChannels() {
    if (!isSellerProfileValid) return false;
    goToStep(2);
    return true;
  }

  void toggleCategory(String category) {
    if (!categories.contains(category)) {
      throw ArgumentError.value(category, 'category');
    }
    final selected = {...state.selectedCategories};
    if (!selected.add(category)) selected.remove(category);
    state = state.copyWith(selectedCategories: selected);
  }

  void reset() => state = OnboardingState();
}
