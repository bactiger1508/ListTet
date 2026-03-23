import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/data/models/photo.dart';
import 'package:person_app/data/repos/photo_repo.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/widgets/full_image_viewer.dart';

class MediaReceiptGalleryScreen extends StatefulWidget {
  const MediaReceiptGalleryScreen({super.key});
  @override
  State<MediaReceiptGalleryScreen> createState() => _MediaReceiptGalleryScreenState();
}

class _MediaReceiptGalleryScreenState extends State<MediaReceiptGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _picker = ImagePicker();
  final _photoRepo = PhotoRepo();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sid = context.read<SeasonViewModel>().activeSeason;
      if (sid != null) context.read<PhotoViewModel>().load(sid);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _addPhoto(ImageSource source, String type) async {
    final seasonId = context.read<SeasonViewModel>().activeSeason;
    if (seasonId == null) return;

    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (picked == null) return;

      if (!mounted) return;
      final note = await _showNoteDialog(context);
      
      if (!mounted) return;
      await context.read<PhotoViewModel>().addPhoto(
        sourcePath: picked.path,
        seasonId: seasonId,
        type: type,
        note: note,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<String?> _showNoteDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Thêm ghi chú (tùy chọn)', style: TextStyle(color: AppColors.textMain)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textMain),
          decoration: const InputDecoration(hintText: 'Ví dụ: Hóa đơn mua hoa, ảnh bánh chưng...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Bỏ qua')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Lưu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhotoViewModel>();
    final seasonVm = context.watch<SeasonViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Đã cấu hình trong Theme
        title: Text('Thư viện', style: Theme.of(context).appBarTheme.titleTextStyle),
        bottom: TabBar(controller: _tab,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold, 
          unselectedLabelColor: AppColors.accentGold.withOpacity(0.6),
          tabs: const [Tab(text: 'Hóa đơn'), Tab(text: 'Sản phẩm')],
        ),
      ),
      body: seasonVm.activeSeason == null
        ? const Center(child: Text('Vui lòng chọn hoặc tạo kỳ Tết', style: TextStyle(color: AppColors.textMain)))
        : TabBarView(controller: _tab, children: [
            _Gallery(photos: vm.receipts, onDelete: (p) => _deletePhoto(p)),
            _Gallery(photos: vm.products, onDelete: (p) => _deletePhoto(p)),
          ]),
      floatingActionButton: seasonVm.activeSeason == null ? null : FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
        label: const Text('Thêm ảnh', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final vm = context.read<PhotoViewModel>();
    // Need a delete method in VM. I'll add it or use repo + reload.
    // For consistency, I'll use the repo and reload via VM.
    await _photoRepo.delete(photo.id);
    if (!mounted) return;
    final sid = context.read<SeasonViewModel>().activeSeason;
    if (sid != null) vm.load(sid);
  }

  void _showAddOptions(BuildContext context) {
    final type = _tab.index == 0 ? 'receipt' : 'product';
    showModalBottomSheet(context: context, backgroundColor: AppColors.cardDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Chụp ảnh mới', style: TextStyle(color: AppColors.textMain)),
              onTap: () { Navigator.pop(context); _addPhoto(ImageSource.camera, type); }),
          ListTile(leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Chọn từ thư viện', style: TextStyle(color: AppColors.textMain)),
              onTap: () { Navigator.pop(context); _addPhoto(ImageSource.gallery, type); }),
          const SizedBox(height: 8),
        ])));
  }
}

class _Gallery extends StatelessWidget {
  final List<Photo> photos;
  final void Function(Photo) onDelete;
  const _Gallery({required this.photos, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(child: Text('Chưa có ảnh nào', style: TextStyle(color: AppColors.textMuted)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemBuilder: (ctx, i) => _GalleryCell(photo: photos[i], onDelete: () => onDelete(photos[i])),
    );
  }
}

class _GalleryCell extends StatelessWidget {
  final Photo photo;
  final VoidCallback onDelete;
  const _GalleryCell({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Xóa ảnh?', style: TextStyle(color: AppColors.textMain)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            TextButton(onPressed: () { Navigator.pop(ctx); onDelete(); }, child: const Text('Xóa', style: TextStyle(color: Colors.red))),
          ],
        ));
      },
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => FullImageViewer(
          imagePath: photo.localPath,
          note: photo.note,
          title: photo.type == 'receipt' ? 'Hóa đơn' : 'Sản phẩm',
        ),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Unified 16px for small cells
        child: Stack(fit: StackFit.expand, children: [
          photo.localPath.startsWith('http') || !File(photo.localPath).existsSync()
            ? Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_not_supported, color: AppColors.textMain24))
            : Image.file(File(photo.localPath), fit: BoxFit.cover),
          if (photo.note != null && photo.note!.isNotEmpty)
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                ),
              ),
              child: Text(photo.note!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
        ]),
      ),
    );
  }
}
