import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/season/create_edit_season_screen.dart';

class SeasonManagementScreen extends StatelessWidget {
  const SeasonManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SeasonViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Đã cấu hình trong Theme
        title: Text('Kỳ Tết', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.accentGold, size: 28),
            onPressed: () => _goCreate(context, vm),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.seasons.isEmpty
              ? _empty(context, vm)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.seasons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _SeasonCard(
                    season: vm.seasons[i],
                    isActive: vm.seasons[i].id == vm.activeSeason,
                    onTap: () => vm.selectSeason(vm.seasons[i].id),
                    onDelete: () => _confirmDelete(ctx, vm, vm.seasons[i].id, vm.seasons[i].name),
                    onEdit: () => _goEdit(ctx, vm, vm.seasons[i].id, vm.seasons[i].name, vm.seasons[i].startDate, vm.seasons[i].endDate, vm.seasons[i].budgetLimit),
                    onClone: () => _confirmClone(ctx, vm, vm.seasons[i]),
                  )),
    );
  }

  void _goCreate(BuildContext context, SeasonViewModel vm) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateEditSeasonScreen(
          onSaved: (name, start, end, budget, cats) async {
            await vm.createSeason(name, startDate: start, endDate: end, budgetLimit: budget, categoriesData: cats);
          },
        )));
  }

  void _goEdit(BuildContext context, SeasonViewModel vm, String id, String currentName, String? start, String? end, int? budgetLimit) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateEditSeasonScreen(
          initialName: currentName,
          initialStartDate: start,
          initialEndDate: end,
          initialBudget: budgetLimit,
          onSaved: (name, newStart, newEnd, budget, _) async {
            await vm.updateSeason(id, name, startDate: newStart, endDate: newEnd, budgetLimit: budget);
          },
        )));
  }

  Widget _empty(BuildContext context, SeasonViewModel vm) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.calendar_month, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 16),
      const Text('Chưa có kỳ Tết nào', style: TextStyle(fontSize: 18, color: AppColors.textMain)),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: () => _goCreate(context, vm),
          icon: const Icon(Icons.add), label: const Text('Tạo kỳ đầu tiên')),
    ]),
  );

  void _confirmDelete(BuildContext ctx, SeasonViewModel vm, String id, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Xóa kỳ Tết?', style: TextStyle(color: AppColors.textMain)),
      content: Text('Xóa "$name" sẽ xóa toàn bộ items và chi tiêu liên quan.',
          style: const TextStyle(color: AppColors.textMain70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        TextButton(onPressed: () { Navigator.pop(ctx); vm.deleteSeason(id); },
            child: const Text('Xóa', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _confirmClone(BuildContext ctx, SeasonViewModel vm, dynamic season) {
    final nameCtrl = TextEditingController(text: '${season.name} (Bản sao)');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Sao chép danh sách?', style: TextStyle(color: AppColors.textMain)),
      content: TextField(
        controller: nameCtrl,
        style: const TextStyle(color: AppColors.textMain),
        decoration: const InputDecoration(
          labelText: 'Tên kỳ mới',
          labelStyle: TextStyle(color: AppColors.primary),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        TextButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            try {
              await vm.cloneSeason(season.id, nameCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx); // pop loading
                Navigator.pop(ctx); // pop dialog
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Đã sao chép thành công!')));
              }
            } catch (e) {
              if (ctx.mounted) {
                Navigator.pop(ctx); // pop loading
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            }
          },  
          child: const Text('Nhân bản', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}

class _SeasonCard extends StatelessWidget {
  final dynamic season;
  final bool isActive;
  final VoidCallback onTap, onDelete, onEdit, onClone;
  const _SeasonCard({required this.season, required this.isActive, required this.onTap, required this.onDelete, required this.onEdit, required this.onClone});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.primary : AppColors.accentGold.withOpacity(0.5), width: isActive ? 2 : 1),
      ),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant),
            child: Icon(Icons.calendar_month, color: isActive ? AppColors.primary : AppColors.textMuted)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(
                season.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Đang dùng', style: TextStyle(fontSize: 11, color: AppColors.primary))),
            ],
          ]),
          if (season.startDate != null)
            Text('${season.startDate} → ${season.endDate ?? '?'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        PopupMenuButton(
          color: AppColors.cardDark,
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'clone', child: Text('Nhân bản', style: TextStyle(color: AppColors.accentGold))),
            const PopupMenuItem(value: 'edit', child: Text('Sửa', style: TextStyle(color: AppColors.textMain))),
            const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'clone') { onClone(); } 
            else if (v == 'edit') { onEdit(); } 
            else { onDelete(); }
          },
        ),
      ]),
    ),
  );
}
