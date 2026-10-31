import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/ai_order_parser_service.dart';
import '../../../core/services/ble_printer_service.dart';
import '../../../core/services/integration_settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/printer_job_dialog.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/presentation/onboarding_notifier.dart';
import '../../orders/data/orders_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/presentation/product_draft_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  Future<void> _configure(
    BuildContext context,
    WidgetRef ref,
    String provider,
    String title,
  ) => showDialog<void>(
    context: context,
    builder: (_) =>
        _IntegrationConfigDialog(providerId: provider, title: title),
  );
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(blePrinterServiceProvider.notifier).disconnect();
    if (!context.mounted) return;
    context.go(RouteNames.login);
    ref.invalidate(authControllerProvider);
    ref.invalidate(onboardingProvider);
    ref.invalidate(ordersRepositoryProvider);
    ref.invalidate(inventoryRepositoryProvider);
    ref.invalidate(productDraftProvider);
    ref.invalidate(integrationSettingsProvider);
    ref.invalidate(blePrinterServiceProvider);
    ref.invalidate(aiOrderParserServiceProvider);
    ref.invalidate(parserHttpClientProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProvider);
    final printer = ref.watch(blePrinterServiceProvider);
    final printerService = ref.read(blePrinterServiceProvider.notifier);
    final simulated = ref.watch(blePrinterTransportProvider).isSimulated;
    final integrations = ref.watch(integrationSettingsProvider);
    Widget connection(String id, String title, String subtitle) {
      final configured = integrations[id];
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${configured == null ? 'Not configured' : 'Configured · not verified'}\n$subtitle',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () => _configure(context, ref, id, title),
          child: Text(configured == null ? 'Configure' : 'Edit'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Text(
                    'PC',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.storeName.trim().isEmpty
                            ? "Priya's Closet"
                            : profile.storeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        profile.mobileNumber,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _Heading('Hardware'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '4x6 BLE Thermal Printer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${printer.connected ? printer.device!.name : 'Not connected'}\n${simulated ? 'Simulated BLE transport · no physical printer' : 'Bluetooth Low Energy'}',
                style: const TextStyle(fontSize: 12),
              ),
              value: printer.connected || printer.busy,
              onChanged: (value) async {
                if (!value) {
                  await printerService.disconnect();
                  return;
                }
                if (await printerService.scan()) {
                  final devices = ref.read(blePrinterServiceProvider).devices;
                  if (devices.length == 1) {
                    await printerService.pair(devices.single);
                  }
                }
              },
            ),
            if (printer.busy)
              LinearProgressIndicator(
                value:
                    printer.phase == BlePrinterPhase.printing &&
                        printer.progress > 0
                    ? printer.progress
                    : null,
              ),
            if (printer.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  printer.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (!printer.connected && !printer.busy) ...[
              OutlinedButton(
                onPressed: printerService.scan,
                child: const Text('Scan for printers'),
              ),
              for (final device in printer.devices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(device.name),
                  trailing: TextButton(
                    onPressed: () => printerService.pair(device),
                    child: const Text('Pair'),
                  ),
                ),
            ],
            DropdownButtonFormField<PrinterProtocol>(
              key: ValueKey(printer.protocol),
              initialValue: printer.protocol,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Printer language'),
              items: [
                for (final protocol in PrinterProtocol.values)
                  DropdownMenuItem(
                    value: protocol,
                    enabled:
                        printer.device?.protocols.contains(protocol) ?? true,
                    child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                      protocol == PrinterProtocol.tspl
                          ? 'TSPL · 203 DPI · 4x6 in'
                          : 'ESC/POS raster · 203 DPI',
                    ),
                  ),
              ],
              onChanged: printer.busy
                  ? null
                  : (value) {
                      if (value != null) printerService.setProtocol(value);
                    },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('testPrintLabel'),
                onPressed: printer.connected && !printer.busy
                    ? () => showPrinterJobDialog(context)
                    : null,
                child: const Text('Test Print 4x6 Label'),
              ),
            ),
            const SizedBox(height: 26),
            const _Heading('Connected Channels'),
            connection(
              'whatsapp',
              'WhatsApp Coexistence',
              'WhatsApp Business app + messaging API',
            ),
            connection(
              'instagram',
              'Instagram Graph API',
              'Professional account connection',
            ),
            connection(
              'facebook',
              'Facebook Messenger',
              'Facebook Page messaging',
            ),
            const SizedBox(height: 22),
            const _Heading('Payment & Logistics'),
            connection(
              'razorpay',
              'Razorpay UPI links',
              'UPI payment-link backend',
            ),
            connection(
              'cashfree',
              'Cashfree UPI links',
              'UPI payment-link backend',
            ),
            connection(
              'shiprocket',
              'Shiprocket API',
              'Shipment and AWB backend',
            ),
            connection(
              'delhivery',
              'Delhivery API',
              'Shipment and tracking backend',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('signOut'),
                onPressed: () => _signOut(context, ref),
                icon: const AppSvgIcon(
                  assetPath: AppAssets.logOut,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    AppColors.dangerText,
                    BlendMode.srcIn,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerText,
                ),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );
}

class _IntegrationConfigDialog extends ConsumerStatefulWidget {
  const _IntegrationConfigDialog({
    required this.providerId,
    required this.title,
  });
  final String providerId, title;
  @override
  ConsumerState<_IntegrationConfigDialog> createState() =>
      _IntegrationConfigDialogState();
}

class _IntegrationConfigDialogState
    extends ConsumerState<_IntegrationConfigDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _endpoint, _account;
  @override
  void initState() {
    super.initState();
    final previous = ref.read(integrationSettingsProvider)[widget.providerId];
    _endpoint = TextEditingController(text: previous?.endpoint.toString());
    _account = TextEditingController(text: previous?.accountLabel);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Configure your backend endpoint. Keep API keys and provider secrets on your server.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: 'Account / merchant label (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('integrationEndpoint'),
              controller: _endpoint,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'HTTPS backend URL'),
              validator: (value) {
                final uri = Uri.tryParse(value?.trim() ?? '');
                return uri != null &&
                        uri.scheme == 'https' &&
                        uri.host.isNotEmpty &&
                        uri.userInfo.isEmpty &&
                        !uri.hasQuery &&
                        !uri.hasFragment
                    ? null
                    : 'Enter a valid HTTPS backend URL.';
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Configuration is session-local and does not verify a provider connection.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
    actions: [
      if (ref.watch(integrationSettingsProvider).containsKey(widget.providerId))
        TextButton(
          onPressed: () {
            ref
                .read(integrationSettingsProvider.notifier)
                .remove(widget.providerId);
            Navigator.pop(context);
          },
          child: const Text('Remove'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            ref
                .read(integrationSettingsProvider.notifier)
                .configure(widget.providerId, _endpoint.text, _account.text);
            Navigator.pop(context);
          }
        },
        child: const Text('Save configuration'),
      ),
    ],
  );
}
