import 'package:hive/hive.dart';
import '../models/sale.dart';
import '../local/hive_service.dart';

class SaleRepository {
  Box<Sale> get _box => HiveService.salesBox;

  void addSale(Sale sale) => _box.put(sale.id, sale);

  void deleteSale(String id) => _box.delete(id);

  List<Sale> getAllSales() =>
      _box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<Sale> getSalesToday() {
    final today = DateTime.now();
    return _box.values.where((s) {
      return s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Sale> getSalesByDateRange(DateTime start, DateTime end) {
    return _box.values.where((s) {
      return s.timestamp.isAfter(start) && s.timestamp.isBefore(end);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Sale> getSalesByCustomer(String customerId) {
    return _box.values.where((s) => s.customerId == customerId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
