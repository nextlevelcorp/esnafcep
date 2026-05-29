import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/sale_provider.dart';
import '../../../widgets/numpad.dart';

class CashAdjustDialog extends StatefulWidget {
  final WidgetRef ref;
  final bool isIn;
  const CashAdjustDialog({super.key, required this.ref, required this.isIn});

  @override
  State<CashAdjustDialog> createState() => _CashAdjustDialogState();
}

class _CashAdjustDialogState extends State<CashAdjustDialog> {
  String _amount = '0';
  final _noteCtrl = TextEditingController();

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
    final note = _noteCtrl.text.trim();
    widget.ref.read(salesProvider.notifier).addSale(
      amount: amount,
      paymentType: 'nakit',
      note: widget.isIn
          ? 'Kasa Giriş${note.isNotEmpty ? ": $note" : ""}'
          : 'Kasa Çıkış${note.isNotEmpty ? ": $note" : ""}',
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
    final color = widget.isIn ? AppColors.success : AppColors.error;
    final icon = widget.isIn ? Icons.south_rounded : Icons.north_rounded;
    final label = widget.isIn ? 'Kasa Giriş' : 'Kasa Çıkış';

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
            // Top handle + colored header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Amount
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '₺$_amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1,
                  color: _canSave ? color : AppColors.textSecondary,
                ),
              ),
            ),
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppNumpad(onTap: _onNumpad),
            ),
            // Note
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave ? color : AppColors.border,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _canSave ? _save : null,
                child: Text(widget.isIn ? 'GİRİŞ KAYDET' : 'ÇIKIŞ KAYDET',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
