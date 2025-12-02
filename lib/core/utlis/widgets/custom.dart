import 'package:flutter/material.dart';
class CustomSliverAppBar extends StatelessWidget {
  final String title;

  const CustomSliverAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,        // keeps title visible always
      floating: false,     // don't snap instantly
      snap: false,
      expandedHeight: 100, // your full appbar height
      backgroundColor: Colors.white,

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            centerTitle: true,

            background: Stack(
              children: [
                // Background image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/images/Firefly_A seamless pattern on a white background, featuring various simple, breathable, blue  303856.webp",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // White overlay
                Container(
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
