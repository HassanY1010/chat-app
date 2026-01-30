import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;

class PdfGenerator {
  static Future<void> generateAndDownload(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load Arabic Font
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    final user = data['user'];
    final stats = data['stats'];
    final ads = data['ads'] as List;
    final reviews = data['reviews'] as List;

    // Use a date formatter compatible with basic string replacing if intl fails for arabic
    final dateFormat = intl.DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
        ),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('تقرير بيانات المستخدم', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('تاريخ التصدير: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // User Info Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('المعلومات الشخصية', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Divider(),
                  _buildInfoRow('الاسم', user['name'] ?? '-'),
                  _buildInfoRow('رقم الهاتف', user['phone'] ?? '-'),
                  _buildInfoRow('تاريخ الانضمام', user['created_at'] != null ? user['created_at'].toString().substring(0, 10) : '-'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Statistics Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                 color: PdfColors.grey50,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('إجمالي الإعلانات', stats['total_ads'].toString()),
                  _buildStatItem('المبيعات', stats['sold_ads'].toString()),
                  _buildStatItem('التقييم', stats['average_rating'].toString()),
                  _buildStatItem('المفضلة', stats['total_favorites'].toString()),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Ads Table
            if (ads.isNotEmpty) ...[
              pw.Text('قائمة الإعلانات', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerRight,
                headers: ['عنوان الإعلان', 'السعر', 'الحالة', 'التاريخ', 'المشاهدات'],
                data: ads.map((ad) => [
                  ad['title'],
                  '${ad['price']} ${ad['currency']}',
                  _translateStatus(ad['status']),
                  ad['created_at'].toString().substring(0, 10),
                  ad['views'].toString(),
                ]).toList(),
              ),
            ],

            pw.SizedBox(height: 20),
            
             // Reviews Section
            if (reviews.isNotEmpty) ...[
              pw.Text('التقييمات المستلمة', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
               pw.SizedBox(height: 10),
               ...reviews.map((review) => pw.Container(
                 margin: const pw.EdgeInsets.only(bottom: 10),
                 padding: const pw.EdgeInsets.all(8),
                 decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                      pw.Row(children: [
                        pw.Text('${review['rating']} / 5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.amber700)),
                        pw.Spacer(),
                        pw.Text(review['created_at'].toString().substring(0, 10), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ]),
                      pw.SizedBox(height: 5),
                      pw.Text(review['comment'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                   ]
                 )
               )).toList(),
            ]

          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'my_data_report.pdf');
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
           pw.SizedBox(width: 100, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
           pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }

  static String _translateStatus(String status) {
    switch (status) {
      case 'active': return 'نشط';
      case 'sold': return 'مباع';
      case 'archived': return 'مؤرشف';
      case 'pending': return 'قيد المراجعة';
      default: return status;
    }
  }
}
