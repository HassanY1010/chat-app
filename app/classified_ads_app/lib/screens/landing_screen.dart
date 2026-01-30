import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    
    // Check auth status immediately to redirect if already logged in? 
    // User requested: "Main page... with login button". 
    // So even if logged in, maybe show this? 
    // Usually if logged in, we go to Home. 
    // Let's keeping the check in CheckAuthScreen logic but moving the UI here.
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00B0FF), // Light Sky Blue
              const Color(0xFF0091EA), // Darker Blue
              const Color(0xFF01579B), // Deep Blue
            ],
          ),
        ),
        child: Stack(
          children: [
             // Decorative Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: PatternPainter(),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      ScaleTransition(
                        scale: _animationController.drive(
                          CurveTween(curve: Curves.elasticOut),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_rounded, // Placeholder for "Luqta" (Snapshot) concept
                            size: 64,
                            color: Color(0xFF0091EA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // App Name
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const Text(
                                'لقطة',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Description
                              Text(
                                'أفضل سوق إلكتروني في اليمن\nبيع واشتري بكل سهولة وأمان',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.5,
                                  color: Colors.white.withAlpha(242),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Login Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0091EA),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                       const SizedBox(height: 20),
                       // Browse as Guest (Optional, kept small)
                       FadeTransition(
                        opacity: _fadeAnimation,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : TextButton(
                            onPressed: () async {
                               setState(() => _isLoading = true);
                               try {
                                 await context.read<AuthProvider>().loginAsGuest();
                                 if (mounted) {
                                   Navigator.pushReplacementNamed(context, '/home');
                                 }
                               } catch (e) {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطأ: ${e.toString()}')),
                                    );
                                  }
                               }
                            },
                            child: const Text(
                              'تصفح التطبيق كزائر',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                              ),
                            ),
                          ),
                       ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(0, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}