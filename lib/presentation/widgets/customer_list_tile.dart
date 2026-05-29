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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: customer.totalDebt > 0
            ? Text(
                '${CurrencyFormatter.format(customer.totalDebt)} borç',
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
              )
            : const Text('Borç yok', style: TextStyle(color: AppColors.success)),
        trailing: customer.phone != null
            ? IconButton(
                icon: const Icon(Icons.phone, color: AppColors.primary),
                onPressed: () => _call(customer.phone!),
              )
            : null,
      ),
    );
  }

  void _call(String phone) {
    final uri = Uri.parse('tel:$phone');
    launchUrl(uri);
  }
}
