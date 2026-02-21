import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../site_Details/providers/site_current_provider.dart';
import 'core/card_strategy.dart';

class AllMaterialsBaseScreen<TPiping, TEquipment>
    extends ConsumerStatefulWidget {
  final String title;

  final StateNotifierProvider<dynamic, List<TPiping>> pipingProvider;
  final StateNotifierProvider<dynamic, List<TEquipment>> equipmentProvider;

  final MaterialCardStrategy<TPiping> pipingCard;
  final MaterialCardStrategy<TEquipment> equipmentCard;

  final Future<List<dynamic>> Function(String siteId) fetch;
  final Future<void> Function({
  required String siteId,
  required String designation,
  required bool isApplied,
  }) setup;

  const AllMaterialsBaseScreen({
    super.key,
    required this.title,
    required this.pipingProvider,
    required this.equipmentProvider,
    required this.pipingCard,
    required this.equipmentCard,
    required this.fetch,
    required this.setup,
  });

  @override
  ConsumerState<AllMaterialsBaseScreen> createState() =>
      _AllMaterialsBaseScreenState();
}

class _AllMaterialsBaseScreenState<TPiping, TEquipment>
    extends ConsumerState<AllMaterialsBaseScreen<TPiping, TEquipment>>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = false;
  bool _initialized = false;
  bool _selectionMode = false;

  final Set<String> _selectedIds = {};

  String? _siteId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _siteId = ref.read(selectedSiteIdProvider);
      _init();
    });
  }

  Future<void> _init() async {
    if (_initialized || _siteId == null) return;

    setState(() => _loading = true);

    try {
      final materials = await widget.fetch(_siteId!);

      final piping = materials.whereType<TPiping>().toList();
      final equipment = materials.whereType<TEquipment>().toList();

      ref.read(widget.pipingProvider.notifier).setMaterials(piping);
      ref.read(widget.equipmentProvider.notifier).setMaterials(equipment);

      _initialized = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final piping = ref.watch(widget.pipingProvider);
    final equipment = ref.watch(widget.equipmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} Selected'
              : widget.title,
        ),
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() => _selectionMode = true);
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Piping'),
            Tab(text: 'Equipment'),
          ],
        ),
      ),
      body: _loading && !_initialized
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList<TPiping>(
            materials: piping,
            strategy: widget.pipingCard,
          ),
          _buildList<TEquipment>(
            materials: equipment,
            strategy: widget.equipmentCard,
          ),
        ],
      ),
    );
  }

  Widget _buildList<T>({
    required List<T> materials,
    required MaterialCardStrategy<T> strategy,
  }) {
    if (materials.isEmpty) {
      return const Center(
        child: Text('No materials found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index] as dynamic;
        final String id = material.id;
        final bool selected = _selectedIds.contains(id);

        return strategy.build(
          context: context,
          material: material,
          isSelectionMode: _selectionMode,
          isSelected: selected,
          onSelect: () => _toggleSelection(id),
          onEdit: () => _onEdit(material),
          onDelete: () => _onDelete(material),
          onCopy: () => _onCopy(material),
          onRemark: () => _onRemark(material),
        );
      },
    );
  }

  // -----------------------
  // DELEGATED ACTION HOOKS
  // -----------------------

  void _onEdit(dynamic material) {
    // delegate to feature screen
  }

  void _onDelete(dynamic material) {
    // delegate to service
  }

  void _onCopy(dynamic material) {
    // delegate to service
  }

  void _onRemark(dynamic material) {
    // delegate to dialog
  }
}
