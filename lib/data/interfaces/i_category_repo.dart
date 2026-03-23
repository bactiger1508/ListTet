import '../models/category.dart';

abstract class ICategoryRepo {
  Future<List<Category>> getBySeason(String seasonId);
  Future<Category> create(String seasonId, String name, {int plannedBudget = 0});
  Future<void> update(Category category);
  Future<void> deleteWithTransfer(String categoryId, String replacementId);
  Future<bool> hasLinkedData(String categoryId);
}
