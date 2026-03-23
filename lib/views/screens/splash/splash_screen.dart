import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:person_app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (c, a1, a2) => widget.nextScreen,
          transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              Color(0xFF8E0000), // Một tông đỏ đậm hơn
              AppColors.primaryDark,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGold.withOpacity(0.15),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.shopping_bag, size: 56, color: AppColors.accentGold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Opacity(
                opacity: _fadeIn.value,
                child: Text('Săn Sale Tết',
                    style: GoogleFonts.dancingScript(
                      fontSize: 42, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.accentGold, 
                      letterSpacing: 1.5
                    )),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Opacity(
                opacity: _fadeIn.value,
                child: const Text('Mua sắm thông minh — Tết vui trọn vẹn',
                    style: TextStyle(fontSize: 14, color: AppColors.accentGold, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 40),

              // Loading
              Opacity(
                opacity: _fadeIn.value,
                child: const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentGold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
