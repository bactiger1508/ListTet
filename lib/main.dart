import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:person_app/viewmodels/season_viewmodel.dart';
import 'package:person_app/viewmodels/dashboard_viewmodel.dart';
import 'package:person_app/viewmodels/shopping_viewmodel.dart';
import 'package:person_app/viewmodels/expense_viewmodel.dart';
import 'package:person_app/viewmodels/deals_viewmodel.dart';
import 'package:person_app/viewmodels/photo_viewmodel.dart';
import 'package:person_app/viewmodels/category_viewmodel.dart';
import 'package:person_app/theme/app_theme.dart';
import 'package:person_app/views/screens/home_screen.dart';
import 'package:person_app/views/screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SeasonViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ItemViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => DealsViewModel()),
        ChangeNotifierProvider(create: (_) => PhotoViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
      ],
      child: MaterialApp(
        title: 'Săn Sale Tết',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(nextScreen: HomeScreen()),
      ),
    );
  }
}