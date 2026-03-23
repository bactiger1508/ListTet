import 'package:flutter/material.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:person_app/data/models/expense.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final String seasonId;
  final String? categoryId;
  final Expense? initialExpense;
  final VoidCallback? onSaved;

  const AddEditExpenseScreen({super.key, required this.seasonId, this.categoryId, this.initialExpense, this.onSaved});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    if (widget.initialExpense != null) {
      final e = widget.initialExpense!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toString();
      _storeCtrl.text = e.store ?? '';
      _noteCtrl.text = e.note ?? '';
      _selectedCategoryId = e.categoryId;
      try { _date = DateTime.parse(e.date); } catch (_) {}
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _amountCtrl.dispose(); _storeCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và số tiền')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn hạng mục chi tiêu')));
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (widget.initialExpense == null) {
        await context.read<ExpenseViewModel>().addExpense(
          seasonId: widget.seasonId,
          categoryId: _selectedCategoryId!,
          title: _titleCtrl.text.trim(),
          amount: amount,
          date: _fmtDate(_date),
          store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      } else {
        await context.read<ExpenseViewModel>().updateExpense(
          widget.initialExpense!.id,
          seasonId: widget.seasonId,
          title: _titleCtrl.text.trim(),
          amount: amount,
          date: _fmtDate(_date),
          store: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonVm = context.watch<SeasonViewModel>();
    final categories = seasonVm.categories;

    // Auto-select first category if none selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.initialExpense == null ? 'Thêm chi tiêu' : 'Sửa chi tiêu',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        actions: [_isSaving
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            : TextButton(onPressed: _save, child: const Text('Lưu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Category selector
          _label('HẠNG MỤC *'),
          const SizedBox(height: 8),
          if (categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryId,
                  dropdownColor: AppColors.cardDark,
                  isExpanded: true,
                  style: const TextStyle(color: AppColors.textMain),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Icon(_categoryIcon(c.name), size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(c.name),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
            )
          else
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.centerLeft,
              child: const Text('Chưa có hạng mục. Vui lòng tạo trong "Quản lý hạng mục"',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          const SizedBox(height: 20),
          _label('TÊN CHI TIÊU *'),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, style: const TextStyle(color: AppColors.textMain), autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(hintText: 'VD: Mua bánh chưng')),
          const SizedBox(height: 16),
          _label('SỐ TIỀN *'),
          const SizedBox(height: 8),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: '0', suffixText: ' ₫')),
          const SizedBox(height: 16),
          _label('NGÀY'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _date = d);
            },
            child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
                child: Row(children: [
                  Expanded(child: Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(color: AppColors.textMain))),
                  const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                ])),
          ),
          const SizedBox(height: 16),
          _label('CỬA HÀNG (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(controller: _storeCtrl, style: const TextStyle(color: AppColors.textMain), autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(hintText: 'VD: Siêu thị BigC')),
          const SizedBox(height: 16),
          _label('GHI CHÚ (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(controller: _noteCtrl, style: const TextStyle(color: AppColors.textMain), maxLines: 2, autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(hintText: 'Ghi chú thêm...')),
          const SizedBox(height: 80),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), color: AppColors.background,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined), label: const Text('Lưu chi tiêu'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

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

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600));
}
