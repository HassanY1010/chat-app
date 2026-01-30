import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Animations setup
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
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
              const Color(0xFF00B0FF).withAlpha(242),
              const Color(0xFF0091EA).withAlpha(242),
              const Color(0xFF0069B9).withAlpha(242),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Elements
            Positioned.fill(
              child: CustomPaint(
                painter: AnimatedSplashPainter(animation: _animationController),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(13),
                      Colors.transparent,
                      Colors.black.withAlpha(26),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Wave
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withAlpha(13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _slideAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo Container
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFE3F2FD),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(102),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0069B9).withAlpha(77),
                              blurRadius: 40,
                              spreadRadius: 10,
                              offset: const Offset(0, 20),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withAlpha(77),
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00B0FF),
                                        Color(0xFF0091EA),
                                        Color(0xFF0069B9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00B0FF).withAlpha(128),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withAlpha(51),
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withAlpha(128),
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 60,
                                    color: Colors.white,
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App Name with Shader Mask
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFE3F2FD),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'حراج السعودية',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Slogan
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 - _animationController.value * 20),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'منصة البيع والشراء الأفضل',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha(230),
                            letterSpacing: 0.5,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading Indicator
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(77),
                            width: 2,
                          ),
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withAlpha(204),
                          ),
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Loading Text
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (1 - _animationController.value).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - _animationController.value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(204),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
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

// Animated Background Painter
class AnimatedSplashPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedSplashPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(38)
      ..style = PaintingStyle.fill;

    final animatedPaint = Paint()
      ..color = Colors.white.withAlpha((51 + 26 * math.sin(animation.value * 2 * math.pi)).toInt())
      ..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 8; i++) {
      final progress = (animation.value + i * 0.125) % 1.0;
      final x = size.width * 0.1 + size.width * 0.8 * math.sin(progress * 2 * math.pi);
      final y = size.height * 0.2 + size.height * 0.6 * math.cos(progress * 2 * math.pi);
      final radius = 5 + math.sin(animation.value * 4 * math.pi + i) * 3;
      canvas.drawCircle(Offset(x, y), radius, animatedPaint);
    }

    // Draw static circles
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw geometric shapes
    final shapesPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Animated triangle
    final trianglePath = Path();
    final triX = size.width * 0.15 + math.sin(animation.value * math.pi) * 20;
    final triY = size.height * 0.85 + math.cos(animation.value * math.pi) * 20;
    trianglePath.moveTo(triX, triY);
    trianglePath.lineTo(triX - 40, triY + 70);
    trianglePath.lineTo(triX + 40, triY + 70);
    trianglePath.close();
    canvas.drawPath(trianglePath, shapesPaint);

    // Animated square
    final squareSize = 50 + math.sin(animation.value * 3 * math.pi) * 15;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.9, size.height * 0.25),
        width: squareSize,
        height: squareSize,
      ),
      shapesPaint,
    );

    // Center glow effect
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.white.withAlpha((26 * (1 - animation.value)).toInt()),
          Colors.white.withAlpha((5 * (1 - animation.value)).toInt()),
          Colors.transparent,
        ],
        radius: 0.4,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 0.6,
      ));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}