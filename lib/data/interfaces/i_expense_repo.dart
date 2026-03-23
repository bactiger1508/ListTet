import '../models/expense.dart';

abstract class IExpenseRepo {
  Future<List<Expense>> getAllBySeason(String seasonId);
  Future<Expense> create({
    required String seasonId,
    required String categoryId,
    required String title,
    required int amount,
    String? itemId,
    String? date,
    int? quantity,
    int? unitPrice,
    String? store,
    String? note,
  });
  Future<void> update(String id, {
    required String title,
    required int amount,
    String? date,
    int? quantity,
    int? unitPrice,
    String? store,
    String? note,
  });
  Future<void> delete(String id);
}
