import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../../../site_Details/repository/siteModel.dart';
import '../providers/dpr_setup_providers.dart';
import '../widgets/assembly_card_widget.dart';

class DPRSetupListScreen extends ConsumerWidget {
  final SiteModel site;
  const DPRSetupListScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(assemblyCardsProvider(site.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: "DPR Setup",
        subtitle: Text(site.siteName),
        actions: [
          PremiumActionIcon(
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(assemblyCardsProvider(site.id).notifier).loadCards(),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: cards.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return AssemblyCardWidget(
                  card: card,
                  onTap: () {
                    context.push('/create-assembly-card', extra: {'site': site, 'card': card});
                  },
                  onDelete: () {
                    _showDeleteDialog(context, ref, card.isarId, site.id);
                  },
                  onUpdate: (mark, qty) {
                    card.assemblyMark = mark;
                    card.quantity = qty;
                    card.totalNetWeight = (card.netWeightPerUnit ?? 0) * qty;
                    card.availableQty = qty - card.usedQty;
                    card.remainingQty = qty - card.usedQty;
                    ref.read(assemblyCardsProvider(site.id).notifier).updateCard(card);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-assembly-card', extra: {'site': site}),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Create Card"),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.architecture_outlined, size: 64, color: cs.onSurfaceVariant.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            "No Assembly Cards yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Create assembly cards from your BOQ items to track daily progress efficiently.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, int cardId, String siteId) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Card"),
        content: const Text("Are you sure you want to delete this assembly card? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              ref.read(assemblyCardsProvider(siteId).notifier).deleteCard(cardId);
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
