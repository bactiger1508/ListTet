import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:person_app/data/models/category.dart';
import 'package:person_app/data/interfaces/i_category_repo.dart';
import 'package:person_app/data/interfaces/i_analytics_repo.dart';
import 'package:person_app/data/repos/category_repo.dart';
import 'package:person_app/data/repos/analytics_repo.dart';

class CategoryViewModel extends ChangeNotifier {
  final ICategoryRepo _repo = CategoryRepo();
  final IAnalyticsRepo _analytics = AnalyticsRepo();

  List<Category> categories = [];
  Map<String, int> spentByCategory = {}; // categoryId -> totalSpent
  bool isLoading = false;

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();

    categories = await _repo.getBySeason(seasonId);

    // Load spending for each category
    spentByCategory = {};
    for (final cat in categories) {
      spentByCategory[cat.id] = await _analytics.getSpentForCategory(cat.id);
    }

    isLoading = false;
    notifyListeners();
  }

  int getSpent(String categoryId) => spentByCategory[categoryId] ?? 0;

  double getProgress(Category cat) {
    if (cat.plannedBudget <= 0) return 0;
    return (getSpent(cat.id) / cat.plannedBudget).clamp(0.0, 1.5);
  }

  bool isOverBudget(Category cat) {
    if (cat.plannedBudget <= 0) return false;
    return getSpent(cat.id) > cat.plannedBudget;
  }

  int get totalPlannedBudget => categories.fold<int>(0, (s, c) => s + c.plannedBudget);
  int get totalSpent => spentByCategory.values.fold<int>(0, (s, v) => s + v);

  Future<void> updateBudget(Category cat, int newBudget) async {
    await _repo.update(cat.copyWith(
      plannedBudget: newBudget,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    final idx = categories.indexWhere((c) => c.id == cat.id);
    if (idx != -1) {
      categories[idx] = cat.copyWith(plannedBudget: newBudget);
    }
    notifyListeners();
  }

  Future<void> addCategory(String seasonId, String name, {int budget = 0}) async {
    await _repo.create(seasonId, name, plannedBudget: budget);
    await load(seasonId);
  }

  Future<void> deleteCategory(String categoryId, String replacementId, String seasonId) async {
    await _repo.deleteWithTransfer(categoryId, replacementId);
    await load(seasonId);
  }
}
