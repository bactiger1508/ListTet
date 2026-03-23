import 'package:flutter/foundation.dart';
import 'package:person_app/data/models/season.dart';
import 'package:person_app/data/models/category.dart' as app_models;
import 'package:person_app/data/interfaces/i_season_repo.dart';
import 'package:person_app/data/repos/season_repo.dart';

class SeasonViewModel extends ChangeNotifier {
  final ISeasonRepo _repo = SeasonRepo();

  List<Season> seasons = [];
  List<app_models.Category> categories = [];
  bool isLoading = false;
  String? activeSeason;

  Future<void> loadSeasons() async {
    isLoading = true;
    notifyListeners();
    seasons = await _repo.getAll();
    if (activeSeason == null && seasons.isNotEmpty) {
      activeSeason = seasons.first.id;
      await loadCategories();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    if (activeSeason == null) return;
    categories = await _repo.getCategoriesOf(activeSeason!);
    notifyListeners();
  }

  Future<void> createSeason(String name, {String? startDate, String? endDate, int? budgetLimit, List<Map<String, dynamic>>? categoriesData}) async {
    final s = await _repo.create(name: name, startDate: startDate, endDate: endDate, budgetLimit: budgetLimit, categoriesData: categoriesData);
    activeSeason = s.id;
    await loadSeasons();
    await loadCategories();
  }

  Future<void> deleteSeason(String id) async {
    await _repo.delete(id);
    if (activeSeason == id) activeSeason = null;
    await loadSeasons();
  }

  Future<void> cloneSeason(String oldId, String newName, {String? startDate, String? endDate}) async {
    final s = await _repo.cloneSeason(oldId, newName, startDate, endDate);
    activeSeason = s.id;
    await loadSeasons();
    await loadCategories();
  }

  Future<void> updateSeason(String id, String name, {String? startDate, String? endDate, int? budgetLimit}) async {
    await _repo.update(id, name: name, startDate: startDate, endDate: endDate, budgetLimit: budgetLimit);
    await loadSeasons();
  }

  void selectSeason(String id) {
    activeSeason = id;
    loadCategories();
    notifyListeners();
  }

  Season? get currentSeason =>
      seasons.where((s) => s.id == activeSeason).firstOrNull;

  String? get firstCategoryId =>
      categories.isNotEmpty ? categories.first.id : null;
}
