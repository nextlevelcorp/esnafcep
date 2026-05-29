import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../widgets/big_button.dart';
import 'widgets/add_expense_dialog.dart';

enum ReportPeriod { today, week, month }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.today;

  _DateRange get _range {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return _DateRange(DateTime(now.year, now.month, now.day), now);
      case ReportPeriod.week:
        return _DateRange(now.subtract(const Duration(days: 7)), now);
      case ReportPeriod.month:
        return _DateRange(DateTime(now.year, now.month, 1), now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesNotifier = ref.watch(salesProvider.notifier);
    final expensesNotifier = ref.watch(expensesProvider.notifier);

    final stats = _period == ReportPeriod.today
        ? salesNotifier.todayStats
        : salesNotifier.getStatsByDateRange(_range.start, _range.end);
    final expenses = _period == ReportPeriod.today
        ? expensesNotifier.todayTotal
        : expensesNotifier.getTotalByDateRange(_range.start, _range.end);

    final income = stats['toplam'] ?? 0;
    final net = income - expenses;
    final expenseList = expensesNotifier.getByDateRange(_range.start, _range.end);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Raporlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(selected: _period, onSelect: (p) => setState(() => _period = p)),
            const SizedBox(height: 16),
            _NetCard(income: income, expenses: expenses, net: net),
            const SizedBox(height: 12),
            _BreakdownRow(stats: stats),
            const SizedBox(height: 24),
            const _SectionLabel(text: 'Giderler'),
            const SizedBox(height: 10),
            BigButton(
              label: '+ Yeni Gider Ekle',
              isPrimary: false,
              icon: Icons.add_rounded,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddExpenseDialog(ref: ref),
              ),
            ),
            const SizedBox(height: 12),
            if (expenseList.isEmpty)
              _EmptyExpenses()
            else
              ...expenseList.map((e) => _ExpenseTile(
                category: e.category,
                amount: e.amount,
                note: e.note,
              )),
          ],
        ),
      ),
    );
  }
}

class _DateRange {
  final DateTime start, end;
  _DateRange(this.start, this.end);
}

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelect;
  const _PeriodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Tab(label: 'Bugün', value: ReportPeriod.today, selected: selected, onTap: onSelect),
          _Tab(label: 'Bu Hafta', value: ReportPeriod.week, selected: selected, onTap: onSelect),
          _Tab(label: 'Bu Ay', value: ReportPeriod.month, selected: selected, onTap: onSelect),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final ReportPeriod value, selected;
  final ValueChanged<ReportPeriod> onTap;
  const _Tab({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetCard extends StatelessWidget {
  final double income, expenses, net;
  const _NetCard({required this.income, required this.expenses, required this.net});

  @override
  Widget build(BuildContext context) {
    final isProfit = net >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF0F6E56), const Color(0xFF1D9E75)]
              : [const Color(0xFFE05C3A), const Color(0xFFFF7B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? AppColors.primary : AppColors.error).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                isProfit ? 'Karlı Gün 🎉' : 'Zarardasın',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Net Kar',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(net.abs()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _NetPill(label: 'Gelir', amount: income, icon: Icons.arrow_downward_rounded),
              const SizedBox(width: 8),
              _NetPill(label: 'Gider', amount: expenses, icon: Icons.arrow_upward_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetPill extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  const _NetPill({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  Text(CurrencyFormatter.format(amount),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Map<String, double> stats;
  const _BreakdownRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniCard(label: 'Nakit', amount: stats['nakit'] ?? 0, color: AppColors.success, icon: Icons.payments_rounded),
        const SizedBox(width: 8),
        _MiniCard(label: 'Kart', amount: stats['kart'] ?? 0, color: const Color(0xFF4A90D9), icon: Icons.credit_card_rounded),
        const SizedBox(width: 8),
        _MiniCard(label: 'Veresiye', amount: stats['veresiye'] ?? 0, color: AppColors.error, icon: Icons.person_rounded),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _MiniCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2),
  );
}

class _EmptyExpenses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text('Bu dönemde gider yok', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final String category;
  final double amount;
  final String? note;
  const _ExpenseTile({required this.category, required this.amount, this.note});

  static const _labels = {
    'kira': 'Kira',
    'elektrik': 'Elektrik',
    'mal_alimi': 'Mal Alımı',
    'diger': 'Diğer',
  };
  static const _icons = {
    'kira': Icons.home_rounded,
    'elektrik': Icons.bolt_rounded,
    'mal_alimi': Icons.shopping_bag_rounded,
    'diger': Icons.category_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[category] ?? Icons.category_rounded;
    final label = _labels[category] ?? category;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (note != null && note!.isNotEmpty)
                  Text(note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.error, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
