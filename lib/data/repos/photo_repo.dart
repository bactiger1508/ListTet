import 'package:uuid/uuid.dart';
import '../interfaces/i_photo_repo.dart';
import '../db/app_database.dart';
import '../models/photo.dart';
import '../services/file_storage_service.dart';

class PhotoRepo implements IPhotoRepo {
  final AppDatabase _db = AppDatabase.instance;
  final FileStorageService _fileService = FileStorageService();
  static const _uuid = Uuid();

  Future<List<Photo>> getBySeason(String seasonId) async {
    final db = await _db.database;
    final maps = await db.query('photos', where: 'season_id = ?', whereArgs: [seasonId], orderBy: 'created_at DESC');
    return maps.map((m) => Photo.fromMap(m)).toList();
  }

  Future<List<Photo>> getByExpense(String expenseId) async {
    final db = await _db.database;
    final maps = await db.query('photos', where: 'expense_id = ?', whereArgs: [expenseId], orderBy: 'created_at DESC');
    return maps.map((m) => Photo.fromMap(m)).toList();
  }

  Future<List<Photo>> getByItem(String itemId) async {
    final db = await _db.database;
    final maps = await db.query('photos', where: 'item_id = ?', whereArgs: [itemId], orderBy: 'created_at DESC');
    return maps.map((m) => Photo.fromMap(m)).toList();
  }

  /// Add a photo: copy file to permanent storage + insert DB record
  Future<Photo> add({
    required String sourcePath,
    required String seasonId,
    required String type,
    String? expenseId,
    String? itemId,
    String? note,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final ext = sourcePath.split('.').last;
    final fileName = '$id.$ext';

    // Copy file to permanent location
    final localPath = await _fileService.savePhoto(
      sourcePath: sourcePath,
      seasonId: seasonId,
      type: type,
      fileName: fileName,
    );

    final photo = Photo(
      id: id,
      seasonId: seasonId,
      type: type,
      localPath: localPath,
      expenseId: expenseId,
      itemId: itemId,
      note: note,
      createdAt: now,
    );

    await db.insert('photos', photo.toMap());
    return photo;
  }

  /// Delete a photo: remove file + delete DB record
  Future<void> delete(String photoId) async {
    final db = await _db.database;
    final maps = await db.query('photos', where: 'id = ?', whereArgs: [photoId]);
    if (maps.isNotEmpty) {
      final photo = Photo.fromMap(maps.first);
      await _fileService.deletePhoto(photo.localPath);
      await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
    }
  }

  /// Delete all photos for a season (files + records)
  Future<void> deleteSeasonPhotos(String seasonId) async {
    final db = await _db.database;
    await _fileService.deleteSeasonPhotos(seasonId);
    await db.delete('photos', where: 'season_id = ?', whereArgs: [seasonId]);
  }
}
