import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/dio.dart';

import '../../../../../../features/language/service/providers.dart';
import '../../../boq/service/boq_service.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../providers/rate_variant_provider.dart';
import '../../providers/selectedSize_provider.dart';
import '../../providers/selection_provider.dart';
import '../../utils/image_track/dpr_cached_image.dart';
import '../add_description.dart';
import '../mechanical_piping_boq_dpr_screen.dart';

class MechanichalStepperScreen extends ConsumerStatefulWidget {
  const MechanichalStepperScreen({
    super.key,
    this.siteId,
    this.teamId,
    this.teamName,
  });

  final String? siteId;
  final String? teamId;
  final String? teamName;

  @override
  ConsumerState<MechanichalStepperScreen> createState() =>
      _MechanichalStepperScreenState();
}

class _MechanichalStepperScreenState
    extends ConsumerState<MechanichalStepperScreen> {
  final TextEditingController _sizeController = TextEditingController();
  int _currentStep = 0;
  int _maxUnlockedStep = 0;
  String? _selectedMoc;
  String? _selectedFloor;

  static const List<String> _stepLabels = ['MOC', 'Location', 'Size'];

  @override
  void initState() {
    super.initState();
    _selectedMoc = ref.read(selectedMocNameProvider);
    _selectedFloor = ref.read(selectedFloorNameProvider);
    _sizeController.text = ref.read(selectedSizeProvider) ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBoqDprIfReady());
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    if (index > _maxUnlockedStep) return;
    setState(() => _currentStep = index.clamp(0, _stepLabels.length - 1));
  }

  bool _isStepComplete(int stepIndex) {
    if (stepIndex == 0) return (_selectedMoc ?? '').trim().isNotEmpty;
    if (stepIndex == 1) return (_selectedFloor ?? '').trim().isNotEmpty;
    return _sizeController.text.trim().isNotEmpty;
  }

  void _unlockNextIfCurrentCompleted() {
    if (!_isStepComplete(_currentStep)) return;
    if (_currentStep >= _stepLabels.length - 1) return;
    setState(() {
      if (_maxUnlockedStep < _currentStep + 1) {
        _maxUnlockedStep = _currentStep + 1;
      }
    });
  }

  void _nextStep() {
    if (_currentStep >= _stepLabels.length - 1) {
      _continueToDescription();
      return;
    }
    if (!_isStepComplete(_currentStep)) return;
    setState(() => _currentStep += 1);
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  void _skipStep() {
    if (_currentStep >= _stepLabels.length - 1) {
      _continueToDescription();
      return;
    }

    setState(() {
      if (_maxUnlockedStep < _currentStep + 1) {
        _maxUnlockedStep = _currentStep + 1;
      }
      _currentStep += 1;
    });
  }

  void _selectMoc(String mocName) {
    setState(() => _selectedMoc = mocName);
    ref.read(selectedMocNameProvider.notifier).state = mocName;
    _unlockNextIfCurrentCompleted();
  }

  void _selectFloor(String floorName) {
    setState(() => _selectedFloor = floorName);
    ref.read(selectedFloorNameProvider.notifier).state = floorName;
    _unlockNextIfCurrentCompleted();
  }

  int _computeMaxUnlockedStep() {
    final hasMoc = (_selectedMoc ?? '').trim().isNotEmpty;
    final hasFloor = (_selectedFloor ?? '').trim().isNotEmpty;
    final hasSize = _sizeController.text.trim().isNotEmpty;

    if (!hasMoc) return 0;
    if (!hasFloor) return 1;
    return hasSize ? 2 : 2;
  }

  void _resetStepperPosition() {
    final size = ref.read(selectedSizeProvider) ?? '';
    setState(() {
      _currentStep = 0;
      _selectedMoc = ref.read(selectedMocNameProvider);
      _selectedFloor = ref.read(selectedFloorNameProvider);
      _sizeController.text = size;
      _maxUnlockedStep = _computeMaxUnlockedStep();
    });
  }

  Future<void> _continueToDescription() async {
    final sizeValue = _sizeController.text.trim();
    ref.read(selectedSizeProvider.notifier).state =
        sizeValue.isEmpty ? null : sizeValue;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddDescriptionScreen()),
    );

    if (!mounted) return;
    _resetStepperPosition();
  }

  void _clearAllSelections() {
    setState(() {
      _currentStep = 0;
      _maxUnlockedStep = 0;
      _selectedMoc = null;
      _selectedFloor = null;
      _sizeController.clear();
    });

    ref.read(selectedMocNameProvider.notifier).state = null;
    ref.read(selectedFloorNameProvider.notifier).state = null;
    ref.read(selectedSizeProvider.notifier).state = null;
  }

  Future<void> _openBoqDprIfReady() async {
    final siteId = widget.siteId;
    if (siteId == null || siteId.trim().isEmpty || !mounted) return;
    try {
      final boqs = await BoqApiService(DioClient.dio)
          .getMechanicalPipingBoqs(siteId: siteId);
      if (!mounted || boqs.isEmpty) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MechanicalPipingBoqDprScreen(
            siteId: siteId,
            teamId: widget.teamId,
            teamName: widget.teamName,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Mechanical piping BOQ entry unavailable: $error');
    }
  }

  Widget _buildImage(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) {
    return DprCachedImage(
      imagePath: imagePath,
      fit: fit,
      alignment: alignment,
      fallback: const _FallbackImage(),
    );
  }

  Widget _buildMocStep(String siteId, AsyncValue<dynamic> asyncRateUpload) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (asyncRateUpload.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (asyncRateUpload.hasError) {
      return const _StepErrorCard(
        title: 'Unable to load rate file',
        subtitle: 'Please check your connection and try again.',
      );
    }

    final mocs = ref.watch(mocWithImagesProvider(siteId));
    if (mocs.isEmpty) {
      return const _StepEmptyCard(
        title: 'No MOC found',
        subtitle: 'You can skip this step and continue.',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: mocs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, index) {
        final item = mocs[index];
        final selected = _selectedMoc == item.name;
        return InkWell(
          onTap: () => _selectMoc(item.name),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D21) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.34 : 0.08),
                  blurRadius: selected ? 16 : 9,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildImage(item.image),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          color: cs.tertiary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloorStep(String siteId, AsyncValue<dynamic> asyncRateUpload) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (asyncRateUpload.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (asyncRateUpload.hasError) {
      return const _StepErrorCard(
        title: 'Unable to load floor data',
        subtitle: 'Please retry after rate file sync.',
      );
    }

    final floors = ref.watch(floorWithImagesProvider(siteId));
    if (floors.isEmpty) {
      return const _StepEmptyCard(
        title: 'No floor found',
        subtitle: 'You can skip this step and continue.',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: floors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, index) {
        final floor = floors[index];
        final selected = _selectedFloor == floor.name;
        return InkWell(
          onTap: () => _selectFloor(floor.name),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D21) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.34 : 0.08),
                  blurRadius: selected ? 16 : 9,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildImage(
                      floor.image,
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          floor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          color: cs.tertiary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSizeStep(String siteId) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedUnit = ref.watch(selectedUnitProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Size',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final cleaned = value.trim();
                      ref.read(selectedSizeProvider.notifier).state =
                          cleaned.isEmpty ? null : cleaned;
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 10, 12.5, 42',
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1A1D21) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D21) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedUnit,
                      items: const [
                        DropdownMenuItem(value: 'inch', child: Text('inch')),
                        DropdownMenuItem(value: 'mm', child: Text('mm')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(selectedUnitProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((_sizeController.text.trim()).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.tertiary.withValues(alpha: 0.7)),
                ),
                child: Text(
                  'Selected size: ${_sizeController.text.trim()} $selectedUnit',
                  style: TextStyle(
                    color: cs.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final siteId = ref.watch(selectedSiteIdProvider) ?? widget.siteId;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (siteId == null || siteId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Site not selected')),
      );
    }

    final asyncRateUpload = ref.watch(rateFileAnalysisProvider(siteId));

    final title = _currentStep == 0
        ? lang.chooseMocTitle
        : _currentStep == 1
            ? 'Choose Location'
            : lang.enterSizeTitle;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
      appBar: _MechanicalWizardAppBar(
        currentStep: _currentStep,
        totalSteps: 3,
        onClearAll: _clearAllSelections,
      ),
      body: ColoredBox(
        color: isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _StepperHeader(
                  currentStep: _currentStep,
                  maxUnlockedStep: _maxUnlockedStep,
                  labels: _stepLabels,
                  onTapStep: _jumpTo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    TextButton(
                      onPressed: _skipStep,
                      style: TextButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Padding(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _currentStep == 0
                          ? _buildMocStep(siteId, asyncRateUpload)
                          : _currentStep == 1
                              ? _buildFloorStep(siteId, asyncRateUpload)
                              : _buildSizeStep(siteId),
                    ),
                  ),
                ),
              ),
              _StepperBottomBar(
                currentStep: _currentStep,
                onBack: _currentStep == 0 ? null : _previousStep,
                onNext: _nextStep,
                canProceed: _isStepComplete(_currentStep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({
    required this.currentStep,
    required this.maxUnlockedStep,
    required this.labels,
    required this.onTapStep,
  });

  final int currentStep;
  final int maxUnlockedStep;
  final List<String> labels;
  final ValueChanged<int> onTapStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: InkWell(
              onTap: i <= maxUnlockedStep ? () => onTapStep(i) : null,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: i <= currentStep
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            i <= currentStep ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: i < currentStep
                        ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i <= currentStep
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: i <= currentStep
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != labels.length - 1)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: i < currentStep
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MechanicalWizardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _MechanicalWizardAppBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onClearAll,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onClearAll;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      toolbarHeight: 82,
      backgroundColor:
          isDark ? const Color(0xFF161A1E) : const Color(0xFFF9FBFF),
      leadingWidth: 64,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232830) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(Icons.arrow_back_rounded, color: cs.primary),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface,
              backgroundColor: isDark ? const Color(0xFF232830) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
      flexibleSpace: const SizedBox.shrink(),
    );
  }
}

class _StepperBottomBar extends StatelessWidget {
  const _StepperBottomBar({
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.canProceed,
  });

  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool canProceed;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == 2;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A1E) : Colors.white,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          if (onBack != null) const SizedBox(width: 8),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: canProceed ? onNext : null,
            icon: Icon(isLast ? Icons.done_all : Icons.arrow_forward),
            label: Text(isLast ? 'Enter' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepErrorCard extends StatelessWidget {
  const _StepErrorCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 44),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepEmptyCard extends StatelessWidget {
  const _StepEmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_clear, color: cs.primary, size: 42),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: cs.onSurfaceVariant,
        size: 26,
      ),
    );
  }
}
