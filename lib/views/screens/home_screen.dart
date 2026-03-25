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
import 'package:person_app/viewmodels/navigation_viewmodel.dart';
import 'package:person_app/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation state moved to NavigationViewModel

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeasonViewModel>().loadSeasons().then((_) => _reloadAllData());
    });
  }

  void _reloadAllData() {
    final seasonVm = context.read<SeasonViewModel>();
    final seasonId = seasonVm.activeSeason;
    if (seasonId != null) {
      final season = seasonVm.currentSeason;
      context.read<DashboardViewModel>().load(
        seasonId, 
        seasonName: season?.name, 
        startDate: season?.startDate,
        endDate: season?.endDate
      );
      context.read<ItemViewModel>().load(seasonId);
      context.read<ExpenseViewModel>().load(seasonId);
      context.read<DealsViewModel>().load(seasonId);
      context.read<PhotoViewModel>().load(seasonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navVm = context.watch<NavigationViewModel>();

    return Scaffold(
      body: IndexedStack(
        index: navVm.currentIndex,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.1), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: navVm.currentIndex,
              onTap: (i) {
                navVm.setIndex(i);
                _reloadAllData();
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Tổng quan'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Chi tiêu'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart_rounded), label: 'Cần mua'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: 'Mùa Tết'),
                BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library_rounded), label: 'Thư viện'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
