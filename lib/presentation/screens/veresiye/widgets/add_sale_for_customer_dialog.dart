import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/customer.dart';
import '../../../../providers/sale_provider.dart';
import '../../../../providers/customer_provider.dart';
import '../../../widgets/big_button.dart';
import '../../../widgets/amount_input.dart';

class AddSaleForCustomerDialog extends StatefulWidget {
  final WidgetRef ref;
  final Customer customer;
  const AddSaleForCustomerDialog({super.key, required this.ref, required this.customer});

  @override
  State<AddSaleForCustomerDialog> createState() => _AddSaleForCustomerDialogState();
}

class _AddSaleForCustomerDialogState extends State<AddSaleForCustomerDialog> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.ref.read(salesProvider.notifier).addSale(
      amount: amount,
      paymentType: 'veresiye',
      customerId: widget.customer.id,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    widget.ref.read(customersProvider.notifier).addDebt(widget.customer.id, amount);
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
          Text('${widget.customer.name} - Veresiye', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AmountInput(controller: _amountCtrl, autofocus: true, label: 'Veresiye Tutarı'),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          BigButton(label: 'VERESİYE EKLE', onPressed: _save, color: AppColors.error),
        ],
      ),
    );
  }
}
