import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/big_button.dart';
import 'widgets/new_sale_dialog.dart';
import 'widgets/cash_adjust_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesNotifier = ref.watch(salesProvider.notifier);
    final stats = salesNotifier.todayStats;
    final todaySales = salesNotifier.todaySales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(salesProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(stats: stats),
              const SizedBox(height: 16),
              BigButton(
                label: '+ YENİ SATIŞ',
                icon: Icons.add,
                onPressed: () => _showNewSale(context, ref),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BigButton(
                      label: 'Kasa Giriş',
                      isPrimary: false,
                      icon: Icons.arrow_downward,
                      color: Colors.white,
                      onPressed: () => _showCashAdjust(context, ref, isIn: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BigButton(
                      label: 'Kasa Çıkış',
                      isPrimary: false,
                      icon: Icons.arrow_upward,
                      color: Colors.white,
                      onPressed: () => _showCashAdjust(context, ref, isIn: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Son Satışlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (todaySales.isEmpty)
                const _EmptyState()
              else
                ...todaySales.take(20).map((sale) => _SaleTile(sale: sale, ref: ref)),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewSale(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewSaleDialog(ref: ref),
    );
  }

  void _showCashAdjust(BuildContext context, WidgetRef ref, {required bool isIn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CashAdjustDialog(ref: ref, isIn: isIn),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> stats;
  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Toplam Kasa', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(stats['toplam'] ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'Nakit', amount: stats['nakit'] ?? 0),
              const SizedBox(width: 8),
              _StatChip(label: 'Kart', amount: stats['kart'] ?? 0),
              const SizedBox(width: 8),
              _StatChip(label: 'Veresiye', amount: stats['veresiye'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double amount;
  const _StatChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  final WidgetRef ref;
  const _SaleTile({required this.sale, required this.ref});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    switch (sale.paymentType) {
      case 'kart':
        typeColor = Colors.blue;
        typeIcon = Icons.credit_card;
        break;
      case 'veresiye':
        typeColor = AppColors.error;
        typeIcon = Icons.person_outline;
        break;
      default:
        typeColor = AppColors.success;
        typeIcon = Icons.payments_outlined;
    }

    return Dismissible(
      key: Key(sale.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(salesProvider.notifier).deleteSale(sale.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: typeColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(sale.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (sale.note != null)
                    Text(sale.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _paymentLabel(sale.paymentType),
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormatter.formatTime(sale.timestamp),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String type) {
    switch (type) {
      case 'nakit': return 'Nakit';
      case 'kart': return 'Kart';
      case 'veresiye': return 'Veresiye';
      default: return type;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.border),
          SizedBox(height: 8),
          Text('Bugün henüz satış yok', style: TextStyle(color: AppColors.textSecondary)),
          Text('Yeni satış eklemek için butona bas', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
