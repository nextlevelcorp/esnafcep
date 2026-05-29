import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/expense_provider.dart';
import '../../../widgets/numpad.dart';

class AddExpenseDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddExpenseDialog({super.key, required this.ref});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  String _amount = '0';
  String _category = 'diger';
  final _noteCtrl = TextEditingController();

  static const _categories = [
    ('kira',      'Kira',      Icons.home_rounded,          Color(0xFF4A90D9)),
    ('elektrik',  'Elektrik',  Icons.bolt_rounded,          Color(0xFFBA7517)),
    ('mal_alimi', 'Mal Alımı', Icons.shopping_bag_rounded,  Color(0xFF8E6BBF)),
    ('diger',     'Diğer',     Icons.category_rounded,      AppColors.textSecondary),
  ];

  bool get _canSave => (double.tryParse(_amount) ?? 0) > 0;

  void _onNumpad(String val) => setState(() {
    if (val == 'DEL') {
      _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
    } else if (val == '.' && _amount.contains('.')) {
      return;
    } else if (_amount == '0' && val != '.') {
      _amount = val;
    } else {
      if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
      _amount += val;
    }
  });

  void _save() {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return;
    widget.ref.read(expensesProvider.notifier).addExpense(
      amount: amount,
      category: _category,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gider Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Amount
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '₺$_amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1,
                  color: _canSave ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
            // Category selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((c) {
                  final isSelected = _category == c.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = c.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? c.$4.withOpacity(0.12) : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? c.$4 : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(c.$3, color: isSelected ? c.$4 : AppColors.textSecondary, size: 20),
                            const SizedBox(height: 3),
                            Text(
                              c.$2,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? c.$4 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppNumpad(onTap: _onNumpad),
            ),
            // Note
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  hintText: 'Not ekle (opsiyonel)',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave ? AppColors.error : AppColors.border,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _canSave ? _save : null,
                child: const Text('GİDER EKLE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
