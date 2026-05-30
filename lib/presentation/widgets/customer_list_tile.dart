import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/customer.dart';

class CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerListTile({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.totalDebt > 0;
    final debtAge = _debtAgeDays();
    final riskColor = _riskColor(hasDebt, debtAge);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDebt && debtAge != null && debtAge > 30
                ? AppColors.error.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            _Avatar(name: customer.name, color: riskColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(hasDebt, debtAge),
                    style: TextStyle(
                      fontSize: 11,
                      color: riskColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(customer.totalDebt),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: hasDebt ? riskColor : AppColors.success,
                  ),
                ),
                if (hasDebt && debtAge != null && debtAge > 7)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _ageBadge(debtAge),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: riskColor),
                    ),
                  ),
              ],
            ),
            if (customer.phone != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${customer.phone}')),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int? _debtAgeDays() {
    if (!customer.totalDebt.isFinite || customer.totalDebt <= 0) return null;
    final ref = customer.lastDebtAt ?? customer.createdAt;
    return DateTime.now().difference(ref).inDays;
  }

  Color _riskColor(bool hasDebt, int? days) {
    if (!hasDebt) return AppColors.success;
    if (days == null || days <= 7) return AppColors.error;
    if (days <= 30) return const Color(0xFFE08A00);
    return AppColors.error;
  }

  String _subtitle(bool hasDebt, int? days) {
    if (!hasDebt) return 'Borç yok ✓';
    if (days == null || days == 0) return 'Bugün borçlandı';
    if (days == 1) return 'Dün borçlandı';
    if (days <= 7) return '$days gündür bekliyor';
    if (days <= 30) return '$days gündür ödeme yok ⚠️';
    return '$days gündür ödeme yok 🔴';
  }

  String _ageBadge(int days) {
    if (days <= 30) return '${days}g';
    return '${days}g!';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
