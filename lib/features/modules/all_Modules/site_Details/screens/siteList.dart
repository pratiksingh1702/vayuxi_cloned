import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/card.dart';
import '../providers/siteProvider.dart';
import '../providers/site_current_provider.dart';
import '../repository/siteModel.dart';

class SiteListScreen extends ConsumerStatefulWidget {
  final Widget Function(SiteModel site) pageBuilder;

  const SiteListScreen({super.key, required this.pageBuilder});

  @override
  ConsumerState<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends ConsumerState<SiteListScreen> {
  @override
  void initState() {
    super.initState();
    print("🚀 SiteListScreen initState");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🔄 Starting site fetch");
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building SiteListScreen");

    return Scaffold(
      appBar: const CustomAppBar(title: "Select Site"),
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, child) {
                final siteState = ref.watch(siteProvider);
                print(
                  "📊 SiteState: isLoading=${siteState.isLoading}, sites=${siteState.sites.length}, error=${siteState.error}",
                );

                return _buildBody(siteState);
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: RoundedButton(
              text: "Back",
              color: Colors.white,
              textColor: Colors.black,

              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SiteState siteState) {
    // Show loading only when truly loading and no data
    if (siteState.isLoading && siteState.sites.isEmpty) {
      print("⏳ Showing loading indicator");
      return const Center(child: CircularProgressIndicator());
    }

    // Show error only when there's an error and no data
    if (siteState.error != null && siteState.sites.isEmpty) {
      print("❌ Showing error: ${siteState.error}");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading sites',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              siteState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print("🔄 Retry button pressed");
                ref.read(siteProvider.notifier).fetchSites();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (siteState.sites.isEmpty) {
      print("📭 Showing empty state");
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No sites available",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show data with grid view
    print("🎯 Showing ${siteState.sites.length} sites in grid");
    return Container(
      color: AppColors.lightBlue,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 1,
          childAspectRatio: 1.1,
        ),
        itemCount: siteState.sites.length,
        itemBuilder: (context, index) {
          final site = siteState.sites[index];
          print("🏢 Building card for site: ${site.siteName} (index: $index)");
          return CompanyCard(
            imagePath:
                'assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png',
            companyName: site.siteName ?? 'Unknown Site',
            onTap: () {
              print("👆 Tapped on site: ${site.siteName}");
              ref.read(selectedSiteIdProvider.notifier).state = site.id;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.pageBuilder(site),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
