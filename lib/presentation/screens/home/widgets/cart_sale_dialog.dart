import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/models/product.dart';
import '../../../../providers/sale_provider.dart';
import '../../../../providers/customer_provider.dart';
import '../../../../providers/product_provider.dart';

class CartSaleDialog extends StatefulWidget {
  final WidgetRef ref;
  const CartSaleDialog({super.key, required this.ref});

  @override
  State<CartSaleDialog> createState() => _CartSaleDialogState();
}

class _CartSaleDialogState extends State<CartSaleDialog> {
  final Map<String, int> _cart = {}; // productId → qty
  String _paymentType = 'nakit';
  Customer? _selectedCustomer;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final products = widget.ref.read(productsProvider);
    double sum = 0;
    for (final entry in _cart.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Product(id: '', name: '', price: 0),
      );
      sum += product.price * entry.value;
    }
    return sum;
  }

  int _cartCount(String id) => _cart[id] ?? 0;

  void _inc(String id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1);

  void _dec(String id) => setState(() {
        final v = (_cart[id] ?? 0) - 1;
        if (v <= 0) {
          _cart.remove(id);
        } else {
          _cart[id] = v;
        }
      });

  bool get _canSave {
    if (_cart.isEmpty || _total <= 0) return false;
    if (_paymentType == 'veresiye' && _selectedCustomer == null) return false;
    return true;
  }

  void _save() {
    if (!_canSave) return;
    final products = widget.ref.read(productsProvider);
    final cartItems = _cart.entries.map((e) {
      final p = products.firstWhere((p) => p.id == e.key);
      return '${p.emoji}${p.name}×${e.value}';
    }).join(', ');
    final note = _noteCtrl.text.trim().isNotEmpty
        ? '${_noteCtrl.text.trim()} ($cartItems)'
        : cartItems;

    widget.ref.read(salesProvider.notifier).addSale(
      amount: _total,
      paymentType: _paymentType,
      customerId: _selectedCustomer?.id,
      note: note,
    );
    if (_paymentType == 'veresiye' && _selectedCustomer != null) {
      widget.ref.read(customersProvider.notifier).addDebt(_selectedCustomer!.id, _total);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.ref.watch(productsProvider);
    final customers = widget.ref.watch(customersProvider);
    final hasCart = _cart.isNotEmpty;

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
            _Handle(),
            const SizedBox(height: 4),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sepet Satış',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: hasCart
                        ? Container(
                            key: const ValueKey('total'),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              CurrencyFormatter.format(_total),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          )
                        : const Text(
                            '₺0',
                            key: ValueKey('zero'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.border,
                            ),
                          ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Product grid
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.border),
                    const SizedBox(height: 8),
                    const Text(
                      'Ürün eklenmemiş',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ayarlar → Ürünlerim\'den ekle',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return _ProductCard(
                      product: p,
                      qty: _cartCount(p.id),
                      onInc: () => _inc(p.id),
                      onDec: () => _dec(p.id),
                    );
                  },
                ),
              ),

            // Cart item chips
            if (hasCart) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: _cart.entries.map((e) {
                    final p = products.firstWhere(
                      (p) => p.id == e.key,
                      orElse: () => Product(id: e.key, name: e.key, price: 0),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _dec(p.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${p.emoji} ${p.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${e.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
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
              const SizedBox(height: 12),

              // Payment type
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PaymentTypeRow(
                  selected: _paymentType,
                  onSelect: (v) => setState(() {
                    _paymentType = v;
                    if (v != 'veresiye') _selectedCustomer = null;
                  }),
                ),
              ),

              // Customer dropdown
              if (_paymentType == 'veresiye') ...[
                const SizedBox(height: 10),
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
                    items: customers
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                  ),
                ),
              ],

              // Note
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Not ekle (isteğe bağlı)...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18, color: AppColors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],

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
                child: Text(
                  _canSave
                      ? 'ÖDET  ${CurrencyFormatter.format(_total)}'
                      : 'ÜRÜN EKLE',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _ProductCard({
    required this.product,
    required this.qty,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: inCart ? AppColors.primary.withOpacity(0.07) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inCart ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            CurrencyFormatter.format(product.price),
            style: TextStyle(
              fontSize: 11,
              color: inCart ? AppColors.primary.withOpacity(0.8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (qty == 0)
            GestureDetector(
              onTap: onInc,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onDec,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onInc,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Payment Type Row ──────────────────────────────────────────────────────────

class _PaymentTypeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PaymentTypeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const types = [
      ('nakit', 'Nakit', AppColors.success, Icons.payments_rounded),
      ('kart', 'Kart', Color(0xFF4A90D9), Icons.credit_card_rounded),
      ('veresiye', 'Veresiye', AppColors.error, Icons.person_rounded),
    ];
    return Row(
      children: types.map((t) {
        final (value, label, color, icon) = t;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? color : color.withOpacity(0.2)),
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
          ),
        );
      }).toList(),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
