import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/customer.dart';
import '../../../../providers/customer_provider.dart';
import '../../../widgets/big_button.dart';
import '../../../widgets/amount_input.dart';

class PaymentDialog extends StatefulWidget {
  final WidgetRef ref;
  final Customer customer;
  const PaymentDialog({super.key, required this.ref, required this.customer});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setFull() {
    _amountCtrl.text = widget.customer.totalDebt.toStringAsFixed(2);
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.ref.read(customersProvider.notifier).recordPayment(
      customerId: widget.customer.id,
      amount: amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('${widget.customer.name} - Ödeme Al', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AmountInput(controller: _amountCtrl, autofocus: true),
          const SizedBox(height: 8),
          TextButton(onPressed: _setFull, child: const Text('Tüm borcu öde')),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          BigButton(label: 'KAYDET', onPressed: _save, color: AppColors.success),
        ],
      ),
    );
  }
}
