import 'package:flutter/foundation.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/data/interfaces/i_item_repo.dart';
import 'package:person_app/data/interfaces/i_expense_repo.dart';
import 'package:person_app/data/repos/item_repo.dart';
import 'package:person_app/data/repos/expense_repo.dart';
import 'package:person_app/data/interfaces/i_photo_repo.dart';
import 'package:person_app/data/repos/photo_repo.dart';

class ItemViewModel extends ChangeNotifier {
  final IItemRepo _itemRepo = ItemRepo();
  final IExpenseRepo _expenseRepo = ExpenseRepo();
  final IPhotoRepo _photoRepo = PhotoRepo();

  List<Item> items = [];
  List<Item> deals = [];
  bool isLoading = false;
  ItemStatus? filterStatus;
  String searchQuery = '';

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();
    items = await _itemRepo.getAllBySeason(seasonId);
    deals = await _itemRepo.getDeals(seasonId);
    isLoading = false;
    notifyListeners();
  }

  List<Item> get filteredItems {
    var list = items;
    if (filterStatus != null) list = list.where((i) => i.status == filterStatus).toList();
    if (searchQuery.isNotEmpty) {
      final q = _removeDiacritics(searchQuery.toLowerCase());
      list = list.where((i) => _removeDiacritics(i.name.toLowerCase()).contains(q)).toList();
    }
    return list;
  }

  static String _removeDiacritics(String s) {
    const vn = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const en = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = s;
    for (int i = 0; i < vn.length; i++) {
      result = result.replaceAll(vn[i], en[i]);
    }
    return result;
  }

  Future<Item> addItem({
    required String seasonId,
    required String categoryId,
    required String name,
    required int targetPrice,
    int quantity = 1,
    String? store,
    String? note,
  }) async {
    final item = await _itemRepo.create(
      seasonId: seasonId,
      categoryId: categoryId,
      name: name,
      targetPrice: targetPrice,
      quantity: quantity,
      store: store,
      note: note,
    );
    await load(seasonId);
    return item;
  }

  Future<void> updateStatus(String id, ItemStatus status, String seasonId) async {
    await _itemRepo.updateStatus(id, status);
    await load(seasonId);
  }

  Future<void> updatePrice(String id, int price, String seasonId) async {
    await _itemRepo.updateCurrentPrice(id, price);
    await load(seasonId);
  }

  Future<void> buyNow({
    required Item item,
    required String categoryId,
    required int amount, // This is unit price entered by user
  }) async {
    final totalAmount = amount * item.quantity;
    
    // 1. Tạo chi tiêu
    await _expenseRepo.create(
      seasonId: item.seasonId,
      categoryId: categoryId,
      itemId: item.id,
      title: item.name,
      amount: totalAmount,
      unitPrice: amount,
      quantity: item.quantity,
    );
    // 2. Cập nhật giá thực tế trên món đồ để so sánh
    await _itemRepo.updateCurrentPrice(item.id, amount);
    // 3. Đổi trạng thái sang Đã mua
    await _itemRepo.updateStatus(item.id, ItemStatus.bought);
    
    await load(item.seasonId);
  }

  Future<void> updateItemImage(Item item, String imagePath) async {
    await _itemRepo.update(item.copyWith(imagePath: imagePath));
    await load(item.seasonId);
  }

  Future<void> deleteItem(String id, String seasonId) async {
    await _itemRepo.delete(id);
    await load(seasonId);
  }

  void setFilter(ItemStatus? status) {
    filterStatus = status;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  List<Item> historicalItems = [];

  Future<void> loadHistoricalData(String name, String currentSeasonId) async {
    isLoading = true;
    notifyListeners();
    final maps = await _itemRepo.getHistoricalData(name, currentSeasonId);
    historicalItems = maps.map((m) => Item.fromMap(m)).toList();
    isLoading = false;
    notifyListeners();
  }
}
