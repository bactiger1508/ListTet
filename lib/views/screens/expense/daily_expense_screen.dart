import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/data/models/expense.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/expense/expense_transaction_detail_screen.dart';
import 'package:person_app/views/screens/expense/add_edit_expense_screen.dart';

class DailyExpenseScreen extends StatefulWidget {
  const DailyExpenseScreen({super.key});
  @override
  State<DailyExpenseScreen> createState() => _DailyExpenseScreenState();
}

class _DailyExpenseScreenState extends State<DailyExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seasonId = context.read<SeasonViewModel>().activeSeason;
      if (seasonId != null) context.read<ExpenseViewModel>().load(seasonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final seasonVm = context.watch<SeasonViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Đã cấu hình trong Theme
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chi tiêu', style: Theme.of(context).appBarTheme.titleTextStyle),
          Text('Tổng: ${_fmt(vm.totalAmount)}',
              style: const TextStyle(fontSize: 12, color: AppColors.accentGold)),
        ]),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.expenses.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.grouped.length,
                  itemBuilder: (ctx, i) {
                    final date = vm.grouped.keys.elementAt(i);
                    final items = vm.grouped[date]!;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color, 
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accentGold.withOpacity(0.5))),
                        child: ListView.separated(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(height: 0, color: AppColors.borderSubtle, indent: 16),
                          itemBuilder: (context, j) => _ExpenseTile(
                            expense: items[j],
                            onDelete: () => _confirmDelete(context, items[j]),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ExpenseTransactionDetailScreen(expenseId: items[j].id)
                              )).then((_) {
                                if (context.mounted) {
                                  context.read<ExpenseViewModel>().load(seasonVm.activeSeason!);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ]);
                  }),
      floatingActionButton: seasonVm.activeSeason == null ? null : FloatingActionButton(
        backgroundColor: AppColors.accentGold,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () {
          final sid = seasonVm.activeSeason!;
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddEditExpenseScreen(
                seasonId: sid,
                categoryId: seasonVm.firstCategoryId,
                onSaved: () => context.read<ExpenseViewModel>().load(sid),
              )));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Xóa chi tiêu?', style: TextStyle(color: AppColors.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa "${expense.title}"?', style: const TextStyle(color: AppColors.textMain70)),
            if (expense.itemId != null) ...[
              const SizedBox(height: 12),
              const Text('Lưu ý: Món đồ liên kết sẽ được chuyển về trạng thái "Theo dõi" để bạn có thể mua lại sau.',
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              final sid = context.read<SeasonViewModel>().activeSeason!;
              // 1. Xóa chi tiêu
              await context.read<ExpenseViewModel>().deleteExpense(expense.id, sid);
              // 2. Nếu có món đồ liên kết, tự động đưa về "Theo dõi"
              if (expense.itemId != null && context.mounted) {
                await context.read<ItemViewModel>().updateStatus(expense.itemId!, ItemStatus.watching, sid);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _empty() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long, size: 64, color: AppColors.textMuted),
      SizedBox(height: 12),
      Text('Chưa có chi tiêu nào', style: TextStyle(color: AppColors.textMain, fontSize: 16)),
      SizedBox(height: 4),
      Text('Nhấn + để thêm chi tiêu', style: TextStyle(color: AppColors.textMuted)),
    ]),
  );

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ExpenseTile({required this.expense, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.receipt, color: AppColors.primary, size: 18)),
    title: Text(expense.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
    subtitle: Text(expense.store ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(_fmt(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
      IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 20), onPressed: onDelete),
    ]),
  );

  String _fmt(int v) => v >= 1000000 ? '-${(v / 1000000).toStringAsFixed(1)}tr' : '-${(v / 1000).round()}k';
}
