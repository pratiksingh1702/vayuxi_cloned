import 'package:flutter/material.dart';

class TemplatePreviewScreen extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback onDownload;

  const TemplatePreviewScreen({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔹 TOP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
      ),

      /// 🔹 IMAGE PREVIEW
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          /// 🔹 DOWNLOAD BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text("Download Template"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
