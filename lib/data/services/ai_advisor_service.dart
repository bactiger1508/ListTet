import 'package:flutter/material.dart';

class AIAdvisorResult {
  final double budgetHealth; // 0.0 to 1.0
  final String advice;
  final String subAdvice;
  final Color statusColor;

  AIAdvisorResult({
    required this.budgetHealth,
    required this.advice,
    required this.subAdvice,
    required this.statusColor,
  });
}

class AIAdvisorService {
  static AIAdvisorResult analyze({
    required int totalSpent,
    required int plannedTotal,
    required int budgetLimit,
  }) {
    // 1. Calculate health based on Budget Limit (Category level)
    double health = 1.0;
    if (budgetLimit > 0) {
      health = (budgetLimit - totalSpent) / budgetLimit;
    }
    
    // Clamp to 0.0 - 1.0
    health = health.clamp(0.0, 1.0);

    String advice = 'Mọi thứ đang rất tuyệt!';
    String subAdvice = 'Bạn đang quản lý chi tiêu rất khoa học.';
    Color color = Colors.greenAccent;

    if (health < 0.2) {
      advice = 'Báo động: Ngân sách sắp cạn!';
      subAdvice = 'Hãy tạm dừng các khoản chi chưa thực sự cấp thiết.';
      color = Colors.redAccent;
    } else if (health < 0.5) {
      advice = 'Cần cân đối lại chi tiêu';
      subAdvice = 'Bạn đã chi hơn nửa ngân sách rồi đấy.';
      color = Colors.orangeAccent;
    } else if (health < 0.8) {
      advice = 'Tiếp tục duy trì phong độ';
      subAdvice = 'Đừng quên kiểm tra giá trước khi mua nhé.';
      color = Colors.blueAccent;
    }

    // Logic đặc biệt: Nếu tổng chi đã vượt 90%
    if (totalSpent > (budgetLimit * 0.9)) {
       advice = 'Dừng lại! Bạn sắp "cháy túi"';
       subAdvice = 'Ví của bạn đang kêu cứu, hãy cân nhắc cắt giảm.';
    }

    return AIAdvisorResult(
      budgetHealth: health,
      advice: advice,
      subAdvice: subAdvice,
      statusColor: color,
    );
  }
}
