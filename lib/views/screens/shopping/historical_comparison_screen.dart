import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/data/models/item.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';

class HistoricalComparisonScreen extends StatefulWidget {
  final String itemName;
  final String currentSeasonId;

  const HistoricalComparisonScreen({super.key, required this.itemName, required this.currentSeasonId});

  @override
  State<HistoricalComparisonScreen> createState() => _HistoricalComparisonScreenState();
}

class _HistoricalComparisonScreenState extends State<HistoricalComparisonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemViewModel>().loadHistoricalData(widget.itemName, widget.currentSeasonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Lịch sử: ${widget.itemName}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.historicalItems.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.historicalItems.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) => _HistoricalCard(item: vm.historicalItems[i]),
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.query_stats, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 16),
      const Text('Chưa có dữ liệu năm cũ', style: TextStyle(fontSize: 18, color: AppColors.textMain)),
      const SizedBox(height: 8),
      Text('Không tìm thấy món "${widget.itemName}" trong các kỳ Tết khác.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
    ]),
  );
}

class _HistoricalCard extends StatelessWidget {
  final Item item;
  const _HistoricalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Kỳ Tết trước đó', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
          Text(_fmtDate(item.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.imagePath != null && File(item.imagePath!).existsSync())
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(item.imagePath!), width: 100, height: 100, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 100, height: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
            ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 6),
            Text('Đã mua: ${_fmt(item.currentPrice ?? item.targetPrice)} ₫',
                style: const TextStyle(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w600)),
            if (item.store != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Tại: ${item.store}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
            if (item.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('"${item.note}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
              ),
          ])),
        ]),
      ]),
    );
  }

  String _fmt(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}tr' : '${(v / 1000).round()}k';
  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day}/${d.month}/${d.year}';
  }
}
