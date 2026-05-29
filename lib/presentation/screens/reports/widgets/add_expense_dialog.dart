import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/expense_provider.dart';
import '../../../widgets/big_button.dart';
import '../../../widgets/amount_input.dart';

class AddExpenseDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddExpenseDialog({super.key, required this.ref});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'diger';

  final _categories = const [
    ('kira', 'Kira'),
    ('elektrik', 'Elektrik'),
    ('mal_alimi', 'Mal Alımı'),
    ('diger', 'Diğer'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.ref.read(expensesProvider.notifier).addExpense(
      amount: amount,
      category: _category,
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
          const Text('Yeni Gider', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AmountInput(controller: _amountCtrl, autofocus: true, label: 'Gider Tutarı'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _categories.map(((String, String) c) => ChoiceChip(
              label: Text(c.$2),
              selected: _category == c.$1,
              onSelected: (_) => setState(() => _category = c.$1),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: _category == c.$1 ? Colors.white : AppColors.textPrimary),
            )).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          BigButton(label: 'GİDER EKLE', onPressed: _save, color: AppColors.error),
        ],
      ),
    );
  }
}
