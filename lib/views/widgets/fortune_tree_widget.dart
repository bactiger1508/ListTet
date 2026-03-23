import 'package:flutter/material.dart';
import 'package:person_app/theme/app_colors.dart';

class FortuneTreeWidget extends StatelessWidget {
  final double budgetHealth; // 0.0 (bad/over) to 1.0 (good/under)
  
  const FortuneTreeWidget({super.key, required this.budgetHealth});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: AppColors.softShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getTreeColor().withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
          ),
          
          // The Tree Representation
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getTreeIcon(),
                size: 80,
                color: _getTreeColor(),
              ),
              const SizedBox(height: 12),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getTreeColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _getSubStatusText(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Floating Blossoms (Simplified with Icons)
          if (budgetHealth > 0.7)
            ...List.generate(5, (i) => _buildBlossom(i)),
        ],
      ),
    );
  }

  IconData _getTreeIcon() {
    if (budgetHealth >= 0.8) return Icons.local_florist; // Blooming
    if (budgetHealth >= 0.5) return Icons.park; // Healthy
    if (budgetHealth >= 0.2) return Icons.eco; // Wilting
    return Icons.nature_people_outlined; // Dry
  }

  Color _getTreeColor() {
    if (budgetHealth >= 0.8) return AppColors.accentGold;
    if (budgetHealth >= 0.5) return Colors.greenAccent;
    if (budgetHealth >= 0.2) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getStatusText() {
    if (budgetHealth >= 0.8) return 'Cây Tài Lộc Nở Hoa!';
    if (budgetHealth >= 0.5) return 'Cây Đang Phát Triển Tốt';
    if (budgetHealth >= 0.2) return 'Cây Cần "Tiết Kiệm" Nước';
    return 'Cây Đang Héo Úa...';
  }

  String _getSubStatusText() {
    if (budgetHealth >= 0.8) return 'Ngân sách của bạn cực kỳ ổn định';
    if (budgetHealth >= 0.5) return 'Mọi thứ vẫn đang trong tầm kiểm soát';
    if (budgetHealth >= 0.2) return 'Hãy cẩn thận với các khoản chi mới';
    return 'Bạn đã vượt ngưỡng chi tiêu an toàn!';
  }

  Widget _buildBlossom(int index) {
    final positions = [
      const Offset(-60, -40),
      const Offset(60, -30),
      const Offset(-40, -70),
      const Offset(40, -70),
      const Offset(0, -90),
    ];
    return Positioned(
      left: 100 + positions[index].dx + 80, // Offset from center
      top: 100 + positions[index].dy,
      child: const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 14),
    );
  }
}
