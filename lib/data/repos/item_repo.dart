import 'package:uuid/uuid.dart';
import '../interfaces/i_item_repo.dart';
import '../db/app_database.dart';
import '../models/item.dart';

class ItemRepo implements IItemRepo {
  final AppDatabase _db = AppDatabase.instance;
  static const _uuid = Uuid();

  Future<List<Item>> getAllBySeason(String seasonId) async {
    final db = await _db.database;
    final maps = await db.query('items', where: 'season_id = ?', whereArgs: [seasonId], orderBy: 'created_at DESC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<List<Item>> getDeals(String seasonId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT * FROM items
      WHERE season_id = ? AND current_price IS NOT NULL AND status IN ('todo', 'watching')
      ORDER BY current_price - target_price ASC
    ''', [seasonId]);
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<Item> create({
    required String seasonId,
    required String categoryId,
    required String name,
    required int targetPrice,
    int quantity = 1,
    String? store,
    String? link,
    String? note,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = Item(
      id: _uuid.v4(),
      seasonId: seasonId,
      categoryId: categoryId,
      name: name,
      quantity: quantity,
      targetPrice: targetPrice,
      createdAt: now,
      updatedAt: now,
      store: store,
      link: link,
      note: note,
    );
    await db.insert('items', item.toMap());
    return item;
  }

  Future<void> update(Item item) async {
    final db = await _db.database;
    await db.update(
      'items',
      item.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateCurrentPrice(String itemId, int currentPrice) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.transaction((txn) async {
      // 0. Lấy thông tin số lượng của món đồ để tính tổng tiền cho chi tiêu
      final itemData = await txn.query('items', columns: ['quantity', 'season_id'], where: 'id = ?', whereArgs: [itemId]);
      if (itemData.isEmpty) return;
      
      final quantity = itemData.first['quantity'] as int? ?? 1;
      final seasonId = itemData.first['season_id'] as String;
      final totalAmount = currentPrice * quantity;

      // 1. Cập nhật giá trên món đồ
      await txn.update('items', {
        'current_price': currentPrice,
        'current_updated_at': now,
        'updated_at': now,
      }, where: 'id = ?', whereArgs: [itemId]);

      // 2. Nếu món đồ này đã mua, cập nhật luôn số tiền, đơn giá và số lượng trong bảng chi tiêu liên kết
      await txn.update('expenses', {
        'amount': totalAmount,
        'unit_price': currentPrice,
        'quantity': quantity,
        'updated_at': now,
      }, where: 'item_id = ?', whereArgs: [itemId]);

      // 3. Lưu lịch sử giá
      await txn.insert('price_history', {
        'id': _uuid.v4(),
        'item_id': itemId,
        'season_id': seasonId,
        'price': currentPrice,
        'created_at': now,
      });
    });
  }

  Future<void> updateStatus(String itemId, ItemStatus status) async {
    final db = await _db.database;
    await db.update('items', {
      'status': status.value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [itemId]);
  }

  /// Tìm kiếm lịch sử của món đồ này trong các mùa khác dựa trên tên
  Future<List<Map<String, dynamic>>> getHistoricalData(String name, String currentSeasonId) async {
    final db = await _db.database;
    // Join với seasons để lấy tên mùa cho dễ hiểu
    return await db.rawQuery('''
      SELECT i.*, s.name as season_name
      FROM items i
      JOIN seasons s ON i.season_id = s.id
      WHERE i.name LIKE ? AND i.season_id != ?
      ORDER BY i.created_at DESC
    ''', ['%$name%', currentSeasonId]);
  }

  Future<void> delete(String itemId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Unlink expenses
      await txn.update('expenses', {'item_id': null}, where: 'item_id = ?', whereArgs: [itemId]);
      // Delete item (cascade deletes photos + price_history)
      await txn.delete('items', where: 'id = ?', whereArgs: [itemId]);
    });
  }
}
