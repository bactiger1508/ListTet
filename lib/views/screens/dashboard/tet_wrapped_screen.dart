import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:person_app/theme/app_colors.dart';
import 'package:person_app/viewmodels/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';

class TetWrappedScreen extends StatefulWidget {
  final String seasonName;
  const TetWrappedScreen({super.key, required this.seasonName});

  @override
  State<TetWrappedScreen> createState() => _TetWrappedScreenState();
}

class _TetWrappedScreenState extends State<TetWrappedScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportImage() async {
    setState(() => _isExporting = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/TetWrapped_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Mở bảng Share để người dùng lưu ảnh về máy hoặc gửi qua app khác
        await Share.shareXFiles([XFile(path)], text: 'Tổng kết mua sắm Tết: ${widget.seasonName}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xuất ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    try {
      final expenses = context.read<ExpenseViewModel>().expenses;
      
      List<List<dynamic>> rows = [];
      // Header
      rows.add(["Ngày", "Khoản chi", "Cửa hàng/Ghi chú", "Đơn giá", "Số lượng", "Thành tiền"]);
      // Data
      for (final e in expenses) {
        rows.add([
          e.date ?? '',
          e.title,
          e.store ?? '',
          e.unitPrice ?? '',
          e.quantity ?? 1,
          e.amount
        ]);
      }
      
      // Calculate total
      final int total = expenses.fold<int>(0, (sum, e) => sum + e.amount);
      rows.add([]);
      rows.add(["", "", "", "", "Tổng Cộng:", total]);

      String csvData = csv.encode(rows);
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/ChiTieuTet_${widget.seasonName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      
      // Write BOM and UTF-8 encoded string for Excel compatibility
      await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);

      if (mounted) {
        await Share.shareXFiles([XFile(path)], text: 'Báo cáo chi tiêu: ${widget.seasonName}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xuất CSV: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    
    return Scaffold(
      backgroundColor: AppColors.cardDark,
      appBar: AppBar(
        title: const Text('Tổng kết Tết', style: TextStyle(color: AppColors.accentGold)),
        backgroundColor: Colors.transparent,
        actions: [
          _isExporting 
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2)))
            : PopupMenuButton<String>(
                icon: const Icon(Icons.download, color: AppColors.accentGold),
                color: AppColors.cardDark,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'image', child: Text('Lưu Ảnh Tổng Kết (PNG)', style: TextStyle(color: AppColors.textMain))),
                  const PopupMenuItem(value: 'csv', child: Text('Xuất Báo Cáo Chi Tiêu (CSV)', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold))),
                ],
                onSelected: (val) {
                  if (val == 'image') _exportImage();
                  if (val == 'csv') _exportCSV();
                },
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E0E00), Color(0xFF1F1C18)], // Deep premium red/brown
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 48),
                const SizedBox(height: 16),
                Text(widget.seasonName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                const Text('TỔNG KẾT MUA SẮM TẾT', style: TextStyle(letterSpacing: 2, fontSize: 12, color: Colors.white60)),
                
                const SizedBox(height: 48),
                _wrappedStat('Tổng chi tiêu', vm.totalSpentFormatted, Icons.account_balance_wallet_outlined),
                _wrappedStat('Số món đã sắm', '${vm.totalItems - vm.pendingItems} món', Icons.shopping_bag_outlined),
                _wrappedStat('Số tiền tiết kiệm', vm.budgetVarianceFormatted, Icons.savings_outlined),
                _wrappedStat('Kỷ lục mua sắm', vm.recentExpenses.isNotEmpty ? vm.recentExpenses.first.title : 'N/A', Icons.emoji_events_outlined),
                
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text('LỜI CHÚC TỪ APP', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                        'Chúc bạn một năm mới An Khang Thịnh Vượng, Vạn Sự Như Ý! Cảm ơn bạn đã đồng hành cùng ứng dụng săn Sale Tết.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                const Opacity(
                  opacity: 0.5,
                  child: Text('Được tạo bởi Tet Shopping Assistant', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrappedStat(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.accentGold, size: 28),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
