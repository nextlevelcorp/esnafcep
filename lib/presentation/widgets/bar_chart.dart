import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/sale_provider.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DayTotal> data;
  const WeeklyBarChart({super.key, required this.data});

  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (m, d) => d.total > m ? d.total : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son 7 Gün',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          if (maxVal > 0)
            Text(
              'En yüksek: ${CurrencyFormatter.format(maxVal)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final ratio = maxVal > 0 ? d.total / maxVal : 0.0;
                final isToday = _isToday(d.date);
                final dayName = _dayLabels[d.date.weekday - 1];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.total > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _shortAmount(d.total),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isToday ? AppColors.primary : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: ratio > 0 ? (ratio * 80).clamp(4.0, 80.0) : 4,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : d.total > 0
                                    ? AppColors.primary.withOpacity(0.35)
                                    : AppColors.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _shortAmount(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }
}
