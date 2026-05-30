import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/customer.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../widgets/big_button.dart';
import 'widgets/new_sale_dialog.dart';
import 'widgets/cash_adjust_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _filterType; // null = all, 'nakit', 'kart', 'veresiye'

  @override
  Widget build(BuildContext context) {
    final salesNotifier = ref.watch(salesProvider.notifier);
    final expensesNotifier = ref.watch(expensesProvider.notifier);
    final customers = ref.watch(customersProvider);
    final stats = salesNotifier.todayStats;
    final allTodaySales = salesNotifier.todaySales;
    final todayExpenses = expensesNotifier.todayTotal;

    final todaySales = _filterType == null
        ? allTodaySales
        : allTodaySales.where((s) => s.paymentType == _filterType).toList();

    // Customers with debt overdue > 30 days
    final now = DateTime.now();
    final criticalDebtors = customers.where((c) {
      if (c.totalDebt <= 0) return false;
      final refDate = c.lastDebtAt ?? c.createdAt;
      return now.difference(refDate).inDays > 30;
    }).toList()
      ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _AppBar(stats: stats, todayExpenses: todayExpenses),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _QuickActions(ref: ref),
                  if (criticalDebtors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CriticalDebtorsCard(debtors: criticalDebtors),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Bugünkü Satışlar',
                    count: allTodaySales.length,
                    filterType: _filterType,
                    onFilterChange: (t) => setState(() => _filterType = t),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (todaySales.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SaleTile(sale: todaySales[i], ref: ref),
                  ),
                  childCount: todaySales.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final Map<String, double> stats;
  final double todayExpenses;
  const _AppBar({required this.stats, required this.todayExpenses});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _SummaryCard(stats: stats, todayExpenses: todayExpenses),
        ),
      ),
      title: const Text('EsnafCep'),
      titleSpacing: 16,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> stats;
  final double todayExpenses;
  const _SummaryCard({required this.stats, required this.todayExpenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    final months = ['','Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month]}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bugün',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(stats['toplam'] ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Toplam Gelir',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (todayExpenses > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Net: ${CurrencyFormatter.format((stats['toplam'] ?? 0) - todayExpenses)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(label: 'Nakit', amount: stats['nakit'] ?? 0, icon: Icons.payments_outlined),
              const SizedBox(width: 8),
              _StatPill(label: 'Kart', amount: stats['kart'] ?? 0, icon: Icons.credit_card_outlined),
              const SizedBox(width: 8),
              _StatPill(label: 'Veresiye', amount: stats['veresiye'] ?? 0, icon: Icons.person_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  const _StatPill({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              CurrencyFormatter.formatShort(amount),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriticalDebtorsCard extends StatelessWidget {
  final List<Customer> debtors;
  const _CriticalDebtorsCard({required this.debtors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${debtors.length} Kritik Borçlu',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                Text(
                  '30+ gündür ödeme yok',
                  style: TextStyle(fontSize: 11, color: AppColors.error.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          ...debtors.take(3).map((c) => _CriticalRow(customer: c)),
          if (debtors.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Text(
                '+${debtors.length - 3} müşteri daha — Veresiye sekmesine bak',
                style: TextStyle(fontSize: 11, color: AppColors.error.withOpacity(0.7)),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CriticalRow extends StatelessWidget {
  final Customer customer;
  const _CriticalRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ref = customer.lastDebtAt ?? customer.createdAt;
    final days = now.difference(ref).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                Text('$days gündür ödeme yok',
                    style: TextStyle(fontSize: 11, color: AppColors.error.withOpacity(0.8))),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(customer.totalDebt),
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.error, fontSize: 14),
          ),
          if (customer.phone != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final phone = customer.phone!
                    .replaceAll(' ', '')
                    .replaceAll('-', '')
                    .replaceFirst(RegExp(r'^0'), '+90');
                final msg = Uri.encodeComponent(
                  'Merhaba ${customer.name} 👋\n\nToplam borcunuz: *${CurrencyFormatter.format(customer.totalDebt)}*\n\nÖdeme yapabilirseniz seviniriz. 🙏',
                );
                launchUrl(
                  Uri.parse('https://wa.me/$phone?text=$msg'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.message_rounded, color: Color(0xFF25D366), size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActions({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BigButton(
          label: 'Yeni Satış',
          icon: Icons.add_rounded,
          height: 58,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => NewSaleDialog(ref: ref),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BigButton(
                label: 'Kasa Giriş',
                isPrimary: false,
                icon: Icons.south_rounded,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CashAdjustDialog(ref: ref, isIn: true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigButton(
                label: 'Kasa Çıkış',
                isPrimary: false,
                icon: Icons.north_rounded,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CashAdjustDialog(ref: ref, isIn: false),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? filterType;
  final ValueChanged<String?> onFilterChange;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.filterType,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        if (count > 0) ...[
          const SizedBox(height: 8),
          _FilterChips(selected: filterType, onSelect: onFilterChange),
        ],
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _FilterChips({required this.selected, required this.onSelect});

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

class _SaleTile extends StatelessWidget {
  final Sale sale;
  final WidgetRef ref;
  const _SaleTile({required this.sale, required this.ref});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (sale.paymentType) {
      case 'kart':
        typeColor = const Color(0xFF4A90D9);
        typeIcon = Icons.credit_card_rounded;
        typeLabel = 'Kart';
        break;
      case 'veresiye':
        typeColor = AppColors.error;
        typeIcon = Icons.person_rounded;
        typeLabel = 'Veresiye';
        break;
      default:
        typeColor = AppColors.success;
        typeIcon = Icons.payments_rounded;
        typeLabel = 'Nakit';
    }

    return Dismissible(
      key: Key(sale.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => ref.read(salesProvider.notifier).deleteSale(sale.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(sale.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (sale.note != null && sale.note!.isNotEmpty)
                    Text(
                      sale.note!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatTime(sale.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz satış yok',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '"Yeni Satış" butonuna bas ve başla',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
