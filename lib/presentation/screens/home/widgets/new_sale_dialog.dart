import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/sale_provider.dart';
import '../../../../providers/customer_provider.dart';
import '../../../../data/models/customer.dart';

class NewSaleDialog extends StatefulWidget {
  final WidgetRef ref;
  const NewSaleDialog({super.key, required this.ref});

  @override
  State<NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<NewSaleDialog> {
  String _amount = '0';
  String _paymentType = '';
  Customer? _selectedCustomer;

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
    if (amount == null || amount <= 0 || _paymentType.isEmpty) return;
    if (_paymentType == 'veresiye' && _selectedCustomer == null) return;

    widget.ref.read(salesProvider.notifier).addSale(
      amount: amount,
      paymentType: _paymentType,
      customerId: _selectedCustomer?.id,
    );

    if (_paymentType == 'veresiye' && _selectedCustomer != null) {
      widget.ref.read(customersProvider.notifier).addDebt(_selectedCustomer!.id, amount);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.ref.watch(customersProvider);
    final canSave = double.tryParse(_amount) != null &&
        double.parse(_amount) > 0 &&
        _paymentType.isNotEmpty &&
        (_paymentType != 'veresiye' || _selectedCustomer != null);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Yeni Satış', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            '₺$_amount',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          _PaymentTypeSelector(
            selected: _paymentType,
            onSelect: (v) => setState(() {
              _paymentType = v;
              if (v != 'veresiye') _selectedCustomer = null;
            }),
          ),
          if (_paymentType == 'veresiye') ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                hint: const Text('Müşteri seç'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: customers.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name),
                )).toList(),
                onChanged: (c) => setState(() => _selectedCustomer = c),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Numpad(onTap: _onNumpad),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: canSave ? AppColors.primary : AppColors.border,
              ),
              onPressed: canSave ? _save : null,
              child: const Text('KAYDET', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PaymentTypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TypeBtn(label: 'Nakit', value: 'nakit', selected: selected, onTap: onSelect, color: AppColors.success),
          const SizedBox(width: 8),
          _TypeBtn(label: 'Kart', value: 'kart', selected: selected, onTap: onSelect, color: Colors.blue),
          const SizedBox(width: 8),
          _TypeBtn(label: 'Veresiye', value: 'veresiye', selected: selected, onTap: onSelect, color: AppColors.error),
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  final Color color;
  const _TypeBtn({required this.label, required this.value, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: keys.map((k) => _NumKey(label: k, onTap: () => onTap(k))).toList(),
      ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: label == 'DEL'
            ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary)
            : Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
