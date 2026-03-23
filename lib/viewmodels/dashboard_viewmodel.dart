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

  String? _currentSeasonName;
  String? _startDate;
  String? _endDate;

  Future<void> load(String seasonId, {String? seasonName, String? startDate, String? endDate}) async {
    isLoading = true;
    notifyListeners();

    _currentSeasonName = seasonName;
    _startDate = startDate;
    _endDate = endDate;
    
    // Actually, DashboardViewModel doesn't store the season name yet. I'll add a property.

    totalSpent = await _analytics.getTotalSpent(seasonId);
    totalBudget = await _analytics.getTotalBudget(seasonId);
    plannedTotal = await _analytics.getPlannedTotal(seasonId);
    _actualSavings = await _analytics.getSavings(seasonId);
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


  int _actualSavings = 0;

  /// Chênh lệch giữa Giá dự kiến và Thực chi cho các món đã mua
  /// (Dương là tiết kiệm được, Âm là chi vượt kế hoạch)
  int get budgetVariance => _actualSavings;

  /// Ngân sách còn lại (Tiền mặt thực tế so với giới hạn)
  int get remainingBudget => totalBudget - totalSpent;

  /// Chênh lệch giữa Ngân sách giới hạn và Tổng dự kiến mua (Cho kế hoạch tương lai)
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

  void setSeasonName(String? name) {
    if (_currentSeasonName == name) return;
    _currentSeasonName = name;
    notifyListeners();
  }

  Map<String, dynamic> get seasonDateStatus {
    if (_startDate == null) return {'type': 'none', 'days': 0};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final sd = DateTime.tryParse(_startDate!);
    if (sd == null) return {'type': 'none', 'days': 0};
    
    final ed = _endDate != null ? DateTime.tryParse(_endDate!) : sd;
    if (ed == null) return {'type': 'none', 'days': 0};

    if (today.isBefore(sd)) {
      final diff = sd.difference(today).inDays;
      return {'type': 'before', 'days': diff};
    } else if (!today.isAfter(ed)) {
      return {'type': 'during', 'days': 0};
    } else {
      final diff = today.difference(ed).inDays;
      return {'type': 'after', 'days': diff};
    }
  }
}
