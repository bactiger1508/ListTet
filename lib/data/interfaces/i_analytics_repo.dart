abstract class IAnalyticsRepo {
  Future<int> getTotalSpent(String seasonId);
  Future<int> getTotalBudget(String seasonId);
  Future<int> getPlannedTotal(String seasonId);
  Future<Map<String, int>> getStoreAggregates(String seasonId);
  Future<int> getItemCount(String seasonId);
  Future<int> getBoughtCount(String seasonId);
  Future<int> getPendingItemCount(String seasonId);
  Future<List<Map<String, dynamic>>> getRecentExpenses(String seasonId, {int limit = 5});
  Future<Map<String, int>> getLast7DaysSpending(String seasonId);
  Future<Map<String, int>> getSpendingByCategory(String seasonId);
  Future<int> getSpentForCategory(String categoryId);
}
