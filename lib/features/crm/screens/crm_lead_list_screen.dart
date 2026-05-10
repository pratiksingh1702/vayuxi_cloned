import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../providers/crm_provider.dart';
import '../models/crm_model.dart';

class CrmLeadListScreen extends ConsumerStatefulWidget {
  const CrmLeadListScreen({super.key});

  @override
  ConsumerState<CrmLeadListScreen> createState() => _CrmLeadListScreenState();
}

class _CrmLeadListScreenState extends ConsumerState<CrmLeadListScreen> {
  String _searchQuery = '';
  LeadStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crmProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final filteredLeads = state.leads.where((lead) {
      final matchesSearch = lead.customerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          lead.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == null || lead.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'CRM Leads',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(crmProvider.notifier).fetchLeads(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(Routes.crmSetup), // Placeholder for create
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Lead'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildStatusFilters()),
          if (state.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredLeads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _LeadCard(lead: filteredLeads[index]);
                  },
                  childCount: filteredLeads.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search leads...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: _selectedStatus == null,
              onSelected: (selected) => setState(() => _selectedStatus = null),
            ),
          ),
          ...LeadStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(status.displayName),
                selected: _selectedStatus == status,
                onSelected: (selected) =>
                    setState(() => _selectedStatus = selected ? status : null),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No leads found',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final CrmLead lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () =>
            context.push('${Routes.crmSetup}/${lead.id}'), // Detail placeholder
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lead.customerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusBadge(status: lead.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lead.companyName,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _InfoItem(
                      icon: Icons.business_center_rounded,
                      label: lead.projectType),
                  const SizedBox(width: 16),
                  _InfoItem(icon: Icons.phone_rounded, label: lead.phoneNumber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case LeadStatus.newLead:
        color = Colors.blue;
        break;
      case LeadStatus.contacted:
        color = Colors.orange;
        break;
      case LeadStatus.interested:
        color = Colors.purple;
        break;
      case LeadStatus.quotationSent:
        color = Colors.teal;
        break;
      case LeadStatus.converted:
        color = Colors.green;
        break;
      case LeadStatus.lost:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.displayName,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
