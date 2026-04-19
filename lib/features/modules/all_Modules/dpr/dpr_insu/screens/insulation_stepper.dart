import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/floorModel.dart';
import '../../providers/selectedSize_provider.dart';
import '../model/insu_step_date.dart';
import 'testing.dart';

enum _InsuStepKind { floor, layer, lagging, cladding, size }

class InsulationStepperScreen extends ConsumerStatefulWidget {
  const InsulationStepperScreen({
    super.key,
    required this.siteId,
    required this.teamId,
    required this.siteName,
    required this.teamName,
  });

  final String siteId;
  final String teamId;
  final String siteName;
  final String teamName;

  @override
  ConsumerState<InsulationStepperScreen> createState() =>
      _InsulationStepperScreenState();
}

class _InsulationStepperScreenState
    extends ConsumerState<InsulationStepperScreen> {
  static const Map<_InsuStepKind, String> _stepLabels = {
    _InsuStepKind.floor: 'Floor',
    _InsuStepKind.layer: 'Layer',
    _InsuStepKind.lagging: 'Lagging',
    _InsuStepKind.cladding: 'Cladding',
    _InsuStepKind.size: 'Size',
  };

  static const List<Map<String, String>> _laggingMaterials = [
    {'name': 'Nitrile Rubber', 'image': 'assets/stepper/nitrie.webp'},
    {'name': 'PUF', 'image': 'assets/stepper/puf.webp'},
    {'name': 'LRB', 'image': 'assets/stepper/lrb.webp'},
  ];

  static const List<Map<String, String>> _claddingMaterials = [
    {'name': 'SS Sheet', 'image': 'assets/stepper/ss.webp'},
    {'name': 'Aluminium Sheet', 'image': 'assets/stepper/ss.webp'},
  ];

  final List<Floor> _allFloors = [
    Floor(
      id: 'floor_ground',
      name: 'Ground',
      image: 'assets/floor/groundfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_first',
      name: 'First',
      image: 'assets/floor/firstfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_second',
      name: 'Second',
      image: 'assets/floor/secondfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_third',
      name: 'Third',
      image: 'assets/floor/thirdfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_fourth',
      name: 'Fourth',
      image: 'assets/floor/fourthfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_terrace',
      name: 'Terrace',
      image: 'assets/floor/terrace.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _laggingThicknessController =
      TextEditingController();
  final TextEditingController _claddingThicknessController =
      TextEditingController();

  int _currentStep = 0;
  int _maxUnlockedStep = 0;
  int _activeLaggingLayerIndex = 0;

  @override
  void initState() {
    super.initState();
    _sizeController.text = ref.read(selectedSizeProvider) ?? '';
    _syncThicknessControllers();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _laggingThicknessController.dispose();
    _claddingThicknessController.dispose();
    super.dispose();
  }

  void _syncThicknessControllers() {
    final insuState = ref.read(insulationStateProvider);
    final layer = _currentLayer(insuState);
    _laggingThicknessController.text =
        layer == null || layer.thickness == 0 ? '' : layer.thickness.toString();
    _claddingThicknessController.text = insuState.cladding.thickness == 0
        ? ''
        : insuState.cladding.thickness.toString();
  }

  LayerData? _currentLayer(InsulationState state) {
    if (state.layers.isEmpty) return null;
    if (_activeLaggingLayerIndex < 0 ||
        _activeLaggingLayerIndex >= state.layers.length) {
      return null;
    }
    return state.layers[_activeLaggingLayerIndex];
  }

  List<_InsuStepKind> _visibleSteps(InsulationState state) {
    return [
      _InsuStepKind.floor,
      _InsuStepKind.layer,
      if (state.layerType != null) _InsuStepKind.lagging,
      _InsuStepKind.cladding,
      _InsuStepKind.size,
    ];
  }

  void _ensureStepInRange(InsulationState state) {
    final steps = _visibleSteps(state);
    if (_currentStep <= steps.length - 1) return;
    setState(() {
      _currentStep = steps.length - 1;
    });
  }

  void _jumpTo(int step) {
    final steps = _visibleSteps(ref.read(insulationStateProvider));
    if (step > _maxUnlockedStep) return;
    setState(() {
      _currentStep = step.clamp(0, steps.length - 1);
      _syncThicknessControllers();
    });
  }

  bool _isStepComplete(_InsuStepKind kind, InsulationState state) {
    switch (kind) {
      case _InsuStepKind.floor:
        return state.floor.trim().isNotEmpty;
      case _InsuStepKind.layer:
        return state.layerType != null;
      case _InsuStepKind.lagging:
        if (state.layers.isEmpty) return false;
        return state.layers.every(
          (e) => e.name.trim().isNotEmpty && e.thickness > 0,
        );
      case _InsuStepKind.cladding:
        return state.cladding.name.trim().isNotEmpty &&
            state.cladding.thickness > 0;
      case _InsuStepKind.size:
        return _sizeController.text.trim().isNotEmpty;
    }
  }

  void _unlockNextIfCurrentCompleted() {
    final state = ref.read(insulationStateProvider);
    final steps = _visibleSteps(state);
    if (_currentStep >= steps.length) return;
    if (!_isStepComplete(steps[_currentStep], state)) return;
    if (_currentStep >= steps.length - 1) return;
    setState(() {
      if (_maxUnlockedStep < _currentStep + 1) {
        _maxUnlockedStep = _currentStep + 1;
      }
    });
  }

  void _nextStep() {
    final steps = _visibleSteps(ref.read(insulationStateProvider));
    if (_currentStep >= steps.length - 1) {
      _submitAndOpenDescription();
      return;
    }
    final state = ref.read(insulationStateProvider);
    if (!_isStepComplete(steps[_currentStep], state)) return;
    setState(() {
      _currentStep += 1;
      _syncThicknessControllers();
    });
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
      _syncThicknessControllers();
    });
  }

  void _skipStep() {
    final steps = _visibleSteps(ref.read(insulationStateProvider));
    if (_currentStep >= steps.length - 1) {
      _submitAndOpenDescription();
      return;
    }

    setState(() {
      if (_maxUnlockedStep < _currentStep + 1) {
        _maxUnlockedStep = _currentStep + 1;
      }
      _currentStep += 1;
      _syncThicknessControllers();
    });
  }

  void _clearAll() {
    setState(() {
      _currentStep = 0;
      _maxUnlockedStep = 0;
      _activeLaggingLayerIndex = 0;
      _sizeController.clear();
      _laggingThicknessController.clear();
      _claddingThicknessController.clear();
    });

    ref.read(insulationStateProvider.notifier).resetAll();
    ref.read(laggingMaterialProvider.notifier).clear();
    ref.read(selectedSizeProvider.notifier).state = null;
  }

  void _onLayerTypeSelected(LayerType type) {
    final notifier = ref.read(insulationStateProvider.notifier);
    final laggingNotifier = ref.read(laggingMaterialProvider.notifier);

    notifier.setLayerType(type);
    final state = ref.read(insulationStateProvider);

    laggingNotifier.clear();
    for (var i = 0; i < state.layers.length; i++) {
      final layer = state.layers[i];
      if (layer.name.isEmpty && layer.thickness == 0) continue;
      laggingNotifier.add(
        LaggingMaterial(
          id: 'layer_$i',
          name: layer.name,
          thickness: layer.thickness,
          uom: 'mm',
        ),
      );
    }

    setState(() {
      _activeLaggingLayerIndex = 0;
      _syncThicknessControllers();
    });

    _ensureStepInRange(ref.read(insulationStateProvider));
    _unlockNextIfCurrentCompleted();
  }

  void _updateLaggingLayer({String? name, double? thickness}) {
    final state = ref.read(insulationStateProvider);
    if (state.layers.isEmpty ||
        _activeLaggingLayerIndex >= state.layers.length) {
      return;
    }

    final notifier = ref.read(insulationStateProvider.notifier);
    notifier.updateLayer(
      index: _activeLaggingLayerIndex,
      name: name,
      thickness: thickness,
    );

    final updatedLayer =
        ref.read(insulationStateProvider).layers[_activeLaggingLayerIndex];
    final laggingNotifier = ref.read(laggingMaterialProvider.notifier);

    if (updatedLayer.name.isEmpty && updatedLayer.thickness == 0) {
      laggingNotifier.delete('layer_$_activeLaggingLayerIndex');
    } else {
      laggingNotifier.delete('layer_$_activeLaggingLayerIndex');
      laggingNotifier.add(
        LaggingMaterial(
          id: 'layer_$_activeLaggingLayerIndex',
          name: updatedLayer.name,
          thickness: updatedLayer.thickness,
          uom: 'mm',
        ),
      );
    }

    _unlockNextIfCurrentCompleted();
  }

  void _submitAndOpenDescription() {
    final size = _sizeController.text.trim();
    ref.read(selectedSizeProvider.notifier).state = size.isEmpty ? null : size;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInsulationDescriptionScreen(),
      ),
    );
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported_outlined),
    );
  }

  Widget _buildFloorStep(InsulationState state) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      itemCount: _allFloors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.93,
      ),
      itemBuilder: (_, index) {
        final floor = _allFloors[index];
        final selected = state.floor == floor.name;

        return InkWell(
          onTap: () {
            ref.read(insulationStateProvider.notifier).setFloor(floor.name);
            _unlockNextIfCurrentCompleted();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D21) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2 : 1,
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
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    child: _buildImage(floor.image, fit: BoxFit.fitHeight),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          floor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: cs.tertiary, size: 18),
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

  Widget _buildLayerStep(InsulationState state) {
    final selected = state.layerType;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget option(LayerType type, String label) {
      final isSelected = selected == type;
      final cs = Theme.of(context).colorScheme;

      return InkWell(
        onTap: () => _onLayerTypeSelected(type),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary
                : (isDark ? const Color(0xFF1A1D21) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${type.count} layer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? cs.onPrimary.withValues(alpha: 0.9)
                      : cs.onSurfaceVariant,
                ),
              )
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        option(LayerType.single, 'Single Layer'),
        const SizedBox(height: 10),
        option(LayerType.double, 'Double Layer'),
        const SizedBox(height: 10),
        option(LayerType.triple, 'Triple Layer'),
      ],
    );
  }

  Widget _buildLaggingStep(InsulationState state) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final layers = state.layers;

    if (layers.isEmpty) {
      return Center(
        child: Text(
          'Choose layer type first.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    final layer = _currentLayer(state) ?? LayerData.empty();

    return ListView(
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(layers.length, (i) {
            final selected = i == _activeLaggingLayerIndex;
            return ChoiceChip(
              label: Text('Layer ${i + 1}'),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _activeLaggingLayerIndex = i;
                  _syncThicknessControllers();
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _laggingMaterials.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, index) {
            final material = _laggingMaterials[index];
            final selected = layer.name == material['name'];

            return InkWell(
              onTap: () => _updateLaggingLayer(name: material['name']),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D21) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: selected ? 2 : 1,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      child: _buildImage(material['image']!,
                          fit: BoxFit.fitHeight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      material['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Thickness (mm)',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _laggingThicknessController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _updateLaggingLayer(thickness: double.tryParse(value.trim()) ?? 0);
          },
          decoration: InputDecoration(
            hintText: 'Enter thickness',
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1D21) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCladdingStep(InsulationState state) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _claddingMaterials.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, index) {
            final material = _claddingMaterials[index];
            final selected = state.cladding.name == material['name'];

            return InkWell(
              onTap: () {
                ref.read(insulationStateProvider.notifier).setCladding(
                      name: material['name'],
                    );
                _unlockNextIfCurrentCompleted();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D21) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: selected ? 2 : 1,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      child: _buildImage(material['image']!,
                          fit: BoxFit.fitHeight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      material['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Thickness (SWG)',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _claddingThicknessController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            ref.read(insulationStateProvider.notifier).setCladding(
                  thickness: double.tryParse(value.trim()) ?? 0,
                );
            _unlockNextIfCurrentCompleted();
          },
          decoration: InputDecoration(
            hintText: 'Enter cladding thickness',
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1D21) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeStep() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedUnit = ref.watch(selectedUnitProvider);

    return ListView(
      children: [
        Text(
          'Size',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
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
                  _unlockNextIfCurrentCompleted();
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Enter size',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A1D21) : Colors.white,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final insuState = ref.watch(insulationStateProvider);
    final steps = _visibleSteps(insuState);
    final currentKind = steps[_currentStep.clamp(0, steps.length - 1)];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = currentKind == _InsuStepKind.floor
        ? 'Choose Floor'
        : currentKind == _InsuStepKind.layer
            ? 'Select Layer Type'
            : currentKind == _InsuStepKind.lagging
                ? 'Configure Lagging'
                : currentKind == _InsuStepKind.cladding
                    ? 'Configure Cladding'
                    : 'Enter Size';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
      appBar: _InsulationWizardAppBar(
        currentStep: _currentStep,
        totalSteps: steps.length,
        onClearAll: _clearAll,
      ),
      body: ColoredBox(
        color: isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _InsulationStepHeader(
                  currentStep: _currentStep,
                  maxUnlockedStep: _maxUnlockedStep,
                  labels: steps.map((e) => _stepLabels[e]!).toList(),
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
                    duration: const Duration(milliseconds: 220),
                    child: Padding(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: currentKind == _InsuStepKind.floor
                          ? _buildFloorStep(insuState)
                          : currentKind == _InsuStepKind.layer
                              ? _buildLayerStep(insuState)
                              : currentKind == _InsuStepKind.lagging
                                  ? _buildLaggingStep(insuState)
                                  : currentKind == _InsuStepKind.cladding
                                      ? _buildCladdingStep(insuState)
                                      : _buildSizeStep(),
                    ),
                  ),
                ),
              ),
              _InsulationStepperBottomBar(
                currentStep: _currentStep,
                totalSteps: steps.length,
                onBack: _currentStep == 0 ? null : _previousStep,
                onNext: _nextStep,
                canProceed: _isStepComplete(currentKind, insuState),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsulationWizardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _InsulationWizardAppBar({
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
            'Insulation Stepper',
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

class _InsulationStepHeader extends StatelessWidget {
  const _InsulationStepHeader({
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
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          i <= currentStep ? cs.primary : cs.onSurfaceVariant,
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

class _InsulationStepperBottomBar extends StatelessWidget {
  const _InsulationStepperBottomBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.canProceed,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool canProceed;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
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
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          if (onBack != null) const SizedBox(width: 8),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: canProceed ? onNext : null,
            icon: Icon(isLast ? Icons.done_all : Icons.arrow_forward_rounded),
            label: Text(isLast ? 'Enter' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
