import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/custom_dropdown.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

import '../models/pm_models.dart';
import '../providers/pm_provider.dart';

enum _PmSetupCategoryAction { view, add }

String _pmCategoryIdentity(PmCategory category) => category.categoryName;

String _formatPmContextLabel(String raw) {
  final cleaned = raw
      .trim()
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return 'General';
  return cleaned
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

enum PmSection {
  setup,
  entry,
  reports;

  String get title {
    switch (this) {
      case PmSection.setup:
        return 'P&M Setup';
      case PmSection.entry:
        return 'P&M Entry';
      case PmSection.reports:
        return 'P&M Reports';
    }
  }
}

class _PmTourTargetEntry {
  final GlobalKey key;
  final Widget child;

  const _PmTourTargetEntry({
    required this.key,
    required this.child,
  });
}

class _PmTourStack extends ConsumerStatefulWidget {
  final Widget child;

  const _PmTourStack({required this.child});

  @override
  ConsumerState<_PmTourStack> createState() => _PmTourStackState();
}

class _PmTourStackState extends ConsumerState<_PmTourStack> {
  final Map<GlobalKey, _PmTourTargetEntry> _targets = {};
  final GlobalKey _stackKey = GlobalKey(debugLabel: 'pm_tour_stack');
  GlobalKey? _highlightKey;
  Rect? _highlightRect;

  void registerTarget(GlobalKey key, Widget child) {
    _targets[key] = _PmTourTargetEntry(key: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    _targets.clear();

    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        widget.child,
        _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    final controller = ref.read(appTourControllerProvider.notifier);
    final step = controller.currentStep;
    final key = step?.targetKey;
    if (key == null) {
      _clearMeasurement();
      return const SizedBox.shrink();
    }

    final target = _targets[key];
    if (target == null) {
      _clearMeasurement();
      return const SizedBox.shrink();
    }

    final rect = _rectFor(key);
    if (rect == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: CustomPaint(
          painter: SpotlightCutoutPainter(
            rect: rect,
            borderRadius: 12.0,
            overlayColor: Colors.black.withOpacity(0.78),
            padding: 6.0,
          ),
        ),
      ),
    );
  }

  Rect? _rectFor(GlobalKey key) {
    _scheduleMeasurement(key);
    if (!identical(_highlightKey, key)) return null;
    return _highlightRect;
  }

  void _scheduleMeasurement(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = key.currentContext;
      final stackContext = _stackKey.currentContext;
      final targetObject = targetContext?.findRenderObject();
      final stackObject = stackContext?.findRenderObject();
      if (targetObject is! RenderBox ||
          stackObject is! RenderBox ||
          !targetObject.hasSize ||
          !stackObject.hasSize) {
        return;
      }
      final targetTopLeft = targetObject.localToGlobal(Offset.zero);
      final stackTopLeft = stackObject.localToGlobal(Offset.zero);
      final nextRect = (targetTopLeft - stackTopLeft) & targetObject.size;
      if (!identical(_highlightKey, key) || _highlightRect != nextRect) {
        setState(() {
          _highlightKey = key;
          _highlightRect = nextRect;
        });
      }
    });
  }

  void _clearMeasurement() {
    if (_highlightKey == null && _highlightRect == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _highlightKey = null;
        _highlightRect = null;
      });
    });
  }
}

class SpotlightCutoutPainter extends CustomPainter {
  final Rect? rect;
  final double borderRadius;
  final Color overlayColor;
  final double padding;

  SpotlightCutoutPainter({
    required this.rect,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0xC7000000),
    this.padding = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    if (rect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final inflatedRect = rect!.inflate(padding);

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(RRect.fromRectAndRadius(inflatedRect, Radius.circular(borderRadius))),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.padding != padding;
  }
}

class _PmTourTarget extends ConsumerWidget {
  final GlobalKey targetKey;
  final Widget child;

  const _PmTourTarget({
    required this.targetKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appTourControllerProvider.notifier);
    final step = controller.currentStep;
    if (identical(step?.targetKey, targetKey) &&
        (step?.autoScrollToTarget ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetContext = targetKey.currentContext;
        if (targetContext == null) return;
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.28,
        );
      });
    }

    _PmTourStackState? owner;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is _PmTourStackState) {
        owner = element.state as _PmTourStackState;
      }
      return true;
    });
    owner?.registerTarget(targetKey, child);

    return KeyedSubtree(
      key: targetKey,
      child: child,
    );
  }
}

class PmScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final String workType;
  final PmSection section;

  const PmScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.workType,
    required this.section,
  });

  @override
  ConsumerState<PmScreen> createState() => _PmScreenState();
}

class _PmScreenState extends ConsumerState<PmScreen> with ScreenOwnedTourMixin<PmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pmProvider.notifier).load(widget.siteId, widget.workType);
    });
  }

  Future<void> _pickDate() async {
    final state = ref.read(pmProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await ref
          .read(pmProvider.notifier)
          .setDate(widget.siteId, widget.workType, picked);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pmProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _PmTourStack(
      child: Scaffold(
        backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
        drawer: const CustomDrawer(),
        appBar: CustomAppBar(
          title: widget.section.title,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref
                  .read(pmProvider.notifier)
                  .load(widget.siteId, widget.workType),
            ),
          ],
        ),
        body: state.error != null && state.categories.isEmpty
            ? _ErrorState(
                message: state.error!,
                onRetry: () => ref
                    .read(pmProvider.notifier)
                    .load(widget.siteId, widget.workType),
              )
            : _buildSection(state),
      ),
    );
  }

  Widget _buildSection(PmState state) {
    switch (widget.section) {
      case PmSection.setup:
        return _SetupTab(
          state: state,
          siteId: widget.siteId,
          siteName: widget.siteName,
          workType: widget.workType,
          onSaved: () => _snack('P&M setup saved successfully'),
          onError: (msg) => _snack(msg, isError: true),
        );
      case PmSection.entry:
        return _EntryTab(
          state: state,
          siteId: widget.siteId,
          siteName: widget.siteName,
          workType: widget.workType,
          onDateTap: _pickDate,
          onSaved: () {
            HapticFeedback.heavyImpact();
            _snack('P&M entry saved successfully');
          },
          onError: (msg) => _snack(msg, isError: true),
        );
      case PmSection.reports:
        return _ReportsTab(
          state: state,
          siteId: widget.siteId,
          workType: widget.workType,
          onDateTap: _pickDate,
        );
    }
  }
}

