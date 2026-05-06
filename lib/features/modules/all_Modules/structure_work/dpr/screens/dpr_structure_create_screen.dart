import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/app_toasts.dart';
import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr_setup/widgets/assembly_card_widget.dart';
import '../../dpr_setup/isar/assembly_card_isar.dart';
import '../providers/dpr_entry_provider.dart';
import '../providers/dpr_structure_provider.dart';
import '../models/dpr_structure_model.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/saved_boq_provider.dart';
import '../../dpr_setup/providers/dpr_setup_providers.dart';
import '../../boq/providers/boq_structure_provider.dart';

class DprStructureCreateScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final VoidCallback? onSuccess;
  final DPRStructure? initialDpr;

  const DprStructureCreateScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.onSuccess,
    this.initialDpr,
  });

  @override
  ConsumerState<DprStructureCreateScreen> createState() =>
      _DprStructureCreateScreenState();
}

enum StructureModuleSortOption {
  nameAsc,
  nameDesc,
  markAsc,
  markDesc,
  weightAsc,
  weightDesc,
  createdAtAsc,
  createdAtDesc
}

class _DprStructureCreateScreenState
    extends ConsumerState<DprStructureCreateScreen> {
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final TextEditingController _workNameController =
      TextEditingController(text: 'Structure Work');
  List<DPRStructure> _existingDprs = [];
  bool _isLoadingDprs = false;
  String? _selectedDprId;
  String? _selectedBoqId;
  DPRStructure? _latestDpr;
  List<AssemblyCardIsar>? _localSetupCards;
  bool _editMode = false;
  
  // New controllers for UI consistency with Insulation DPR
  late final TextEditingController _plantController;
  late final TextEditingController _floorController;
  late final TextEditingController _sizeController;
  late final TextEditingController _mocController;
  late final TextEditingController _boqNameController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Filter and Sort state
  StructureModuleSortOption _currentSort = StructureModuleSortOption.createdAtDesc;
  Set<String> _filterCategories = {}; // e.g. "Setup", "New", "Existing"
  Set<String> _filterStatuses = {};   // e.g. "Draft", "Submitted"
  
  bool get hasActiveFilters => _filterCategories.isNotEmpty || _filterStatuses.isNotEmpty || _currentSort != StructureModuleSortOption.createdAtDesc;
  String _selectedUnit = 'mm';

  String? get selectedDprId => _selectedDprId;
  bool get _isUpdate => _selectedDprId != null;

  @override
  void initState() {
    super.initState();

    if (widget.initialDpr != null) {
      _selectedDate = widget.initialDpr!.date ?? _selectedDate;
      _workNameController.text = widget.initialDpr!.dprName;
      _selectedDprId = widget.initialDpr!.id;
      _latestDpr = widget.initialDpr;
      _selectedBoqId = widget.initialDpr!.boqId;
    }

    _plantController = TextEditingController();
    _floorController = TextEditingController();
    _sizeController = TextEditingController();
    _mocController = TextEditingController();
    _boqNameController = TextEditingController(text: 'Select BOQ');
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dprEntryProvider.notifier).initialize(widget.siteId);
      ref.read(savedBOQProvider.notifier).fetchAndSync(widget.siteId).then((_) {
        final boqs = ref.read(savedBOQProvider).boqs;
        if (widget.initialDpr != null) {
          setState(() => _selectedBoqId = widget.initialDpr!.boqId);
        } else if (boqs.length == 1) {
          setState(() {
            _selectedBoqId = boqs.first.id;
          });
        }
      });
      _fetchDprsForDate(_selectedDate, preserveInitial: widget.initialDpr != null);
    });
  }

  Future<void> _fetchDprsForDate(DateTime date, {bool preserveInitial = false}) async {
    setState(() => _isLoadingDprs = true);
    try {
      final dprs = await ref.read(dprStructureProvider.notifier).fetchDPRsForDate(widget.siteId, date);
      setState(() {
        _existingDprs = dprs;
        _isLoadingDprs = false;
        
        // Auto-load latest if available and not currently in manual edit mode
        if (dprs.isNotEmpty && !preserveInitial && _selectedDprId == null) {
          // Sort by updatedAt descending, then createdAt descending
          final sortedDprs = List<DPRStructure>.from(dprs)
            ..sort((a, b) {
              final aTime = a.updatedAt ?? a.createdAt ?? DateTime(2000);
              final bTime = b.updatedAt ?? b.createdAt ?? DateTime(2000);
              return bTime.compareTo(aTime);
            });
          
          final latest = sortedDprs.first;
          _selectedDprId = latest.id;
          _latestDpr = latest;
          _populateFromDpr(latest);
        } else if (dprs.isEmpty && !preserveInitial) {
          _resetForFreshEntry();
        }
      });
    } catch (e) {
      setState(() => _isLoadingDprs = false);
      debugPrint('Error fetching DPRs: $e');
    }
  }

  void _populateFromDpr(DPRStructure dpr) {
    _workNameController.text = dpr.dprName;
    _plantController.text = dpr.plant ?? '';
    _floorController.text = dpr.location ?? '';
    _mocController.text = dpr.moc ?? '';
    _sizeController.text = dpr.size?.toString() ?? '';
    _selectedUnit = dpr.unit ?? 'mm';
    _selectedBoqId = dpr.boqId;
    _boqNameController.text = dpr.boqName ?? 'Select BOQ';
    
    // Clear active cards to show existing items from _latestDpr
    ref.read(dprEntryProvider.notifier).clearCards();
  }

  void _resetForFreshEntry() {
    setState(() {
      _selectedDprId = null;
      _latestDpr = null;
      _workNameController.text = 'Structure Work';
      _plantController.clear();
      _floorController.clear();
      _mocController.clear();
      _sizeController.clear();
      _boqNameController.text = 'Select BOQ';
      _selectedBoqId = null;
      
      // Clear active cards for fresh entry
      ref.read(dprEntryProvider.notifier).clearCards();
    });
  }

  @override
  void dispose() {
    _workNameController.dispose();
    _plantController.dispose();
    _floorController.dispose();
    _sizeController.dispose();
    _mocController.dispose();
    _boqNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final structureState = ref.watch(dprStructureProvider);
    final entryState = ref.watch(dprEntryProvider);
    final boqState = ref.watch(savedBOQProvider);
    final setupCards = ref.watch(assemblyCardsProvider(widget.siteId));
    final boqStructureState = ref.watch(boqStructureProvider);

    // Initialize local setup cards from provider (Setup -> Entry reflection)
    // ENFORCE SINGLE CARD: Only take the first one if it exists
    if (_localSetupCards == null && setupCards.isNotEmpty) {
      _localSetupCards = [_cloneCard(setupCards.first)];
    }

    // Sync controller with state if it's empty
    if (_workNameController.text.isEmpty &&
        entryState.selectedWorkName != null) {
      _workNameController.text = entryState.selectedWorkName!;
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: cs.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton.extended(
          onPressed: _resetForFreshEntry,
          label: const Text(
            'New Entry',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          icon: const Icon(Icons.add_rounded, size: 24),
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          elevation: 4,
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          final title = widget.siteName.isNotEmpty
              ? widget.siteName
              : 'Structure DPR Entry';
          return [
            CustomSliverAppBar(title: title),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: structureState.isSaving ? 'Submitting...' : 'Submit DPR Entry',
                isLoading: structureState.isSaving,
                color: (entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true))
                    ? cs.surfaceContainerHighest
                    : cs.primary,
                textColor: (entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true))
                    ? cs.onSurfaceVariant
                    : cs.onPrimary,
                onPressed: ((entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true)) || structureState.isSaving) ? () {} : _submitDPR,
                isOutlined: false,
              ),
            ),
          ],
          child: Column(
            children: [
              if (entryState.isLoading || _isLoadingDprs)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Site Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.siteName.isNotEmpty ? widget.siteName : "DPR Entry",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Structure Module",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDateSection(cs),
                      const SizedBox(height: 16),
                      _buildDprInfoCard(cs, entryState, boqState),
                      const SizedBox(height: 16),
                      _buildSearchAndFilterRow(cs),
                      _buildCardList(cs, entryState, boqState),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Report',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDprInfoCard(ColorScheme cs, DprEntryState state, SavedBOQState boqState) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildDprNameSection(cs),
            const SizedBox(height: 16),
            _buildInputFields(cs, boqState),
          ],
        ),
      ),
    );
  }

  Widget _buildDprNameSection(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _editMode
              ? TextField(
                  controller: _workNameController,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  onChanged: (val) {
                    ref.read(dprEntryProvider.notifier).setWorkName(val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Enter DPR Name',
                    prefixIcon: Icon(Icons.edit_document, size: 20, color: cs.primary),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _workNameController.text,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_existingDprs.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: cs.primary),
                          onPressed: () => _showDprSelector(context),
                          tooltip: 'Select Existing DPR',
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () {
              if (_editMode && _workNameController.text.trim().isEmpty) {
                AppToast.error('Please enter DPR name');
                return;
              }
              setState(() => _editMode = !_editMode);
            },
            icon: Icon(
              _editMode ? Icons.check_circle : Icons.edit_rounded,
              color: _editMode ? cs.tertiary : cs.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields(ColorScheme cs, SavedBOQState boqState) {
    if (_selectedBoqId != null && _boqNameController.text == 'Select BOQ') {
      final boq = boqState.boqs.firstWhere((b) => b.id == _selectedBoqId, orElse: () => boqState.boqs.first);
      _boqNameController.text = boq.boqName;
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildCompactInputField(
                'Plant',
                _plantController,
                Icons.factory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInputField(
                'Location',
                _floorController,
                Icons.location_on,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInputField(
                'BOQ',
                _boqNameController,
                Icons.folder_zip_rounded,
                readOnly: true,
                onTap: () => _showBoqSelector(context, boqState.boqs),
                suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInputField(
                'MOC',
                _mocController,
                Icons.category_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(minWidth: 5, minHeight: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildSearchAndFilterRow(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search assembly item...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: cs.primary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          cs: cs,
          icon: Icons.add,
          onPressed: () {
            ref.read(dprEntryProvider.notifier).addEmptyCard(widget.siteId);
          },
          tooltip: 'Add Entry',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          cs: cs,
          icon: Icons.tune_rounded,
          onPressed: _showFilterSortBottomSheet,
          tooltip: 'Filter & Sort',
          isActive: hasActiveFilters,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required ColorScheme cs,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? cs.primary : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? cs.primary : cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? cs.onPrimary : cs.primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final cs = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _currentSort = StructureModuleSortOption.createdAtDesc;
                          _filterCategories = {};
                          _filterStatuses = {};
                        });
                        setState(() {});
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildFilterLabel(cs, 'Sort By'),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      cs: cs,
                      label: 'Name (A-Z)',
                      selected: _currentSort == StructureModuleSortOption.nameAsc,
                      onSelected: (val) {
                        setSheetState(() => _currentSort = StructureModuleSortOption.nameAsc);
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'Name (Z-A)',
                      selected: _currentSort == StructureModuleSortOption.nameDesc,
                      onSelected: (val) {
                        setSheetState(() => _currentSort = StructureModuleSortOption.nameDesc);
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'Mark (A-Z)',
                      selected: _currentSort == StructureModuleSortOption.markAsc,
                      onSelected: (val) {
                        setSheetState(() => _currentSort = StructureModuleSortOption.markAsc);
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'Weight',
                      selected: _currentSort == StructureModuleSortOption.weightDesc,
                      onSelected: (val) {
                        setSheetState(() => _currentSort = StructureModuleSortOption.weightDesc);
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'Latest',
                      selected: _currentSort == StructureModuleSortOption.createdAtDesc,
                      onSelected: (val) {
                        setSheetState(() => _currentSort = StructureModuleSortOption.createdAtDesc);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFilterLabel(cs, 'Item Category'),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      cs: cs,
                      label: 'Setup Cards',
                      selected: _filterCategories.contains('Setup'),
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) _filterCategories.add('Setup');
                          else _filterCategories.remove('Setup');
                        });
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'New Entries',
                      selected: _filterCategories.contains('New'),
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) _filterCategories.add('New');
                          else _filterCategories.remove('New');
                        });
                        setState(() {});
                      },
                    ),
                    _buildFilterChip(
                      cs: cs,
                      label: 'Existing Items',
                      selected: _filterCategories.contains('Existing'),
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) _filterCategories.add('Existing');
                          else _filterCategories.remove('Existing');
                        });
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterLabel(ColorScheme cs, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildFilterChip({
    required ColorScheme cs,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: cs.surface,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? cs.primary : cs.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }


  void _showBoqSelector(BuildContext context, List<BOQStructure> boqs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Select BOQ File',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: boqs.length,
                itemBuilder: (context, index) {
                  final boq = boqs[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_open_rounded),
                    title: Text(boq.boqName),
                    subtitle: Text(boq.boqNumber),
                    onTap: () {
                      _validateAndSelectBoq(boq);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _validateAndSelectBoq(BOQStructure boq) async {
    final entryState = ref.read(dprEntryProvider);
    final unmatchedItems = <String>[];

    for (final card in entryState.activeCards) {
      final exists = boq.items.any((item) =>
          item.assemblyMark == card.assemblyMark ||
          item.id == card.boqItemId);
      if (!exists && card.assemblyMark.isNotEmpty) {
        unmatchedItems.add(card.assemblyMark);
      }
    }

    if (unmatchedItems.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unmatched Items'),
          content: Text(
            'The following items are not found in the selected BOQ (${boq.boqName}):\n\n'
            '${unmatchedItems.join(", ")}\n\n'
            'Do you still want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() {
      _selectedBoqId = boq.id;
      _boqNameController.text = boq.boqName;
    });
  }

  void _showDprSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Existing DPRs for this date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _existingDprs.length,
                itemBuilder: (context, index) {
                  final dpr = _existingDprs[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(dpr.dprName),
                    subtitle: Text(dpr.dprNumber),
                    trailing: Text(dpr.status,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() {
                        _selectedDprId = dpr.id;
                        _latestDpr = dpr;
                        _populateFromDpr(dpr);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildCardList(ColorScheme cs, DprEntryState state, SavedBOQState boqState) {
    final displaySetupCards = _localSetupCards ?? [];
    final boqStructureState = ref.watch(boqStructureProvider);
    final existingItems = _latestDpr?.items ?? [];
    
    // 1. Search Filter
    List<AssemblyCardIsar> filteredSetup = displaySetupCards.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.assemblyMark.toLowerCase().contains(_searchQuery) ||
             c.description.toLowerCase().contains(_searchQuery);
    }).toList();

    List<AssemblyCardIsar> filteredActive = state.activeCards.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.assemblyMark.toLowerCase().contains(_searchQuery) ||
             c.description.toLowerCase().contains(_searchQuery);
    }).toList();

    List<DPRStructureItem> filteredExisting = existingItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.assemblyMark.toLowerCase().contains(_searchQuery);
    }).toList();

    // 2. Category Filter
    if (_filterCategories.isNotEmpty) {
      if (!_filterCategories.contains('Setup')) filteredSetup = [];
      if (!_filterCategories.contains('New')) filteredActive = [];
      if (!_filterCategories.contains('Existing')) filteredExisting = [];
    }

    final totalItemsCount = filteredSetup.length + filteredActive.length + filteredExisting.length;

    // 3. Sorting
    void sortIsar(List<AssemblyCardIsar> list) {
      list.sort((a, b) {
        switch (_currentSort) {
          case StructureModuleSortOption.nameAsc:
            return a.description.toLowerCase().compareTo(b.description.toLowerCase());
          case StructureModuleSortOption.nameDesc:
            return b.description.toLowerCase().compareTo(a.description.toLowerCase());
          case StructureModuleSortOption.markAsc:
            return a.assemblyMark.toLowerCase().compareTo(b.assemblyMark.toLowerCase());
          case StructureModuleSortOption.markDesc:
            return b.assemblyMark.toLowerCase().compareTo(a.assemblyMark.toLowerCase());
          case StructureModuleSortOption.weightDesc:
            return (b.totalNetWeight ?? 0).compareTo(a.totalNetWeight ?? 0);
          case StructureModuleSortOption.createdAtDesc:
            return b.createdAt.compareTo(a.createdAt);
          case StructureModuleSortOption.createdAtAsc:
            return a.createdAt.compareTo(b.createdAt);
          default:
            return 0;
        }
      });
    }

    sortIsar(filteredSetup);
    sortIsar(filteredActive);
    
    filteredExisting.sort((a, b) {
       switch (_currentSort) {
          case StructureModuleSortOption.markAsc:
            return a.assemblyMark.toLowerCase().compareTo(b.assemblyMark.toLowerCase());
          case StructureModuleSortOption.markDesc:
            return b.assemblyMark.toLowerCase().compareTo(a.assemblyMark.toLowerCase());
          case StructureModuleSortOption.weightDesc:
            return (b.totalNetWeight ?? 0).compareTo(a.totalNetWeight ?? 0);
          default:
            return 0;
        }
    });

    if (totalItemsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: cs.onSurfaceVariant.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(_searchQuery.isEmpty && !hasActiveFilters ? "No entries added yet" : "No matches found",
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      itemCount: totalItemsCount,
      itemBuilder: (context, index) {
        // 1. LOCAL SETUP CARDS
        if (index < filteredSetup.length) {
          final card = filteredSetup[index];
          return AssemblyCardWidget(
            card: card,
            onUpdate: (mark, qty) {
              setState(() {
                _syncCardWithBOQ(card, mark, qty, boqStructureState);
              });
            },
            onDelete: () {
               setState(() {
                 _localSetupCards?.remove(card);
               });
            },
            onCopy: () {
              setState(() {
                _localSetupCards?.add(_cloneCard(card));
              });
            },
            onRemark: () => _showRemarksDialog(card),
          );
        }

        // 2. ACTIVE (NEW) CARDS
        final int activeIndex = index - filteredSetup.length;
        if (activeIndex < filteredActive.length) {
          final card = filteredActive[activeIndex];
          return AssemblyCardWidget(
            card: card,
            onUpdate: (mark, qty) {
              setState(() {
                _syncCardWithBOQ(card, mark, qty, boqStructureState);
              });
              final originalIndex = state.activeCards.indexOf(card);
              ref.read(dprEntryProvider.notifier).updateCard(originalIndex, mark, qty);
            },
            onDelete: () {
              final originalIndex = state.activeCards.indexOf(card);
              ref.read(dprEntryProvider.notifier).removeCard(originalIndex);
            },
            onCopy: () {
              ref.read(dprEntryProvider.notifier).addCard(_cloneCard(card));
            },
            onRemark: () => _showRemarksDialog(card),
          );
        } else {
          // 3. EXISTING ITEMS
          final existingItemIndex = index - filteredSetup.length - filteredActive.length;
          final item = filteredExisting[existingItemIndex];
          
          // Look up description from BOQ provider
          String lookedUpDesc = '';
          for (var b in boqState.boqs) {
            final found = b.items.where((i) => i.assemblyMark == item.assemblyMark);
            if (found.isNotEmpty) {
              lookedUpDesc = found.first.typeDescription;
              break;
            }
          }

          final AssemblyCardIsar card = AssemblyCardIsar()
            ..siteId = widget.siteId
            ..boqItemId = item.boqItemId ?? ''
            ..boqId = '' // Default
            ..assemblyMark = item.assemblyMark
            ..description = lookedUpDesc
            ..quantity = item.qtyUsed
            ..availableQty = item.availableQty ?? 0
            ..usedQty = 0
            ..remainingQty = item.remainingQty ?? 0
            ..progressPercentage = 0
            ..createdAt = DateTime.now()
            ..isSynced = true
            ..netWeightPerUnit = item.netWeightPerUnit
            ..totalNetWeight = item.totalNetWeight;

          return AssemblyCardWidget(
            card: card,
            readOnly: false,
            allowMarkEdit: false,
            allowQtyEdit: true,
            onUpdate: (mark, qty) async {
              if (_latestDpr == null) return;
              
              final updatedItems = _latestDpr!.items.map((i) {
                if (i.assemblyMark == mark) {
                  return {
                    'assemblyMark': mark,
                    'qtyUsed': qty,
                    'boqItemId': i.boqItemId,
                  };
                }
                return {
                  'assemblyMark': i.assemblyMark,
                  'qtyUsed': i.qtyUsed,
                  'boqItemId': i.boqItemId,
                };
              }).toList();

              final success = await ref.read(dprStructureProvider.notifier).updateDPR(
                widget.siteId,
                _latestDpr!.id,
                items: updatedItems,
                replaceMode: true,
              );

              if (success) {
                _fetchDprsForDate(_selectedDate);
              }
            },
            onDelete: () async {},
            onCopy: () {
              ref.read(dprEntryProvider.notifier).addCard(_cloneCard(card));
            },
            onRemark: () => _showRemarksDialog(card),
          );
        }
      },
    );
  }

  Future<void> _submitDPR() async {
    final entryState = ref.read(dprEntryProvider);
    final setupCards = _localSetupCards ?? [];
    final boqState = ref.read(savedBOQProvider);

    // Collect all items to submit (Setup cards + Active cards)
    final List<AssemblyCardIsar> allCards = [...setupCards, ...entryState.activeCards];

    if (allCards.isEmpty) return;

    final invalidMarks = allCards
        .where((c) => c.assemblyMark.trim().isEmpty)
        .toList();
    if (invalidMarks.isNotEmpty) {
      AppToast.error('Please enter an assembly mark for all entries.');
      return;
    }

    final boqId =
        _selectedBoqId ?? _resolveBoqId(allCards, boqState.boqs);
    if (boqId == null) {
      AppToast.error('Please select a BOQ file for this DPR.');
      return;
    }

    final selectedBoq =
        boqState.boqs.where((b) => b.id == boqId).firstOrNull;

    final items = allCards.map((c) {
      String? itemId = c.boqItemId;
      
      // Auto-resolve itemId if missing using the selected BOQ
      if ((itemId == null || itemId.isEmpty) && selectedBoq != null) {
        final matchedItem = selectedBoq.items
            .where((item) => item.assemblyMark == c.assemblyMark)
            .firstOrNull;
        itemId = matchedItem?.id;
      }

      return {
        'assemblyMark': c.assemblyMark,
        'qtyUsed': c.quantity,
        'boqItemId': itemId ?? "",
      };
    }).toList();

    // Final validation: ensure no boqItemId is empty
    if (items.any((item) => (item['boqItemId'] as String).isEmpty)) {
      AppToast.error('Some items could not be matched with the selected BOQ.');
      return;
    }
    final dprName = _workNameController.text.trim();
    final plant = _plantController.text.trim();
    final location = _floorController.text.trim();
    final moc = _mocController.text.trim();
    final size = double.tryParse(_sizeController.text);
    
    final bool success;
    if (_isUpdate) {
      success = await ref.read(dprStructureProvider.notifier).updateDPR(
            widget.siteId,
            _selectedDprId!,
            items: items,
            remarks: dprName.isNotEmpty ? dprName : null,
            plant: plant.isNotEmpty ? plant : null,
            location: location.isNotEmpty ? location : null,
            moc: moc.isNotEmpty ? moc : null,
            size: size,
            unit: _selectedUnit,
          );
    } else {
      success = await ref.read(dprStructureProvider.notifier).createDPR(
            widget.siteId,
            boqId: boqId,
            items: items,
            dprName: dprName.isNotEmpty ? dprName : null,
            date: _selectedDate,
            remarks: dprName.isNotEmpty ? dprName : null,
            plant: plant.isNotEmpty ? plant : null,
            location: location.isNotEmpty ? location : null,
            moc: moc.isNotEmpty ? moc : null,
            size: size,
            unit: _selectedUnit,
          );
    }

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      AppToast.success(_isUpdate ? "DPR Updated Successfully!" : "DPR Submitted Successfully!");
      widget.onSuccess?.call();
      context.pop();
    } else if (mounted) {
      final error = ref.read(dprStructureProvider).error;
      if (error != null && error.isNotEmpty) {
        AppToast.error(error);
      }
    }
  }

  String? _resolveBoqId(List<AssemblyCardIsar> cards, List<BOQStructure> boqs) {
    String? foundBoqId;
    for (final card in cards) {
      final itemId = card.boqItemId.trim();
      if (itemId.isEmpty) {
        AppToast.error('Please select a valid BOQ mark for all entries.');
        return null;
      }
      String? parentId;
      for (final boq in boqs) {
        if (boq.items.any((i) => i.id == itemId)) {
          parentId = boq.id;
          break;
        }
      }

      if (parentId == null || parentId.isEmpty) {
        AppToast.error('BOQ item not found for mark ${card.assemblyMark}.');
        return null;
      }

      if (foundBoqId == null) {
        foundBoqId = parentId;
      } else if (foundBoqId != parentId) {
        AppToast.error('All entries must belong to the same BOQ.');
        return null;
      }
    }
    return foundBoqId;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDprId = null; // Clear selection on date change
      });
      _fetchDprsForDate(picked);
    }
  }

  void _syncCardWithBOQ(AssemblyCardIsar card, String mark, double qty, BOQStructureState boqState) {
    if (mark.isEmpty) {
      card.assemblyMark = "";
      card.description = "Description";
      card.quantity = qty;
      card.boqItemId = "";
      card.boqId = "";
      card.availableQty = 0;
      card.remainingQty = 0;
      card.netWeightPerUnit = 0;
      card.totalNetWeight = 0;
      card.length = null;
      card.width = null;
      card.height = null;
      card.progressPercentage = 0;
      return;
    }

    // Try to find matching BOQ item
    BOQStructureItem? matchedItem;
    String? matchedBoqId;

    for (var boq in boqState.boqs) {
      for (var item in boq.items) {
        if (item.assemblyMark.toLowerCase() == mark.toLowerCase()) {
          matchedItem = item;
          matchedBoqId = boq.id;
          break;
        }
      }
      if (matchedItem != null) break;
    }

    if (matchedItem != null) {
      // Sync details
      card.boqId = matchedBoqId ?? "";
      card.boqItemId = matchedItem.id;
      card.assemblyMark = matchedItem.assemblyMark;
      card.description = matchedItem.typeDescription;
      card.quantity = qty > 0 ? qty : matchedItem.quantity;
      card.netWeightPerUnit = matchedItem.netWeightPerUnit;
      card.totalNetWeight = (matchedItem.netWeightPerUnit ?? 0) * (qty > 0 ? qty : matchedItem.quantity);
      card.length = matchedItem.length;
      card.width = matchedItem.width;
      card.height = matchedItem.height;
      card.availableQty = qty > 0 ? qty : matchedItem.quantity;
      card.remainingQty = qty > 0 ? qty : matchedItem.quantity;
      card.usedQty = 0;
      card.progressPercentage = 0;
      card.isSynced = false;
    } else {
      // Manual entry mode: Just update Mark and Qty
      card.boqId = "";
      card.boqItemId = "";
      card.description = "Description";
      card.assemblyMark = mark;
      card.quantity = qty;
      card.availableQty = qty;
      card.remainingQty = qty;
      card.usedQty = 0;
      card.netWeightPerUnit = 0;
      card.totalNetWeight = 0;
    }
  }

  void _showRemarksDialog(AssemblyCardIsar card) {
    final remarksController = TextEditingController(text: card.remarks ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remarks for ${card.assemblyMark.isNotEmpty ? card.assemblyMark : "Item"}'),
        content: TextField(
          controller: remarksController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your remarks here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                card.remarks = remarksController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  AssemblyCardIsar _cloneCard(AssemblyCardIsar card) {
    final clone = AssemblyCardIsar();
    clone.isarId = card.isarId;
    clone.siteId = card.siteId;
    
    // Safely copy late fields with defaults
    try { clone.boqId = card.boqId; } catch (_) { clone.boqId = ""; }
    try { clone.boqItemId = card.boqItemId; } catch (_) { clone.boqItemId = ""; }
    try { clone.assemblyMark = card.assemblyMark; } catch (_) { clone.assemblyMark = ""; }
    try { clone.description = card.description; } catch (_) { clone.description = "Description"; }
    
    clone.quantity = card.quantity;
    clone.availableQty = card.availableQty;
    clone.usedQty = card.usedQty;
    clone.remainingQty = card.remainingQty;
    clone.length = card.length;
    clone.width = card.width;
    clone.height = card.height;
    clone.netWeightPerUnit = card.netWeightPerUnit;
    clone.totalNetWeight = card.totalNetWeight;
    clone.progressPercentage = card.progressPercentage;
    clone.createdAt = card.createdAt;
    clone.isSynced = card.isSynced;
    clone.remarks = card.remarks; // Copy remarks
    
    return clone;
  }
}
