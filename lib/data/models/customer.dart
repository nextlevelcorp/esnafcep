import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 1)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  double totalDebt;

  @HiveField(4)
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.totalDebt = 0.0,
    required this.createdAt,
  });
}
