import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:person_app/theme/app_colors.dart';

import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';

class AddItemScreen extends StatefulWidget {
  final String seasonId;
  final VoidCallback? onSaved;

  const AddItemScreen({super.key, required this.seasonId, this.onSaved});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  int _qty = 1;
  String? _selectedCategoryId;
  bool _isSaving = false;
  File? _pickedImage;
  final _photoNoteCtrl = TextEditingController();
  
  // Re-add missing repo import if accidentally removed (it was on line 8)
  // Actually let's just make sure the imports are correct at the top.


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<SeasonViewModel>().categories;
      if (categories.isNotEmpty) setState(() => _selectedCategoryId = categories.first.id);
    });
  }

  @override
  void dispose() { 
    _nameCtrl.dispose(); 
    _priceCtrl.dispose(); 
    _storeCtrl.dispose(); 
    _photoNoteCtrl.dispose();
    super.dispose(); 
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
    if (picked != null) {
      if (mounted) {
        final ctrl = TextEditingController();
        final note = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Text('Ghi chú ảnh (tùy chọn)', style: TextStyle(color: AppColors.textMain, fontSize: 16)),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(hintText: 'VD: Màu sắc, size, hàng sẵn...'),
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
        if (note != null && note.isNotEmpty) {
          _photoNoteCtrl.text = note;
        }
      }
      setState(() => _pickedImage = File(picked.path));
    }
  }


  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và giá mục tiêu')));
      return;
    }
    final price = int.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giá mục tiêu không hợp lệ')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (!mounted) return;
      final seasonVm = context.read<SeasonViewModel>();
      final itemVm = context.read<ItemViewModel>();
      final photoVm = context.read<PhotoViewModel>();
      
      final categoryId = _selectedCategoryId ?? (seasonVm.categories.isNotEmpty ? seasonVm.categories.first.id : null);
      if (categoryId == null) throw 'Vui lòng tạo ít nhất một hạng mục trước khi thêm món đồ.';

      // 1. Create item in DB
      final item = await itemVm.addItem(
        seasonId: widget.seasonId,
        categoryId: categoryId,
        name: _nameCtrl.text.trim(),
        targetPrice: price,
        quantity: _qty,
        store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
      );

      // 2. If image picked, save to Photo Lib and link to Item
      if (_pickedImage != null) {
        final photo = await photoVm.addPhoto(
          sourcePath: _pickedImage!.path,
          seasonId: widget.seasonId,
          type: 'product',
          itemId: item.id,
          note: _photoNoteCtrl.text.trim().isEmpty ? 'Ảnh sản phẩm' : _photoNoteCtrl.text.trim(),
        );
        // Sync the item's imagePath with the photo's permanent localPath
        await itemVm.updateItemImage(item, photo.localPath);
      }

      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error saving item: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi thêm món: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonVm = context.watch<SeasonViewModel>();
    final categories = seasonVm.categories;

    // Auto-select first category if none selected and categories available
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Thêm món cần mua', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 1. Image Section
          _sectionCard(
            title: 'HÌNH ẢNH SẢN PHẨM',
            child: Column(children: [
              GestureDetector(
                onTap: () => _showImagePicker(context),
                child: _pickedImage != null
                    ? Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_pickedImage!, width: double.infinity, height: 200, fit: BoxFit.cover),
                        ),
                        Positioned(top: 10, right: 10, child: GestureDetector(
                          onTap: () => setState(() => _pickedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        )),
                      ])
                    : Container(
                        width: double.infinity, height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.add_a_photo_rounded, size: 32, color: AppColors.accentGold),
                          ),
                          const SizedBox(height: 12),
                          const Text('Chụp hoặc chọn ảnh sản phẩm', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        ]),
                      ),
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _photoNoteCtrl,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú đặc điểm của món này...',
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.accentGold),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderMuted.withValues(alpha: 0.2))),
                  ),
                ),
              ],
            ]),
          ),
          
          const SizedBox(height: 24),

          // 2. Info Section
          _sectionCard(
            title: 'THÔNG TIN CƠ BẢN',
            child: Column(children: [
              TextField(
                controller: _nameCtrl, 
                style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Tên món đồ *',
                  hintText: 'VD: Bánh chưng, thịt kho...',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _priceCtrl, 
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Giá mục tiêu *',
                  hintText: '0', 
                  suffixText: ' ₫',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Số lượng cần mua', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.borderMuted.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    _qtyBtn(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    ),
                    _qtyBtn(Icons.add, () => setState(() => _qty++)),
                  ]),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 24),

          // 3. Category & Store Section
          _sectionCard(
            title: 'CHI TIẾT PHÂN LOẠI',
            child: Column(children: [
              _label('HẠNG MỤC CHI TIÊU'),
              const SizedBox(height: 8),
              Container(
                height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: AppColors.borderMuted.withValues(alpha: 0.3))
                ),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId)) ? _selectedCategoryId : (categories.isNotEmpty ? categories.first.id : null),
                  hint: const Text('Chọn hạng mục...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  isExpanded: true,
                  style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w500), 
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _storeCtrl, 
                style: const TextStyle(color: AppColors.textMain),
                decoration: const InputDecoration(
                  labelText: 'Nơi bán dự kiến',
                  hintText: 'VD: Siêu thị, Chợ hoa...',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.goldShadow,
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary), 
            label: const Text('THÊM VÀO DANH SÁCH'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.05)),
      boxShadow: AppColors.softShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(title),
      const SizedBox(height: 20),
      child,
    ]),
  );
  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.softShadow),
      child: Icon(icon, size: 20, color: AppColors.primary),
    ),
  );

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Chọn ảnh sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Chụp ảnh', style: TextStyle(color: AppColors.textMain)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Chọn từ thư viện', style: TextStyle(color: AppColors.textMain)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600));
}
