import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/deals_viewmodel.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';

class BestDealAlertsScreen extends StatefulWidget {
  const BestDealAlertsScreen({super.key});
  @override
  State<BestDealAlertsScreen> createState() => _BestDealAlertsScreenState();
}

class _BestDealAlertsScreenState extends State<BestDealAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = context.read<SeasonViewModel>().activeSeason;
      if (sid != null) context.read<DealsViewModel>().load(sid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DealsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Săn Deal Tết 🔥', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _chip(context, vm, 'tất_cả', 'Tất cả'),
            _chip(context, vm, 'tốt', '🟢 Deal tốt'),
            _chip(context, vm, 'ổn', '🟡 Gần đạt'),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF991B1B)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Tiết kiệm được', '${(vm.totalSavings / 1000).round()}k ₫'),
              Container(width: 1, height: 36, color: AppColors.textMain24),
              _stat('Deals tìm thấy', '${vm.deals.length} món'),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : vm.filteredDeals.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: vm.filteredDeals.length,
                      itemBuilder: (ctx, i) => _DealCard(item: vm.filteredDeals[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext ctx, DealsViewModel vm, String cat, String label) {
    final active = vm.activeCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => vm.setCategory(cat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? Colors.transparent : AppColors.borderSubtle),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? AppColors.textMain : AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFFFCDD2))),
  ]);

  Widget _empty() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.discount_outlined, size: 64, color: AppColors.textMuted),
      SizedBox(height: 12),
      Text('Chưa có deals nào', style: TextStyle(color: AppColors.textMain, fontSize: 16)),
      SizedBox(height: 4),
      Text('Thêm items và nhập giá hiện tại để xem deals', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]),
  );
}

class _DealCard extends StatelessWidget {
  final Item item;
  const _DealCard({required this.item});

  Color get _color {
    if (item.dealLevel == 'tốt') return Colors.green;
    if (item.dealLevel == 'ổn') return Colors.orange;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withValues(alpha: 0.15)),
          child: Center(child: Text(item.dealLevel == 'tốt' ? '✓' : item.dealLevel == 'ổn' ? '~' : '?',
              style: TextStyle(fontSize: 22, color: _color, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        if (item.store != null)
          Text(item.store!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(children: [
          Text('Mục tiêu: ${_fmt(item.targetPrice)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 10),
          if (item.currentPrice != null)
            Text(_fmt(item.currentPrice!),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _color)),
        ]),
        if (item.savings != 0)
          Text(
            item.savings > 0 
              ? 'Tiết kiệm: ${_fmt(item.savings)}' 
              : 'Vượt mức: ${_fmt(item.savings.abs())}', 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500,
              color: item.savings > 0 ? Colors.green : Colors.red
            )
          ),
      ])),
    ]),
  );

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr ₫' : '${(v / 1000).round()}k ₫';
}
