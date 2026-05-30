import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/customer_provider.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterType; // null = all

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSales = ref.watch(salesProvider);
    final customers = ref.watch(customersProvider);

    // Build customer name lookup
    final customerNames = {for (final c in customers) c.id: c.name};

    // Filter
    var filtered = allSales.where((s) {
      if (_filterType != null && s.paymentType != _filterType) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final note = (s.note ?? '').toLowerCase();
        final customerName = (customerNames[s.customerId] ?? '').toLowerCase();
        if (!note.contains(q) && !customerName.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group by date
    final grouped = <String, List<Sale>>{};
    for (final s in filtered) {
      final key = _dayKey(s.timestamp);
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final days = grouped.keys.toList();

    // Totals for filtered
    final total = filtered.fold(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Satış Geçmişi'),
        actions: [
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Not veya müşteri ara...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                _FilterRow(selected: _filterType, onSelect: (t) => setState(() => _filterType = t)),
              ],
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(hasAny: allSales.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: days.length,
                    itemBuilder: (_, i) {
                      final day = days[i];
                      final daySales = grouped[day]!;
                      final dayTotal = daySales.fold(0.0, (s, e) => s + e.amount);
                      return _DayGroup(
                        dayLabel: day,
                        dayTotal: dayTotal,
                        sales: daySales,
                        customerNames: customerNames,
                        onDelete: (id) => ref.read(salesProvider.notifier).deleteSale(id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _dayKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    return DateFormatter.formatDate(day);
  }
}

class _FilterRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, 'Tümü', AppColors.primary),
      ('nakit', 'Nakit', AppColors.success),
      ('kart', 'Kart', const Color(0xFF4A90D9)),
      ('veresiye', 'Veresiye', AppColors.error),
    ];
    return Row(
      children: filters.map((f) {
        final (type, label, color) = f;
        final isSelected = selected == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? color : color.withOpacity(0.2)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final String dayLabel;
  final double dayTotal;
  final List<Sale> sales;
  final Map<String?, String> customerNames;
  final ValueChanged<String> onDelete;
  const _DayGroup({
    required this.dayLabel,
    required this.dayTotal,
    required this.sales,
    required this.customerNames,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                CurrencyFormatter.format(dayTotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...sales.map((s) => _SaleRow(
              sale: s,
              customerName: customerNames[s.customerId],
              onDelete: () => onDelete(s.id),
            )),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Sale sale;
  final String? customerName;
  final VoidCallback onDelete;
  const _SaleRow({required this.sale, this.customerName, required this.onDelete});

  static const _typeColors = {
    'nakit': AppColors.success,
    'kart': Color(0xFF4A90D9),
    'veresiye': AppColors.error,
  };
  static const _typeIcons = {
    'nakit': Icons.payments_rounded,
    'kart': Icons.credit_card_rounded,
    'veresiye': Icons.person_rounded,
  };
  static const _typeLabels = {
    'nakit': 'Nakit',
    'kart': 'Kart',
    'veresiye': 'Veresiye',
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[sale.paymentType] ?? AppColors.textSecondary;
    final icon = _typeIcons[sale.paymentType] ?? Icons.point_of_sale_rounded;
    final label = _typeLabels[sale.paymentType] ?? sale.paymentType;

    return Dismissible(
      key: Key(sale.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Satışı Sil', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text('${CurrencyFormatter.format(sale.amount)} tutarındaki satış silinecek.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (customerName != null ? ' — $customerName' : ''),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (sale.note != null && sale.note!.isNotEmpty)
                    Text(sale.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(sale.amount),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
                ),
                Text(
                  DateFormatter.formatTime(sale.timestamp),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasAny;
  const _EmptyState({required this.hasAny});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            hasAny ? 'Sonuç bulunamadı' : 'Henüz satış yok',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            hasAny ? 'Farklı bir filtre dene' : 'Ana ekrandan satış ekle',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
