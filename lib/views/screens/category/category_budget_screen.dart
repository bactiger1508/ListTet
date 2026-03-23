import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/category_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/data/models/category.dart';
import 'package:person_app/theme/app_colors.dart';

class CategoryBudgetScreen extends StatefulWidget {
  const CategoryBudgetScreen({super.key});
  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = context.read<SeasonViewModel>().activeSeason;
      if (sid != null) context.read<CategoryViewModel>().load(sid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();
    final seasonVm = context.watch<SeasonViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Ngân sách hạng mục', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => _addCategory(context, vm, seasonVm),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              // Summary header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFB71C1C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _summaryItem('Tổng ngân sách', _fmt(vm.totalPlannedBudget)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Đã chi', _fmt(vm.totalSpent)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Còn lại', _fmt(vm.totalPlannedBudget - vm.totalSpent)),
                ]),
              ),

              // Category list
              Expanded(
                child: vm.categories.isEmpty
                    ? const Center(child: Text('Chưa có hạng mục', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: vm.categories.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _CategoryCard(
                          category: vm.categories[i],
                          spent: vm.getSpent(vm.categories[i].id),
                          progress: vm.getProgress(vm.categories[i]),
                          isOver: vm.isOverBudget(vm.categories[i]),
                          onEditBudget: () => _editBudget(context, vm, vm.categories[i]),
                        ),
                      ),
              ),
            ]),
    );
  }

  Widget _summaryItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFFFCDD2))),
  ]);

  void _editBudget(BuildContext context, CategoryViewModel vm, Category cat) {
    final ctrl = TextEditingController(text: cat.plannedBudget > 0 ? cat.plannedBudget.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Ngân sách: ${cat.name}', style: const TextStyle(color: AppColors.textMain)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textMain),
          decoration: const InputDecoration(
            hintText: 'VD: 2000000',
            suffixText: ' ₫',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () {
            final budget = int.tryParse(ctrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
            vm.updateBudget(cat, budget);
            Navigator.pop(ctx);
          }, child: const Text('Lưu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _addCategory(BuildContext context, CategoryViewModel vm, SeasonViewModel seasonVm) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Thêm hạng mục', style: TextStyle(color: AppColors.textMain)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textMain),
            decoration: const InputDecoration(hintText: 'Tên hạng mục (VD: Lì xì)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: budgetCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textMain),
            decoration: const InputDecoration(hintText: 'Ngân sách (VD: 5000000)', suffixText: ' ₫'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () {
            if (nameCtrl.text.trim().isNotEmpty && seasonVm.activeSeason != null) {
              final budget = int.tryParse(budgetCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
              vm.addCategory(seasonVm.activeSeason!, nameCtrl.text.trim(), budget: budget);
            }
            Navigator.pop(ctx);
          }, child: const Text('Thêm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final int spent;
  final double progress;
  final bool isOver;
  final VoidCallback onEditBudget;

  const _CategoryCard({
    required this.category,
    required this.spent,
    required this.progress,
    required this.isOver,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isOver ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderSubtle),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOver ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(_categoryIcon(category.name),
              color: isOver ? AppColors.error : AppColors.primary, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          Text(category.plannedBudget > 0
              ? 'Ngân sách: ${_fmt(category.plannedBudget)}'
              : 'Chưa đặt ngân sách',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
          onPressed: onEditBudget,
        ),
      ]),
      const SizedBox(height: 10),
      if (category.plannedBudget > 0) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.borderSubtle,
            color: isOver ? AppColors.error : AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
      ],
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Đã chi: ${_fmt(spent)}',
            style: TextStyle(fontSize: 13, color: isOver ? AppColors.error : AppColors.textMain, fontWeight: FontWeight.w600)),
        if (category.plannedBudget > 0)
          Text('Còn lại: ${_fmt(category.plannedBudget - spent)}',
              style: TextStyle(fontSize: 13, color: isOver ? AppColors.error : AppColors.success)),
      ]),
    ]),
  );

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('thực phẩm') || n.contains('ăn') || n.contains('bánh')) return Icons.restaurant;
    if (n.contains('đồ uống') || n.contains('nước')) return Icons.local_cafe;
    if (n.contains('quần áo') || n.contains('áo')) return Icons.checkroom;
    if (n.contains('trang trí')) return Icons.home;
    if (n.contains('quà') || n.contains('lì xì')) return Icons.card_giftcard;
    if (n.contains('khác')) return Icons.more_horiz;
    return Icons.category;
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}
