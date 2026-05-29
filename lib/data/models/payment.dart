import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? note;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.timestamp,
    this.note,
  });
}
