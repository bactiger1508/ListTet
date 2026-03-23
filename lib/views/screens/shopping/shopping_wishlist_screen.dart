import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/shopping/add_item_screen.dart';
import 'package:person_app/views/screens/shopping/shopping_item_detail_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ShoppingWishlistScreen extends StatefulWidget {
  const ShoppingWishlistScreen({super.key});
  @override
  State<ShoppingWishlistScreen> createState() => _ShoppingWishlistScreenState();
}

class _ShoppingWishlistScreenState extends State<ShoppingWishlistScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = context.read<SeasonViewModel>().activeSeason;
      if (sid != null) context.read<ItemViewModel>().load(sid);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemViewModel>();
    final seasonVm = context.watch<SeasonViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Đã cấu hình trong Theme
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.accentGold, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm món đồ...',
                  hintStyle: TextStyle(color: AppColors.accentGold),
                  border: InputBorder.none,
                ),
                onChanged: (v) => vm.setSearch(v),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cần mua', style: Theme.of(context).appBarTheme.titleTextStyle),
                Text('${vm.filteredItems.length} món', style: const TextStyle(fontSize: 12, color: AppColors.accentGold)),
              ]),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: AppColors.accentGold, size: 22),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  vm.setSearch('');
                }
              });
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              // Filter chips row
              if (!_showSearch)
                Container(
                  height: 72, // Further increased to 72
                  padding: const EdgeInsets.only(top: 12, bottom: 8), // More top padding
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(vm, null, 'Tất cả', Icons.list),
                      const SizedBox(width: 8),
                      _filterChip(vm, ItemStatus.todo, 'Cần mua', Icons.shopping_cart_outlined),
                      const SizedBox(width: 8),
                      _filterChip(vm, ItemStatus.watching, 'Theo dõi', Icons.visibility_outlined),
                      const SizedBox(width: 8),
                      _filterChip(vm, ItemStatus.bought, 'Đã mua', Icons.check_circle_outline),
                    ],
                  ),
                ),
              const SizedBox(height: 16), // Increased spacing
              // Item list
              Expanded(
                child: vm.filteredItems.isEmpty
                    ? _empty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: vm.filteredItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = vm.filteredItems[i];
                          return _SwipeableItemCard(
                            item: item,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ShoppingItemDetailScreen(item: item, seasonId: seasonVm.activeSeason!),
                            )).then((_) => vm.load(seasonVm.activeSeason!)),
                            onDelete: () async {
                              await vm.deleteItem(item.id, seasonVm.activeSeason!);
                            },
                            onBuyNow: () => _confirmBuyNow(context, vm, item),
                            onUpdatePrice: (p) async {
                              await vm.updatePrice(item.id, p, seasonVm.activeSeason!);
                            },
                            onStatusChange: (s) async {
                              await vm.updateStatus(item.id, s, seasonVm.activeSeason!);
                            },
                          );
                        },
                      ),
              ),
            ]),
      floatingActionButton: seasonVm.activeSeason == null ? null : FloatingActionButton(
        backgroundColor: AppColors.accentGold,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddItemScreen(
                seasonId: seasonVm.activeSeason!,
                onSaved: () => vm.load(seasonVm.activeSeason!),
              )));
        },
      ),
    );
  }

  Widget _filterChip(ItemViewModel vm, ItemStatus? s, String label, IconData icon) {
    final active = vm.filterStatus == s;
    return GestureDetector(
      onTap: () => vm.setFilter(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4), // Better spacing
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active 
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4), spreadRadius: -1)]
            : AppColors.softShadow,
          border: active ? null : Border.all(color: AppColors.borderMuted.withValues(alpha: 0.8)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: active ? Colors.white : AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: active ? Colors.white : AppColors.textMuted)),
        ]),
      ),
    );
  }

  void _confirmBuyNow(BuildContext context, ItemViewModel vm, Item item) {
    final amountController = TextEditingController(text: (item.currentPrice ?? item.targetPrice).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Mua ngay: ${item.name}', style: const TextStyle(color: AppColors.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Xác nhận tạo chi tiêu và đánh dấu đã mua.', style: TextStyle(color: AppColors.textMain70)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(
                labelText: 'Số tiền thực tế (₫)',
                labelStyle: TextStyle(color: AppColors.primary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text) ?? item.targetPrice;
              await vm.buyNow(item: item, categoryId: item.categoryId, amount: amount);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Xác nhận', style: TextStyle(color: AppColors.primary)),
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
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.primary),
      ),
      const SizedBox(height: 24),
      const Text('Chưa có món đồ nào!', style: TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Lên kế hoạch sắm Tết ngay hôm nay.', style: TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 32),
      ElevatedButton.icon(
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Thêm món đồ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () {
          final sid = context.read<SeasonViewModel>().activeSeason;
          if (sid != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddItemScreen(
                seasonId: sid,
                onSaved: () => context.read<ItemViewModel>().load(sid),
              )));
          }
        },
      )
    ]),
  );
}

