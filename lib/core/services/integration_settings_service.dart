import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntegrationConfig {
  const IntegrationConfig({required this.endpoint, this.accountLabel = ''});
  final Uri endpoint;
  final String accountLabel;
}

final integrationSettingsProvider =
    NotifierProvider<
      IntegrationSettingsService,
      Map<String, IntegrationConfig>
    >(IntegrationSettingsService.new);

class IntegrationSettingsService
    extends Notifier<Map<String, IntegrationConfig>> {
  static const providers = [
    'whatsapp',
    'instagram',
    'facebook',
    'razorpay',
    'cashfree',
    'shiprocket',
    'delhivery',
  ];
  @override
  Map<String, IntegrationConfig> build() => const {};
  void configure(String provider, String endpoint, String label) {
    final uri = Uri.tryParse(endpoint.trim());
    if (!providers.contains(provider) ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Use an HTTPS backend URL without credentials, query parameters or fragments.',
      );
    }
    state = Map.unmodifiable({
      ...state,
      provider: IntegrationConfig(endpoint: uri, accountLabel: label.trim()),
    });
  }

  void remove(String provider) =>
      state = Map.unmodifiable({...state}..remove(provider));
}
