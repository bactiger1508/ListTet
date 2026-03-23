import 'package:uuid/uuid.dart';
import '../interfaces/i_category_repo.dart';
import '../db/app_database.dart';
import '../models/category.dart';

class CategoryRepo implements ICategoryRepo {
  final AppDatabase _db = AppDatabase.instance;
  static const _uuid = Uuid();

  Future<List<Category>> getBySeason(String seasonId) async {
    final db = await _db.database;
    final maps = await db.query(
      'categories',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category> create(String seasonId, String name, {int plannedBudget = 0}) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cat = Category(
      id: _uuid.v4(),
      seasonId: seasonId,
      name: name,
      plannedBudget: plannedBudget,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('categories', cat.toMap());
    return cat;
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete category, transferring linked items/expenses to [replacementId]
  Future<void> deleteWithTransfer(String categoryId, String replacementId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('items', {'category_id': replacementId}, where: 'category_id = ?', whereArgs: [categoryId]);
      await txn.update('expenses', {'category_id': replacementId}, where: 'category_id = ?', whereArgs: [categoryId]);
      await txn.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
    });
  }

  Future<bool> hasLinkedData(String categoryId) async {
    final db = await _db.database;
    final items = await db.rawQuery('SELECT COUNT(*) AS cnt FROM items WHERE category_id = ?', [categoryId]);
    final expenses = await db.rawQuery('SELECT COUNT(*) AS cnt FROM expenses WHERE category_id = ?', [categoryId]);
    return ((items.first['cnt'] as int?) ?? 0) > 0 || ((expenses.first['cnt'] as int?) ?? 0) > 0;
  }
}
