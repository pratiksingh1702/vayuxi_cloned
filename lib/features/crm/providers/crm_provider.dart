import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_model.dart';

class CrmService {
  Future<List<CrmLead>> getLeads() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      CrmLead(
        id: 'L1',
        customerName: 'Rahul Sharma',
        companyName: 'Sharma Constructions',
        phoneNumber: '+91 9876543210',
        email: 'rahul@sharma.com',
        status: LeadStatus.newLead,
        projectType: 'Warehouse',
        address: 'Sector 62, Noida',
        notes: 'Interested in PEB for a new warehouse project.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CrmLead(
        id: 'L2',
        customerName: 'Amit Patel',
        companyName: 'Patel Logistics',
        phoneNumber: '+91 9123456789',
        email: 'amit@patel.com',
        status: LeadStatus.contacted,
        projectType: 'Factory Building',
        address: 'GIDC, Ahmedabad',
        notes: 'Requires a 50,000 sq ft factory building.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CrmLead(
        id: 'L3',
        customerName: 'Sneha Reddy',
        companyName: 'Reddy Infra',
        phoneNumber: '+91 9988776655',
        email: 'sneha@reddy.com',
        status: LeadStatus.interested,
        projectType: 'Cold Storage',
        address: 'Hitech City, Hyderabad',
        notes: 'Follow up on structural requirements.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<List<CrmActivity>> getActivities(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      CrmActivity(
        id: 'A1',
        leadId: leadId,
        type: ActivityType.call,
        status: ActivityStatus.completed,
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Initial call. Discussed project scope.',
        durationSeconds: 180,
      ),
      CrmActivity(
        id: 'A2',
        leadId: leadId,
        type: ActivityType.followUp,
        status: ActivityStatus.pending,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        notes: 'Send preliminary brochure.',
        durationSeconds: 0,
      ),
    ];
  }
}

final crmServiceProvider = Provider((ref) => CrmService());

class CrmState {
  final List<CrmLead> leads;
  final bool isLoading;
  final String? error;

  CrmState({
    this.leads = const [],
    this.isLoading = false,
    this.error,
  });

  CrmState copyWith({
    List<CrmLead>? leads,
    bool? isLoading,
    String? error,
  }) {
    return CrmState(
      leads: leads ?? this.leads,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CrmNotifier extends StateNotifier<CrmState> {
  final CrmService _service;
  CrmNotifier(this._service) : super(CrmState()) {
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final leads = await _service.getLeads();
      state = state.copyWith(leads: leads, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateLeadStatus(String leadId, LeadStatus newStatus) {
    state = state.copyWith(
      leads: state.leads.map((l) {
        if (l.id == leadId) {
          return l.copyWith(status: newStatus, updatedAt: DateTime.now());
        }
        return l;
      }).toList(),
    );
  }
}

final crmProvider = StateNotifierProvider<CrmNotifier, CrmState>((ref) {
  return CrmNotifier(ref.watch(crmServiceProvider));
});