class _SetupTab extends ConsumerStatefulWidget {
  final PmState state;
  final String siteId;
  final String siteName;
  final String workType;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _SetupTab({
    required this.state,
    required this.siteId,
    required this.siteName,
    required this.workType,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends ConsumerState<_SetupTab>
    with ScreenOwnedTourMixin<_SetupTab> {
  final GlobalKey _siteTourKey = GlobalKey(debugLabel: 'pm_setup_site');
  final GlobalKey _categoryTourKey =
      GlobalKey(debugLabel: 'pm_setup_category');
  final GlobalKey _addWorkTourKey = GlobalKey(debugLabel: 'pm_setup_add_work');
  final GlobalKey _workListTourKey = GlobalKey(debugLabel: 'pm_setup_work_list');
  String? _lastShowcasedTourStepId;
  String? _categoryId;

  void _syncPmSetupTour(
    BuildContext showcaseContext, {
    required bool hasCategories,
    required bool categorySelected,
  }) {
    final definition = AppTourDefinition(
      id:
          '${SetupModuleTours.pmSetupId}_${widget.siteId}_${categorySelected ? 'works' : 'categories'}',
      title: 'P&M Setup',
      description: 'Prepare plant and machinery work for this site.',
      icon: Icons.precision_manufacturing_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_setup_intro',
          title: 'P&M Setup',
          body:
              'Start here before daily P&M entry. Categories stay fixed, and you add works inside the right category.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_setup_site',
          title: 'Selected Site',
          body: 'This confirms which site the P&M setup will be saved under.',
          targetKey: _siteTourKey,
          progressLabel: 'Site',
        ),
        if (hasCategories && !categorySelected)
          AppTourStep(
            id: 'pm_setup_categories',
            title: 'P&M Categories',
            body:
                'Choose a category to view its works or add a new work inside it.',
            targetKey: _categoryTourKey,
            progressLabel: 'Categories',
          ),
        if (categorySelected)
          AppTourStep(
            id: 'pm_setup_add_work',
            title: 'Add Work',
            body: 'Use this button to add a new P&M work under the selected category.',
            targetKey: _addWorkTourKey,
            progressLabel: 'Add Work',
          ),
        if (categorySelected)
          AppTourStep(
            id: 'pm_setup_work_list',
            title: 'Work List',
            body: 'Existing works for this category appear here. Tap a work to edit it.',
            targetKey: _workListTourKey,
            progressLabel: 'Works',
          ),
      ],
    );

    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.pmSetupId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    ref.watch(appTourControllerProvider);
    if (state.isLoading && state.categories.isEmpty) {
      return const _PmCategorySelectionSkeleton();
    }
    if (state.categories.isEmpty) {
      return ShowCaseWidget(
        builder: (showcaseContext) {
          _syncPmSetupTour(
            showcaseContext,
            hasCategories: false,
            categorySelected: false,
          );
          return _PmTourStack(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _tourTarget(
                  _siteTourKey,
                  _PmSetupSiteCard(siteName: widget.siteName),
                ),
                const SizedBox(height: 12),
                const _EmptyPanel(title: 'No P&M categories found'),
              ],
            ),
          );
        },
      );
    }

    final selectedCategory = _categoryId == null
        ? null
        : state.categories.firstWhere(
            (category) => _pmCategoryIdentity(category) == _categoryId,
            orElse: () => state.categories.first,
          );

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncPmSetupTour(
          showcaseContext,
          hasCategories: state.categories.isNotEmpty,
          categorySelected: selectedCategory != null,
        );
        return _PmTourStack(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
            _tourTarget(
              _siteTourKey,
              _PmSetupSiteCard(siteName: widget.siteName),
            ),
            const SizedBox(height: 12),
            if (selectedCategory == null) ...[
              const Text(
                'Select P&M Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _tourTarget(
                _categoryTourKey,
                _PmCategoryGrid(
                  categories: state.categories,
                  onSelected: _openCategoryActions,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _categoryId = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Categories'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tourTarget(
                      _addWorkTourKey,
                      FilledButton.icon(
                        onPressed: () => _openAddWorkScreen(selectedCategory),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Work'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _tourTarget(
                _workListTourKey,
                _PmEquipmentList(
                  category: selectedCategory,
                  onEdit: (equipment) => _openEquipmentSheet(equipment),
                  onDelete: _deleteEquipment,
                ),
              ),
            ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCategoryActions(PmCategory category) async {
    final action = await Navigator.of(context).push<_PmSetupCategoryAction>(
      MaterialPageRoute(
        builder: (_) => _PmSetupCategoryActionScreen(category: category),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _PmSetupCategoryAction.view:
        setState(() => _categoryId = _pmCategoryIdentity(category));
        break;
      case _PmSetupCategoryAction.add:
        await _openAddWorkScreen(category);
        break;
    }
  }

  Future<void> _openAddWorkScreen(PmCategory category) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _PmEquipmentAddScreen(
          siteId: widget.siteId,
          workType: widget.workType,
          category: category,
          onSaved: widget.onSaved,
          onError: widget.onError,
        ),
      ),
    );
  }

  Future<void> _openEquipmentSheet(PmEquipment? equipment) async {
    await showPmEquipmentSheet(
      context: context,
      ref: ref,
      state: widget.state,
      siteId: widget.siteId,
      workType: widget.workType,
      equipment: equipment,
      onSaved: widget.onSaved,
      onError: widget.onError,
    );
  }

  Future<void> _deleteEquipment(PmEquipment equipment) async {
    if (!equipment.isCustom) {
      widget.onError('Only custom P&M works can be deleted');
      return;
    }
    final ok = await ref
        .read(pmProvider.notifier)
        .deleteEquipment(widget.siteId, widget.workType, equipment);
    ok
        ? widget.onSaved()
        : widget.onError(ref.read(pmProvider).error ?? 'Delete failed');
  }
}

class _PmSetupSiteCard extends StatelessWidget {
  final String siteName;

  const _PmSetupSiteCard({required this.siteName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.apartment_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siteName.trim().isEmpty ? 'Selected Site' : siteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Categories below are available for this site',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
        ],
      ),
    );
  }
}

class _PmSetupCategoryActionScreen extends ConsumerStatefulWidget {
  final PmCategory category;

  const _PmSetupCategoryActionScreen({required this.category});

  @override
  ConsumerState<_PmSetupCategoryActionScreen> createState() =>
      _PmSetupCategoryActionScreenState();
}

