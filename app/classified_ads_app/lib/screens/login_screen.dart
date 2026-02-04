import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'terms_screen.dart';
import '../widgets/responsive_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  // Country code selection
  String _selectedCountryCode = '967'; // Default to Yemen
  final Map<String, Map<String, dynamic>> _countryCodes = {
    '967': {
      'name': 'اليمن',
      'flag': '🇾🇪',
      'minLength': 6,
      'maxLength': 9,
      'validPrefixes': ['7', '0'],
      'example': '77xxxxxxx',
    },
    '966': {
      'name': 'السعودية',
      'flag': '🇸🇦',
      'minLength': 9,
      'maxLength': 9,
      'validPrefixes': ['5'],
      'example': '5xxxxxxxx',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPhone() async {
    if (_formKey.currentState!.validate()) {
      try {
        final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
        await context.read<AuthProvider>().sendOtp(phone);
        
        // Navigate to OTP screen
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(phone: phone),
          ),
        );
        
      } catch (e) {
        if (!mounted) return;
        
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        );
      }
    }
  }

  Future<void> _loginAsGuest() async {
    try {
      await context.read<AuthProvider>().loginAsGuest();
      
      // Navigate to home screen after successful login
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'فشل الدخول كزائر: ${e.toString()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine screen size category
          final isDesktop = constraints.maxWidth > 1200;
          final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 1200;

          
          // Responsive values
          final cardMaxWidth = isDesktop ? 500.0 : (isTablet ? 450.0 : double.infinity);
          final cardPadding = isDesktop ? 48.0 : (isTablet ? 40.0 : 24.0);
          final contentPadding = isDesktop ? 36.0 : (isTablet ? 32.0 : 24.0);
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withAlpha(242),
                  const Color(0xFF4F46E5).withAlpha(242),
                  const Color(0xFF3730A3).withAlpha(242),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: AnimatedStarsPainter(animation: _animationController),
                  ),
                ),
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
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(cardPadding),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _slideAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 24,
                          shadowColor: Colors.black.withAlpha(102),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            padding: EdgeInsets.all(contentPadding),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).cardColor.withAlpha(242),
                                  Theme.of(context).cardColor.withAlpha(250),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // شعار التطبيق
                                  Container(
                                    padding: EdgeInsets.all(isDesktop ? 24 : 20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFF4F46E5),
                                          Color(0xFF3730A3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6).withAlpha(102),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withAlpha(26),
                                          blurRadius: 2,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      size: isDesktop ? 64 : (isTablet ? 58 : 54),
                                      color: Colors.white,
                                      shadows: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  // App Name
                                  ResponsiveText(
                                    'لقطة',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 48 : (isTablet ? 44 : 42),
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).primaryColor,
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF4F46E5),
                                      ],
                                    ).createShader(bounds),
                                    child: ResponsiveText(
                                      'مرحباً بك',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamily: 'NotoSansArabic',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'سجل الدخول برقم الهاتف',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : 15,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      letterSpacing: 0.5,
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  
                                  // حقل رقم الهاتف
                                  _buildPhoneField(),
                                  const SizedBox(height: 32),
                                  
                                  // زر تسجيل الدخول
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      return _buildLoginButton(auth);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // زر الدخول كزائر
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      return _buildGuestButton(auth);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withAlpha(50) : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[800]! : Colors.blue.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'سيتم إنشاء حساب تلقائياً إذا كان رقمك جديد',
                                            style: TextStyle(
                                              color: Colors.blue.shade900,
                                              fontSize: 13,
                                              fontFamily: 'NotoSansArabic',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Legal Links
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TermsScreen(type: TermsType.privacy),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'سياسة الخصوصية',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontFamily: 'NotoSansArabic',
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('|', style: TextStyle(color: Colors.grey.shade300)),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TermsScreen(type: TermsType.terms),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'شروط الاستخدام',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontFamily: 'NotoSansArabic',
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    final countryData = _countryCodes[_selectedCountryCode]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country Code Selector
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
              ),
              items: _countryCodes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(
                        entry.value['flag'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value['name'],
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(+${entry.key})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCountryCode = newValue;
                    _phoneController.clear(); // Clear phone when changing country
                  });
                }
              },
            ),
          ),
        ),
        
        // Phone Number Field
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w500,
            fontFamily: 'Cairo',
          ),
          cursorColor: const Color(0xFF00B0FF),
          cursorWidth: 2,
          cursorRadius: const Radius.circular(1),
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            hintText: countryData['example'],
            alignLabelWithHint: true,
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoSansArabic',
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF00B0FF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSansArabic',
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontFamily: 'Cairo',
            ),
            prefixIcon: Container(
              width: 80,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+$_selectedCountryCode',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00B0FF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade500,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: TextStyle(
              color: Colors.red.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال رقم الهاتف';
            }
            
            final cleanValue = value.replaceAll(RegExp(r'\s+'), '');
            
            if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
              return 'يجب أن يحتوي على أرقام فقط';
            }

            final validPrefixes = countryData['validPrefixes'] as List<dynamic>;
            final hasValidPrefix = validPrefixes.any((prefix) => cleanValue.startsWith(prefix.toString()));
            
            if (!hasValidPrefix) {
              if (_selectedCountryCode == '967') {
                return 'يجب أن يبدأ الرقم بـ 7';
              } else {
                return 'يجب أن يبدأ الرقم بـ 5';
              }
            }
            
            final minLength = countryData['minLength'] as int;
            final maxLength = countryData['maxLength'] as int;
            
            if (cleanValue.length < minLength || cleanValue.length > maxLength) {
              if (minLength == maxLength) {
                return 'رقم الهاتف يجب أن يكون $maxLength أرقام';
              } else {
                return 'رقم الهاتف يجب أن يكون بين $minLength و $maxLength أرقام';
              }
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthProvider auth) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: auth.isLoading ? null : _loginWithPhone,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: auth.isLoading
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : const [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: auth.isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(128),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              if (!auth.isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(26),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: auth.isLoading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontFamily: 'NotoSansArabic',
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(51),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGuestButton(AuthProvider auth) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: auth.isLoading ? null : _loginAsGuest,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF8B5CF6),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  color: const Color(0xFF8B5CF6),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'الدخول كزائر',
                  style: TextStyle(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// رسم النجوم المتحركة في الخلفية
class AnimatedStarsPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedStarsPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(38)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    
    // رسم نجوم ثابتة
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // رسم نجوم متحركة
    final animatedPaint = Paint()
      ..color = Colors.white.withAlpha(((0.25 + 0.1 * math.sin(animation.value * 2 * math.pi)) * 255).toInt())
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + i * 0.05) % 1.0;
      final x = (size.width * 0.3 + size.width * 0.4 * math.sin(progress * 2 * math.pi + i));
      final y = (size.height * 0.3 + size.height * 0.4 * math.cos(progress * 2 * math.pi + i));
      final radius = 1.0 + math.sin(animation.value * 4 * math.pi + i) * 0.5;
      canvas.drawCircle(Offset(x, y), radius, animatedPaint);
    }
    
    // تأثير توهج مركزي
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.white.withAlpha((0.05 * (1 - animation.value) * 255).toInt()),
          Colors.white.withAlpha((0.02 * (1 - animation.value) * 255).toInt()),
          Colors.transparent,
        ],
        radius: 0.3,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 0.5,
      ));
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.3,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}