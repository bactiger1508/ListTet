import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/dashboard_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/navigation_viewmodel.dart';
import 'package:person_app/data/services/ai_advisor_service.dart';
import 'package:person_app/views/widgets/fortune_tree_widget.dart';
import 'package:person_app/views/screens/dashboard/tet_wrapped_screen.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/category/category_budget_screen.dart';
import 'package:person_app/views/widgets/spending_bar_chart.dart';
import 'package:person_app/views/widgets/category_pie_chart.dart';
import 'package:person_app/data/models/season.dart';
import 'package:person_app/views/screens/games/love_match_game_screen.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final seasonVm = context.watch<SeasonViewModel>();
    final season = seasonVm.currentSeason;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 24),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(season?.name ?? 'Chưa có kỳ nào',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 16)),
                Text(_getStatusText(vm.seasonDateStatus),
                    style: TextStyle(fontSize: 11, color: AppColors.accentGold.withOpacity(0.8))),
              ]),
            ]),
            IconButton(
              icon: const Icon(Icons.auto_awesome_motion_outlined, color: AppColors.accentGold),
              tooltip: 'Tổng kết Tết',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TetWrappedScreen(seasonName: season?.name ?? 'Kỳ Tết')
                ));
              },
            ),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : season == null
              ? _emptyState(context)
              : _content(context, vm, season),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.nature_people_outlined, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 16),
      const Text('Chưa có kỳ Tết nào', style: TextStyle(fontSize: 18, color: AppColors.textMain)),
      const SizedBox(height: 8),
      const Text('Tạo kỳ Tết để bắt đầu trồng "Cây Tài Lộc"',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
    ]),
  );

  Widget _content(BuildContext context, DashboardViewModel vm, Season season) {
    final aiResult = AIAdvisorService.analyze(
      totalSpent: vm.totalSpent,
      plannedTotal: vm.plannedTotal,
      budgetLimit: vm.totalBudget,
    );

    return RefreshIndicator(
      onRefresh: () async {
        if (season.id.isNotEmpty) await vm.load(season.id, seasonName: season.name, startDate: season.startDate, endDate: season.endDate);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fortune Tree (Gamification)
            FortuneTreeWidget(budgetHealth: aiResult.budgetHealth),
            
            const SizedBox(height: 16),
            // 2. AI Advisor Message
            _aiAdvisorCard(aiResult),

            const SizedBox(height: 24),
            // +++ LOVE MATCH MINI GAME +++
            const LoveMatchDashboardCard(),

            // 3. Stats Rows
            Row(children: [
              Expanded(child: _statCard('Ngân sách', vm.totalBudgetFormatted, Icons.account_balance_wallet_outlined, Colors.indigo)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Đã chi', vm.totalSpentFormatted, Icons.shopping_cart, AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(
                vm.budgetVariance >= 0 ? 'Tiết kiệm' : 'Vượt mức', 
                vm.budgetVarianceFormatted, 
                Icons.savings_outlined, 
                vm.budgetVariance >= 0 ? AppColors.success : AppColors.error
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Cần mua', '${vm.pendingItems} món', Icons.list_alt, AppColors.warning)),
            ]),

            const SizedBox(height: 32),
            // 4. Analysis Charts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phân tích chi tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                TextButton.icon(
                  onPressed: () {
                    if (season.id.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CategoryBudgetScreen(seasonId: season.id)
                      )).then((_) => vm.load(season.id));
                    }
                  },
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Hạng mục', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SpendingBarChart(data: vm.last7Days),
            const SizedBox(height: 20),
            CategoryPieChart(data: vm.categorySpending),
            
            const SizedBox(height: 32),
            // 5. Recent Transactions
            if (vm.recentExpenses.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Giao dịch gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                   TextButton(
                    onPressed: () => context.read<NavigationViewModel>().setIndex(1),
                    child: const Text('Xem tất cả')
                  ),
                ],
              ),
              _recentExpensesList(vm),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _aiAdvisorCard(AIAdvisorResult result) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: AppColors.glassGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: result.statusColor.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: result.statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.tips_and_updates_rounded, color: result.statusColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.advice, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 15)),
              const SizedBox(height: 4),
              Text(result.subAdvice, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardDark, 
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppColors.goldShadow,
      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.05)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 16),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    ]),
  );

  Widget _recentExpensesList(DashboardViewModel vm) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardDark, 
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppColors.softShadow,
      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.05)),
    ),
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.recentExpenses.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.borderMuted.withOpacity(0.05), indent: 70),
      itemBuilder: (ctx, i) {
        final e = vm.recentExpenses[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withOpacity(0.05),
            ),
            child: (e.itemImagePath != null && File(e.itemImagePath!).existsSync())
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(e.itemImagePath!), fit: BoxFit.cover))
                : const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
          ),
          title: Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          subtitle: Text(e.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          trailing: Text('-${_fmt(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain)),
        );
      },
    ),
  );

  String _getStatusText(Map<String, dynamic> status) {
    final type = status['type'];
    final days = status['days'];
    if (type == 'none') return 'Chưa hẹn ngày';
    if (type == 'before') return 'Còn $days ngày đến Tết';
    if (type == 'during') return 'Tết đã đến hiện tại!';
    if (type == 'after') return 'Tết đã qua $days ngày';
    return '';
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr' : '${(v / 1000).round()}k';
}
