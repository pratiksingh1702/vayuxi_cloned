import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class AdBannerCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final BoxFit boxFit; // New parameter

  const AdBannerCarousel({
    super.key,
    required this.imageUrls,
    this.height = 150,
    this.boxFit = BoxFit.cover, // Default cover
  });


  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: height,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 2),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: imageUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  // In your AdBannerCarousel, you could update the image loading:
                  image: url.startsWith('http')
                      ? NetworkImage(url)
                      : AssetImage(url) as ImageProvider,
                  fit: boxFit,
                ),

              ),
            );
          },
        );
      }).toList(),
    );
  }
}
