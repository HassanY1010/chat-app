import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المساعدة'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqItem(
            'كيف يمكنني إضافة إعلان جديد؟',
            'يمكنك إضافة إعلان جديد بالضغط على زر "+" في أسفل الشاشة الرئيسية، ثم اتباع الخطوات لإدخال تفاصيل الإعلان والصور.',
          ),
          _buildFaqItem(
            'هل التطبيق مجاني؟',
            'نعم، تحميل التطبيق وتصفح الإعلانات مجاني تماماً. بعض الميزات المتقدمة قد تكون مدفوعة.',
          ),
          _buildFaqItem(
            'كيف أتواصل مع البائع؟',
            'يمكنك التواصل مع البائع عبر الدردشة داخل التطبيق أو الاتصال به مباشرة إذا كان قد أتاح رقم هاتفه.',
          ),
          _buildFaqItem(
            'كيف أحذف إعلاني؟',
            'اذهب إلى "إعلاناتي" من صفحة الملف الشخصي، اضغط على الإعلان، ثم اختر "حذف" من القائمة.',
          ),
          _buildFaqItem(
            'نسيت كلمة المرور، ماذا أفعل؟',
            'يمكنك استعادة كلمة المرور عبر رقم الهاتف في شاشة تسجيل الدخول.',
          ),
          _buildFaqItem(
            'كيف أبلغ عن إعلان مخالف؟',
            'داخل صفحة الإعلان، اضغط على زر "إبلاغ" وحدد سبب المخالفة وسيتم مراجعتها من قبل الإدارة.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(fontFamily: 'NotoSansArabic', height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
