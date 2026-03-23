import 'package:flutter/foundation.dart';
import 'package:person_app/data/interfaces/i_analytics_repo.dart';
import 'package:person_app/data/repos/analytics_repo.dart';
import 'package:person_app/data/models/expense.dart';

class DashboardViewModel extends ChangeNotifier {
  final IAnalyticsRepo _analytics = AnalyticsRepo();

  int totalSpent = 0;
  int totalBudget = 0;
  int plannedTotal = 0; // Tổng giá mục tiêu của tất cả item
  int totalItems = 0;
  int pendingItems = 0;
  Map<String, int> last7Days = {};
  Map<String, int> categorySpending = {};
  Map<String, int> storeAggregates = {};
  List<Expense> recentExpenses = [];
  bool isLoading = false;

  Future<void> load(String seasonId) async {
    isLoading = true;
    notifyListeners();

    _currentSeasonName = ''; // To be updated if needed or via a dedicated property
    // We might need the season object here, but we can try to extract from name if we have access to it or pass it.
    // For now, I'll assume we can get the name from the repo or pass it.
    // Actually, DashboardViewModel doesn't store the season name yet. I'll add a property.

    totalSpent = await _analytics.getTotalSpent(seasonId);
    totalBudget = await _analytics.getTotalBudget(seasonId);
    plannedTotal = await _analytics.getPlannedTotal(seasonId);
    totalItems = await _analytics.getItemCount(seasonId);
    pendingItems = await _analytics.getPendingItemCount(seasonId);
    last7Days = await _analytics.getLast7DaysSpending(seasonId);
    categorySpending = await _analytics.getSpendingByCategory(seasonId);
    storeAggregates = await _analytics.getStoreAggregates(seasonId);
    
    final rows = await _analytics.getRecentExpenses(seasonId, limit: 5);
    recentExpenses = rows.map(Expense.fromMap).toList();

    isLoading = false;
    notifyListeners();
  }

  /// Ngân sách còn lại (Tiền mặt thực tế)
  int get remainingBudget => totalBudget - totalSpent;

  /// Chênh lệch giữa Số tiền đã thực chi và Tổng cần chi dự kiến
  /// (Dương là tiết kiệm được so với kế hoạch, Âm là chi vượt kế hoạch)
  int get budgetVariance => plannedTotal - totalSpent;

  /// Chênh lệch giữa Ngân sách giới hạn và Tổng dự kiến mua
  int get planningBalance => totalBudget - plannedTotal;

  /// Trình trạng sức khỏe tài chính
  String get financialHealthStatus {
    if (totalBudget == 0) return 'trung_tính';
    if (planningBalance < 0) return 'nguy_hiểm'; // List đồ muốn mua vượt quá túi tiền
    if (totalSpent > totalBudget) return 'tới_hạn'; // Thực tế đã tiêu lố
    return 'tốt';
  }

  String _formatVND(int amount) {
    if (amount.abs() >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}tr ₫';
    if (amount.abs() >= 1000) return '${(amount / 1000).round()}k ₫';
    return '$amount ₫';
  }

  String get totalSpentFormatted => _formatVND(totalSpent);
  String get totalBudgetFormatted => _formatVND(totalBudget);
  String get remainingBudgetFormatted => _formatVND(remainingBudget);
  String get budgetVarianceFormatted => _formatVND(budgetVariance);

  /// Gợi ý thông minh khi vượt ngân sách
  List<String> get budgetSuggestions {
    final suggestions = <String>[];
    if (planningBalance < 0) {
      suggestions.add('Bạn đang muốn mua vượt quá ngân sách ${_formatVND(planningBalance.abs())}.');
      suggestions.add('Cân nhắc chuyển các món "Ưu tiên thấp" sang trạng thái "Đã bỏ" hoặc "Đang theo dõi".');
    }
    if (totalSpent > totalBudget && totalBudget > 0) {
      suggestions.add('Cảnh báo: Bạn đã tiêu quá tay thực tế! Hãy kiểm tra lại các khoản chi không thiết yếu.');
    }
    return suggestions;
  }

  String? _currentSeasonName;
  void setSeasonName(String? name) {
    _currentSeasonName = name;
    notifyListeners();
  }

  int get daysUntilTet {
    if (_currentSeasonName == null) return 0;
    
    // Extract year from name (e.g. "Tết 2028" -> 2028)
    final yearMatch = RegExp(r'\d{4}').firstMatch(_currentSeasonName!);
    final year = yearMatch != null ? int.parse(yearMatch.group(0)!) : DateTime.now().year;

    // Tet dates lookup (Jan 1 Lunar)
    final Map<int, DateTime> tetDates = {
      2024: DateTime(2024, 2, 10),
      2025: DateTime(2025, 1, 29),
      2026: DateTime(2026, 2, 17),
      2027: DateTime(2027, 2, 6),
      2028: DateTime(2028, 1, 26),
      2029: DateTime(2029, 2, 13),
      2030: DateTime(2030, 2, 3),
    };

    final tetDate = tetDates[year] ?? DateTime(year, 1, 20); // Fallback
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = tetDate.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }
}
