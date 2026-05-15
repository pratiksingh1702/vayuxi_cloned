import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/requestQueue.dart';
import '../../../../../core/api/requestQueueModel.dart';
import '../../../../../core/api/sync_job.dart';
import '../../application/providers/notification_list_notifier.dart';
import '../../application/providers/notification_providers.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_priority.dart';
import '../../data/models/notification_type.dart';
import '../../domain/services/notification_ingestion_service.dart';
import '../navigation/updates_routes.dart';
import '../widgets/notification_tile.dart';

enum NotificationCategory { overview, api, drafts }

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  NotificationCategory _currentCategory = NotificationCategory.overview;
  String _searchQuery = "";
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  List<NotificationModel> _getFilteredNotifications(List<NotificationModel> all) {
    var filtered = all;

    if (_currentCategory == NotificationCategory.api) {
      filtered = filtered.where((n) => n.metadata['source'] == 'sync_queue').toList();
    } else if (_currentCategory == NotificationCategory.drafts) {
      filtered = filtered.where((n) {
        final src = n.metadata['source'];
        return src == 'dpr_upload' || src == 'dpr_insu_upload';
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(query) ||
               n.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (s) {
            if (_currentCategory == NotificationCategory.overview) {
              return _buildDashboard(context, s.notifications);
            }
            
            final filtered = _getFilteredNotifications(s.notifications);
            return _buildDetailList(context, filtered);
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<NotificationModel> notifications) {
    final theme = Theme.of(context);
    
    // API Sync Category
    final syncJobs = ref.watch(syncJobsProvider);
    final runningSyncs = syncJobs.where((j) => j.status == SyncJobStatus.running).length;
    final queuedSyncs = RequestQueue.count;
    
    // Drafts Category
    final draftNotifications = notifications.where((n) {
      final src = n.metadata['source'];
      return src == 'dpr_upload' || src == 'dpr_insu_upload';
    }).toList();

    final hasGeneralNotifications = notifications.any((n) => !_isCategoryItem(n));
    final isEmpty = !hasGeneralNotifications && draftNotifications.isEmpty && runningSyncs == 0 && queuedSyncs == 0;

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No pending drafts or sync tasks.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Actions Row at Top Right
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded, color: Colors.black54),
                  tooltip: 'Management Options',
                  onPressed: _showSettingsSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black54),
                  tooltip: 'Notification Settings',
                  onPressed: () => UpdatesRoutes.goSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 1. Hero Card (Commented out as requested)
          // _buildHeroCard(context, runningSyncs, queuedSyncs),
          
          // const SizedBox(height: 32),

          // 2. Summary Tiles (Services)
          // Network Sync Pending (Commented out as requested)
          // _buildMinimalSummaryTile(...)

          if (draftNotifications.isNotEmpty) ...[
            _buildMinimalSummaryTile(
              context,
              icon: Icons.bookmark_added_rounded,
              iconBg: const Color(0xFFE0E7FF),
              iconColor: const Color(0xFF6366F1),
              title: "Saved Drafts",
              subtitle: "${draftNotifications.length} items ready for final review",
              onTap: () => setState(() => _currentCategory = NotificationCategory.drafts),
            ),
            const SizedBox(height: 12),
          ],

          // General Notifications Header
          if (hasGeneralNotifications || queuedSyncs > 0 || runningSyncs > 0) ...[
            const SizedBox(height: 24),
            Text(
              "Activity",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            
            // Dynamic Status Tile (Only show if active)
            if (runningSyncs > 0)
              _buildStatusTile(
                context,
                icon: Icons.sync_rounded,
                iconBg: Colors.amber.shade100,
                iconColor: Colors.amber.shade800,
                text: "Your data is resyncing...",
                textColor: Colors.amber.shade900,
              )
            else if (queuedSyncs > 0)
              _buildStatusTile(
                context,
                icon: Icons.cloud_off_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
                text: "Internet not available. Data saved safely. Auto upload will start when the network returns.",
                textColor: Colors.red.shade600,
              ),

            const SizedBox(height: 8),

            ...notifications
                .where((n) => !_isCategoryItem(n))
                .map((n) => NotificationTile(notification: n)),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCategoryItem(NotificationModel n) {
    final src = n.metadata['source'];
    return src == 'sync_queue' || src == 'dpr_upload' || src == 'dpr_insu_upload';
  }

  Widget _buildHeroCard(BuildContext context, int running, int queued) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Darker Navy/Slate for premium feel
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(28),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notification Center",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Everything to update you in better way.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.hub_rounded, // Sync/Command center icon
              size: 120,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalSummaryTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero, // Sharper corners as requested
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // Light grey background
          borderRadius: BorderRadius.zero, // Sharp corners
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailList(BuildContext context, List<NotificationModel> filtered) {
    if (filtered.isEmpty) return const _EmptyState();

    return Column(
      children: [
        const SizedBox(height: 10),
        // Integrated Search for Details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.black.withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => NotificationTile(notification: filtered[index]),
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                _injectPreviewData();
                Navigator.pop(context);
              },
              leading: const Icon(Icons.bug_report_rounded, color: Color(0xFF6366F1)),
              title: const Text("Inject Preview Data", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              onTap: () {
                ref.read(notificationListProvider.notifier).clearAllNotifications();
                Navigator.pop(context);
              },
              leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              title: const Text("Clear Notifications", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              onTap: () {
                RequestQueue.clearAll();
                ref.read(syncJobsProvider.notifier).allDone();
                Navigator.pop(context);
              },
              leading: const Icon(Icons.cloud_off_rounded, color: Colors.orange),
              title: const Text("Purge API Queue", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _injectPreviewData() async {
    final repo = ref.read(notificationRepositoryProvider);
    final now = DateTime.now();

    // 1. Inject General Activity Notifications
    final generalItems = [
      ("Security Alert", "New login detected from Site ID: 402"),
      ("Team Update", "Manager shared a new resource link"),
      ("Maintenance", "Server will be down for 2 mins at midnight"),
      ("Broadcast", "Monthly performance reports are now available"),
      ("Alert", "Critical equipment failure reported at block B"),
    ];

    for (var item in generalItems) {
      await repo.addNotification(NotificationModel(
        id: "gen_${now.millisecondsSinceEpoch}_${item.$1.hashCode}",
        title: item.$1,
        description: item.$2,
        timestamp: now,
        priority: NotificationPriority.medium,
        type: NotificationType.update,
        metadata: {"source": "general"},
      ));
    }

    // 2. Inject Network Sync Items
    for (int i = 1; i <= 3; i++) {
      final dummyReq = QueuedRequest(
        method: "POST",
        path: "/api/sync/test_$i",
        data: {"batch": i},
      );
      await RequestQueue.add(dummyReq);
      await NotificationIngestionService.persistQueuedRequest(dummyReq);
      ref.read(syncJobsProvider.notifier).addQueued(dummyReq.id, "Sync Batch #$i Data");
    }

    // 3. Inject Saved Drafts
    final draftTitles = ["Site Log #203", "Safety Audit - South", "Material Req #88"];
    for (var title in draftTitles) {
      await repo.addNotification(NotificationModel(
        id: "draft_${now.millisecondsSinceEpoch}_${title.hashCode}",
        title: title,
        description: "Unsaved local progress detected. Review to finalize.",
        timestamp: now,
        priority: NotificationPriority.high,
        type: NotificationType.update,
        metadata: {"source": "dpr_upload", "draft_id": "draft_${title.hashCode}"},
      ));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 52,
                color: const Color(0xFF6366F1).withOpacity(0.2)),
            const SizedBox(height: 24),
            const Text('No activity recorded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('Your updates will appear here.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.3),
                )),
          ],
        ),
      );
}
