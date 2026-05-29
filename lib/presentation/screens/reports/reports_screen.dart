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

  DateRange get _range {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return DateRange(DateTime(now.year, now.month, now.day), now);
      case ReportPeriod.week:
        return DateRange(now.subtract(const Duration(days: 7)), now);
      case ReportPeriod.month:
        return DateRange(DateTime(now.year, now.month, 1), now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesNotifier = ref.watch(salesProvider.notifier);
    final expensesNotifier = ref.watch(expensesProvider.notifier);

    Map<String, double> stats;
    double expenses;

    if (_period == ReportPeriod.today) {
      stats = salesNotifier.todayStats;
      expenses = expensesNotifier.todayTotal;
    } else {
      stats = salesNotifier.getStatsByDateRange(_range.start, _range.end);
      expenses = expensesNotifier.getTotalByDateRange(_range.start, _range.end);
    }

    final income = stats['toplam'] ?? 0;
    final net = income - expenses;
    final expenseList = expensesNotifier.getByDateRange(_range.start, _range.end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PeriodSelector(selected: _period, onSelect: (p) => setState(() => _period = p)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Gelir', amount: income, color: AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Gider', amount: expenses, color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Net Kar',
              amount: net,
              color: net >= 0 ? AppColors.success : AppColors.error,
              large: true,
            ),
            const SizedBox(height: 12),
            _BreakdownCard(stats: stats),
            const SizedBox(height: 16),
            BigButton(
              label: '+ YENİ GİDER',
              icon: Icons.add,
              isPrimary: false,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddExpenseDialog(ref: ref),
              ),
            ),
            const SizedBox(height: 16),
            if (expenseList.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Giderler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ...expenseList.map((e) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_categoryLabel(e.category), style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (e.note != null) Text(e.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    )),
                    Text(CurrencyFormatter.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'kira': return 'Kira';
      case 'elektrik': return 'Elektrik';
      case 'mal_alimi': return 'Mal Alımı';
      default: return 'Diğer';
    }
  }
}

class DateRange {
  final DateTime start, end;
  DateRange(this.start, this.end);
}

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelect;
  const _PeriodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeriodBtn(label: 'Bugün', value: ReportPeriod.today, selected: selected, onTap: onSelect),
        const SizedBox(width: 8),
        _PeriodBtn(label: 'Bu Hafta', value: ReportPeriod.week, selected: selected, onTap: onSelect),
        const SizedBox(width: 8),
        _PeriodBtn(label: 'Bu Ay', value: ReportPeriod.month, selected: selected, onTap: onSelect),
      ],
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final ReportPeriod value, selected;
  final ValueChanged<ReportPeriod> onTap;
  const _PeriodBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool large;
  const _StatCard({required this.label, required this.amount, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(color: color, fontSize: large ? 32 : 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final Map<String, double> stats;
  const _BreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gelir Dağılımı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          _Row(label: 'Nakit', amount: stats['nakit'] ?? 0, color: AppColors.success),
          _Row(label: 'Kart', amount: stats['kart'] ?? 0, color: Colors.blue),
          _Row(label: 'Veresiye', amount: stats['veresiye'] ?? 0, color: AppColors.error),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _Row({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(CurrencyFormatter.format(amount), style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
