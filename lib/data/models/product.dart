import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 4)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String emoji;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.emoji = '🛍️',
  });
}
