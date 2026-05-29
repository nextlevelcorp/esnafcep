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
  String _paymentType = 'nakit';
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
    if (amount == null || amount <= 0) return;
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

  bool get _canSave {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return false;
    if (_paymentType == 'veresiye' && _selectedCustomer == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.ref.watch(customersProvider);

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
            _BottomSheetHandle(),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yeni Satış', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Text(
                '₺$_amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: _canSave ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            // Payment type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PaymentTypeSelector(
                selected: _paymentType,
                onSelect: (v) => setState(() {
                  _paymentType = v;
                  if (v != 'veresiye') _selectedCustomer = null;
                }),
              ),
            ),
            // Customer dropdown
            if (_paymentType == 'veresiye') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  hint: const Text('Müşteri seç...'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Numpad(onTap: _onNumpad),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave ? AppColors.primary : AppColors.border,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _canSave ? _save : null,
                child: const Text('KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
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
    return Row(
      children: [
        _TypeBtn(label: 'Nakit', value: 'nakit', selected: selected, onTap: onSelect,
            color: AppColors.success, icon: Icons.payments_rounded),
        const SizedBox(width: 8),
        _TypeBtn(label: 'Kart', value: 'kart', selected: selected, onTap: onSelect,
            color: const Color(0xFF4A90D9), icon: Icons.credit_card_rounded),
        const SizedBox(width: 8),
        _TypeBtn(label: 'Veresiye', value: 'veresiye', selected: selected, onTap: onSelect,
            color: AppColors.error, icon: Icons.person_rounded),
      ],
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  final Color color;
  final IconData icon;
  const _TypeBtn({required this.label, required this.value, required this.selected,
      required this.onTap, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.2),
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
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
            : Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
