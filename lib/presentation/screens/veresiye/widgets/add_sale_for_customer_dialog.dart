import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/sale_provider.dart';
import '../../../../providers/customer_provider.dart';

class AddSaleForCustomerDialog extends StatefulWidget {
  final WidgetRef ref;
  final String customerId;
  const AddSaleForCustomerDialog({super.key, required this.ref, required this.customerId});

  @override
  State<AddSaleForCustomerDialog> createState() => _AddSaleForCustomerDialogState();
}

class _AddSaleForCustomerDialogState extends State<AddSaleForCustomerDialog> {
  String _amount = '0';
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final v = double.tryParse(_amount);
    return v != null && v > 0;
  }

  void _onNumpad(String val) {
    setState(() {
      if (val == 'DEL') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (val == '.' && _amount.contains('.')) {
        return;
      } else if (_amount == '0' && val != '.') {
        _amount = val;
      } else {
        if (_amount.contains('.')) {
          final parts = _amount.split('.');
          if (parts[1].length >= 2) return;
        }
        _amount += val;
      }
    });
  }

  void _save() {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return;

    // Add sale record
    widget.ref.read(salesProvider.notifier).addSale(
      amount: amount,
      paymentType: 'veresiye',
      customerId: widget.customerId,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    // Update customer debt
    widget.ref.read(customersProvider.notifier).addDebt(widget.customerId, amount);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get customer name reactively
    final customers = widget.ref.watch(customersProvider);
    final customer = customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => customers.first,
    );

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Veresiye Ekle',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(customer.name,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Amount display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '₺$_amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: _canSave ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Numpad(onTap: _onNumpad),
            ),
            // Note field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
            // Save button
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
                child: const Text('VERESİYE EKLE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _Numpad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','.','0','DEL'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.8,
      children: keys.map((k) => _NumKey(label: k, onTap: () => onTap(k))).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: label == 'DEL'
            ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 20)
            : Text(label,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }
}
