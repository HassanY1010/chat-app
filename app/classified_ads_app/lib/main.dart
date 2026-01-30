import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/ad_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notification_provider.dart';

import 'providers/settings_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

import 'screens/login_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'package:classified_ads_app/utils/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/create_ad_screen.dart';
import 'screens/delete_ad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة مدير الجلسة واكتشاف السيرفر
  await AppConstants.init();
  await SessionService.instance.init();
  
  ApiService.instance.setBaseUrl(AppConstants.baseUrl);

  // ✅ تحميل التوكين مسبقاً من مدير الجلسة لضمان استمرارية الجلسة
  final savedToken = SessionService.instance.getToken();
  if (savedToken != null) {
    ApiService.instance.setToken(savedToken);
  }

  // ✅ منع Flutter Web من تحميل أي خطوط خارجية مثل Roboto وGoogle Fonts
  if (kIsWeb) {
    // تعطيل رسائل الخطأ من الخطوط فقط، وليس كل الأخطاء
    FlutterError.onError = (FlutterErrorDetails details) {
      if (!details.toString().contains('font')) {
        FlutterError.presentError(details);
      }
    };
  }


  try {
    await initializeDateFormatting('ar', null);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error initializing date formatting: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Background initialization after app starts
  _initBackgroundServices();
}

void _initBackgroundServices() async {
  try {
    await NotificationService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error initializing NotificationService: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'لقطة',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: settings.locale,
          home: const CheckAuthScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/landing': (context) => const LandingScreen(),
            '/create-ad': (context) => const CreateAdScreen(),
            '/delete-ads': (context) => const DeleteAdScreen(),
          },
          builder: (context, child) {
            // إجبار كل النصوص على RTL
            return Directionality(
              textDirection: settings.locale.languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
              child: child!,
            );
          },
        );
      },
    );
  }
}

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuthProvider>().checkAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingAuth) {
          return const AuthSplashScreen();
        }
        
        if (auth.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LandingScreen();
        }
      },
    );
  }
}

class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00B0FF), Color(0xFF01579B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(AppIcons.camera, width: 64, colorFilter: const ColorFilter.mode(Color(0xFF0091EA), BlendMode.srcIn)),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
