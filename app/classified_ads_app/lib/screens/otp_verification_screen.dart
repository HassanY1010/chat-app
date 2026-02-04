import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;

  const OtpVerificationScreen({super.key, required this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  
  // Progressive Timer Logic
  int _start = 60; // Initial wait 1 minute
  int _resendAttempts = 0;
  static const int _maxResendAttempts = 3; // 0 (1m), 1 (3m), 2 (5m), 3 (10m) -> Then Support
  static const String _supportNumber = '782305677'; 
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Get duration based on attempts: 1m, 3m, 5m, 10m
  int _getTimerDuration(int attempt) {
    switch (attempt) {
      case 0: return 60;   // 1 minute
      case 1: return 180;  // 3 minutes
      case 2: return 300;  // 5 minutes
      case 3: return 600;  // 10 minutes
      default: return 600;
    }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    String code = _controllers.map((e) => e.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كود التحقق كاملاً', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().verifyOtp(widget.phone, code);
      if (success) {
        if (!mounted) return;
        _showOathDialog();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كود التحقق غير صحيح، يرجى التأكد وإعادة المحاولة', style: TextStyle(fontFamily: 'NotoSansArabic')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      } catch (e) {
        if (!mounted) return;
        
        String errorMessage = e.toString();
        // Remove 'Exception: ' prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontFamily: 'NotoSansArabic')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOathDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, size: 40, color: Colors.amber),
                ),
                const SizedBox(height: 20),
                const Text(
                  'إقرار وإلتزام',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'أقسم بالله العظيم، وبذمتي إلى يوم الدين، أنني أتعهد بدفع عمولة قدرها (1%) لإدارة التطبيق بالتواصل معهم في حال تم شراء أي سلعة عن طريق التطبيق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6DFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'أوافق وألتزم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resendOtp() async {
    // Increase attempts
    int nextAttempt = _resendAttempts + 1;
    
    setState(() {
      _resendAttempts = nextAttempt;
      _start = _getTimerDuration(nextAttempt);
      _isLoading = true;
    });
    startTimer();

    try {
      await context.read<AuthProvider>().sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال الرمز', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage, style: const TextStyle(fontFamily: 'NotoSansArabic'))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canResend = _start == 0 && _resendAttempts < _maxResendAttempts;
    bool showSupport = _start == 0 && _resendAttempts >= _maxResendAttempts;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFE8EAF6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'تأكيد رقم الهاتف',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic',
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم إرسال رمز التحقق إلى الرقم\n${widget.phone}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
                fontFamily: 'Cairo', // Using Cairo for numbers
              ),
            ),
            const SizedBox(height: 40),
            
            // OTP Fields
            LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final double spacing = 10.0; // Desired spacing
                final int count = 6;
                // Calculate max width per item to fit in row
                // Total width = (width * count) + (spacing * (count - 1))
                // width * count = Total width - (spacing * (count - 1))
                // width = (Total width - (spacing * (count - 1))) / count
                final double itemWidth = (availableWidth - (spacing * (count - 1))) / count;
                // Clamp width to maximum 45 to avoid giant inputs on tablets
                final double finalWidth = itemWidth > 45 ? 45 : itemWidth;
                
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: finalWidth,
                        height: 55,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(fontSize: finalWidth * 0.5, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                                _verifyOtp();
                              }
                            } else {
                               if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),
                );
              }
            ),
            
            const SizedBox(height: 40),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'تحقق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timer and Resend Logic
            if (showSupport)
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withAlpha(50) : Colors.red.shade50,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.red.shade200),
                 ),
                 child: Column(
                   children: [
                     const Text(
                       'تجاوزت الحد المسموح لإعادة الإرسال',
                       style: TextStyle(
                         fontFamily: 'NotoSansArabic',
                         color: Colors.red,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       'يرجى التواصل مع الدعم الفني:',
                       style: TextStyle(
                         fontFamily: 'NotoSansArabic',
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                       ),
                     ),
                     const SizedBox(height: 4),
                     SelectableText(
                       _supportNumber,
                       style: TextStyle(
                         fontFamily: 'Cairo',
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).primaryColor,
                       ),
                     ),
                   ],
                 ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'لم يصلك الرمز؟ ',
                    style: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.grey),
                  ),
                  if (_start > 0)
                    Text(
                      timerText,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  else if (canResend)
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'إعادة إرسال',
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
