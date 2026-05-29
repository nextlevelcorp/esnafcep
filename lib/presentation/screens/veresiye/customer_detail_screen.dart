import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/payment.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/sale_provider.dart';
import '../../widgets/big_button.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/add_sale_for_customer_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(customersProvider);
    ref.watch(salesProvider);
    final customer = ref.read(customersProvider.notifier).getCustomer(customerId);
    if (customer == null) return const Scaffold(body: Center(child: Text('Müşteri bulunamadı')));

    final payments = ref.read(customersProvider.notifier).getPayments(customerId);
    final allSales = ref.read(saleRepositoryProvider).getSalesByCustomer(customerId);

    // Merge sales and payments into timeline
    final events = <_Event>[];
    for (final s in allSales) events.add(_Event(type: 'sale', timestamp: s.timestamp, amount: s.amount, sale: s));
    for (final p in payments) events.add(_Event(type: 'payment', timestamp: p.timestamp, amount: p.amount, payment: p));
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          if (customer.phone != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => launchUrl(Uri.parse('tel:${customer.phone}')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(customer.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: customer.totalDebt > 0 ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toplam Borç', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    CurrencyFormatter.format(customer.totalDebt),
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BigButton(
              label: 'ÖDEME AL',
              icon: Icons.payments,
              onPressed: customer.totalDebt > 0
                  ? () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PaymentDialog(ref: ref, customer: customer),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            BigButton(
              label: 'VERESİYE EKLE',
              icon: Icons.add_shopping_cart,
              isPrimary: false,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddSaleForCustomerDialog(ref: ref, customer: customer),
              ),
            ),
            const SizedBox(height: 8),
            BigButton(
              label: 'WHATSAPP GÖNDER',
              icon: Icons.message,
              isPrimary: false,
              color: const Color(0xFF25D366),
              onPressed: customer.phone != null ? () => _sendWhatsApp(customer.name, customer.phone!, customer.totalDebt) : null,
            ),
            const SizedBox(height: 24),
            const Text('İşlem Geçmişi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henüz işlem yok', style: TextStyle(color: AppColors.textSecondary)),
              ))
            else
              ...events.map((e) => _EventTile(event: e)),
          ],
        ),
      ),
    );
  }

  void _sendWhatsApp(String name, String phone, double debt) {
    final formatted = phone.replaceAll(' ', '').replaceAll('-', '')
        .replaceFirst(RegExp(r'^0'), '+90');
    final msg = Uri.encodeComponent(
      '*VERESIYE MAKBUZU*\n\nMüşteri: $name\nToplam Borç: ${CurrencyFormatter.format(debt)}\n\nEsnafCep ile oluşturuldu',
    );
    launchUrl(Uri.parse('https://wa.me/$formatted?text=$msg'), mode: LaunchMode.externalApplication);
  }
}

class _Event {
  final String type;
  final DateTime timestamp;
  final double amount;
  final Sale? sale;
  final Payment? payment;
  _Event({required this.type, required this.timestamp, required this.amount, this.sale, this.payment});
}

class _EventTile extends StatelessWidget {
  final _Event event;
  const _EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isPayment = event.type == 'payment';
    return Container(
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
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isPayment ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPayment ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPayment ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPayment ? 'Ödeme' : 'Veresiye',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPayment ? "-" : "+"}${CurrencyFormatter.format(event.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPayment ? AppColors.success : AppColors.error,
                ),
              ),
              Text(DateFormatter.formatRelative(event.timestamp), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
