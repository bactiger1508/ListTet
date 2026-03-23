import 'package:uuid/uuid.dart';
import '../interfaces/i_expense_repo.dart';
import '../db/app_database.dart';
import '../models/expense.dart';

class ExpenseRepo implements IExpenseRepo {
  final AppDatabase _db = AppDatabase.instance;
  static const _uuid = Uuid();

  Future<List<Expense>> getAllBySeason(String seasonId) async {
    final db = await _db.database;
    final maps = await db.query('expenses', where: 'season_id = ?', whereArgs: [seasonId], orderBy: 'date DESC, created_at DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

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
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final dateStr = date ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final expense = Expense(
      id: _uuid.v4(),
      seasonId: seasonId,
      categoryId: categoryId,
      itemId: itemId,
      title: title,
      date: dateStr,
      quantity: quantity,
      unitPrice: unitPrice,
      amount: amount,
      store: store,
      note: note,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    await db.insert('expenses', expense.toMap());
    return expense;
  }

  Future<void> update(String id, {
    required String title,
    required int amount,
    String? date,
    int? quantity,
    int? unitPrice,
    String? store,
    String? note,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'expenses',
      {
        'title': title,
        'amount': amount,
        'date': date,
        'quantity': quantity,
        'unit_price': unitPrice,
        'store': store,
        'note': note,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
  Future<Expense?> findByItemId(String itemId) async {
    final db = await _db.database;
    final maps = await db.query('expenses', where: 'item_id = ?', whereArgs: [itemId]);
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  Future<void> deleteByItemId(String itemId) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'item_id = ?', whereArgs: [itemId]);
  }
}
