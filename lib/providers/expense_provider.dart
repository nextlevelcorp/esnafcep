import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref.read(expenseRepositoryProvider));
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repo;

  ExpensesNotifier(this._repo) : super(_repo.getAllExpenses());

  void addExpense({
    required double amount,
    required String category,
    String? note,
    String? photoPath,
  }) {
    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      timestamp: DateTime.now(),
      note: note,
      photoPath: photoPath,
    );
    _repo.addExpense(expense);
    state = _repo.getAllExpenses();
  }

  void deleteExpense(String id) {
    _repo.deleteExpense(id);
    state = _repo.getAllExpenses();
  }

  double get todayTotal =>
      _repo.getExpensesToday().fold(0, (sum, e) => sum + e.amount);

  double getTotalByDateRange(DateTime start, DateTime end) =>
      _repo.getExpensesByDateRange(start, end).fold(0, (sum, e) => sum + e.amount);

  List<Expense> getByDateRange(DateTime start, DateTime end) =>
      _repo.getExpensesByDateRange(start, end);
}
