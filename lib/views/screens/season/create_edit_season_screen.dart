import 'package:flutter/material.dart';
import 'package:person_app/theme/app_colors.dart';

class CreateEditSeasonScreen extends StatefulWidget {
  final String? initialName;
  final String? initialStartDate;
  final String? initialEndDate;
  final int? initialBudget;
  final Future<void> Function(String name, String? startDate, String? endDate, int? budgetLimit) onSaved;

  const CreateEditSeasonScreen({super.key, this.initialName, this.initialStartDate, this.initialEndDate, this.initialBudget, required this.onSaved});

  @override
  State<CreateEditSeasonScreen> createState() => _CreateEditSeasonScreenState();
}

class _CreateEditSeasonScreenState extends State<CreateEditSeasonScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _budgetCtrl;
  DateTime? _start;
  DateTime? _end;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? 'Tết 2026');
    _budgetCtrl = TextEditingController(text: widget.initialBudget?.toString() ?? '');
    if (widget.initialStartDate != null) _start = DateTime.tryParse(widget.initialStartDate!);
    if (widget.initialEndDate != null) _end = DateTime.tryParse(widget.initialEndDate!);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _budgetCtrl.dispose(); super.dispose(); }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
      return;
    }
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày kết thúc không được trước ngày bắt đầu')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final budgetLimit = int.tryParse(_budgetCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      await widget.onSaved(_nameCtrl.text.trim(), _start != null ? _fmt(_start!) : null, _end != null ? _fmt(_end!) : null, budgetLimit);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          TextField(controller: _nameCtrl, style: const TextStyle(color: AppColors.textMain), autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(hintText: 'VD: Tết Ất Tỵ 2025')),
          const SizedBox(height: 16),
          _label('NGÂN SÁCH DỰ KIẾN (VNĐ)'),
          const SizedBox(height: 8),
          TextField(controller: _budgetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textMain), decoration: const InputDecoration(hintText: 'VD: 10000000')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('NGÀY BẮT ĐẦU'),
              const SizedBox(height: 8),
              _dateBtn(_start, 'Chọn ngày', (d) { setState(() { _start = d; if (_end != null && _end!.isBefore(_start!)) _end = null; }); }, firstDate: DateTime(2020)),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('NGÀY KẾT THÚC'),
              const SizedBox(height: 8),
              _dateBtn(_end, 'Chọn ngày', (d) => setState(() => _end = d), firstDate: _start ?? DateTime(2020)),
            ])),
          ]),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cardDark.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Sẽ tự tạo 6 hạng mục mặc định\n(Thực phẩm, Đồ uống, Quần áo, Trang trí, Quà tặng, Khác)',
                    style: TextStyle(fontSize: 12, color: AppColors.textMain70))),
              ])),
          const SizedBox(height: 80),
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

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600));

  Widget _dateBtn(DateTime? date, String hint, ValueChanged<DateTime> onPick, {required DateTime firstDate}) => GestureDetector(
    onTap: () async {
      final initialDate = date != null && !date.isBefore(firstDate) ? date : (firstDate.isAfter(DateTime.now()) ? firstDate : DateTime.now());
      final d = await showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: DateTime(2030));
      if (d != null) onPick(d);
    },
    child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
        child: Row(children: [
          Expanded(child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : hint,
              style: TextStyle(color: date != null ? AppColors.textMain : AppColors.textMuted))),
          const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
        ])),
  );
}
