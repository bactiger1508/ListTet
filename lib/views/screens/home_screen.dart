import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/dashboard_viewmodel.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/deals_viewmodel.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
import 'package:person_app/views/screens/dashboard/main_dashboard_screen.dart';
import 'package:person_app/views/screens/expense/daily_expense_screen.dart';
import 'package:person_app/views/screens/season/season_management_screen.dart';
import 'package:person_app/views/screens/shopping/shopping_wishlist_screen.dart';
import 'package:person_app/views/screens/media/media_receipt_gallery_screen.dart';
import 'package:person_app/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeasonViewModel>().loadSeasons().then((_) => _reloadAllData());
    });
  }

  void _reloadAllData() {
    final seasonId = context.read<SeasonViewModel>().activeSeason;
    if (seasonId != null) {
      context.read<DashboardViewModel>().load(seasonId);
      context.read<ItemViewModel>().load(seasonId);
      context.read<ExpenseViewModel>().load(seasonId);
      context.read<DealsViewModel>().load(seasonId);
      context.read<PhotoViewModel>().load(seasonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MainDashboardScreen(),
          DailyExpenseScreen(),
          ShoppingWishlistScreen(),
          SeasonManagementScreen(),
          MediaReceiptGalleryScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              _reloadAllData();
            },
            backgroundColor: AppColors.background,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tổng quan'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Chi tiêu'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cần mua'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Kỳ Tết'),
              BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library), label: 'Thư viện'),
            ],
          ),
        ),
      ),
    );
  }
}
