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
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import '../../../../tour/definitions/site_rate_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
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
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _addButtonTourKey =
      GlobalKey(debugLabel: 'site_list_add_button');
  final GlobalKey _deleteModeTourKey =
      GlobalKey(debugLabel: 'site_list_delete_mode');
  final GlobalKey _firstSiteTourKey =
      GlobalKey(debugLabel: 'site_list_first_card');
  final GlobalKey _emptyTourKey = GlobalKey(debugLabel: 'site_list_empty');

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
            onPressed: () => context.pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => context.pop(true),
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
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
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
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        final siteState = ref.read(siteProvider);
        _syncSiteListTour(
          showcaseContext,
          sites: siteState.sites,
          showActions: widget.show,
        );
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
            button: _tourTarget(
              _addButtonTourKey,
              RoundedButton(
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
                        _tourTarget(
                          _deleteModeTourKey,
                          IconButton(
                            icon: Icon(Icons.delete_sweep, color: cs.error),
                            onPressed:
                                sites.isEmpty ? null : _toggleSelectionMode,
                            tooltip: 'Select Sites to Delete',
                          ),
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
      return _tourTarget(
        _emptyTourKey,
        Center(
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
        ),
      );
    }

    // Show empty state
    if (siteState.sites.isEmpty) {
      print("📭 Showing empty state");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              "Site data is empty",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No site records found. Please add a site to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
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

              final card = Stack(
                children: [
                  Opacity(
                    opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
                    child: CompanyCard(
                      imagePath: site.siteImage ?? '',
                      fallbackIcon: Icons.location_city_rounded,
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
              return index == 0 ? _tourTarget(_firstSiteTourKey, card) : card;
            },
          ),
        ));
  }

  void _syncSiteListTour(
    BuildContext showcaseContext, {
    required List<SiteModel> sites,
    required bool showActions,
  }) {
    final hasSites = sites.isNotEmpty;
    final definition = AppTourDefinition(
      id:
          '${SiteRateModuleTours.siteDetailsId}_list_${hasSites ? 'with_sites' : 'empty'}_${showActions ? 'manage' : 'select'}',
      title: 'Site List',
      description: 'Learn how to use the site list.',
      icon: Icons.location_city_rounded,
      steps: [
        const AppTourStep(
          id: 'site_list_intro',
          title: 'Site List',
          body: 'This screen shows the project sites created in your account.',
          progressLabel: 'Site list',
          useSpotlight: false,
        ),
        if (showActions)
          AppTourStep(
            id: 'site_list_add',
            title: 'Add Site',
            body: 'Tap Add when you need to create another project site.',
            targetKey: _addButtonTourKey,
            progressLabel: 'Add',
            tooltipBottomOffset: 96,
          ),
        if (hasSites && showActions)
          AppTourStep(
            id: 'site_list_delete_mode',
            title: 'Delete Mode',
            body: 'Use this when you need to select and delete site records.',
            targetKey: _deleteModeTourKey,
            progressLabel: 'Delete mode',
          ),
        if (hasSites)
          AppTourStep(
            id: 'site_list_first_card',
            title: 'Site Card',
            body: 'Tap a site card to open that site for the selected module.',
            targetKey: _firstSiteTourKey,
            progressLabel: 'Site card',
          )
        else
          AppTourStep(
            id: 'site_list_empty',
            title: 'No Sites Yet',
            body:
                'Add a site first so entries, setup, and reports have a project to use.',
            targetKey: _emptyTourKey,
            progressLabel: 'Empty state',
          ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SiteRateModuleTours.siteDetailsId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null ||
          !activeTour.id.startsWith(SiteRateModuleTours.siteDetailsId)) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }
}
