import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/payment.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/sale_provider.dart';
import '../../widgets/big_button.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/add_sale_for_customer_dialog.dart';
import 'widgets/edit_customer_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers so screen rebuilds on any change
    final allCustomers = ref.watch(customersProvider);
    final allSales = ref.watch(salesProvider);

    final customer = allCustomers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => allCustomers.isEmpty ? throw Exception() : allCustomers.first,
    );

    // Build timeline: veresiye sales + payments for this customer
    final customerSales = allSales
        .where((s) => s.customerId == customerId && s.paymentType == 'veresiye')
        .toList();
    final payments = ref.read(customerRepositoryProvider).getPaymentsByCustomer(customerId);

    final events = <_Event>[
      for (final s in customerSales)
        _Event(type: 'sale', timestamp: s.timestamp, amount: s.amount, note: s.note),
      for (final p in payments)
        _Event(type: 'payment', timestamp: p.timestamp, amount: p.amount, note: p.note),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Düzenle',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => EditCustomerDialog(ref: ref, customer: customer),
            ),
          ),
          if (customer.phone != null)
            IconButton(
              icon: const Icon(Icons.phone_rounded),
              onPressed: () => launchUrl(Uri.parse('tel:${customer.phone}')),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debt card
            _DebtCard(
              customer: customer,
              onPay: () => _showPayment(context, ref, customer.id),
              onAddDebt: () => _showAddSale(context, ref, customer.id),
              onWhatsApp: customer.phone != null
                  ? () => _sendWhatsApp(customer.name, customer.phone!, customer.totalDebt)
                  : null,
            ),
            const SizedBox(height: 24),
            // Timeline header
            Row(
              children: [
                const Text(
                  'İşlem Geçmişi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                if (events.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                const Spacer(),
                if (events.isNotEmpty)
                  GestureDetector(
                    onTap: () => _shareStatement(customer.name, customer.totalDebt, events),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share_rounded, size: 13, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Hesap Özeti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              _EmptyTimeline()
            else
              ...events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EventTile(event: e),
              )),
          ],
        ),
      ),
    );
  }

  void _showPayment(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentDialog(ref: ref, customerId: id),
    );
  }

  void _showAddSale(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSaleForCustomerDialog(ref: ref, customerId: id),
    );
  }

  void _sendWhatsApp(String name, String phone, double debt) {
    final formatted = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceFirst(RegExp(r'^0'), '+90');
    final businessName = HiveService.settingsBox.get('businessName', defaultValue: '') as String;
    final senderLine = businessName.isNotEmpty ? '\n_${businessName}_' : '\n_EsnafCep_';
    final msg = Uri.encodeComponent(
      'Merhaba $name 👋\n\n'
      'Toplam borcunuz: *${CurrencyFormatter.format(debt)}*\n\n'
      'Ödeme yaptıysanız lütfen bildiriniz.$senderLine',
    );
    launchUrl(
      Uri.parse('https://wa.me/$formatted?text=$msg'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _shareStatement(String name, double totalDebt, List<_Event> events) {
    final businessName = HiveService.settingsBox.get('businessName', defaultValue: '') as String;
    final header = businessName.isNotEmpty ? businessName : 'EsnafCep';
    final lines = <String>[
      '📋 HESAP ÖZETİ — $header',
      '─────────────────────',
      'Müşteri: $name',
      'Tarih: ${DateFormatter.format(DateTime.now())}',
      '─────────────────────',
    ];
    for (final e in events.take(15)) {
      final sign = e.type == 'payment' ? '✅ -' : '🔴 +';
      final label = e.type == 'payment' ? 'Ödeme' : 'Borç';
      final note = e.note != null && e.note!.isNotEmpty ? ' (${e.note})' : '';
      lines.add('$sign${CurrencyFormatter.format(e.amount)}  $label$note  ${DateFormatter.formatShort(e.timestamp)}');
    }
    if (events.length > 15) lines.add('... ve ${events.length - 15} işlem daha');
    lines.addAll([
      '─────────────────────',
      'Toplam Borç: ${CurrencyFormatter.format(totalDebt)}',
    ]);
    Share.share(lines.join('\n'), subject: '$name Hesap Özeti');
  }
}

// ─── Debt Card ────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final dynamic customer;
  final VoidCallback onPay;
  final VoidCallback onAddDebt;
  final VoidCallback? onWhatsApp;

  const _DebtCard({
    required this.customer,
    required this.onPay,
    required this.onAddDebt,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.totalDebt > 0;
    return Column(
      children: [
        // Amount card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasDebt
                  ? [const Color(0xFFE05C3A), const Color(0xFFFF7B5A)]
                  : [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (hasDebt ? AppColors.error : AppColors.primary).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasDebt ? Icons.account_balance_wallet_rounded : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (customer.phone != null)
                        Text(
                          customer.phone,
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                hasDebt ? 'Toplam Borç' : 'Borç Yok',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(customer.totalDebt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: BigButton(
                label: 'Veresiye Ekle',
                icon: Icons.add_rounded,
                isPrimary: false,
                onPressed: onAddDebt,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BigButton(
                label: 'Ödeme Al',
                icon: Icons.payments_rounded,
                color: hasDebt ? AppColors.success : null,
                onPressed: hasDebt ? onPay : null,
              ),
            ),
          ],
        ),
        if (onWhatsApp != null) ...[
          const SizedBox(height: 8),
          BigButton(
            label: 'WhatsApp\'a Gönder',
            icon: Icons.message_rounded,
            color: const Color(0xFF25D366),
            onPressed: onWhatsApp,
          ),
        ],
      ],
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _Event {
  final String type;
  final DateTime timestamp;
  final double amount;
  final String? note;
  _Event({required this.type, required this.timestamp, required this.amount, this.note});
}

class _EventTile extends StatelessWidget {
  final _Event event;
  const _EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isPayment = event.type == 'payment';
    final color = isPayment ? AppColors.success : AppColors.error;
    final icon = isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final label = isPayment ? 'Ödeme' : 'Veresiye';
    final sign = isPayment ? '-' : '+';

    return Container(
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (event.note != null && event.note!.isNotEmpty)
                  Text(event.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${CurrencyFormatter.format(event.amount)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
              ),
              Text(
                DateFormatter.formatRelative(event.timestamp),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.border),
          SizedBox(height: 8),
          Text('Henüz işlem yok', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
