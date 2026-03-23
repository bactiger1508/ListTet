import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:person_app/data/repos/item_repo.dart';
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
  void dispose() { _nameCtrl.dispose(); _priceCtrl.dispose(); _storeCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
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
          note: 'Ảnh chụp khi thêm mới',
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Thêm món cần mua', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        actions: [
          _isSaving
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            : const SizedBox.shrink()
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('ẢNH SẢN PHẨM'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showImagePicker(context),
            child: _pickedImage != null
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_pickedImage!, width: double.infinity, height: 180, fit: BoxFit.cover),
                    ),
                    Positioned(top: 8, right: 8, child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    )),
                  ])
                : Container(
                    width: double.infinity, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
                    ),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Chụp ảnh hoặc chọn từ thư viện', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ]),
                  ),
          ),
          const SizedBox(height: 20),

          _label('TÊN MÓN *'),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(hintText: 'VD: Bánh chưng')),
          const SizedBox(height: 16),
          _label('GIÁ MỤC TIÊU *'),
          const SizedBox(height: 8),
          TextField(controller: _priceCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: '0', suffixText: ' ₫')),
          const SizedBox(height: 16),
          _label('SỐ LƯỢNG'),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted), onPressed: () { if (_qty > 1) setState(() => _qty--); }),
            Text('$_qty', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => setState(() => _qty++)),
          ]),
          const SizedBox(height: 16),
          
          _label('HẠNG MỤC'),
          const SizedBox(height: 8),
          Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId)) ? _selectedCategoryId : (categories.isNotEmpty ? categories.first.id : null),
                hint: const Text('Đang tải danh mục...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                dropdownColor: AppColors.cardDark, isExpanded: true,
                style: const TextStyle(color: AppColors.textMain), icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ))),
          const SizedBox(height: 16),

          _label('NƠI BÁN (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(controller: _storeCtrl, style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(hintText: 'VD: WinMart, Shopee')),
          const SizedBox(height: 80),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), color: AppColors.background,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.shopping_cart_checkout), label: const Text('Thêm vào danh sách'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

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


  void _parseAndFill(String text) {
    // Hidden logic for potential future use
  }

  String _formatPriceInput(int p) {
    return p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }


  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600));
}
