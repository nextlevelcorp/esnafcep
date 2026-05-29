import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/big_button.dart';
import '../../widgets/customer_list_tile.dart';
import 'customer_detail_screen.dart';
import 'widgets/add_customer_dialog.dart';

class VeresiyeScreen extends ConsumerStatefulWidget {
  const VeresiyeScreen({super.key});

  @override
  ConsumerState<VeresiyeScreen> createState() => _VeresiyeScreenState();
}

class _VeresiyeScreenState extends ConsumerState<VeresiyeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

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
        (c.phone ?? '').contains(_query)).toList();
    final totalDebt = customers.fold(0.0, (sum, c) => sum + c.totalDebt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veresiye', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                if (totalDebt > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Toplam alacak: ${CurrencyFormatter.format(totalDebt)}',
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Müşteri ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          })
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BigButton(
              label: '+ YENİ MÜŞTERİ',
              icon: Icons.person_add,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddCustomerDialog(ref: ref),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Müşteri bulunamadı', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => CustomerListTile(
                      customer: filtered[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: filtered[i].id)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
