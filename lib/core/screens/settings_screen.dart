import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../router/routes.dart';
import '../utlis/widgets/premium_app_bar.dart';
import 'dpr_offline_dashboard_screen.dart';
import 'theme_switcher.dart';
import '../../../features/noti_system/noti_settings/notification_settings_screen.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../../../features/profile_page/provider/userProvider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Future<void> _confirmAndLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      ShowCaseWidget.of(context)?.dismiss();
    } catch (_) {}

    await ref.read(authProvider.notifier).logout();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    final userName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Team Member';
    final companyName = (user?.company?.name?.trim().isNotEmpty ?? false)
        ? user!.company!.name!.trim()
        : 'No company linked';
    final avatarUrl = user?.profilePhoto?.trim();

    final allItems = <_SettingsItem>[
      _SettingsItem(
        title: 'Notification Preferences',
        subtitle: 'Reminders, quiet hours and alert behavior.',
        icon: Icons.notifications_active_rounded,
        accent: const Color(0xFF2B5AA8),
        section: 'Alerts & Experience',
        type: _SettingsActionType.notifications,
      ),
      _SettingsItem(
        title: 'Theme & Appearance',
        subtitle: 'Colors, typography and UI comfort.',
        icon: Icons.auto_awesome_mosaic_rounded,
        accent: const Color(0xFF6A3FA2),
        section: 'Alerts & Experience',
        route: Routes.theme,
      ),
      _SettingsItem(
        title: 'Accessibility',
        subtitle: 'Readability and interaction comfort controls.',
        icon: Icons.accessibility_new_rounded,
        accent: const Color(0xFF8A4B3A),
        section: 'Alerts & Experience',
      ),
      _SettingsItem(
        title: 'Profile',
        subtitle: 'Edit account details and identity preferences.',
        icon: Icons.person_rounded,
        accent: const Color(0xFF2B5AA8),
        section: 'Account & Identity',
        route: Routes.profile,
      ),
      _SettingsItem(
        title: 'Subscription',
        subtitle: 'Manage plan, billing and renewal settings.',
        icon: Icons.workspace_premium_rounded,
        accent: const Color(0xFF8A5A12),
        section: 'Account & Identity',
        route: Routes.subscription,
      ),
      _SettingsItem(
        title: 'Language',
        subtitle: 'Switch language and translation settings.',
        icon: Icons.language_rounded,
        accent: const Color(0xFF0A6C8A),
        section: 'Account & Identity',
        route: Routes.language,
      ),
      _SettingsItem(
        title: 'Privacy & Security',
        subtitle: 'Session controls and account safety options.',
        icon: Icons.shield_moon_rounded,
        accent: const Color(0xFF0A6C8A),
        section: 'Data & Security',
      ),
      _SettingsItem(
        title: 'Data & Sync',
        subtitle: 'Sync behavior, cache and background operations.',
        icon: Icons.sync_rounded,
        accent: const Color(0xFF0D7A62),
        section: 'Data & Security',
        type: _SettingsActionType.dprOffline,
      ),
      _SettingsItem(
        title: 'Help',
        subtitle: 'Support, tips and troubleshooting guides.',
        icon: Icons.help_rounded,
        accent: const Color(0xFF8A4B3A),
        section: 'Support',
        route: Routes.help,
      ),
      _SettingsItem(
        title: 'Upcoming Update',
        subtitle: 'See what new features are coming next.',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFF0D7A62),
        section: 'Support',
        route: Routes.upcomingUpdate,
      ),
      _SettingsItem(
        title: 'Logout',
        subtitle: 'Sign out safely from this device.',
        icon: Icons.logout_rounded,
        accent: const Color(0xFFB42318),
        section: 'Support',
        type: _SettingsActionType.logout,
      ),
    ];

    final normalizedQuery = _query.trim().toLowerCase();
    final filteredItems = allItems.where((item) {
      if (normalizedQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(normalizedQuery) ||
          item.subtitle.toLowerCase().contains(normalizedQuery) ||
          item.section.toLowerCase().contains(normalizedQuery);
    }).toList();

    final grouped = <String, List<_SettingsItem>>{};
    for (final item in filteredItems) {
      grouped.putIfAbsent(item.section, () => <_SettingsItem>[]).add(item);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PremiumAppBar(
        title: 'Settings',
        showDrawerButton: false,
        actions: [
          PremiumActionIcon(
            icon: Icons.notifications_rounded,
            tooltip: 'Notification Preferences',
            backgroundColor: colorScheme.surfaceContainerHigh,
            iconColor: colorScheme.onSurface,
            borderColor: colorScheme.outlineVariant,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface,
          ],
        ),
        surfaceTintColor: colorScheme.surface,
        height: 74,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            _SettingsUserBanner(
              name: userName,
              company: companyName,
              avatarUrl: avatarUrl,
              onLogoutTap: _confirmAndLogout,
            ),
            const SizedBox(height: 12),
            _SettingsSearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: 12),
            const _ThemeSwitcherCard(),
            const SizedBox(height: 14),
            if (grouped.isEmpty)
              _EmptySearchState(query: _query)
            else
              ...grouped.entries.map(
                (entry) => _SettingsSection(
                  title: entry.key,
                  items: entry.value,
                  onItemTap: (item) {
                    if (item.type == _SettingsActionType.notifications) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                      return;
                    }

                    if (item.type == _SettingsActionType.logout) {
                      _confirmAndLogout();
                      return;
                    }

                    if (item.type == _SettingsActionType.dprOffline) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DprOfflineDashboardScreen(),
                        ),
                      );
                      return;
                    }

                    if (item.route != null) {
                      context.push(item.route!);
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.title} settings coming soon.'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsAppBarTop extends StatelessWidget {
  const _SettingsAppBarTop({
    required this.name,
    required this.company,
    required this.avatarUrl,
  });

  final String name;
  final String company;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _MiniAvatar(name: name, avatarUrl: avatarUrl, radius: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsUserBanner extends StatelessWidget {
  const _SettingsUserBanner({
    required this.name,
    required this.company,
    required this.avatarUrl,
    required this.onLogoutTap,
  });

  final String name;
  final String company;
  final String? avatarUrl;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _MiniAvatar(name: name, avatarUrl: avatarUrl, radius: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Account',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BeautifulLogoutButton(
                compact: true,
                onPressed: onLogoutTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.name,
    required this.avatarUrl,
    required this.radius,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: CircleAvatar(
        radius: radius - 2,
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
        child: hasImage
            ? null
            : Text(
                _initials(name),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.52,
                ),
              ),
      ),
    );
  }

  String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'U';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _SettingsSearchBar extends StatelessWidget {
  const _SettingsSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search settings, actions, preferences...',
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _ThemeSwitcherCard extends StatelessWidget {
  const _ThemeSwitcherCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.brightness_6_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Light / Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Switch app appearance instantly.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const BeautifulThemeSwitcher(),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final List<_SettingsItem> items;
  final ValueChanged<_SettingsItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _SettingsTile(
                item: item,
                onTap: () => onItemTap(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No results for "$query". Try another keyword.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SettingsActionType { notifications, logout, dprOffline, regular }

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.section,
    this.route,
    this.type = _SettingsActionType.regular,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String section;
  final String? route;
  final _SettingsActionType type;
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item, required this.onTap});

  final _SettingsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.accent.withOpacity(
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.28
                        : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
