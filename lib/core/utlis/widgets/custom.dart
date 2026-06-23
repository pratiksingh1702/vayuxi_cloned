import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true, // keeps title visible always
      floating: false, // don't snap instantly
      snap: false,
      expandedHeight: 100, // your full appbar height
      backgroundColor: isDark ? cs.surfaceContainerHigh : cs.surface,
      actions: actions,

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? cs.surfaceContainerHigh : cs.surface)
                            .withOpacity(isDark ? 0.92 : 0.94),
                        cs.surface.withOpacity(isDark ? 0.8 : 0.82),
                        (isDark
                                ? cs.surfaceContainer
                                : cs.surfaceContainerLowest)
                            .withOpacity(isDark ? 0.88 : 0.9),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
