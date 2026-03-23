import 'package:flutter/foundation.dart';
import 'package:person_app/data/models/photo.dart';
import 'package:person_app/data/interfaces/i_photo_repo.dart';
import 'package:person_app/data/repos/photo_repo.dart';

class PhotoViewModel extends ChangeNotifier {
  final IPhotoRepo _repo = PhotoRepo();

  List<Photo> photos = [];
  List<Photo> itemPhotos = [];
  List<Photo> expensePhotos = [];
  bool isLoading = false;

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();
    photos = await _repo.getBySeason(seasonId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadForItem(String itemId) async {
    isLoading = true;
    notifyListeners();
    itemPhotos = await _repo.getByItem(itemId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadForExpense(String expenseId) async {
    isLoading = true;
    notifyListeners();
    expensePhotos = await _repo.getByExpense(expenseId);
    isLoading = false;
    notifyListeners();
  }

  Future<Photo> addPhoto({
    required String sourcePath,
    required String seasonId,
    required String type,
    String? expenseId,
    String? itemId,
    String? note,
  }) async {
    final photo = await _repo.add(
      sourcePath: sourcePath,
      seasonId: seasonId,
      type: type,
      expenseId: expenseId,
      itemId: itemId,
      note: note,
    );
    if (itemId != null) await loadForItem(itemId);
    if (expenseId != null) await loadForExpense(expenseId);
    await load(seasonId);
    return photo;
  }

  List<Photo> get receipts => photos.where((p) => p.type == 'receipt').toList();
  List<Photo> get products => photos.where((p) => p.type == 'product').toList();
}
