import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/domain/order_model.dart';
import '../services/ble_printer_service.dart';
import '../theme/app_colors.dart';

Future<void> showPrinterJobDialog(BuildContext context, {OrderModel? order}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrinterJobDialog(order: order),
    );

class PrinterJobDialog extends ConsumerStatefulWidget {
  const PrinterJobDialog({super.key, this.order});
  final OrderModel? order;
  @override
  ConsumerState<PrinterJobDialog> createState() => _PrinterJobDialogState();
}

class _PrinterJobDialogState extends ConsumerState<PrinterJobDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(blePrinterServiceProvider).connected) _print();
    });
  }

  Future<void> _print() async {
    final service = ref.read(blePrinterServiceProvider.notifier);
    if (widget.order == null) {
      await service.printTestLabel();
    } else {
      await service.printOrder(widget.order!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blePrinterServiceProvider);
    final service = ref.read(blePrinterServiceProvider.notifier);
    final simulated = ref.watch(blePrinterTransportProvider).isSimulated;
    return PopScope(
      canPop: !state.busy,
      child: AlertDialog(
        title: const Text('Print 4x6 Label'),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  simulated
                      ? 'Simulated BLE printer · no physical output'
                      : 'BLE thermal printer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.message.isEmpty
                      ? 'Connect a 4-inch BLE printer to print.'
                      : state.message,
                ),
                if (state.busy) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value:
                        state.phase == BlePrinterPhase.printing &&
                            state.progress > 0
                        ? state.progress
                        : null,
                  ),
                ],
                if (!state.connected && !state.busy) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: service.scan,
                    child: const Text('Scan for printers'),
                  ),
                  for (final device in state.devices)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        device.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          if (await service.pair(device) && mounted) {
                            await _print();
                          }
                        },
                        child: const Text('Pair & print'),
                      ),
                    ),
                ],
                if (state.connected && !state.busy) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _print,
                      child: const Text('Print again'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (state.busy) await service.disconnect();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(state.busy ? 'Cancel job' : 'Close'),
          ),
        ],
      ),
    );
  }
}
