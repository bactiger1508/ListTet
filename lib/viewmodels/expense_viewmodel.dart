import 'package:flutter/foundation.dart';
import 'package:person_app/data/models/expense.dart';
import 'package:person_app/data/interfaces/i_expense_repo.dart';
import 'package:person_app/data/repos/expense_repo.dart';

class ExpenseViewModel extends ChangeNotifier {
  final IExpenseRepo _repo = ExpenseRepo();

  List<Expense> expenses = [];
  bool isLoading = false;
  String filterDate = '';

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();
    expenses = await _repo.getAllBySeason(seasonId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense({
    required String seasonId,
    required String categoryId,
    required String title,
    required int amount,
    String? date,
    int? quantity,
    int? unitPrice,
    String? store,
    String? note,
  }) async {
    await _repo.create(
      seasonId: seasonId,
      categoryId: categoryId,
      title: title,
      amount: amount,
      date: date,
      quantity: quantity,
      unitPrice: unitPrice,
      store: store,
      note: note,
    );
    await load(seasonId);
  }

  Future<void> deleteExpense(String id, String seasonId) async {
    await _repo.delete(id);
    await load(seasonId);
  }

  Future<void> updateExpense(String id, {
    required String seasonId,
    required String title,
    required int amount,
    String? date,
    int? quantity,
    int? unitPrice,
    String? store,
    String? note,
  }) async {
    await _repo.update(
      id,
      title: title,
      amount: amount,
      date: date,
      quantity: quantity,
      unitPrice: unitPrice,
      store: store,
      note: note,
    );
    await load(seasonId);
  }

  int get totalAmount => expenses.fold(0, (s, e) => s + e.amount);

  Map<String, List<Expense>> get grouped {
    final result = <String, List<Expense>>{};
    for (final e in expenses) {
      result[e.date] = [...(result[e.date] ?? []), e];
    }
    return result;
  }
}
