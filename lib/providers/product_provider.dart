import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider =
    StateNotifierProvider<ProductsNotifier, List<Product>>((ref) {
  return ProductsNotifier(ref.read(productRepositoryProvider));
});

class ProductsNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repo;

  ProductsNotifier(this._repo) : super(_repo.getAll());

  void add({required String name, required double price, String emoji = '🛍️'}) {
    final p = Product(id: const Uuid().v4(), name: name, price: price, emoji: emoji);
    _repo.add(p);
    state = _repo.getAll();
  }

  void update(Product product) {
    _repo.update(product);
    state = _repo.getAll();
  }

  void delete(String id) {
    _repo.delete(id);
    state = _repo.getAll();
  }
}
