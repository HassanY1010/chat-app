import 'package:flutter/material.dart';

/// App Theme - Centralized Design System
/// Primary: White background
/// Secondary: Light Blue accents
/// Fonts: Cairo, NotoSansArabic (local only)

class AppTheme {
  // ==================== COLORS ====================
  
  /// Primary background color
  static const Color primaryBackground = Colors.white;
  
  /// Secondary color - Light Blue
  static const Color secondaryColor = Color(0xFFADD8E6);
  
  /// Darker shade of light blue for hover/pressed states
  static const Color secondaryDark = Color(0xFF87CEEB);
  
  /// Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  
  /// Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  
  /// Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // ==================== SPACING ====================
  
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // ==================== BORDER RADIUS ====================
  
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // ==================== SHADOWS ====================
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: secondaryColor.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  // ==================== TEXT STYLES ====================
  
  // Cairo Font Styles
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'NotoSansArabic',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'NotoSansArabic',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'NotoSansArabic',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: textSecondary,
    height: 1.5,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: 'NotoSansArabic',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: textHint,
    height: 1.4,
  );
  
  // ==================== COMMON WIDGETS ====================
  
  /// Primary Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    shadowColor: secondaryColor.withOpacity(0.3),
  );
  
  /// Outlined Button Style
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: secondaryColor,
    side: const BorderSide(color: secondaryColor, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
  );
  
  /// Text Button Style
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: secondaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
  
  /// Input Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: bodyMedium.copyWith(color: textHint),
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  
  /// Card Decoration
  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? primaryBackground,
      borderRadius: BorderRadius.circular(radiusL),
      boxShadow: cardShadow,
    );
  }
  
  /// App Bar Theme
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: primaryBackground,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: headingSmall,
    iconTheme: IconThemeData(color: secondaryColor),
  );
  
  /// Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData get bottomNavTheme => BottomNavigationBarThemeData(
    backgroundColor: primaryBackground,
    selectedItemColor: secondaryColor,
    unselectedItemColor: textSecondary,
    selectedLabelStyle: bodySmall.copyWith(fontWeight: FontWeight.w700),
    unselectedLabelStyle: bodySmall,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );
  
  /// Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: primaryBackground,
    primaryColor: secondaryColor,
    colorScheme: const ColorScheme.light(
      primary: secondaryColor,
      secondary: secondaryDark,
      surface: primaryBackground,
      error: error,
    ),
    appBarTheme: appBarTheme,
    bottomNavigationBarTheme: bottomNavTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    inputDecorationTheme: _buildInputDecorationTheme(isDark: false),
    dropdownMenuTheme: _buildDropdownMenuTheme(isDark: false),
    cardTheme: CardThemeData(
      color: primaryBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: headingLarge.copyWith(color: textPrimary),
      displayMedium: headingMedium.copyWith(color: textPrimary),
      displaySmall: headingSmall.copyWith(color: textPrimary),
      headlineMedium: headingMedium.copyWith(color: textPrimary),
      headlineSmall: headingSmall.copyWith(color: textPrimary),
      titleLarge: headingSmall.copyWith(color: textPrimary),
      titleMedium: bodyLarge.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
      titleSmall: bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: bodyLarge.copyWith(color: textPrimary),
      bodyMedium: bodyMedium.copyWith(color: textPrimary),
      bodySmall: bodySmall.copyWith(color: textSecondary),
      labelLarge: buttonText.copyWith(color: Colors.white),
      labelMedium: caption.copyWith(color: textSecondary),
      labelSmall: caption.copyWith(color: textHint),
    ),
    fontFamily: 'NotoSansArabic',
  );

  // ==================== DARK THEME ====================

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: secondaryColor,
    colorScheme: const ColorScheme.dark(
      primary: secondaryColor,
      secondary: secondaryDark,
      surface: surfaceDark,
      error: error,
      onSurface: textPrimaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headingSmall.copyWith(color: textPrimaryDark),
      iconTheme: const IconThemeData(color: secondaryColor),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: secondaryColor,
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: headingLarge.copyWith(color: textPrimaryDark),
      displayMedium: headingMedium.copyWith(color: textPrimaryDark),
      displaySmall: headingSmall.copyWith(color: textPrimaryDark),
      headlineMedium: headingMedium.copyWith(color: textPrimaryDark),
      headlineSmall: headingSmall.copyWith(color: textPrimaryDark),
      titleLarge: headingSmall.copyWith(color: textPrimaryDark),
      titleMedium: bodyLarge.copyWith(color: textPrimaryDark, fontWeight: FontWeight.bold),
      titleSmall: bodyMedium.copyWith(color: textPrimaryDark, fontWeight: FontWeight.bold),
      bodyLarge: bodyLarge.copyWith(color: textPrimaryDark),
      bodyMedium: bodyMedium.copyWith(color: textPrimaryDark),
      bodySmall: bodySmall.copyWith(color: textSecondaryDark),
      labelLarge: buttonText.copyWith(color: Colors.white),
      labelMedium: caption.copyWith(color: textSecondaryDark),
      labelSmall: caption.copyWith(color: textHint),
    ),
    inputDecorationTheme: _buildInputDecorationTheme(isDark: true),
    dropdownMenuTheme: _buildDropdownMenuTheme(isDark: true),
    fontFamily: 'NotoSansArabic',
  );

  // ==================== SHARED DECORATIONS ====================

  static InputDecorationTheme _buildInputDecorationTheme({required bool isDark}) {
    final bgColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFF);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
    final textColor = isDark ? textPrimaryDark : textPrimary;
    
    return InputDecorationTheme(
      filled: true,
      fillColor: bgColor,
      // ✅ تحسين وضوح النص المدخل (مثل السعر) بجعله داكناً وواضحاً
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: TextStyle(
        color: isDark ? textSecondaryDark : textHint,
        fontSize: 14,
        fontFamily: 'NotoSansArabic',
      ),
      labelStyle: TextStyle(
        color: isDark ? textPrimaryDark : textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      // ✅ نمط النص المدخل الفعلي
      suffixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      border: _buildOutlineBorder(borderColor),
      enabledBorder: _buildOutlineBorder(borderColor),
      focusedBorder: _buildOutlineBorder(secondaryColor, width: 2),
      errorBorder: _buildOutlineBorder(error),
      focusedErrorBorder: _buildOutlineBorder(error, width: 2),
    );
  }

  static DropdownMenuThemeData _buildDropdownMenuTheme({required bool isDark}) {
    return DropdownMenuThemeData(
      textStyle: TextStyle(
        color: isDark ? textPrimaryDark : textPrimary, // ✅ حل مشكلة النص الرمادي في الـ Dropdown
        fontSize: 16,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w600,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(isDark ? surfaceDark : Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        ),
      ),
    );
  }

  static OutlineInputBorder _buildOutlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
