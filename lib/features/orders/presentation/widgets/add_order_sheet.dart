import 'package:flutter/material.dart';

import 'import_order_form.dart';
import 'manual_order_form.dart';

class AddOrderSheet extends StatefulWidget {
  const AddOrderSheet({super.key});
  @override
  State<AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<AddOrderSheet> {
  bool _manual = false;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Paste conversation')),
                ButtonSegment(value: true, label: Text('Enter manually')),
              ],
              selected: {_manual},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _manual = v.first),
            ),
          ),
          if (_manual) const ManualOrderForm() else const ImportOrderForm(),
        ],
      ),
    ),
  );
}
