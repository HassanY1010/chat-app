import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../screens/ad_details_screen.dart';
import '../utils/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdCard extends StatelessWidget {
  final dynamic ad;

  const AdCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailsScreen(ad: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'ad-image-${ad['id']}',
                  child: CachedNetworkImage(
                    imageUrl: ad['main_image']?['image_url'] ?? '',
                    fit: BoxFit.cover,
                    memCacheWidth: 800, // Optimized for memory
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ad['title'] ?? 'بدون عنوان',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A6DFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ad['price'] ?? '0'} ${ad['currency'] ?? ''}',
                          style: const TextStyle(
                            color: Color(0xFF4A6DFF),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        ad['location'] ?? 'غير محدد',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(ad['created_at']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'منذ فترة';
    try {
      final date = DateTime.parse(dateStr);
      return timeago.format(date, locale: 'ar');
    } catch (e) {
      return 'قبل قليل';
    }
  }
}
