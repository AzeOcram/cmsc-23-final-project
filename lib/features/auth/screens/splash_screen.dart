// FILE LOCATION: lib/features/auth/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import '../../home/screens/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _petalController;

  @override
  void initState() {
    super.initState();
    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      _goHome();
    } else {
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.forestDeep,
              AppColors.oliveGreen,
              Color(0xFF4A6520),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background leaf pattern
            ...List.generate(8, (i) => _buildLeaf(i)),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sunflower logo
                  _SunflowerLogo(controller: _petalController).animate().scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 28),

                  // App name
                  Text(
                    'Elbigayan',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                      letterSpacing: 1.2,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    'Share the harvest, grow together',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: AppColors.meadow,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                    ),
                  ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
                ],
              ),
            ),

            // Bottom loader
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.oliveGreen.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.sunflowerGold,
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaf(int index) {
    final positions = [
      const Offset(0.05, 0.1),
      const Offset(0.9, 0.05),
      const Offset(0.15, 0.85),
      const Offset(0.85, 0.8),
      const Offset(0.7, 0.2),
      const Offset(0.2, 0.55),
      const Offset(0.6, 0.7),
      const Offset(0.4, 0.12),
    ];
    final sizes = [60.0, 80.0, 50.0, 70.0, 55.0, 65.0, 45.0, 75.0];

    return Positioned(
      left: MediaQuery.of(context).size.width * positions[index].dx,
      top: MediaQuery.of(context).size.height * positions[index].dy,
      child: Opacity(
        opacity: 0.12,
        child: Icon(
          Icons.eco,
          size: sizes[index],
          color: AppColors.meadow,
        ),
      ).animate(delay: (index * 100).ms).fadeIn(duration: 800.ms).rotate(
            begin: -0.1,
            end: 0.1,
            duration: (2000 + index * 300).ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

class _SunflowerLogo extends StatelessWidget {
  final AnimationController controller;

  const _SunflowerLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating petals
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return Transform.rotate(
              angle: controller.value * 6.28,
              child: _buildPetalsRing(),
            );
          },
        ),
        // Center disk
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.sunflowerDeep, AppColors.barkBrown],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sunflowerDeep.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_florist,
            color: AppColors.cream,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildPetalsRing() {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(painter: _PetalPainter()),
    );
  }
}

class _PetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalPaint = Paint()
      ..color = AppColors.sunflowerGold
      ..style = PaintingStyle.fill;

    final count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2;
      final petalCenter = Offset(
        center.dx +
            46 *
                (angle == 0 ? 1 : (angle > 0 ? 1 : -1) * 1) *
                (0.5 - (i / count - 0.5).abs()) *
                2,
        center.dy,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path();
      path.moveTo(0, -30);
      path.quadraticBezierTo(10, -52, 0, -62);
      path.quadraticBezierTo(-10, -52, 0, -30);

      final gradient = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.sunflowerGold, AppColors.sunflowerDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(-10, -65, 20, 40));

      canvas.drawPath(path, gradient);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
