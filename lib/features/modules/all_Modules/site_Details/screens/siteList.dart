import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';

import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/card.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../providers/siteProvider.dart';
import '../providers/site_current_provider.dart';
import '../providers/site_service.dart';
import '../repository/siteModel.dart';

class SiteListScreen extends ConsumerStatefulWidget {
  final Widget Function(SiteModel site) pageBuilder;
  final bool show;

  const SiteListScreen({super.key, required this.pageBuilder, this.show = false});

  @override
  ConsumerState<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends ConsumerState<SiteListScreen> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedSiteIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedSiteId = ref.read(selectedSiteIdProvider);
      final currentSite = ref.read(currentSiteProvider);

      if (selectedSiteId != null && currentSite != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => widget.pageBuilder(currentSite),
          ),
        );
      }
    });
  }

  Future<void> _confirmAndDeleteSite(SiteModel site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Site"),
        content: Text(
          "Are you sure you want to delete '${site.siteName}'?\n\n"
              "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SiteAPI.delete(site.id);
      ref.read(siteProvider.notifier).fetchSites();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${site.siteName} deleted successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete site"),
          backgroundColor: Colors.red[100],
        ),
      );
    }
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSiteIds.clear();
      }
    });
  }

  /// Toggle individual site selection
  void _toggleSiteSelection(String siteId) {
    setState(() {
      if (_selectedSiteIds.contains(siteId)) {
        _selectedSiteIds.remove(siteId);
      } else {
        _selectedSiteIds.add(siteId);
      }
    });
  }

  /// Select all sites
  void _selectAllSites(List<SiteModel> sites) {
    setState(() {
      for (var site in sites) {
        _selectedSiteIds.add(site.id);
      }
    });
  }

  /// Delete selected sites
  Future<void> _deleteSelectedSites() async {
    if (_selectedSiteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sites selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Sites'),
        content: Text(
          'Are you sure you want to delete ${_selectedSiteIds.length} selected sites?\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SiteAPI.bulkDeleteSites(_selectedSiteIds.toList());

      ref.read(siteProvider.notifier).fetchSites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted ${_selectedSiteIds.length} sites'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedSiteIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building SiteListScreen");

    final selectedSiteId = ref.watch(selectedSiteIdProvider);
    final currentSite = ref.watch(currentSiteProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: _isSelectionMode
                  ? '${_selectedSiteIds.length} Selected'
                  : "Select Site",
            ),
          ];
        },
        body: _buildMainBody(),
      ),
    );
  }

  Widget _buildMainBody() {
    final siteState = ref.watch(siteProvider);
    final sites = siteState.sites;

    return BottomButtonWrapper(
      customButtons: [
        if (widget.show)
          CustomButton(
            button: RoundedButton(
              text: "Add",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SiteEntrySelectCardGrid()),
                );
              },
            ),
          ),
      ],
      child: Column(
        children: [
          // Top action bar with selection controls
          if (sites.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                Row(
                  children: [
                    if (_isSelectionMode) ...[
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSelectionMode,
                        tooltip: 'Cancel',
                      ),
                      TextButton(
                        onPressed: () => _selectAllSites(sites),
                        child: const Text('Select All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        label: const Text('Delete'),
                        onPressed: _selectedSiteIds.isEmpty
                            ? null
                            : _deleteSelectedSites,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      if (widget.show)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: sites.isEmpty ? null : _toggleSelectionMode,
                          tooltip: 'Select Sites to Delete',
                        ),
                    ],
                  ],
                ),
              ],
            ),

          // Site grid
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final siteState = ref.watch(siteProvider);
                print("👀 Watching site state");
                print(siteState);
                return _buildBody(siteState);
              },
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
          final isSelected = _selectedSiteIds.contains(site.id);

          print(site.siteImage);
          print("🏢 Building card for site: ${site.siteName} (index: $index)");

          return Stack(
            children: [
              Opacity(
                opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
                child: CompanyCard(
                  imagePath: site.siteImage ?? '',
                  companyName: site.siteName ?? 'Unknown Site',
                  onTap: _isSelectionMode
                      ? () => _toggleSiteSelection(site.id)
                      : () {
                    print("👆 Tapped on site: ${site.siteName}");
                    ref.read(selectedSiteIdProvider.notifier).state = site.id;
                    final ew = ref.read(currentSiteProvider);
                    print(ew?.siteName);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => widget.pageBuilder(site),
                      ),
                    );
                  },
                  onDelete: _isSelectionMode
                      ? null
                      : () => _confirmAndDeleteSite(site),
                  show: widget.show && !_isSelectionMode,
                ),
              ),

              // Selection checkbox overlay
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleSiteSelection(site.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.red : Colors.white,
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                          : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}