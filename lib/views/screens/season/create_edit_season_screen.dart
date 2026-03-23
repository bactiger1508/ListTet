import 'package:flutter/material.dart';
import 'package:person_app/theme/app_colors.dart';

class CreateEditSeasonScreen extends StatefulWidget {
  final String? initialName;
  final String? initialStartDate;
  final String? initialEndDate;
  final int? initialBudget;
  final Future<void> Function(String name, String? startDate, String? endDate, int? budgetLimit, List<Map<String, dynamic>>? categoriesData) onSaved;

  const CreateEditSeasonScreen({super.key, this.initialName, this.initialStartDate, this.initialEndDate, this.initialBudget, required this.onSaved});

  @override
  State<CreateEditSeasonScreen> createState() => _CreateEditSeasonScreenState();
}

class _CategoryInput {
  final TextEditingController nameCtrl;
  final TextEditingController budgetCtrl;
  final String icon;
  final String color;

  _CategoryInput({required String name, int budget = 0, this.icon = 'category', this.color = '0xFF9E9E9E'})
    : nameCtrl = TextEditingController(text: name),
      budgetCtrl = TextEditingController(text: budget > 0 ? budget.toString() : '');
      
  void dispose() { nameCtrl.dispose(); budgetCtrl.dispose(); }
}

class _CreateEditSeasonScreenState extends State<CreateEditSeasonScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _budgetCtrl;
  final List<_CategoryInput> _categories = [];
  DateTime? _start;
  DateTime? _end;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final nextYear = DateTime.now().year + (DateTime.now().month > 2 ? 1 : 0);
    _nameCtrl = TextEditingController(text: widget.initialName ?? 'Tết $nextYear');
    _budgetCtrl = TextEditingController(text: widget.initialBudget?.toString() ?? '');
    if (widget.initialStartDate != null) _start = DateTime.tryParse(widget.initialStartDate!);
    if (widget.initialEndDate != null) _end = DateTime.tryParse(widget.initialEndDate!);

    if (widget.initialName == null) {
      // Default categories for new season
      _categories.addAll([
        _CategoryInput(name: 'Thực phẩm', icon: 'restaurant', color: '0xFF4CAF50'),
        _CategoryInput(name: 'Đồ uống', icon: 'local_bar', color: '0xFF2196F3'),
        _CategoryInput(name: 'Quần áo', icon: 'checkroom', color: '0xFFFF9800'),
        _CategoryInput(name: 'Trang trí', icon: 'home', color: '0xFFE91E63'),
        _CategoryInput(name: 'Quà tặng', icon: 'featured_video', color: '0xFF9C27B0'),
        _CategoryInput(name: 'Khác', icon: 'more_horiz', color: '0xFF607D8B'),
      ]);
    }
  }

  @override
  void dispose() { 
    _nameCtrl.dispose(); 
    _budgetCtrl.dispose(); 
    for (var c in _categories) { c.dispose(); }
    super.dispose(); 
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final budgetLimit = int.tryParse(_budgetCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      
      List<Map<String, dynamic>>? catsData;
      if (widget.initialName == null) {
        catsData = _categories.map((c) => {
          'name': c.nameCtrl.text,
          'budget': int.tryParse(c.budgetCtrl.text) ?? 0,
          'icon': c.icon,
          'color': c.color,
        }).toList();
      }

      await widget.onSaved(
        _nameCtrl.text.trim(), 
        _start != null ? _fmt(_start!) : null, 
        _end != null ? _fmt(_end!) : null, 
        budgetLimit,
        catsData,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(_budgetCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final allocated = _categories.fold(0, (s, c) => s + (int.tryParse(c.budgetCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0));
    final remaining = total - allocated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.initialName == null ? 'Tạo kỳ mới' : 'Sửa kỳ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('TÊN KỲ'),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, style: const TextStyle(color: AppColors.textMain), decoration: const InputDecoration(hintText: 'VD: Tết Ất Tỵ 2025')),
          
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _dateSection('BẮT ĐẦU', _start, (d) => setState(() => _start = d))),
            const SizedBox(width: 16),
            Expanded(child: _dateSection('KẾT THÚC', _end, (d) => setState(() => _end = d))),
          ]),

          const SizedBox(height: 24),
          _label('TỔNG NGÂN SÁCH (VNĐ)'),
          const SizedBox(height: 8),
          TextField(controller: _budgetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold), 
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'VD: 10000000', prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary))),

          if (widget.initialName == null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  _stat('Tổng ngân sách', total),
                  const VerticalDivider(width: 32),
                  _stat('Đã phân bổ', allocated, color: AppColors.primary),
                  const VerticalDivider(width: 32),
                  _stat(remaining >= 0 ? 'Còn lại' : 'Vượt mức', remaining.abs(), color: remaining >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label('PHÂN BỔ NGÂN SÁCH HẠNG MỤC'),
              TextButton.icon(
                onPressed: () => setState(() => _categories.add(_CategoryInput(name: 'Hạng mục mới'))),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm', style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderMuted),
                itemBuilder: (ctx, i) => _categoryRow(i),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), color: AppColors.background,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.initialName == null ? 'Tạo kỳ mới' : 'Lưu thay đổi'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _categoryRow(int i) {
    final cat = _categories[i];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(flex: 3, child: TextField(controller: cat.nameCtrl, style: const TextStyle(fontSize: 14, color: AppColors.textMain), decoration: const InputDecoration(hintText: 'Tên hạng mục', border: InputBorder.none))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: TextField(controller: cat.budgetCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary), 
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'VND', border: InputBorder.none))),
        if (i >= 6) // Allow removing custom ones
          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18), onPressed: () => setState(() => _categories.removeAt(i))),
      ]),
    );
  }

  Widget _stat(String label, int value, {Color? color}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(_fmtVnd(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppColors.textMain)),
      ],
    ),
  );

  String _fmtVnd(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr' : '${(v / 1000).round()}k';

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600));

  Widget _dateSection(String label, DateTime? date, ValueChanged<DateTime> onPick) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label),
    const SizedBox(height: 8),
    _dateBtn(date, 'Chọn ngày', onPick, firstDate: DateTime(2020)),
  ]);

  Widget _dateBtn(DateTime? date, String hint, ValueChanged<DateTime> onPick, {required DateTime firstDate}) => GestureDetector(
    onTap: () async {
      // Try to guess the year from the name, otherwise use current year
      int? yearFromName = int.tryParse(RegExp(r'\d{4}').firstMatch(_nameCtrl.text)?.group(0) ?? '');
      final defaultDate = yearFromName != null ? DateTime(yearFromName, 1, 20) : DateTime.now();
      
      final initialDate = date != null && !date.isBefore(firstDate) ? date : (firstDate.isAfter(defaultDate) ? firstDate : defaultDate);
      final d = await showDatePicker(
        context: context, 
        initialDate: initialDate, 
        firstDate: DateTime(2020), 
        lastDate: DateTime(2050)
      );
      if (d != null) onPick(d);
    },
    child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
        child: Row(children: [
          Expanded(child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : hint,
              style: TextStyle(color: date != null ? AppColors.textMain : AppColors.textMuted, fontSize: 13))),
          const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
        ])),
  );
}
