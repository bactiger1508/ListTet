import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/data/models/photo.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/shopping/historical_comparison_screen.dart';
import 'package:person_app/views/widgets/full_image_viewer.dart';

class ShoppingItemDetailScreen extends StatefulWidget {
  final Item item;
  final String seasonId;

  const ShoppingItemDetailScreen({super.key, required this.item, required this.seasonId});

  @override
  State<ShoppingItemDetailScreen> createState() => _ShoppingItemDetailScreenState();
}

class _ShoppingItemDetailScreenState extends State<ShoppingItemDetailScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoViewModel>().loadForItem(widget.item.id);
    });
  }

  Future<void> _addPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1080, imageQuality: 80);
    if (picked == null) return;

    if (mounted) {
      final ctrl = TextEditingController();
      final note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Ghi chú sản phẩm (tùy chọn)', style: TextStyle(color: AppColors.textMain)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textMain),
            decoration: const InputDecoration(hintText: 'Ví dụ: Màu đỏ, size L, hàng sẵn có...'),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bỏ qua')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), 
              child: const Text('Lưu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      );

      if (!mounted) return;
      final newPhoto = await context.read<PhotoViewModel>().addPhoto(
        sourcePath: picked.path,
        seasonId: widget.seasonId,
        type: 'product',
        itemId: widget.item.id,
        note: note,
      );
      // Reload photos for the item after adding a new one
      if (mounted) {
        context.read<PhotoViewModel>().loadForItem(widget.item.id);
        
        // Sync with Item viewmodel - always update to latest photo
        final itemVm = context.read<ItemViewModel>();
        final currentItem = itemVm.filteredItems.firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);
        await itemVm.updateItemImage(currentItem, newPhoto.localPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemViewModel>();
    final photoVm = context.watch<PhotoViewModel>();
    final item = vm.items.firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        actions: [
          if (item.status != ItemStatus.bought)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, vm),
            ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            onPressed: _addPhoto,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero card with primary photo or placeholder
          _HeroCard(item: item, photos: photoVm.itemPhotos),
          
          const SizedBox(height: 24),
          _infoCard([
            _infoRow('Mục tiêu', '${_fmt(item.targetPrice)} ₫'),
            _infoRow('Số lượng', '${item.quantity}'),
            _infoRow('Trạng thái', _statusLabel(item.status)),
            if (item.store != null) _infoRow('Nơi mua', item.store!),
            if (item.priority != ItemPriority.medium) _infoRow('Ưu tiên', item.priority.label),
            if (item.isEssential) _infoRow('Tính chất', 'Bắt buộc mua', valueColor: Colors.orange),
            if (item.note != null) _infoRow('Ghi chú', item.note!),
            if (item.savings != 0)
              _infoRow(
                item.savings > 0 ? 'Tiết kiệm được' : 'Đắt hơn',
                '${_fmt(item.savings.abs())} ₫',
                valueColor: item.savings > 0 ? Colors.green : Colors.red,
              ),
          ]),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: item.status != ItemStatus.bought
                ? () => _markBought(context, vm)
                : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Đã mua'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          
          const SizedBox(height: 40),
          // Link to historical data
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HistoricalComparisonScreen(
                    itemName: item.name,
                    currentSeasonId: widget.seasonId,
                  ),
                ));
              },
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Xem lịch sử giá & ảnh năm ngoái'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: AppColors.background, 
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppColors.softShadow,
      border: Border.all(color: AppColors.borderMuted.withValues(alpha: 0.5)),
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(String label, String value, {Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: TextStyle(color: valueColor ?? AppColors.textMain, fontWeight: FontWeight.w600, fontSize: 14)),
    ]),
  );

  void _confirmDelete(BuildContext context, ItemViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Xác nhận xóa: ${widget.item.name}', style: const TextStyle(color: AppColors.textMain)),
        content: const Text('Món đồ này sẽ bị xóa vĩnh viễn khỏi danh sách.', style: TextStyle(color: AppColors.textMain70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await vm.deleteItem(widget.item.id, widget.seasonId);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _markBought(BuildContext context, ItemViewModel vm) {
    final amountController = TextEditingController(text: (widget.item.currentPrice ?? widget.item.targetPrice).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Xác nhận mua: ${widget.item.name}', style: const TextStyle(color: AppColors.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ghi nhận chi tiêu thực tế cho món đồ này.', style: TextStyle(color: AppColors.textMain70)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(
                labelText: 'Số tiền (₫)',
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
              final amount = int.tryParse(amountController.text) ?? widget.item.targetPrice;
              await vm.buyNow(item: widget.item, categoryId: widget.item.categoryId, amount: amount);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Xác nhận', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ItemStatus s) {
    switch (s) {
      case ItemStatus.bought: return 'Đã mua ✓';
      case ItemStatus.watching: return 'Đang theo dõi';
      case ItemStatus.dropped: return 'Đã bỏ';
      default: return 'Cần mua';
    }
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr' : '${(v / 1000).round()}k';
}

class _HeroCard extends StatelessWidget {
  final Item item;
  final List<Photo> photos;
  const _HeroCard({required this.item, required this.photos});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photos.isNotEmpty || (item.imagePath != null && File(item.imagePath!).existsSync());
    final dealLevel = item.dealLevel;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _dealBg(dealLevel),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: _dealColor(dealLevel).withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        if (item.imagePath != null && File(item.imagePath!).existsSync())
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.file(File(item.imagePath!),
                width: double.infinity, height: 220, fit: BoxFit.cover),
          )
        else
          Container(
            height: 140,
            alignment: Alignment.center,
            child: Icon(Icons.shopping_bag_outlined, size: 64, color: _dealColor(dealLevel).withValues(alpha: 0.5)),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 8),
            if (item.currentPrice != null)
              Text('${_fmtPrice(item.currentPrice!)} ₫',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _dealColor(dealLevel)))
            else
              Text('Giá mục tiêu: ${_fmtPrice(item.targetPrice)} ₫', style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  String _fmtPrice(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr' : '${(v / 1000).round()}k';

  Color _dealColor(String level) {
    switch (level) {
      case 'tốt': return Colors.green;
      case 'ổn': return Colors.orange;
      case 'cao': return Colors.red;
      default: return AppColors.primary;
    }
  }

  Color _dealBg(String level) {
    switch (level) {
      case 'tốt': return Colors.green.withValues(alpha: 0.05);
      case 'ổn': return Colors.orange.withValues(alpha: 0.05);
      case 'cao': return Colors.red.withValues(alpha: 0.05);
      default: return AppColors.cardDark;
    }
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;
  const _PhotoThumbnail({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => FullImageViewer(
          imagePath: photo.localPath,
          note: photo.note,
          title: 'Ảnh sản phẩm',
        ),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(photo.localPath), width: 120, height: 120, fit: BoxFit.cover),
      ),
    );
  }
}
