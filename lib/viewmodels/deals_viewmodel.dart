import 'package:flutter/foundation.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/data/repos/item_repo.dart';

class DealsViewModel extends ChangeNotifier {
  final _repo = ItemRepo();

  List<Item> deals = [];
  bool isLoading = false;
  String activeCategory = 'tất_cả';

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();
    deals = await _repo.getDeals(seasonId);
    isLoading = false;
    notifyListeners();
  }

  List<Item> get filteredDeals {
    if (activeCategory == 'tất_cả') return deals;
    if (activeCategory == 'tốt') return deals.where((d) => d.dealLevel == 'tốt').toList();
    if (activeCategory == 'ổn') return deals.where((d) => d.dealLevel == 'ổn').toList();
    return deals;
  }

  void setCategory(String cat) {
    activeCategory = cat;
    notifyListeners();
  }

  int get totalSavings => deals.where((d) => d.savings > 0).fold(0, (s, d) => s + d.savings);
}
