import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/customer.dart';
import '../../../../providers/customer_provider.dart';

class EditCustomerDialog extends StatefulWidget {
  final WidgetRef ref;
  final Customer customer;
  const EditCustomerDialog({super.key, required this.ref, required this.customer});

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  void _save() {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    widget.customer.name = _nameCtrl.text.trim();
    widget.customer.phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    widget.ref.read(customersProvider.notifier).updateCustomer(widget.customer);
    Navigator.pop(context);
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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Müşteriyi Düzenle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  // Name field
                  AnimatedBuilder(
                    animation: _nameCtrl,
                    builder: (_, __) => TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Ad Soyad *',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: _nameCtrl.text.isNotEmpty && _nameCtrl.text.trim().isEmpty
                            ? 'Geçerli bir isim girin'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Phone field
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon (opsiyonel)',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: '0555 123 45 67',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: AnimatedBuilder(
                animation: _nameCtrl,
                builder: (_, __) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? AppColors.primary : AppColors.border,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isValid ? _save : null,
                  child: const Text('KAYDET',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