// ===== Swipe item card =====

class _SwipeableItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onBuyNow;
  final void Function(int) onUpdatePrice;
  final void Function(ItemStatus) onStatusChange;

  const _SwipeableItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onBuyNow,
    required this.onUpdatePrice,
    required this.onStatusChange,
  });

  Color get _dealColor {
    switch (item.dealLevel) {
      case 'tốt': return Colors.green;
      case 'ổn': return Colors.orange;
      case 'cao': return Colors.red;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: item.status != ItemStatus.bought ? 0.7 : 0.55,
          children: [
            if (item.status != ItemStatus.bought)
              CustomSlidableAction(
                onPressed: (_) => onBuyNow(),
                backgroundColor: AppColors.background,
                padding: EdgeInsets.zero,
                child: _actionBtnRaw(Icons.shopping_cart, 'Mua', AppColors.primary),
              ),
            CustomSlidableAction(
              onPressed: (_) => _showPriceDialog(context),
              backgroundColor: AppColors.background,
              padding: EdgeInsets.zero,
              child: _actionBtnRaw(Icons.edit, 'Giá', Colors.blue),
            ),
            CustomSlidableAction(
              onPressed: (_) => onStatusChange(ItemStatus.watching),
              backgroundColor: AppColors.background,
              padding: EdgeInsets.zero,
              child: _actionBtnRaw(Icons.visibility, 'Theo dõi', Colors.orange),
            ),
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.background,
              padding: EdgeInsets.zero,
              child: _actionBtnRaw(Icons.delete, 'Xóa', Colors.red),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
              border: Border.all(color: AppColors.borderMuted.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              // Thumbnail
              if (item.imagePath != null && File(item.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(item.imagePath!), width: 50, height: 50, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag, color: AppColors.primary, size: 24),
                ),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(item.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _statusColor(item.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_statusLabel(item.status),
                        style: TextStyle(fontSize: 10, color: _statusColor(item.status))),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(_fmt(item.targetPrice), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  if (item.currentPrice != null) ...[
                    const Text(' → ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(_fmt(item.currentPrice!),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _dealColor)),
                  ],
                ]),
                if (item.currentPrice != null && item.savings != 0)
                  Text(
                    item.savings > 0 
                      ? 'Tiết kiệm được: ${_fmt(item.savings)}' 
                      : 'Vượt mức: ${_fmt(item.savings.abs())}',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w500,
                      color: item.savings > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                if (item.store != null)
                  Text('📍 ${item.store}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 18), // Swipe hint
            ]),
          ),
        ),
      ),
    );
  }

  Widget _actionBtnRaw(IconData icon, String label, Color color) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showPriceDialog(BuildContext context) {
    final ctrl = TextEditingController(text: item.currentPrice?.toString() ?? '');
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text('Giá ${item.name}', style: const TextStyle(color: AppColors.textMain)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textMain),
          decoration: const InputDecoration(hintText: 'Nhập giá hiện tại (đ)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        TextButton(onPressed: () {
          final p = int.tryParse(ctrl.text);
          if (p != null) onUpdatePrice(p);
          Navigator.pop(context);
        }, child: const Text('Lưu', style: TextStyle(color: AppColors.primary))),
      ],
    ));
  }

  Color _statusColor(ItemStatus s) {
    switch (s) {
      case ItemStatus.bought: return Colors.green;
      case ItemStatus.watching: return Colors.orange;
      case ItemStatus.dropped: return Colors.grey;
      default: return AppColors.primary;
    }
  }

  String _statusLabel(ItemStatus s) {
    switch (s) {
      case ItemStatus.bought: return 'Đã mua';
      case ItemStatus.watching: return 'Theo dõi';
      case ItemStatus.dropped: return 'Bỏ qua';
      default: return 'Cần mua';
    }
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}
