import 'package:uuid/uuid.dart';
import '../interfaces/i_season_repo.dart';
import '../db/app_database.dart';
import '../models/season.dart';
import '../models/category.dart';
import '../services/file_storage_service.dart';

class SeasonRepo implements ISeasonRepo {
  final AppDatabase _db = AppDatabase.instance;
  final FileStorageService _fileService = FileStorageService();
  static const _uuid = Uuid();

  Future<List<Season>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('seasons', orderBy: 'created_at DESC');
    return maps.map((m) => Season.fromMap(m)).toList();
  }

  Future<Season?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('seasons', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Season.fromMap(maps.first) : null;
  }

  Future<List<Category>> getCategoriesOf(String seasonId) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'season_id = ?', whereArgs: [seasonId], orderBy: 'sort_order');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Season> create({required String name, String? startDate, String? endDate, int? budgetLimit}) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final season = Season(
      id: _uuid.v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      budgetLimit: budgetLimit,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('seasons', season.toMap());

    // Auto-create 6 default categories
    final defaultCategories = [
      {'name': 'Thực phẩm', 'icon': 'restaurant', 'color': '0xFF4CAF50'},
      {'name': 'Đồ uống', 'icon': 'local_bar', 'color': '0xFF2196F3'},
      {'name': 'Quần áo', 'icon': 'checkroom', 'color': '0xFFFF9800'},
      {'name': 'Trang trí', 'icon': 'home', 'color': '0xFFE91E63'},
      {'name': 'Quà tặng', 'icon': 'featured_video', 'color': '0xFF9C27B0'},
      {'name': 'Khác', 'icon': 'more_horiz', 'color': '0xFF607D8B'},
    ];

    for (int i = 0; i < defaultCategories.length; i++) {
      final cat = defaultCategories[i];
      await db.insert('categories', {
        'id': _uuid.v4(),
        'season_id': season.id,
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }

    return season;
  }

  Future<void> update(String id, {required String name, String? startDate, String? endDate, int? budgetLimit}) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'seasons',
      {'name': name, 'start_date': startDate, 'end_date': endDate, 'budget_limit': budgetLimit, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String seasonId) async {
    final db = await _db.database;
    await _fileService.deleteSeasonPhotos(seasonId);
    await db.delete('seasons', where: 'id = ?', whereArgs: [seasonId]);
  }
}
