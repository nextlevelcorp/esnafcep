import '../local/hive_service.dart';
import '../models/product.dart';

class ProductRepository {
  List<Product> getAll() => HiveService.productsBox.values.toList();

  void add(Product product) => HiveService.productsBox.put(product.id, product);

  void update(Product product) => product.save();

  void delete(String id) => HiveService.productsBox.delete(id);
}
