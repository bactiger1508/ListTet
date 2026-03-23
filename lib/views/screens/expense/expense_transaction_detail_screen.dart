import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/views/screens/expense/add_edit_expense_screen.dart';
import 'package:person_app/data/models/photo.dart';

class ExpenseTransactionDetailScreen extends StatefulWidget {
  final String expenseId;
  const ExpenseTransactionDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseTransactionDetailScreen> createState() => _ExpenseTransactionDetailScreenState();
}

class _ExpenseTransactionDetailScreenState extends State<ExpenseTransactionDetailScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoViewModel>().loadForExpense(widget.expenseId);
    });
  }

  Future<void> _addReceipt() async {
    final sid = context.read<SeasonViewModel>().activeSeason;
    if (sid == null) return;

    final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1080, imageQuality: 80);
    if (picked == null) return;

    if (mounted) {
      await context.read<PhotoViewModel>().addPhoto(
        sourcePath: picked.path,
        seasonId: sid,
        type: 'receipt',
        expenseId: widget.expenseId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ExpenseViewModel>();
    final photoVm = context.watch<PhotoViewModel>();
    final expense = vm.expenses.where((e) => e.id == widget.expenseId).firstOrNull;

    if (expense == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background,
            leading: const BackButton(color: AppColors.textMain)),
        body: const Center(child: Text('Không tìm thấy', style: TextStyle(color: AppColors.textMain))),
      );
    }

    final seasonVm = context.read<SeasonViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Chi tiết chi tiêu',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary), 
            onPressed: _addReceipt),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              final sid = seasonVm.activeSeason;
              if (sid != null) {
                context.read<ExpenseViewModel>().deleteExpense(expense.id, sid);
              }
              Navigator.pop(context);
            }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _AmountHeader(amount: expense.amount, date: expense.date),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle)),
            child: Column(children: [
              _row('Tên', expense.title),
              if (expense.store != null) _row('Cửa hàng', expense.store!),
              if (expense.note != null) _row('Ghi chú', expense.note!),
            ]),
          ),
          const SizedBox(height: 24),

          if (photoVm.expensePhotos.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Ảnh hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoVm.expensePhotos.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _ReceiptThumbnail(photo: photoVm.expensePhotos[i]),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back), label: const Text('Quay lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMain,
                side: const BorderSide(color: AppColors.borderSubtle),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddEditExpenseScreen(
                    seasonId: seasonVm.activeSeason ?? '',
                    categoryId: expense.categoryId,
                    initialExpense: expense,
                    onSaved: () {
                      if (seasonVm.activeSeason != null) {
                        context.read<ExpenseViewModel>().load(seasonVm.activeSeason!);
                      }
                      Navigator.pop(context);
                    },
                  ))),
              icon: const Icon(Icons.edit), label: const Text('Sửa'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

class _AmountHeader extends StatelessWidget {
  final int amount;
  final String date;
  const _AmountHeader({required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15)),
          child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 32)),
      const SizedBox(height: 12),
      Text(_fmt(amount),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
      const SizedBox(height: 6),
      Text(date, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
    ]);
  }

  String _fmt(int v) => v >= 1000000 ? '-${(v / 1000000).toStringAsFixed(1)}tr ₫' : '-${(v / 1000).round()}k ₫';
}

class _ReceiptThumbnail extends StatelessWidget {
  final Photo photo;
  const _ReceiptThumbnail({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.file(File(photo.localPath)))),
        ),
      )),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          image: DecorationImage(image: FileImage(File(photo.localPath)), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
