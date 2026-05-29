import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/sale.dart';
import '../data/repositories/sale_repository.dart';

final saleRepositoryProvider = Provider((ref) => SaleRepository());

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  return SalesNotifier(ref.read(saleRepositoryProvider));
});

class SalesNotifier extends StateNotifier<List<Sale>> {
  final SaleRepository _repo;

  SalesNotifier(this._repo) : super(_repo.getAllSales());

  void addSale({
    required double amount,
    required String paymentType,
    String? customerId,
    String? note,
  }) {
    final sale = Sale(
      id: const Uuid().v4(),
      amount: amount,
      paymentType: paymentType,
      customerId: customerId,
      timestamp: DateTime.now(),
      note: note,
    );
    _repo.addSale(sale);
    state = _repo.getAllSales();
  }

  void deleteSale(String id) {
    _repo.deleteSale(id);
    state = _repo.getAllSales();
  }

  List<Sale> get todaySales => _repo.getSalesToday();

  Map<String, double> get todayStats {
    final sales = todaySales;
    double nakit = 0, kart = 0, veresiye = 0;
    for (final s in sales) {
      if (s.paymentType == 'nakit') nakit += s.amount;
      else if (s.paymentType == 'kart') kart += s.amount;
      else if (s.paymentType == 'veresiye') veresiye += s.amount;
    }
    return {
      'nakit': nakit,
      'kart': kart,
      'veresiye': veresiye,
      'toplam': nakit + kart + veresiye,
    };
  }

  Map<String, double> getStatsByDateRange(DateTime start, DateTime end) {
    final sales = _repo.getSalesByDateRange(start, end);
    double nakit = 0, kart = 0, veresiye = 0;
    for (final s in sales) {
      if (s.paymentType == 'nakit') nakit += s.amount;
      else if (s.paymentType == 'kart') kart += s.amount;
      else if (s.paymentType == 'veresiye') veresiye += s.amount;
    }
    return {
      'nakit': nakit,
      'kart': kart,
      'veresiye': veresiye,
      'toplam': nakit + kart + veresiye,
    };
  }
}
