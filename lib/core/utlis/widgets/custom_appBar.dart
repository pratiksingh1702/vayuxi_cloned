import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawer; // Option to hide drawer on certain screens

  const CustomAppBar({
    super.key,
    required this.title,
    this.showDrawer = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "assets/images/Firefly_A seamless pattern on a white background, featuring various simple, breathable, blue  303856.webp",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: showDrawer ? 16 : 16,
          right: 16,
          bottom: 10,
        ),
        child: Row(
          children: [
            // 🔹 MENU BUTTON TO OPEN DRAWER
            if (showDrawer)
              Builder(
                builder: (context) => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(10),

                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),

            // 🔹 TITLE
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(left: showDrawer ? 0 : 0),
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 SPACER TO BALANCE MENU BUTTON
            if (showDrawer)
              const SizedBox(width: 48), // Same width as IconButton
          ],
        ),
      ),
    );
  }
}