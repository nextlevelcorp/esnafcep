import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/customer_list_tile.dart';
import 'customer_detail_screen.dart';
import 'widgets/add_customer_dialog.dart';

class VeresiyeScreen extends ConsumerStatefulWidget {
  const VeresiyeScreen({super.key});

  @override
  ConsumerState<VeresiyeScreen> createState() => _VeresiyeScreenState();
}

enum _SortBy { nameAsc, debtDesc, dateDesc }

class _VeresiyeScreenState extends ConsumerState<VeresiyeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SortBy _sortBy = _SortBy.debtDesc;

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Müşteriyi Sil', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('"$name" ve tüm işlem geçmişi silinecek.'),
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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final filtered = customers.where((c) =>
        c.name.toLowerCase().contains(_query.toLowerCase()) ||
        (c.phone ?? '').contains(_query)).toList()
      ..sort((a, b) => switch (_sortBy) {
        _SortBy.nameAsc => a.name.compareTo(b.name),
        _SortBy.debtDesc => b.totalDebt.compareTo(a.totalDebt),
        _SortBy.dateDesc => b.createdAt.compareTo(a.createdAt),
      });
    final totalDebt = customers.fold(0.0, (sum, c) => sum + c.totalDebt);
    final debtorCount = customers.where((c) => c.totalDebt > 0).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Veresiye'),
        actions: [
          PopupMenuButton<_SortBy>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sırala',
            initialValue: _sortBy,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: _SortBy.debtDesc, child: Text('En yüksek borç')),
              const PopupMenuItem(value: _SortBy.nameAsc, child: Text('İsme göre (A-Z)')),
              const PopupMenuItem(value: _SortBy.dateDesc, child: Text('En son eklenen')),
            ],
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => AddCustomerDialog(ref: ref),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Summary banner
          if (totalDebt > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error.withOpacity(0.9), AppColors.error],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(totalDebt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '$debtorCount müşteride toplam alacak',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Müşteri ara...',
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
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(hasCustomers: customers.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return Dismissible(
                        key: Key(c.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context, c.name),
                        onDismissed: (_) => ref.read(customersProvider.notifier).deleteCustomer(c.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        ),
                        child: CustomerListTile(
                          customer: c,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customerId: c.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasCustomers;
  const _EmptyState({required this.hasCustomers});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            hasCustomers ? 'Sonuç bulunamadı' : 'Henüz müşteri yok',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            hasCustomers ? 'Farklı bir isim dene' : 'Sağ üstteki + butonuna bas',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
