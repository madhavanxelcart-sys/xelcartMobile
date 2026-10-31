/// Immutable draft shared by all four onboarding steps.
class OnboardingState {
  OnboardingState({
    this.currentStep = 1,
    this.fullName = '',
    this.mobileNumber = '+91 98765 43210',
    this.mobileVerified = true,
    this.storeName = '',
    this.legalBusinessName = '',
    this.businessType = '',
    Set<String> selectedCategories = const {},
    this.whatsappConnected = false,
    this.instagramConnected = false,
    this.facebookConnected = false,
    this.website = '',
    this.monthlyOrders = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.postalCode = '',
    this.state = '',
    this.country = 'India',
    this.useForPickupAndReturns = false,
    this.currency = 'INR \u20B9',
    this.agreeTerms = false,
    this.confirmAgeAndAuth = false,
    this.pickupAddress = '',
    this.returnAddress = '',
    this.deliveryRegions = '',
    this.deliveryTimeline = '',
    this.supportContact = '',
    this.complaintHandling = '',
    this.returnsPolicy = '',
    this.refundPolicy = '',
    this.deliveryPolicy = '',
    this.gstNumber = '',
    this.licences = '',
    this.cashOnDelivery = false,
    this.prepaidPayments = true,
    this.optInTips = false,
  }) : assert(currentStep >= 1 && currentStep <= 4),
       selectedCategories = Set.unmodifiable(selectedCategories);

  final int currentStep;
  final String fullName;
  final String mobileNumber;
  final bool mobileVerified;
  final String storeName;
  final String legalBusinessName;
  final String businessType;
  final Set<String> selectedCategories;
  final bool whatsappConnected;
  final bool instagramConnected;
  final bool facebookConnected;
  final String website;
  final String monthlyOrders;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final String state;
  final String country;
  final bool useForPickupAndReturns;
  final String currency;
  final bool agreeTerms;
  final bool confirmAgeAndAuth;
  final String pickupAddress;
  final String returnAddress;
  final String deliveryRegions;
  final String deliveryTimeline;
  final String supportContact;
  final String complaintHandling;
  final String returnsPolicy;
  final String refundPolicy;
  final String deliveryPolicy;
  final String gstNumber;
  final String licences;
  final bool cashOnDelivery;
  final bool prepaidPayments;
  final bool optInTips;

  OnboardingState copyWith({
    int? currentStep,
    String? fullName,
    String? mobileNumber,
    bool? mobileVerified,
    String? storeName,
    String? legalBusinessName,
    String? businessType,
    Set<String>? selectedCategories,
    bool? whatsappConnected,
    bool? instagramConnected,
    bool? facebookConnected,
    String? website,
    String? monthlyOrders,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? state,
    String? country,
    bool? useForPickupAndReturns,
    String? currency,
    bool? agreeTerms,
    bool? confirmAgeAndAuth,
    String? pickupAddress,
    String? returnAddress,
    String? deliveryRegions,
    String? deliveryTimeline,
    String? supportContact,
    String? complaintHandling,
    String? returnsPolicy,
    String? refundPolicy,
    String? deliveryPolicy,
    String? gstNumber,
    String? licences,
    bool? cashOnDelivery,
    bool? prepaidPayments,
    bool? optInTips,
  }) => OnboardingState(
    currentStep: currentStep ?? this.currentStep,
    fullName: fullName ?? this.fullName,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    mobileVerified: mobileVerified ?? this.mobileVerified,
    storeName: storeName ?? this.storeName,
    legalBusinessName: legalBusinessName ?? this.legalBusinessName,
    businessType: businessType ?? this.businessType,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    whatsappConnected: whatsappConnected ?? this.whatsappConnected,
    instagramConnected: instagramConnected ?? this.instagramConnected,
    facebookConnected: facebookConnected ?? this.facebookConnected,
    website: website ?? this.website,
    monthlyOrders: monthlyOrders ?? this.monthlyOrders,
    addressLine1: addressLine1 ?? this.addressLine1,
    addressLine2: addressLine2 ?? this.addressLine2,
    city: city ?? this.city,
    postalCode: postalCode ?? this.postalCode,
    state: state ?? this.state,
    country: country ?? this.country,
    useForPickupAndReturns:
        useForPickupAndReturns ?? this.useForPickupAndReturns,
    currency: currency ?? this.currency,
    agreeTerms: agreeTerms ?? this.agreeTerms,
    confirmAgeAndAuth: confirmAgeAndAuth ?? this.confirmAgeAndAuth,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    returnAddress: returnAddress ?? this.returnAddress,
    deliveryRegions: deliveryRegions ?? this.deliveryRegions,
    deliveryTimeline: deliveryTimeline ?? this.deliveryTimeline,
    supportContact: supportContact ?? this.supportContact,
    complaintHandling: complaintHandling ?? this.complaintHandling,
    returnsPolicy: returnsPolicy ?? this.returnsPolicy,
    refundPolicy: refundPolicy ?? this.refundPolicy,
    deliveryPolicy: deliveryPolicy ?? this.deliveryPolicy,
    gstNumber: gstNumber ?? this.gstNumber,
    licences: licences ?? this.licences,
    cashOnDelivery: cashOnDelivery ?? this.cashOnDelivery,
    prepaidPayments: prepaidPayments ?? this.prepaidPayments,
    optInTips: optInTips ?? this.optInTips,
  );
}
