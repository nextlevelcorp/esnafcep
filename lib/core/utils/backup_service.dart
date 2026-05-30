import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../../data/local/hive_service.dart';

class BackupService {
  static Future<void> exportData() async {
    final sales = HiveService.salesBox.values.map((s) => {
      'id': s.id,
      'amount': s.amount,
      'paymentType': s.paymentType,
      'customerId': s.customerId,
      'timestamp': s.timestamp.toIso8601String(),
      'note': s.note,
    }).toList();

    final customers = HiveService.customersBox.values.map((c) => {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'totalDebt': c.totalDebt,
      'createdAt': c.createdAt.toIso8601String(),
      'lastDebtAt': c.lastDebtAt?.toIso8601String(),
    }).toList();

    final payments = HiveService.paymentsBox.values.map((p) => {
      'id': p.id,
      'customerId': p.customerId,
      'amount': p.amount,
      'timestamp': p.timestamp.toIso8601String(),
      'note': p.note,
    }).toList();

    final expenses = HiveService.expensesBox.values.map((e) => {
      'id': e.id,
      'amount': e.amount,
      'category': e.category,
      'timestamp': e.timestamp.toIso8601String(),
      'note': e.note,
    }).toList();

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'sales': sales,
      'customers': customers,
      'payments': payments,
      'expenses': expenses,
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final date = DateTime.now();
    final filename = 'esnafcep_yedek_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'EsnafCep Yedek - $filename',
      text: 'EsnafCep verilerinizin yedeği.',
    );
  }

  static Map<String, dynamic> _parseJson(String content) {
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static String buildSummary() {
    final salesCount = HiveService.salesBox.length;
    final customersCount = HiveService.customersBox.length;
    final paymentsCount = HiveService.paymentsBox.length;
    final expensesCount = HiveService.expensesBox.length;
    return '$customersCount müşteri, $salesCount satış, $paymentsCount ödeme, $expensesCount gider';
  }
}
