import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CompanyCard extends StatelessWidget {
  final String imagePath;
  final String companyName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool show;

  const CompanyCard({
    super.key,
    required this.imagePath,
    required this.companyName,
    this.onTap,
    this.onDelete,
    this.show=false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imagePath,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,

                        // 🔥 THIS prevents decoding huge images
                        memCacheWidth: 400,


                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/default.webp',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      companyName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if(show)  Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,

                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              )]

          ),
        ),
      ),


    );
  }
}
