import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/sale_provider.dart';
import '../../../widgets/big_button.dart';
import '../../../widgets/amount_input.dart';

class CashAdjustDialog extends StatefulWidget {
  final WidgetRef ref;
  final bool isIn;
  const CashAdjustDialog({super.key, required this.ref, required this.isIn});

  @override
  State<CashAdjustDialog> createState() => _CashAdjustDialogState();
}

class _CashAdjustDialogState extends State<CashAdjustDialog> {
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
      paymentType: 'nakit',
      note: widget.isIn ? 'Kasa Giriş: ${_noteCtrl.text}' : 'Kasa Çıkış: ${_noteCtrl.text}',
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
          Text(
            widget.isIn ? 'Kasa Giriş' : 'Kasa Çıkış',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AmountInput(controller: _amountCtrl, autofocus: true),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          BigButton(
            label: 'KAYDET',
            onPressed: _save,
            color: widget.isIn ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}
