import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import 'featured_ad_card.dart';

class FeaturedAdsSlider extends StatefulWidget {
  const FeaturedAdsSlider({super.key});

  @override
  State<FeaturedAdsSlider> createState() => _FeaturedAdsSliderState();
}

class _FeaturedAdsSliderState extends State<FeaturedAdsSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        if (adProvider.isFeaturedLoading) {
           // Show Shimmer Loading
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 200,
            child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
          );
        }

        final ads = adProvider.featuredAds;

        if (ads.isEmpty) {
          return const SizedBox.shrink(); // Hide if no ads
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: ads.length > 1, // Only auto scroll if > 1
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                aspectRatio: 16/9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: ads.map((ad) {
                return FeaturedAdCard(ad: ad);
              }).toList(),
            ),
            
            // Pagination Dots
            if (ads.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ads.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).primaryColor)
                            .withOpacity(_currentIndex == entry.key ? 0.9 : 0.2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
