import '../models/photo.dart';

abstract class IPhotoRepo {
  Future<List<Photo>> getBySeason(String seasonId);
  Future<List<Photo>> getByExpense(String expenseId);
  Future<List<Photo>> getByItem(String itemId);
  Future<Photo> add({
    required String sourcePath,
    required String seasonId,
    required String type,
    String? expenseId,
    String? itemId,
    String? note,
  });
  Future<void> delete(String photoId);
  Future<void> deleteSeasonPhotos(String seasonId);
}