class _PmSetupCategoryActionScreenState
    extends ConsumerState<_PmSetupCategoryActionScreen>
    with ScreenOwnedTourMixin<_PmSetupCategoryActionScreen> {
  final GlobalKey _chooserTourKey =
      GlobalKey(debugLabel: 'pm_setup_action_chooser');
  String? _lastShowcasedTourStepId;

  void _syncChooserTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id:
          '${SetupModuleTours.pmSetupId}_${widget.category.categoryKey}_action_chooser',
      title: 'Choose Work Action',
      description: 'Choose whether to view or add P&M work.',
      icon: Icons.touch_app_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_setup_action_intro',
          title: 'Choose Work Action',
          body:
              'This screen asks what you want to do inside the selected P&M category.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_setup_action_buttons',
          title: 'View or Add',
          body:
              'Tap View Works to check existing work. Tap Add Work to create a new work in this category.',
          targetKey: _chooserTourKey,
          progressLabel: 'Action',
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.pmSetupId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncChooserTour(showcaseContext);
        return _PmTourStack(
          child: Scaffold(
            drawer: const CustomDrawer(),
            backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
            appBar: const CustomAppBar(title: 'Select Work Action'),
            body: _tourTarget(
              _chooserTourKey,
              _SetupChooser(
                viewLabel: 'View Works',
                addLabel: 'Add Work',
                onView: () =>
                    Navigator.of(context).pop(_PmSetupCategoryAction.view),
                onAdd: () =>
                    Navigator.of(context).pop(_PmSetupCategoryAction.add),
                emptyText:
                    '${widget.category.categoryName}\nView existing works or add a new work under this category.',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SetupChooser extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onAdd;
  final String? emptyText;
  final String viewLabel;
  final String addLabel;

  const _SetupChooser({
    required this.onView,
    required this.onAdd,
    this.emptyText,
    this.viewLabel = 'View',
    this.addLabel = 'add',
  });

  @override
  Widget build(BuildContext context) {
    Widget actionCard({
      required Widget icon,
      required String label,
      required VoidCallback? onTap,
    }) {
      return Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: IgnorePointer(
          ignoring: onTap == null,
          child: SelectCard(
            icon: icon,
            label: label,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            actionCard(
              icon: const SelectCardIcon(
                icon: Icons.visibility_rounded,
                color: Colors.blue,
              ),
              label: viewLabel,
              onTap: onView,
            ),
            actionCard(
              icon: const SelectCardIcon(
                icon: Icons.add_circle_outline_rounded,
                color: Colors.green,
              ),
              label: addLabel,
              onTap: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose an option',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyText ??
                    '- View: You can view existing P&M works and edit them.\n'
                        '- Add: You can create a new P&M work with an optional image.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _WorkSelectionPage extends StatefulWidget {
  final List<PmCategory> categories;
  final ValueChanged<PmEquipment> onSelect;

  const _WorkSelectionPage({
    required this.categories,
    required this.onSelect,
  });

  @override
  State<_WorkSelectionPage> createState() => _WorkSelectionPageState();
}

class _WorkSelectionPageState extends State<_WorkSelectionPage> {
  final _equipmentSearchController = TextEditingController();
  String? _categoryId;
  String _equipmentSearch = '';

  @override
  void dispose() {
    _equipmentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categoryId == null
        ? null
        : widget.categories.firstWhere(
            (category) => _pmCategoryIdentity(category) == _categoryId,
            orElse: () => widget.categories.first,
          );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (selectedCategory == null) ...[
          const Text(
            'Select P&M Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _PmCategoryGrid(
            categories: widget.categories,
            onSelected: (category) => setState(() {
              _categoryId = _pmCategoryIdentity(category);
              _equipmentSearch = '';
              _equipmentSearchController.clear();
            }),
          ),
        ] else ...[
          TextField(
            controller: _equipmentSearchController,
            onChanged: (value) => setState(() => _equipmentSearch = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search work in ${selectedCategory.categoryName}',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _equipmentSearch.trim().isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _equipmentSearch = '';
                        _equipmentSearchController.clear();
                      }),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PmEquipmentList(
            category: selectedCategory,
            equipment: _filterEquipment(
              selectedCategory.equipment,
              _equipmentSearch,
            ),
            emptyTitle: _equipmentSearch.trim().isEmpty
                ? 'No works found in this category'
                : 'No works match your search',
            onTap: widget.onSelect,
          ),
        ],
      ],
    );
  }

  List<PmEquipment> _filterEquipment(
    List<PmEquipment> equipment,
    String query,
  ) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return equipment;
    return equipment.where((item) {
      final searchable = [
        item.equipmentName,
        item.categoryName,
        item.capacity,
        item.unit,
      ].join(' ').toLowerCase();
      return searchable.contains(key);
    }).toList();
  }
}

class _PmCategorySelectionSkeleton extends StatelessWidget {
  const _PmCategorySelectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const ShimmerImage(height: 22, width: 190, borderRadius: 8),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerImage(height: 42, width: 42, borderRadius: 12),
                  SizedBox(height: 14),
                  ShimmerImage(height: 14, width: 96, borderRadius: 7),
                  SizedBox(height: 8),
                  ShimmerImage(height: 11, width: 74, borderRadius: 6),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PmCategoryGrid extends StatelessWidget {
  final List<PmCategory> categories;
  final ValueChanged<PmCategory> onSelected;

  const _PmCategoryGrid({
    required this.categories,
    required this.onSelected,
  });

  IconData _iconFor(String value) {
    final key = value.toLowerCase();
    if (key.contains('earth')) return Icons.landscape_rounded;
    if (key.contains('concrete')) return Icons.foundation_rounded;
    if (key.contains('transport')) return Icons.local_shipping_rounded;
    if (key.contains('crane') || key.contains('lifting')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (key.contains('dg') || key.contains('generator')) {
      return Icons.electrical_services_rounded;
    }
    return Icons.construction_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () => onSelected(category),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _iconFor(category.categoryName),
                  color: cs.primary,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  category.categoryName,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${category.equipment.length} works',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PmEquipmentList extends StatelessWidget {
  final PmCategory category;
  final List<PmEquipment>? equipment;
  final String emptyTitle;
  final ValueChanged<PmEquipment>? onTap;
  final ValueChanged<PmEquipment>? onEdit;
  final ValueChanged<PmEquipment>? onDelete;

  const _PmEquipmentList({
    required this.category,
    this.equipment,
    this.emptyTitle = 'No works found in this category',
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final items = equipment ?? category.equipment;
    if (items.isEmpty) {
      return _EmptyPanel(title: emptyTitle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.categoryName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (equipment) => _EquipmentCard(
            equipment: equipment,
            onTap: onTap == null ? null : () => onTap!(equipment),
            onEdit: onEdit == null ? null : () => onEdit!(equipment),
            onDelete: onDelete == null ? null : () => onDelete!(equipment),
          ),
        ),
      ],
    );
  }
}

class _PmEntryWorkTitle extends StatelessWidget {
  final PmEquipment equipment;

  const _PmEntryWorkTitle({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          equipment.equipmentName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          equipment.categoryName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PmEquipmentEditHeader extends StatelessWidget {
  final PmEquipment equipment;

  const _PmEquipmentEditHeader({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _ImagePreview(imageUrl: equipment.image, height: 62, width: 72),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  equipment.categoryName,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCategoryField extends StatelessWidget {
  final String categoryName;

  const _LockedCategoryField({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.category_rounded, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoryName.trim().isEmpty ? 'P&M' : categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, size: 17, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

Future<void> showPmEquipmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PmState state,
  required String siteId,
  required String workType,
  required VoidCallback onSaved,
  required ValueChanged<String> onError,
  PmEquipment? equipment,
  PmCategory? fixedCategory,
}) async {
  final defaultCategory =
      state.categories.isNotEmpty ? state.categories.first : null;
  final initialCategory = equipment == null
      ? fixedCategory ?? defaultCategory
      : null;
  final name = TextEditingController(text: equipment?.equipmentName ?? '');
  final capacity = TextEditingController(text: equipment?.capacity ?? '');
  final unit = TextEditingController(text: equipment?.unit ?? 'Nos');
  var image = equipment?.image ?? '';
  var categoryKey =
      equipment?.categoryKey ?? initialCategory?.categoryKey ?? '';
  var categoryName =
      equipment?.categoryName ?? initialCategory?.categoryName ?? '';

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              allowMultiple: false,
            );
            final file = result?.files.single;
            if (file == null) return;
            final url =
                await ref.read(pmProvider.notifier).uploadImage(siteId, file);
            if (!sheetContext.mounted) return;
            if (url.isNotEmpty) setModalState(() => image = url);
          }

          Future<void> save() async {
            if (categoryKey.trim().isEmpty || categoryName.trim().isEmpty) {
              onError('Category is required');
              return;
            }
            if (name.text.trim().isEmpty) {
              onError('Work name is required');
              return;
            }
            final ok = await ref.read(pmProvider.notifier).saveEquipment(
                  siteId,
                  equipment: equipment,
                  categoryKey: categoryKey,
                  categoryName: categoryName,
                  equipmentName: name.text.trim(),
                  capacity: capacity.text.trim(),
                  unit: unit.text.trim().isEmpty ? 'Nos' : unit.text.trim(),
                  image: image,
                  workType: workType,
                  reloadAfterSave: false,
                );
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop(ok);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment == null ? 'Add P&M Work' : 'Edit P&M Work',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (equipment == null)
                    _LockedCategoryField(categoryName: categoryName),
                  const SizedBox(height: 10),
                  _TextField(controller: name, label: 'Work Name'),
                  _TextField(controller: capacity, label: 'Capacity'),
                  _TextField(controller: unit, label: 'Unit'),
                  const SizedBox(height: 10),
                  _ImagePreview(imageUrl: image, height: 150),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Upload / Replace Image'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: state.isSaving ? null : save,
                      child: const Text('Save Work'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  name.dispose();
  capacity.dispose();
  unit.dispose();

  if (saved == true) {
    await ref.read(pmProvider.notifier).load(siteId, workType);
    onSaved();
  } else if (saved == false) {
    onError(ref.read(pmProvider).error ?? 'Save failed');
  }
}

class _PmEquipmentAddScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String workType;
  final PmCategory category;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _PmEquipmentAddScreen({
    required this.siteId,
    required this.workType,
    required this.category,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_PmEquipmentAddScreen> createState() =>
      _PmEquipmentAddScreenState();
}

class _PmEquipmentAddScreenState extends ConsumerState<_PmEquipmentAddScreen>
    with ScreenOwnedTourMixin<_PmEquipmentAddScreen> {
  final GlobalKey _categoryTourKey = GlobalKey(debugLabel: 'pm_add_category');
  final GlobalKey _nameTourKey = GlobalKey(debugLabel: 'pm_add_name');
  final GlobalKey _capacityTourKey = GlobalKey(debugLabel: 'pm_add_capacity');
  final GlobalKey _imageTourKey = GlobalKey(debugLabel: 'pm_add_image');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'pm_add_save');
  String? _lastShowcasedTourStepId;
  late final TextEditingController _name;
  late final TextEditingController _capacity;
  late final TextEditingController _unit;
  String _image = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _capacity = TextEditingController();
    _unit = TextEditingController(text: 'Nos');
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return;
    final url =
        await ref.read(pmProvider.notifier).uploadImage(widget.siteId, file);
    if (!mounted) return;
    if (url.isNotEmpty) setState(() => _image = url);
  }

  Future<void> _save() async {
    if (widget.category.categoryKey.trim().isEmpty ||
        widget.category.categoryName.trim().isEmpty) {
      widget.onError('Category is required');
      return;
    }
    if (_name.text.trim().isEmpty) {
      widget.onError('Work name is required');
      return;
    }
    final ok = await ref.read(pmProvider.notifier).saveEquipment(
          widget.siteId,
          categoryKey: widget.category.categoryKey,
          categoryName: widget.category.categoryName,
          equipmentName: _name.text.trim(),
          capacity: _capacity.text.trim(),
          unit: _unit.text.trim().isEmpty ? 'Nos' : _unit.text.trim(),
          image: _image,
          workType: widget.workType,
          reloadAfterSave: false,
        );
    if (!mounted) return;
    if (ok) {
      await ref
          .read(pmProvider.notifier)
          .load(widget.siteId, widget.workType);
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } else {
      widget.onError(ref.read(pmProvider).error ?? 'Save failed');
    }
  }

  void _syncPmWorkFormTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id:
          '${SetupModuleTours.pmSetupId}_${widget.siteId}_${widget.category.categoryKey}_add_work_form',
      title: 'Add P&M Work',
      description: 'Learn how to add a plant and machinery work.',
      icon: Icons.precision_manufacturing_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_work_add_intro',
          title: 'Add P&M Work',
          body:
              'Use this form to create a work or machine item under the selected P&M category.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_work_add_category',
          title: 'Category',
          body:
              'This locked field shows where the new work will be saved.',
          targetKey: _categoryTourKey,
          progressLabel: 'Category',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_add_name',
          title: 'Work Name',
          body:
              'Enter the machine, equipment, or P&M work name here.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_add_capacity',
          title: 'Capacity and Unit',
          body:
              'Add capacity and unit if this work needs it, like 10 Ton, 1 Nos, or 5 HP.',
          targetKey: _capacityTourKey,
          progressLabel: 'Capacity',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_add_image',
          title: 'Work Image',
          body:
              'Upload an image if you want this work to be easier to identify later.',
          targetKey: _imageTourKey,
          progressLabel: 'Image',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_add_save',
          title: 'Save Work',
          body: 'Tap Save Work after the P&M work details are ready.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.pmSetupId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(pmProvider);
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncPmWorkFormTour(showcaseContext);
        return _PmTourStack(
          child: Scaffold(
            drawer: const CustomDrawer(),
            backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
            appBar: const CustomAppBar(title: 'Add P&M Work'),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tourTarget(
                  _categoryTourKey,
                  _LockedCategoryField(
                    categoryName: widget.category.categoryName,
                  ),
                ),
                const SizedBox(height: 14),
                _tourTarget(
                  _nameTourKey,
                  _TextField(controller: _name, label: 'Work Name'),
                ),
                _tourTarget(
                  _capacityTourKey,
                  Column(
                    children: [
                      _TextField(controller: _capacity, label: 'Capacity'),
                      _TextField(controller: _unit, label: 'Unit'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _tourTarget(
                  _imageTourKey,
                  Column(
                    children: [
                      _ImagePreview(imageUrl: _image, height: 180),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('Upload / Replace Image'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _tourTarget(
                  _saveTourKey,
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: state.isSaving ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Work'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PmEquipmentEditScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String workType;
  final PmEquipment equipment;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _PmEquipmentEditScreen({
    required this.siteId,
    required this.workType,
    required this.equipment,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_PmEquipmentEditScreen> createState() =>
      _PmEquipmentEditScreenState();
}

class _PmEquipmentEditScreenState
    extends ConsumerState<_PmEquipmentEditScreen>
    with ScreenOwnedTourMixin<_PmEquipmentEditScreen> {
  final GlobalKey _headerTourKey = GlobalKey(debugLabel: 'pm_edit_header');
  final GlobalKey _nameTourKey = GlobalKey(debugLabel: 'pm_edit_name');
  final GlobalKey _capacityTourKey = GlobalKey(debugLabel: 'pm_edit_capacity');
  final GlobalKey _imageTourKey = GlobalKey(debugLabel: 'pm_edit_image');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'pm_edit_save');
  String? _lastShowcasedTourStepId;
  late final TextEditingController _name;
  late final TextEditingController _capacity;
  late final TextEditingController _unit;
  late String _image;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.equipment.equipmentName);
    _capacity = TextEditingController(text: widget.equipment.capacity);
    _unit = TextEditingController(text: widget.equipment.unit);
    _image = widget.equipment.image;
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return;
    final url =
        await ref.read(pmProvider.notifier).uploadImage(widget.siteId, file);
    if (!mounted) return;
    if (url.isNotEmpty) setState(() => _image = url);
  }

  Future<void> _save() async {
    if (widget.equipment.categoryKey.trim().isEmpty ||
        widget.equipment.categoryName.trim().isEmpty) {
      widget.onError('Category is required');
      return;
    }
    if (_name.text.trim().isEmpty) {
      widget.onError('Work name is required');
      return;
    }
    final ok = await ref.read(pmProvider.notifier).saveEquipment(
          widget.siteId,
          equipment: widget.equipment,
          categoryKey: widget.equipment.categoryKey,
          categoryName: widget.equipment.categoryName,
          equipmentName: _name.text.trim(),
          capacity: _capacity.text.trim(),
          unit: _unit.text.trim().isEmpty ? 'Nos' : _unit.text.trim(),
          image: _image,
          workType: widget.workType,
          reloadAfterSave: false,
        );
    if (!mounted) return;
    if (ok) {
      await ref
          .read(pmProvider.notifier)
          .load(widget.siteId, widget.workType);
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } else {
      widget.onError(ref.read(pmProvider).error ?? 'Save failed');
    }
  }

  void _syncPmWorkEditTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.pmSetupId}_${widget.siteId}_${widget.equipment.id}_edit_work_form',
      title: 'Edit P&M Work',
      description: 'Learn how to edit a plant and machinery work.',
      icon: Icons.edit_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_work_edit_intro',
          title: 'Edit P&M Work',
          body:
              'Use this screen to check or update an existing P&M work.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_work_edit_header',
          title: 'Current Work',
          body:
              'This shows the selected P&M work and its category.',
          targetKey: _headerTourKey,
          progressLabel: 'Current',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_edit_name',
          title: 'Work Name',
          body: 'Update the equipment or work name here if needed.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_edit_capacity',
          title: 'Capacity and Unit',
          body:
              'Update capacity and unit when the work needs clearer measurement.',
          targetKey: _capacityTourKey,
          progressLabel: 'Capacity',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_edit_image',
          title: 'Work Image',
          body:
              'Replace the image if you want this P&M work to be easier to recognize.',
          targetKey: _imageTourKey,
          progressLabel: 'Image',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_work_edit_save',
          title: 'Save Work',
          body: 'Tap Save Work after checking the updated details.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.pmSetupId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(pmProvider);
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncPmWorkEditTour(showcaseContext);
        return _PmTourStack(
          child: Scaffold(
            drawer: const CustomDrawer(),
            backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
            appBar: const CustomAppBar(title: 'Edit P&M Work'),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tourTarget(
                  _headerTourKey,
                  _PmEquipmentEditHeader(equipment: widget.equipment),
                ),
                const SizedBox(height: 14),
                _tourTarget(
                  _nameTourKey,
                  _TextField(controller: _name, label: 'Work Name'),
                ),
                _tourTarget(
                  _capacityTourKey,
                  Column(
                    children: [
                      _TextField(controller: _capacity, label: 'Capacity'),
                      _TextField(controller: _unit, label: 'Unit'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _tourTarget(
                  _imageTourKey,
                  Column(
                    children: [
                      _ImagePreview(imageUrl: _image, height: 180),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('Upload / Replace Image'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _tourTarget(
                  _saveTourKey,
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: state.isSaving ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Work'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EntryTab extends ConsumerStatefulWidget {
  final PmState state;
  final String siteId;
  final String siteName;
  final String workType;
  final VoidCallback onDateTap;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _EntryTab({
    required this.state,
    required this.siteId,
    required this.siteName,
    required this.workType,
    required this.onDateTap,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_EntryTab> createState() => _EntryTabState();
}

class _EntryTabState extends ConsumerState<_EntryTab>
    with ScreenOwnedTourMixin<_EntryTab> {
  final GlobalKey _selectionTourKey = GlobalKey(debugLabel: 'pm_entry_select');
  final GlobalKey _dateTourKey = GlobalKey(debugLabel: 'pm_entry_date');
  final GlobalKey _workTourKey = GlobalKey(debugLabel: 'pm_entry_work');
  final GlobalKey _machineTourKey = GlobalKey(debugLabel: 'pm_entry_machine');
  final GlobalKey _timeTourKey = GlobalKey(debugLabel: 'pm_entry_time');
  final GlobalKey _hoursTourKey = GlobalKey(debugLabel: 'pm_entry_hours');
  final GlobalKey _fuelTourKey = GlobalKey(debugLabel: 'pm_entry_fuel');
  final GlobalKey _progressTourKey = GlobalKey(debugLabel: 'pm_entry_progress');
  final GlobalKey _statusTourKey = GlobalKey(debugLabel: 'pm_entry_status');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'pm_entry_save');
  String? _lastShowcasedTourStepId;
  String? _pendingRuntimeTourId;
  PmEquipment? _equipment;
  final _equipmentNo = TextEditingController();
  final _capacity = TextEditingController();
  final _vendor = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _working = TextEditingController();
  final _breakdown = TextEditingController();
  final _idle = TextEditingController();
  final _operator = TextEditingController();
  final _driver = TextEditingController();
  final _fuel = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController();
  final _location = TextEditingController();
  final _activity = TextEditingController();
  final _description = TextEditingController();
  String _ownerType = '';
  String _fuelType = '';
  String _status = 'working';
  bool _maintenanceRequired = false;
  String _entrySyncKey = '';

  @override
  void dispose() {
    for (final controller in [
      _equipmentNo,
      _capacity,
      _vendor,
      _start,
      _end,
      _working,
      _breakdown,
      _idle,
      _operator,
      _driver,
      _fuel,
      _quantity,
      _unit,
      _location,
      _activity,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncPmEntrySelectionTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.pmEntryId}_${widget.siteId}_${widget.workType}_select',
      title: 'P&M Entry',
      description: 'Choose the P&M work for daily entry.',
      icon: Icons.engineering_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_entry_select_intro',
          title: 'P&M Entry',
          body:
              'First choose the P&M work or machine you want to record for today.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_entry_select_work',
          title: 'Select Work',
          body:
              'Tap a work card to add or edit the selected date entry.',
          targetKey: _selectionTourKey,
          progressLabel: 'Select',
          autoScrollToTarget: true,
        ),
      ],
    );
    _syncRuntimeTour(
      showcaseContext,
      definition: definition,
      policyTourId: SetupModuleTours.pmEntryId,
    );
  }

  void _syncPmEntryFormTour(
    BuildContext showcaseContext,
    PmEquipment selectedEquipment,
  ) {
    final definition = AppTourDefinition(
      id:
          '${SetupModuleTours.pmEntryId}_${widget.siteId}_${widget.workType}_${selectedEquipment.id}_form',
      title: 'P&M Entry Form',
      description: 'Record daily plant and machinery details.',
      icon: Icons.engineering_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_entry_form_intro',
          title: 'P&M Entry Form',
          body:
              'Use this form to record what this machine or P&M work did today.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_entry_date',
          title: 'Entry Date',
          body:
              'This is the date for the P&M entry. Tap it to change the day.',
          targetKey: _dateTourKey,
          progressLabel: 'Date',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_work',
          title: 'Selected Work',
          body:
              'This confirms which machine or P&M work you are filling details for.',
          targetKey: _workTourKey,
          progressLabel: 'Work',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_machine',
          title: 'Machine Details',
          body:
              'Add equipment number, capacity, owner type, and vendor details if available.',
          targetKey: _machineTourKey,
          progressLabel: 'Machine',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_time',
          title: 'Start and End Time',
          body:
              'Enter when the machine started and stopped working for this entry.',
          targetKey: _timeTourKey,
          progressLabel: 'Time',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_hours',
          title: 'Working Hours',
          body:
              'Record working, breakdown, and idle hours so reports show correct machine usage.',
          targetKey: _hoursTourKey,
          progressLabel: 'Hours',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_fuel',
          title: 'Fuel and People',
          body:
              'Add operator, driver, fuel type, and fuel consumed if these details apply.',
          targetKey: _fuelTourKey,
          progressLabel: 'Fuel',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_progress',
          title: 'Work Progress',
          body:
              'Enter quantity, unit, location, activity, and a short work description.',
          targetKey: _progressTourKey,
          progressLabel: 'Progress',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_status',
          title: 'Status',
          body:
              'Choose whether the machine was working, idle, under breakdown, or in maintenance.',
          targetKey: _statusTourKey,
          progressLabel: 'Status',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_entry_save',
          title: 'Save P&M Entry',
          body:
              'Tap this button when today’s P&M details are ready.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );
    _syncRuntimeTour(
      showcaseContext,
      definition: definition,
      policyTourId: SetupModuleTours.pmEntryId,
    );
  }

  void _syncRuntimeTour(
    BuildContext showcaseContext, {
    required AppTourDefinition definition,
    required String policyTourId,
  }) {
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);
    if (_pendingRuntimeTourId == definition.id) return;
    _pendingRuntimeTourId = definition.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        if (!showcaseContext.mounted) return;
        final tourState = ref.read(appTourControllerProvider);
        final tourController = ref.read(appTourControllerProvider.notifier);
        if (tourState.status != AppTourStatus.running) {
          await tourController.maybeStartRuntimeTour(
            definition,
            policyTourId: policyTourId,
          );
        }
        if (!mounted || !showcaseContext.mounted) return;
        final step = tourController.currentStep;
        final activeTour = tourController.activeTour;
        if (activeTour == null || activeTour.id != definition.id) {
          if (_lastShowcasedTourStepId != null) {
            _lastShowcasedTourStepId = null;
          }
          return;
        }
        final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
        if (step == null) {
          if (_lastShowcasedTourStepId != null) {
            _lastShowcasedTourStepId = null;
          }
          return;
        }
        if (_lastShowcasedTourStepId == stepKey) return;
        _lastShowcasedTourStepId = stepKey;
        // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
      } finally {
        if (_pendingRuntimeTourId == definition.id) {
          _pendingRuntimeTourId = null;
        }
      }
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.categories;
    if (widget.state.isLoading && categories.isEmpty) {
      return const _PmCategorySelectionSkeleton();
    }
    if (categories.isEmpty) {
      return const _EmptyState(title: 'Configure P&M setup first');
    }

    final selectedEquipment = _findCurrentEquipment(categories);
    if (selectedEquipment == null) {
      ref.watch(appTourControllerProvider);
      return ShowCaseWidget(
        builder: (showcaseContext) {
          _syncPmEntrySelectionTour(showcaseContext);
          return _PmTourStack(
            child: _tourTarget(
              _selectionTourKey,
              _WorkSelectionPage(
                categories: categories,
                onSelect: _selectEquipment,
              ),
            ),
          );
        },
      );
    }
    _equipment = selectedEquipment;
    _syncSelectedEntry(selectedEquipment);

    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncPmEntryFormTour(showcaseContext, selectedEquipment);
        return _PmTourStack(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
        _tourTarget(
          _dateTourKey,
          _PmEntryInfoBanner(
          siteName: widget.siteName,
          teamName: _formatPmContextLabel(widget.workType),
          date: widget.state.selectedDate,
          onTap: widget.onDateTap,
          ),
        ),
        const SizedBox(height: 12),
        _tourTarget(
          _workTourKey,
          _PmEntryWorkTitle(equipment: selectedEquipment),
        ),
        const SizedBox(height: 8),
        _tourTarget(
          _machineTourKey,
          Column(
            children: [
              _TextField(controller: _equipmentNo, label: 'Equipment Number'),
              _TextField(controller: _capacity, label: 'Equipment Capacity'),
              _MenuField(
                label: 'Owner Type',
                value: _ownerType,
                values: const ['', 'company', 'rental'],
                onChanged: (value) => setState(() => _ownerType = value),
              ),
              _TextField(controller: _vendor, label: 'Vendor Name'),
            ],
          ),
        ),
        _tourTarget(
          _timeTourKey,
          Row(
          children: [
            Expanded(
              child: _TextField(
                controller: _start,
                label: 'Start Time',
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TextField(
                controller: _end,
                label: 'End Time',
                keyboardType: TextInputType.datetime,
              ),
            ),
          ],
          ),
        ),
        _tourTarget(
          _hoursTourKey,
          Column(
            children: [
        Row(
          children: [
            Expanded(
              child: _TextField(
                controller: _working,
                label: 'Working Hours',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TextField(
                controller: _breakdown,
                label: 'Breakdown Hours',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        _TextField(
            controller: _idle,
            label: 'Idle Hours',
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ],
          ),
        ),
        _tourTarget(
          _fuelTourKey,
          Column(
            children: [
              _TextField(controller: _operator, label: 'Operator Name'),
              _TextField(controller: _driver, label: 'Driver Name'),
              _MenuField(
                label: 'Fuel Type',
                value: _fuelType,
                values: const ['', 'diesel', 'petrol', 'electric', 'other'],
                onChanged: (value) => setState(() => _fuelType = value),
              ),
              _TextField(
                  controller: _fuel,
                  label: 'Fuel Consumed',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
            ],
          ),
        ),
        _tourTarget(
          _progressTourKey,
          Column(
            children: [
        Row(
          children: [
            Expanded(
              child: _TextField(
                controller: _quantity,
                label: 'Quantity Executed',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _TextField(controller: _unit, label: 'Unit')),
          ],
        ),
        _TextField(controller: _location, label: 'Location'),
        _TextField(controller: _activity, label: 'Activity Performed'),
        _TextField(
            controller: _description, label: 'Work Description', maxLines: 3),
            ],
          ),
        ),
        _tourTarget(
          _statusTourKey,
          Column(
            children: [
              _MenuField(
                label: 'Status',
                value: _status,
                values: const ['working', 'idle', 'breakdown', 'maintenance'],
                onChanged: (value) => setState(() => _status = value),
              ),
              SwitchListTile(
                value: _maintenanceRequired,
                onChanged: (value) =>
                    setState(() => _maintenanceRequired = value),
                title: const Text('Maintenance Required'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _tourTarget(
          _saveTourKey,
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: widget.state.isSaving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save P&M Entry'),
            ),
          ),
        ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final equipment = _equipment;
    if (equipment == null) {
      widget.onError('Please select equipment');
      return;
    }
    final existingEntry = _entryForEquipment(equipment);
    final ok = await ref.read(pmProvider.notifier).createEntry(
      widget.siteId,
      equipment: equipment,
      workType: widget.workType,
      data: {
        if (existingEntry?.id.isNotEmpty == true) 'entryId': existingEntry!.id,
        'equipmentNumber': _equipmentNo.text.trim(),
        'equipmentCapacity': _capacity.text.trim(),
        'vendorName': _vendor.text.trim(),
        'ownerType': _ownerType,
        'startTime': _start.text.trim(),
        'endTime': _end.text.trim(),
        'totalWorkingHours': _num(_working.text),
        'breakdownHours': _num(_breakdown.text),
        'idleHours': _num(_idle.text),
        'operatorName': _operator.text.trim(),
        'driverName': _driver.text.trim(),
        'fuelType': _fuelType,
        'fuelConsumed': _num(_fuel.text),
        'quantityExecuted': _num(_quantity.text),
        'unit': _unit.text.trim(),
        'location': _location.text.trim(),
        'activityPerformed': _activity.text.trim(),
        'workDescription': _description.text.trim(),
        'status': _status,
        'maintenanceRequired': _maintenanceRequired,
      },
    );
    ok
        ? widget.onSaved()
        : widget.onError(ref.read(pmProvider).error ?? 'Save failed');
  }

  PmEquipment? _findCurrentEquipment(List<PmCategory> categories) {
    final selected = _equipment;
    if (selected == null) return null;
    for (final equipment in _flattenEquipment(categories)) {
      if (equipment.id == selected.id && equipment.source == selected.source) {
        return equipment;
      }
    }
    return null;
  }

  void _selectEquipment(PmEquipment equipment) {
    setState(() {
      _equipment = equipment;
      _entrySyncKey = '';
      _syncSelectedEntry(equipment);
    });
  }

  PmEntry? _entryForEquipment(PmEquipment equipment) {
    for (final entry in widget.state.entries) {
      if (entry.equipmentId == equipment.id) return entry;
    }
    for (final entry in widget.state.entries) {
      final sameName = entry.equipmentName.trim().toLowerCase() ==
          equipment.equipmentName.trim().toLowerCase();
      final sameCategory = entry.categoryName.trim().toLowerCase() ==
          equipment.categoryName.trim().toLowerCase();
      if (sameName && sameCategory) return entry;
    }
    return null;
  }

  void _syncSelectedEntry(PmEquipment equipment) {
    final dateKey = formatPmDate(widget.state.selectedDate);
    final entry = _entryForEquipment(equipment);
    final nextKey = '${equipment.id}:$dateKey:${entry?.id ?? 'new'}';
    if (_entrySyncKey == nextKey) return;
    _entrySyncKey = nextKey;

    if (entry == null) {
      _clearEntryFields(equipment);
      return;
    }

    _equipmentNo.text = entry.equipmentNumber;
    _capacity.text = entry.equipmentCapacity.isNotEmpty
        ? entry.equipmentCapacity
        : equipment.capacity;
    _ownerType = entry.ownerType;
    _vendor.text = entry.vendorName;
    _start.text = entry.startTime;
    _end.text = entry.endTime;
    _working.text = _formatEntryNumber(entry.totalWorkingHours);
    _breakdown.text = _formatEntryNumber(entry.breakdownHours);
    _idle.text = _formatEntryNumber(entry.idleHours);
    _operator.text = entry.operatorName;
    _driver.text = entry.driverName;
    _fuelType = entry.fuelType;
    _fuel.text = _formatEntryNumber(entry.fuelConsumed);
    _quantity.text = _formatEntryNumber(entry.quantityExecuted);
    _unit.text = entry.unit.isNotEmpty ? entry.unit : equipment.unit;
    _location.text = entry.location;
    _activity.text = entry.activityPerformed;
    _description.text = entry.workDescription;
    _status = entry.status.isNotEmpty ? entry.status : 'working';
    _maintenanceRequired = entry.maintenanceRequired;
  }

  void _clearEntryFields(PmEquipment equipment) {
    _equipmentNo.clear();
    _capacity.text = equipment.capacity;
    _ownerType = '';
    _vendor.clear();
    _start.clear();
    _end.clear();
    _working.clear();
    _breakdown.clear();
    _idle.clear();
    _operator.clear();
    _driver.clear();
    _fuelType = '';
    _fuel.clear();
    _quantity.clear();
    _unit.text = equipment.unit;
    _location.clear();
    _activity.clear();
    _description.clear();
    _status = 'working';
    _maintenanceRequired = false;
  }

  String _formatEntryNumber(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  double _num(String value) => double.tryParse(value.trim()) ?? 0;
}

class _ReportsTab extends ConsumerStatefulWidget {
  final PmState state;
  final String siteId;
  final String workType;
  final VoidCallback onDateTap;

  const _ReportsTab({
    required this.state,
    required this.siteId,
    required this.workType,
    required this.onDateTap,
  });

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab>
    with ScreenOwnedTourMixin<_ReportsTab> {
  final GlobalKey _dateTourKey = GlobalKey(debugLabel: 'pm_reports_date');
  final GlobalKey _summaryTourKey = GlobalKey(debugLabel: 'pm_reports_summary');
  final GlobalKey _entriesTourKey = GlobalKey(debugLabel: 'pm_reports_entries');
  String? _lastShowcasedTourStepId;

  void _syncPmReportsTour(BuildContext showcaseContext) {
    final hasEntries = widget.state.entries.isNotEmpty;
    final definition = AppTourDefinition(
      id:
          '${SetupModuleTours.pmReportsId}_${widget.siteId}_${widget.workType}_${formatPmDate(widget.state.selectedDate)}_${hasEntries ? 'entries' : 'empty'}',
      title: 'P&M Reports',
      description: 'Check daily plant and machinery summaries.',
      icon: Icons.analytics_rounded,
      steps: [
        const AppTourStep(
          id: 'pm_reports_intro',
          title: 'P&M Reports',
          body:
              'Use this screen to check machine usage, entries, working hours, and fuel for a selected date.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'pm_reports_date',
          title: 'Report Date',
          body:
              'This is the date used for the report. Tap it to check another day.',
          targetKey: _dateTourKey,
          progressLabel: 'Date',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_reports_summary',
          title: 'Summary',
          body:
              'These tiles show total equipment, saved entries, working hours, and fuel for the selected date.',
          targetKey: _summaryTourKey,
          progressLabel: 'Summary',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'pm_reports_entries',
          title: hasEntries ? 'Entry List' : 'No Entries',
          body: hasEntries
              ? 'Each card below is a saved P&M entry for this date.'
              : 'If no entry is saved for this date, the report will show this empty message.',
          targetKey: _entriesTourKey,
          progressLabel: 'Entries',
          autoScrollToTarget: true,
        ),
      ],
    );

    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.pmReportsId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // P&M uses the local no-cutout overlay; Showcase presentation is disabled.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return _PmTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    ref.watch(appTourControllerProvider);
    if (state.isLoading && state.entries.isEmpty) {
      return const _PmReportSkeleton();
    }

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncPmReportsTour(showcaseContext);
        return _PmTourStack(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _tourTarget(
                _dateTourKey,
                _DateCard(
                    title: 'P&M Report Date',
                    date: state.selectedDate,
                    onTap: widget.onDateTap),
              ),
              const SizedBox(height: 12),
              _tourTarget(
                _summaryTourKey,
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _SummaryTile(
                        label: 'Equipment',
                        value: '${state.summary.totalEquipment}'),
                    _SummaryTile(
                        label: 'Entries',
                        value: '${state.summary.totalEntries}'),
                    _SummaryTile(
                        label: 'Working Hrs',
                        value: _fmt(state.summary.totalWorkingHours)),
                    _SummaryTile(
                        label: 'Fuel',
                        value: _fmt(state.summary.totalFuelConsumption)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _tourTarget(
                _entriesTourKey,
                state.entries.isEmpty
                    ? const _EmptyState(title: 'No entries for selected date')
                    : Column(
                        children: state.entries
                            .map((entry) => _EntryCard(entry: entry))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PmReportSkeleton extends StatelessWidget {
  const _PmReportSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        ShimmerImage(
          height: 56,
          width: double.infinity,
          borderRadius: 14,
          border: Border.all(color: cs.outlineVariant),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: List.generate(
            4,
            (index) => ShimmerImage(
              height: 72,
              width: double.infinity,
              borderRadius: 14,
              border: Border.all(color: cs.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ShimmerImage(
              height: 88,
              width: double.infinity,
              borderRadius: 14,
              border: Border.all(color: cs.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final PmEquipment equipment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _EquipmentCard({
    required this.equipment,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _ImagePreview(imageUrl: equipment.image, height: 68, width: 76),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.equipmentName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equipment.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [equipment.capacity, equipment.unit]
                          .where((text) => text.trim().isNotEmpty)
                          .join(' • '),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
              if (equipment.isCustom && onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_rounded, size: 20, color: cs.error),
                ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final PmEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagePreview(
                imageUrl: entry.equipmentImage, height: 64, width: 72),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.equipmentName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(entry.categoryName,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ChipText('${_fmt(entry.totalWorkingHours)} hrs'),
                      _ChipText(
                          '${_fmt(entry.quantityExecuted)} ${entry.unit}'),
                      _ChipText(entry.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double? width;

  const _ImagePreview({
    required this.imageUrl,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: cs.surfaceContainerHighest,
        child: imageUrl.trim().isEmpty
            ? Icon(Icons.precision_manufacturing_rounded, color: cs.primary)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(
                  Icons.precision_manufacturing_rounded,
                  color: cs.primary,
                ),
                placeholder: (_, __) => ShimmerImage(
                  height: height,
                  width: width ?? double.infinity,
                  borderRadius: 12,
                ),
              ),
      ),
    );
  }
}

class _PmEntryInfoBanner extends StatelessWidget {
  final String siteName;
  final String teamName;
  final DateTime date;
  final VoidCallback onTap;

  const _PmEntryInfoBanner({
    required this.siteName,
    required this.teamName,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 14,
        compact ? 12 : 14,
        compact ? 12 : 14,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withOpacity(0.55),
            cs.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_city_rounded,
              color: cs.primary,
              size: compact ? 20 : 22,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siteName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'P&M Daily Entry',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (teamName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    'Team: $teamName',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.primary.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: compact ? 12 : 13,
                    color: cs.primary,
                  ),
                  SizedBox(width: compact ? 4 : 5),
                  Text(
                    DateFormat('dd MMM yy').format(date),
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final VoidCallback onTap;

  const _DateCard({
    required this.title,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text(DateFormat('dd MMM yyyy').format(date)),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;

  const _ChipText(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _MenuField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _MenuField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdownField<String>(
      label: label,
      value: values.contains(value) ? value : values.first,
      items: values
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.isEmpty ? 'Select' : item),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLines: maxLines,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.precision_manufacturing_rounded,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;

  const _EmptyPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

List<PmEquipment> _flattenEquipment(List<PmCategory> categories) {
  return [
    for (final category in categories) ...category.equipment,
  ];
}
