import '../models/season.dart';
import '../models/category.dart';

abstract class ISeasonRepo {
  Future<List<Season>> getAll();
  Future<Season?> getById(String id);
  Future<List<Category>> getCategoriesOf(String seasonId);
  Future<Season> create({required String name, String? startDate, String? endDate, int? budgetLimit});
  Future<void> update(String id, {required String name, String? startDate, String? endDate, int? budgetLimit});
  Future<void> delete(String seasonId);
}
