import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 0)
class Sale extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String paymentType; // 'nakit', 'kart', 'veresiye'

  @HiveField(3)
  final String? customerId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? note;

  Sale({
    required this.id,
    required this.amount,
    required this.paymentType,
    this.customerId,
    required this.timestamp,
    this.note,
  });
}
