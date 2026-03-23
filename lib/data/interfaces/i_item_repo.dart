import '../models/item.dart';

abstract class IItemRepo {
  Future<List<Item>> getAllBySeason(String seasonId);
  Future<List<Item>> getDeals(String seasonId);
  Future<Item> create({
    required String seasonId,
    required String categoryId,
    required String name,
    required int targetPrice,
    int quantity = 1,
    String? store,
    String? link,
    String? note,
  });
  Future<void> update(Item item);
  Future<void> updateCurrentPrice(String itemId, int currentPrice);
  Future<void> updateStatus(String itemId, ItemStatus status);
  Future<List<Map<String, dynamic>>> getHistoricalData(String name, String currentSeasonId);
  Future<void> delete(String itemId);
}
