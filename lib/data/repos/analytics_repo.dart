import '../interfaces/i_analytics_repo.dart';
import '../db/app_database.dart';

class AnalyticsRepo implements IAnalyticsRepo {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> getTotalSpent(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE season_id = ?',
      [seasonId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalBudget(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(planned_budget), 0) as total FROM categories WHERE season_id = ?',
      [seasonId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Tổng giá trị dự kiến của tất cả món đồ (target_price * quantity)
  Future<int> getPlannedTotal(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(target_price * quantity), 0) as total FROM items WHERE season_id = ? AND status != "dropped"',
      [seasonId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Thống kê theo cửa hàng để tối ưu lộ trình mua sắm
  Future<Map<String, int>> getStoreAggregates(String seasonId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT store, COUNT(*) as item_count, SUM(target_price * quantity) as total_value
      FROM items
      WHERE season_id = ? AND status IN ('todo', 'watching') AND store IS NOT NULL
      GROUP BY store
      ORDER BY total_value DESC
    ''', [seasonId]);
    
    final result = <String, int>{};
    for (final row in rows) {
      result[row['store'] as String] = (row['total_value'] as int?) ?? 0;
    }
    return result;
  }

  Future<int> getItemCount(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM items WHERE season_id = ?',
      [seasonId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getBoughtCount(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM items WHERE season_id = ? AND status = 'bought'",
      [seasonId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getPendingItemCount(String seasonId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM items WHERE season_id = ? AND status IN ('todo', 'watching')",
      [seasonId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentExpenses(String seasonId, {int limit = 5}) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT e.*, i.image_path as item_image_path
      FROM expenses e
      LEFT JOIN items i ON e.item_id = i.id
      WHERE e.season_id = ?
      ORDER BY e.created_at DESC
      LIMIT ?
    ''', [seasonId, limit]);
  }

  Future<Map<String, int>> getLast7DaysSpending(String seasonId) async {
    final db = await _db.database;
    final result = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE season_id = ? AND date = ?',
        [seasonId, dateStr],
      );
      result[dateStr] = (rows.first['total'] as int?) ?? 0;
    }
    return result;
  }

  /// Chi tiêu theo từng hạng mục (cho Pie Chart)
  Future<Map<String, int>> getSpendingByCategory(String seasonId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT c.name, COALESCE(SUM(e.amount), 0) as total
      FROM categories c
      LEFT JOIN expenses e ON e.category_id = c.id AND e.season_id = ?
      WHERE c.season_id = ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [seasonId, seasonId]);
    final result = <String, int>{};
    for (final row in rows) {
      result[row['name'] as String] = (row['total'] as int?) ?? 0;
    }
    return result;
  }

  /// Tổng chi tiêu cho 1 hạng mục cụ thể
  Future<int> getSpentForCategory(String categoryId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
