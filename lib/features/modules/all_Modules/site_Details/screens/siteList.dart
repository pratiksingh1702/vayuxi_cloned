import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/core/utlis/widgets/custom_scrollbar.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';

import '../../../../../core/router/routes.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/card.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../tour/domain/tour_aware_mixin.dart';
import '../../../../tour/domain/tour_controller.dart';
import '../../../../tour/domain/tour_presistent.dart';
import '../../../../tour/domain/tour_registery.dart';
import '../../../../tour/domain/tour_step_model.dart';
import '../providers/siteProvider.dart';
import '../providers/site_current_provider.dart';
import '../providers/site_service.dart';
import '../repository/siteModel.dart';
import '../../team/provider/teamProvider.dart';
import '../../../../../typeProvider/type_provider.dart';

class SiteListScreen extends ConsumerStatefulWidget {
  final Widget Function(SiteModel site) pageBuilder;
  final bool show;
  final String? module;

  const SiteListScreen(
      {super.key, required this.pageBuilder, this.show = false, this.module});

  @override
  ConsumerState<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends ConsumerState<SiteListScreen>
    with TourAwareMixin {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedSiteIds = {};
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch sites — no more auto-navigation here
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  Future<void> _confirmAndDeleteSite(SiteModel site) async {
    final cs = Theme.of(context).colorScheme;
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
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
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

      AppToast.success("✅ ${site.siteName} deleted successfully");
    } on DioException catch (e) {
      debugPrint("❌ Delete site failed: $e");
      if (!mounted) return;

      AppToast.error("❌ Failed to delete site");
    } catch (e) {
      debugPrint("❌ Delete site failed: $e");
      if (!mounted) return;

      final error = extractBackendError(e);
      AppToast.error("❌ $error");
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

  Future<void> _deleteSelectedSites() async {
    if (_selectedSiteIds.isEmpty) {
      AppToast.info('No sites selected');
      return;
    }

    final cs = Theme.of(context).colorScheme;

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
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SiteAPI.bulkDeleteSites(_selectedSiteIds.toList());

      ref.read(siteProvider.notifier).fetchSites();

      if (!mounted) return;

      AppToast.success(
          "✅ Successfully deleted ${_selectedSiteIds.length} sites");

      setState(() {
        _selectedSiteIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');
      if (!mounted) return;

      final error = extractBackendError(e);
      AppToast.error("❌ Bulk delete failed: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building SiteListScreen");
    final lang = ref.watch(dailyEntryTranslationHelperProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          runTourForRoute("/site-list/site", showcaseContext);
        });
        return Scaffold(
          drawer: const CustomDrawer(),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CustomSliverAppBar(
                  title: _isSelectionMode
                      ? '${_selectedSiteIds.length} Selected'
                      : lang.selectSiteTitle,
                ),
              ];
            },
            body: _buildMainBody(),
          ),
        );
      },
    );
  }

  Widget _buildMainBody() {
    final cs = Theme.of(context).colorScheme;
    final siteState = ref.watch(siteProvider);
    final sites = siteState.sites;

    return BottomButtonWrapper(
      customButtons: [
        if (widget.show)
          CustomButton(
            button: Showcase(
              key: TourRegistry.siteCreateKey,
              description: "Tap here to create your first Site",
              child: RoundedButton(
                text: "Add",
                color: cs.primary,
                textColor: cs.onPrimary,
                onPressed: () async {
                  context.push(Routes.siteEntrySelect);
                  await TourPersistence().markCompleted();
                },
                isOutlined: false,
              ),
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
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                      ),
                    ] else ...[
                      if (widget.show)
                        IconButton(
                          icon: Icon(Icons.delete_sweep, color: cs.error),
                          onPressed:
                              sites.isEmpty ? null : _toggleSelectionMode,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading only when truly loading and no data
    if (siteState.isLoading && siteState.sites.isEmpty) {
      print("⏳ Showing loading indicator");
      return const ShimmerList(
        type: ShimmerListType.grid,
        crossAxisCount: 2,
        itemCount: 6,
      );
    }

    // Show error only when there's an error and no data
    if (siteState.error != null && siteState.sites.isEmpty) {
      print("❌ Showing error: ${siteState.error}");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Error loading sites',
              style: TextStyle(fontSize: 18, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              siteState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
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
            Icon(Icons.search_off, size: 64),
            SizedBox(height: 16),
            Text(
              "No sites available",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Show data with grid view
    print("🎯 Showing ${siteState.sites.length} sites in grid");
    return Container(
        color: isDark ? cs.surface : cs.surfaceContainerLowest,
        child: CustomScrollbar(
          controller: _gridScrollController,
          child: GridView.builder(
            controller: _gridScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
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
              print(
                  "🏢 Building card for site: ${site.siteName} (index: $index)");

              return Stack(
                children: [
                  Opacity(
                    opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
                    child: CompanyCard(
                      imagePath:
                          site.siteImage ?? 'assets/images/site_def.webp',
                      defaultImage: 'assets/images/site_def.webp',
                      companyName: site.siteName ?? 'Unknown Site',
                      onTap: _isSelectionMode
                          ? () => _toggleSiteSelection(site.id)
                          : () {
                              print("👆 Tapped on site: ${site.siteName}");
                              ref.read(selectedSiteIdProvider.notifier).state =
                                  site.id;

                              if (widget.module == 'dpr') {
                                final type = ref.read(typeProvider);
                                final notifier =
                                    ref.read(teamProvider.notifier);
                                if (type == "mechanical_work") {
                                  notifier.fetchMechanicalCombined(
                                      siteId: site.id);
                                } else if (type == "insulation_work") {
                                  notifier.fetchInsulationCombined(
                                      siteId: site.id);
                                } else {
                                  notifier.fetchTeams(
                                      type: type ?? "", siteId: site.id);
                                }
                              }
                              final ew = ref.read(currentSiteProvider);
                              print(ew?.siteName);

                              // context.push(Routes.siteDetail, extra: site);
                              // For now, let's stick to pushing the page since pageBuilder is a closure
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      widget.pageBuilder(site),
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
                            color: isSelected ? cs.error : cs.surface,
                            border: Border.all(
                              color: cs.error,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    cs.shadow.withOpacity(isDark ? 0.28 : 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: cs.onError,
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
        ));
  }
}
