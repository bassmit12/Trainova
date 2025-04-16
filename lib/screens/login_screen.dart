import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor = themeProvider.isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final textPrimaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textLightColor = themeProvider.isDarkMode
        ? AppColors.darkTextLight
        : AppColors.lightTextLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/brands/trainova_v3.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App Title
                  Text(
                    'Trainova',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // App Subtitle
                  Text(
                    'Your Personalized Workout Companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Google Sign-in Button - styled as standard Google OAuth button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: _isLoading
                            ? null
                            : () => _signInWithGoogle(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Using local Google logo from assets
                              Container(
                                height: 38,
                                width: 38,
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  'assets/images/icons/Google.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(
                                      0xFF757575), // Standard Google button text color
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textLightColor),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Google Logo as fallback
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Google logo colors
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);

    // Create paths for each color section
    final Path bluePath = Path()
      ..moveTo(width * 0.75, height * 0.5)
      ..lineTo(width * 0.85, height * 0.5)
      ..arcTo(
        Rect.fromLTWH(width * 0.45, 0, width * 0.55, height),
        -1.57, // -90 degrees in radians
        3.14, // 180 degrees in radians
        false,
      )
      ..lineTo(width * 0.75, height * 0.1)
      ..close();

    final Path redPath = Path()
      ..moveTo(width * 0.25, height * 0.3)
      ..lineTo(width * 0.5, height * 0.3)
      ..lineTo(width * 0.5, height * 0.7)
      ..lineTo(width * 0.25, height * 0.7)
      ..arcTo(
        Rect.fromLTWH(0, height * 0.3, width * 0.5, height * 0.4),
        1.57, // 90 degrees in radians
        3.14, // 180 degrees in radians
        false,
      )
      ..close();

    final Path yellowPath = Path()
      ..moveTo(width * 0.25, height * 0.7)
      ..lineTo(width * 0.5, height * 0.7)
      ..lineTo(width * 0.5, height * 0.92)
      ..arcTo(
        Rect.fromLTWH(width * 0.25, height * 0.6, width * 0.5, height * 0.4),
        -1.57, // -90 degrees in radians
        -1.57, // -90 degrees in radians
        false,
      )
      ..close();

    final Path greenPath = Path()
      ..moveTo(width * 0.5, height * 0.5)
      ..lineTo(width * 0.5, height * 0.7)
      ..lineTo(width * 0.85, height * 0.7)
      ..arcTo(
        Rect.fromLTWH(width * 0.5, height * 0.3, width * 0.35, height * 0.4),
        1.57, // 90 degrees in radians
        -3.14, // -180 degrees in radians
        false,
      )
      ..close();

    // Draw each section
    canvas.drawPath(bluePath, bluePaint);
    canvas.drawPath(redPath, redPaint);
    canvas.drawPath(yellowPath, yellowPaint);
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
