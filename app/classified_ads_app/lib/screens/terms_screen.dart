import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum TermsType {
  privacy,
  terms,
}

class TermsScreen extends StatelessWidget {
  final TermsType type;

  const TermsScreen({super.key, required this.type});

  String get _title => type == TermsType.privacy ? 'سياسة الخصوصية' : 'شروط الاستخدام';

  String get _content {
    if (type == TermsType.privacy) {
      return '''
سياسة الخصوصية لتطبيق لقطة

نحن نأخذ خصوصيتك على محمل الجد. توضح هذه السياسة كيفية جمعنا واستخدامنا وحمايتنا لبياناتك الشخصية.

1. البيانات التي نجمعها
نقوم بجمع البيانات التي تقدمها لنا عند التسجيل، مثل الاسم ورقم الهاتف. كما قد نجمع بيانات حول استخدامك للتطبيق.

2. استخدام البيانات
نستخدم بياناتك لتقديم خدماتنا، وتحسين تجربة المستخدم، والتواصل معك بشأن حسابك أو إعلاناتك.

3. مشاركة البيانات
لا نشارك بياناتك الشخصية مع أطراف ثالثة إلا في الحالات التي يتطلبها القانون أو لتقديم خدماتنا (مثل مزودي خدمات الدفع).

4. الأمان
نتخذ تدابير أمنية معقولة لحماية بياناتك من الوصول غير المصرح به.

5. حقوقك
لديك الحق في الوصول إلى بياناتك وتصحيحها وحذفها. يمكنك حذف حسابك في أي وقت من إعدادات التطبيق.
''';
    } else {
      return '''
شروط الاستخدام لتطبيق لقطة

يرجى قراءة شروط الاستخدام هذه بعناية قبل استخدام التطبيق.

1. القبول بالشروط
بمجرد استخدامك لتطبيق لقطة، فإنك توافق على الالتزام بهذه الشروط.

2. الحساب
أنت مسؤول عن الحفاظ على سرية معلومات حسابك، وعن جميع الأنشطة التي تحدث تحت حسابك.

3. المحتوى المحظور
يمنع نشر إعلانات لمنتجات غير قانونية، أو مسيئة، أو تنتهك حقوق الملكية الفكرية للآخرين.

4. السلوك
يجب عليك استخدام التطبيق بطريقة قانونية ومحترمة. يمنع مضايقة المستخدمين الآخرين أو الاحتيال عليهم.

5. إنهاء الخدمة
نحتفظ بالحق في إيقاف حسابك إذا خالفت هذه الشروط.

6. التغييرات
قد نقوم بتحديث هذه الشروط من وقت لآخر. سيتم إشعارك بأي تغييرات جوهورية.
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        actions: type == TermsType.privacy ? [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'عرض النسخة المحدثة أونلاين',
            onPressed: () async {
              final url = Uri.parse('https://hassany1010.github.io/laqta-privacy/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          )
        ] : null,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          _content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.8,
            fontFamily: 'NotoSansArabic',
          ),
        ),
      ),
    );
  }
}
