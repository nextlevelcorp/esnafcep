import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category; // 'kira', 'elektrik', 'mal_alimi', 'diger'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? photoPath;

  @HiveField(5)
  final String? note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.photoPath,
    this.note,
  });
}
