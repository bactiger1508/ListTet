import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/data/models/expense.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
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
    final photoVm = context.watch<PhotoViewModel>();

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
                            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.15))),
                        child: ListView.separated(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(height: 0, color: AppColors.borderSubtle, indent: 16),
                          itemBuilder: (context, j) {
                            final exp = items[j];
                            final receiptPhoto = photoVm.receipts.where((p) => p.expenseId == exp.id).firstOrNull;
                            return _ExpenseTile(
                              expense: exp,
                              receiptPhotoPath: receiptPhoto?.localPath,
                              onDelete: () => _confirmDelete(context, exp),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ExpenseTransactionDetailScreen(expenseId: exp.id)
                                )).then((_) {
                                  if (context.mounted) {
                                    context.read<ExpenseViewModel>().load(seasonVm.activeSeason!);
                                  }
                                });
                              },
                            );
                          },
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Text('Xóa chi tiêu?', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(text: TextSpan(
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              children: [
                const TextSpan(text: 'Bạn có chắc muốn xóa "'),
                TextSpan(text: expense.title, style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                const TextSpan(text: '"?'),
              ]
            )),
            if (expense.itemId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(child: Text('Lưu ý: Món đồ liên kết sẽ được chuyển về trạng thái "Theo dõi".',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              final sid = context.read<SeasonViewModel>().activeSeason!;
              final expenseVm = context.read<ExpenseViewModel>();
              final itemVm = context.read<ItemViewModel>();

              // 1. Close dialog immediately to reflect action
              Navigator.pop(ctx);
              // 2. Perform deletion
              await expenseVm.deleteExpense(expense.id, sid);
              // 3. Update linked item status
              if (expense.itemId != null) {
                await itemVm.updateStatus(expense.itemId!, ItemStatus.watching, sid);
              }
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.receipt_long, size: 64, color: AppColors.primary),
      ),
      const SizedBox(height: 24),
      const Text('Chưa có chi tiêu nào', style: TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Ghi chép lại các khoản chi để dễ kiểm soát hơn.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 32),
      ElevatedButton.icon(
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Thêm khoản chi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () {
          final seasonVm = context.read<SeasonViewModel>();
          final sid = seasonVm.activeSeason;
          if (sid != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddEditExpenseScreen(
                seasonId: sid,
                categoryId: seasonVm.firstCategoryId,
                onSaved: () => context.read<ExpenseViewModel>().load(sid),
              )));
          }
        },
      )
    ]),
  );

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String? receiptPhotoPath;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ExpenseTile({required this.expense, this.receiptPhotoPath, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.receipt, color: AppColors.primary, size: 18)),
    title: Text(expense.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expense.store != null) Text(expense.store!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        if (receiptPhotoPath != null) 
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.image, size: 12, color: AppColors.primary),
               SizedBox(width: 4),
               Text('Có hóa đơn', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ]
          )
      ]
    ),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(_fmt(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
      IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 20), onPressed: onDelete),
    ]),
  );

  String _fmt(int v) => v >= 1000000 ? '-${(v / 1000000).toStringAsFixed(1)}tr' : '-${(v / 1000).round()}k';
}
