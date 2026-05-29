import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../local/hive_service.dart';

class ExpenseRepository {
  Box<Expense> get _box => HiveService.expensesBox;

  void addExpense(Expense expense) => _box.put(expense.id, expense);

  void deleteExpense(String id) => _box.delete(id);

  List<Expense> getAllExpenses() =>
      _box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _box.values.where((e) {
      return e.timestamp.isAfter(start) && e.timestamp.isBefore(end);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Expense> getExpensesToday() {
    final today = DateTime.now();
    return _box.values.where((e) {
      return e.timestamp.year == today.year &&
          e.timestamp.month == today.month &&
          e.timestamp.day == today.day;
    }).toList();
  }
}
