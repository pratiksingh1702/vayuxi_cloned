import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../../../site_Details/repository/siteModel.dart';
import '../providers/dpr_setup_providers.dart';
import '../widgets/assembly_card_widget.dart';
import '../isar/assembly_card_isar.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/boq_structure_provider.dart';

class DPRSetupListScreen extends ConsumerStatefulWidget {
  final SiteModel site;
  const DPRSetupListScreen({super.key, required this.site});

  @override
  ConsumerState<DPRSetupListScreen> createState() => _DPRSetupListScreenState();
}

class _DPRSetupListScreenState extends ConsumerState<DPRSetupListScreen> with SingleTickerProviderStateMixin {
  late AssemblyCardIsar _workingCard;
  bool _isFirstLoad = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _resetWorkingCard();
    // Ensure BOQs are loaded for syncing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqStructureProvider.notifier).fetchBOQs(widget.site.id);
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  void _resetWorkingCard() {
    _workingCard = AssemblyCardIsar()
      ..siteId = widget.site.id
      ..boqItemId = ""
      ..boqId = ""
      ..assemblyMark = ""
      ..description = "Description"
      ..quantity = 0
      ..availableQty = 0
      ..length = null
      ..width = null
      ..height = null
      ..netWeightPerUnit = 0
      ..totalNetWeight = 0
      ..usedQty = 0
      ..remainingQty = 0
      ..progressPercentage = 0
      ..createdAt = DateTime.now()
      ..isSynced = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(assemblyCardsProvider(widget.site.id));
    final boqState = ref.watch(boqStructureProvider);
    final cs = Theme.of(context).colorScheme;

    // AUTO-INITIALIZE or SYNC SETUP CARD
    if (_isFirstLoad) {
      if (cards.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resetWorkingCard();
          ref.read(assemblyCardsProvider(widget.site.id).notifier).addCard(_workingCard);
        });
      } else {
        _workingCard = cards.first;
      }
      _isFirstLoad = false;
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: "DPR Setup",
        subtitle: Text(widget.site.siteName),
        actions: [
          PremiumActionIcon(
            icon: Icons.refresh_rounded,
            onPressed: () {
              ref.read(assemblyCardsProvider(widget.site.id).notifier).loadCards();
              setState(() => _isFirstLoad = true);
            },
            tooltip: "Sync",
          ),
          PremiumActionIcon(
            icon: Icons.restart_alt_rounded,
            onPressed: _handleReset,
            tooltip: "Reset Fields",
            iconColor: cs.onSurfaceVariant,
          ),
          PremiumActionIcon(
            icon: Icons.delete_sweep_rounded,
            onPressed: () => _showDeleteDialog(context, ref, _workingCard.isarId, widget.site.id),
            tooltip: "Delete Card",
            iconColor: cs.error,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cs.primary,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.28),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(height: 40, text: 'Structure', icon: Icon(Icons.precision_manufacturing, size: 15)),
                    Tab(height: 40, text: 'Suggestion', icon: Icon(Icons.lightbulb_outline, size: 15)),
                  ],
                ),
              ),
            ),
            
            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Structure
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 16),
                          child: Text(
                            "Active Setup Card",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        AssemblyCardWidget(
                          card: _workingCard,
                          allowMarkEdit: true,
                          allowQtyEdit: true,
                          onUpdate: (mark, qty) {
                            _onCardUpdate(mark, qty, boqState);
                          },
                          onTap: () {
                             if (_workingCard.isarId != Isar.autoIncrement) {
                                context.push('/create-assembly-card', extra: {'site': widget.site, 'card': _workingCard});
                             }
                          },
                          onCopy: () {
                            final notifier = ref.read(assemblyCardsProvider(widget.site.id).notifier);
                            final clone = _cloneWorkingCard(_workingCard);
                            notifier.addCard(clone);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Card duplicated")),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Enter a Mark Number to automatically sync all details from the BOQ. This card will be used for your daily progress report.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab 2: Suggestion
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 64, color: cs.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "Suggested items here",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Coming soon in the future update.",
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardUpdate(String mark, double qty, BOQStructureState boqState) {
    final notifier = ref.read(assemblyCardsProvider(widget.site.id).notifier);

    if (mark.isEmpty) {
      setState(() {
        _workingCard.assemblyMark = "";
        _workingCard.description = "Description";
        _workingCard.quantity = qty;
        _workingCard.boqItemId = "";
        _workingCard.boqId = "";
        _workingCard.availableQty = 0;
        _workingCard.remainingQty = 0;
        _workingCard.netWeightPerUnit = 0;
        _workingCard.totalNetWeight = 0;
        _workingCard.length = null;
        _workingCard.width = null;
        _workingCard.height = null;
        _workingCard.progressPercentage = 0;
      });
      
      if (_workingCard.isarId == Isar.autoIncrement) {
        notifier.addCard(_workingCard);
      } else {
        notifier.updateCard(_workingCard);
      }
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
      setState(() {
        _workingCard.boqId = matchedBoqId ?? "";
        _workingCard.boqItemId = matchedItem!.id;
        _workingCard.assemblyMark = matchedItem!.assemblyMark;
        _workingCard.description = matchedItem!.typeDescription;
        _workingCard.quantity = qty > 0 ? qty : matchedItem!.quantity;
        _workingCard.netWeightPerUnit = matchedItem!.netWeightPerUnit;
        _workingCard.totalNetWeight = (matchedItem!.netWeightPerUnit ?? 0) * (qty > 0 ? qty : matchedItem!.quantity);
        _workingCard.length = matchedItem!.length;
        _workingCard.width = matchedItem!.width;
        _workingCard.height = matchedItem!.height;
        _workingCard.availableQty = qty > 0 ? qty : matchedItem!.quantity;
        _workingCard.remainingQty = qty > 0 ? qty : matchedItem!.quantity;
        _workingCard.usedQty = 0;
        _workingCard.progressPercentage = 0;
        _workingCard.isSynced = false;
      });

      // Save/Update in provider
      if (_workingCard.isarId == Isar.autoIncrement) {
        notifier.addCard(_workingCard);
      } else {
        notifier.updateCard(_workingCard);
      }
    } else {
      // Just update local state if no match found yet
      setState(() {
        _workingCard.assemblyMark = mark;
        _workingCard.quantity = qty;
      });
      
      // Still save the basic info (Mark and Qty)
      if (_workingCard.isarId == Isar.autoIncrement) {
        notifier.addCard(_workingCard);
      } else {
        notifier.updateCard(_workingCard);
      }
    }
  }

  AssemblyCardIsar _cloneWorkingCard(AssemblyCardIsar card) {
    final clone = AssemblyCardIsar()
      ..siteId = card.siteId
      ..boqItemId = card.boqItemId
      ..boqId = card.boqId
      ..assemblyMark = card.assemblyMark
      ..description = card.description
      ..quantity = card.quantity
      ..availableQty = card.availableQty
      ..length = card.length
      ..width = card.width
      ..height = card.height
      ..netWeightPerUnit = card.netWeightPerUnit
      ..totalNetWeight = card.totalNetWeight
      ..usedQty = card.usedQty
      ..remainingQty = card.remainingQty
      ..progressPercentage = card.progressPercentage
      ..createdAt = DateTime.now()
      ..isSynced = false;
    return clone;
  }

  void _handleReset() {
    setState(() {
      _resetWorkingCard();
    });
    // Save the reset state
    final notifier = ref.read(assemblyCardsProvider(widget.site.id).notifier);
    if (_workingCard.isarId != Isar.autoIncrement) {
      notifier.updateCard(_workingCard);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Card fields reset")),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, int cardId, String siteId) {
    if (cardId == Isar.autoIncrement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to delete")),
      );
      return;
    }
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Card"),
        content: const Text("Are you sure you want to delete this assembly card? This will remove it from the setup."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              ref.read(assemblyCardsProvider(siteId).notifier).deleteCard(cardId);
              setState(() {
                _resetWorkingCard();
                _isFirstLoad = true;
              });
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
