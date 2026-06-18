// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/api/sync_job.dart';
import 'package:untitled2/features/noti_system/updates/presentation/navigation/updates_routes.dart';
import 'package:untitled2/features/noti_system/updates/application/providers/notification_providers.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../router/route_tracker.dart';

extension _RouteTrailEntryBreadcrumbIcon on RouteTrailEntry {
  IconData? get icon {
    final normalized = normalizeRouteLocation(path);

    if (normalized == '/' || normalized == '/workCategory') {
      return Icons.home_rounded;
    }
    if (normalized.contains('profile')) return Icons.person_outline_rounded;
    if (normalized.contains('site')) return Icons.apartment_rounded;
    if (normalized.contains('module')) return Icons.widgets_outlined;
    if (normalized.contains('dpr')) return Icons.assignment_outlined;
    if (normalized.contains('inventory')) return Icons.inventory_2_outlined;
    if (normalized.contains('salary')) return Icons.payments_outlined;
    if (normalized.contains('expense')) return Icons.receipt_long_outlined;
    if (normalized.contains('help')) return Icons.help_outline_rounded;
    if (normalized.contains('theme')) return Icons.palette_outlined;

    return null;
  }
}

// ─── Public API ──────────────────────────────────────────────────────────────

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawer;
  final bool showBreadcrumb;
  final List<Widget> actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showDrawer = true,
    this.showBreadcrumb = true,
    this.actions = const [],
  });

  @override
  Size get preferredSize => Size.fromHeight(showBreadcrumb ? 126 : 76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trail = ref.watch(routeTrailProvider);
    final selectedType = ref.watch(typeProvider);
    final visibleTrail = trail
        .where((entry) => isBreadcrumbVisibleLocation(entry.path))
        .toList(growable: false);
    final fallbackType =
        visibleTrail.isNotEmpty ? visibleTrail.last.label : null;
    final workTypeLabel = _formatWorkTypeLabel(selectedType ?? fallbackType);
    final unreadCount = ref.watch(unreadCountProvider);
    final syncJobs = ref.watch(syncJobsProvider);
    final isSyncing = syncJobs.any(
      (j) =>
          j.status == SyncJobStatus.running || j.status == SyncJobStatus.queued,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? cs.surfaceContainerHigh : cs.surface)
                  .withOpacity(isDark ? 0.92 : 0.94),
              cs.surface.withOpacity(isDark ? 0.80 : 0.82),
              (isDark ? cs.surfaceContainer : cs.surfaceContainerLowest)
                  .withOpacity(isDark ? 0.88 : 0.90),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showDrawer)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _MenuButton(
                            onPressed: () =>
                                Scaffold.maybeOf(context)?.openDrawer(),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...actions,
                            if (actions.isNotEmpty) const SizedBox(width: 8),
                            _NotificationButton(
                              unreadCount: unreadCount,
                              isSyncing: isSyncing,
                              onPressed: () => context.push(UpdatesRoutes.list),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: AutoSizeText(
                            title,
                            maxLines: 2,
                            minFontSize: 13,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showBreadcrumb && visibleTrail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final targetWidth =
                            (screenWidth * 0.60).clamp(210.0, screenWidth - 24);

                        return SizedBox(
                          width: targetWidth.toDouble(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WorkTypeBadge(label: workTypeLabel),
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                width: targetWidth.toDouble(),
                                child: BreadcrumbNavBar(trail: visibleTrail),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkTypeBadge extends StatelessWidget {
  final String label;

  const _WorkTypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey<String>(label),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        constraints: const BoxConstraints(maxWidth: 160),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withOpacity(0.22), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspaces_outline,
                size: 11, color: cs.onPrimaryContainer),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                  letterSpacing: 0.16,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWorkTypeLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'General';
  }

  final cleaned = raw
      .trim()
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  return cleaned
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

// ─── BreadcrumbNavBar ─────────────────────────────────────────────────────────

class BreadcrumbNavBar extends ConsumerStatefulWidget {
  final List<RouteTrailEntry> trail;

  const BreadcrumbNavBar({super.key, required this.trail});

  @override
  ConsumerState<BreadcrumbNavBar> createState() => _BreadcrumbNavBarState();
}

class _BreadcrumbNavBarState extends ConsumerState<BreadcrumbNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  List<RouteTrailEntry> _displayed = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _displayed = widget.trail;
    _controller.forward();
  }

  @override
  void didUpdateWidget(BreadcrumbNavBar old) {
    super.didUpdateWidget(old);
    if (old.trail != widget.trail) {
      _controller.reset();
      setState(() => _displayed = widget.trail);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: BreadcrumbContainer(
          child: BreadcrumbOverflowHandler(
            trail: _displayed,
          ),
        ),
      ),
    );
  }
}

// ─── BreadcrumbContainer ─────────────────────────────────────────────────────

class BreadcrumbContainer extends StatelessWidget {
  final Widget child;

  const BreadcrumbContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(maxHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh.withOpacity(0.72)
                : cs.surface.withOpacity(0.76),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? cs.outlineVariant.withOpacity(0.18)
                  : cs.outline.withOpacity(0.14),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(isDark ? 0.28 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── BreadcrumbOverflowHandler ────────────────────────────────────────────────

class BreadcrumbOverflowHandler extends ConsumerStatefulWidget {
  final List<RouteTrailEntry> trail;

  const BreadcrumbOverflowHandler({super.key, required this.trail});

  @override
  ConsumerState<BreadcrumbOverflowHandler> createState() =>
      _BreadcrumbOverflowHandlerState();
}

class _BreadcrumbOverflowHandlerState
    extends ConsumerState<BreadcrumbOverflowHandler> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant BreadcrumbOverflowHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail != widget.trail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    }
  }

  void _scrollToEnd({bool jump = false}) {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (jump) {
      _scrollController.jumpTo(maxExtent);
      return;
    }

    _scrollController.animateTo(
      maxExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;
    if (trail.isEmpty) return const SizedBox.shrink();

    final List<_CrumbSlot> slots;

    if (trail.length > 5) {
      slots = [
        _CrumbSlot.entry(trail.first, isCurrent: false),
        _CrumbSlot.overflow(trail.sublist(1, trail.length - 2)),
        _CrumbSlot.entry(trail[trail.length - 2], isCurrent: false),
        _CrumbSlot.entry(trail.last, isCurrent: true),
      ];
    } else {
      slots = [
        for (var i = 0; i < trail.length; i++)
          _CrumbSlot.entry(trail[i], isCurrent: i == trail.length - 1),
      ];
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) _BreadcrumbSeparator(),
            if (slots[i].isOverflow)
              _OverflowDot(hiddenEntries: slots[i].overflowEntries!)
            else
              BreadcrumbItem(
                entry: slots[i].entry!,
                isCurrent: slots[i].isCurrent,
              ),
          ],
        ],
      ),
    );
  }
}

// ─── BreadcrumbItem ───────────────────────────────────────────────────────────

class BreadcrumbItem extends ConsumerStatefulWidget {
  final RouteTrailEntry entry;
  final bool isCurrent;

  const BreadcrumbItem({
    super.key,
    required this.entry,
    required this.isCurrent,
  });

  @override
  ConsumerState<BreadcrumbItem> createState() => _BreadcrumbItemState();
}

class _BreadcrumbItemState extends ConsumerState<BreadcrumbItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = widget.isCurrent;
    final label = widget.entry.label;

    final textColor =
        isCurrent ? cs.onSurface : cs.onSurfaceVariant.withOpacity(0.72);

    final bgColor = isCurrent
        ? (isDark
            ? cs.onSurface.withOpacity(0.10)
            : cs.onSurface.withOpacity(0.07))
        : (_hovered
            ? cs.onSurfaceVariant.withOpacity(0.08)
            : cs.surface.withOpacity(0));

    final borderColor = isCurrent
        ? cs.primary.withOpacity(isDark ? 0.22 : 0.16)
        : cs.surface.withOpacity(0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: isCurrent ? null : (_) => _press.forward(),
        onTapUp: isCurrent
            ? null
            : (_) async {
                HapticFeedback.lightImpact();
                await _press.reverse();
                if (context.mounted) {
                  _navigateToBreadcrumb(context, ref, widget.entry);
                }
              },
        onTapCancel: isCurrent ? null : () => _press.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Tooltip(
            message: label.length > 18 ? label : '',
            waitDuration: const Duration(milliseconds: 600),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(maxWidth: 92),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.entry.icon != null) ...[
                    Icon(
                      widget.entry.icon,
                      size: 11,
                      color: textColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCurrent ? 12 : 11.5,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.12,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 3),
                    _CurrentDot(color: cs.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _CurrentDot ─────────────────────────────────────────────────────────────

class _CurrentDot extends StatelessWidget {
  final Color color;
  const _CurrentDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── _BreadcrumbSeparator ─────────────────────────────────────────────────────

class _BreadcrumbSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '›',
        style: TextStyle(
          fontSize: 13,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.30),
          fontWeight: FontWeight.w400,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── _OverflowDot ─────────────────────────────────────────────────────────────

class _OverflowDot extends ConsumerStatefulWidget {
  final List<RouteTrailEntry> hiddenEntries;
  const _OverflowDot({required this.hiddenEntries});

  @override
  ConsumerState<_OverflowDot> createState() => _OverflowDotState();
}

class _OverflowDotState extends ConsumerState<_OverflowDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _showOverflowSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface.withOpacity(0),
      builder: (_) => _OverflowSheet(
        entries: widget.hiddenEntries,
        onTap: (entry) {
          Navigator.of(context).pop();
          _navigateToBreadcrumb(context, ref, entry);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _pulse.forward(),
        onTapUp: (_) async {
          await _pulse.reverse();
          if (context.mounted) _showOverflowSheet(context);
        },
        onTapCancel: () => _pulse.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.92)
              .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeIn)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _hovered
                  ? cs.onSurfaceVariant.withOpacity(0.08)
                  : cs.surface.withOpacity(0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(cs),
                const SizedBox(width: 3),
                _dot(cs),
                const SizedBox(width: 3),
                _dot(cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme cs) => Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
      );
}

// ─── _OverflowSheet ───────────────────────────────────────────────────────────

class _OverflowSheet extends StatelessWidget {
  final List<RouteTrailEntry> entries;
  final void Function(RouteTrailEntry) onTap;

  const _OverflowSheet({required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh.withOpacity(0.88)
                : cs.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.18),
                width: 0.8,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Text(
                'Route history',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withOpacity(0.55),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map(
                (e) => _SheetRow(entry: e, onTap: () => onTap(e)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatefulWidget {
  final RouteTrailEntry entry;
  final VoidCallback onTap;

  const _SheetRow({required this.entry, required this.onTap});

  @override
  State<_SheetRow> createState() => _SheetRowState();
}

class _SheetRowState extends State<_SheetRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed
                ? cs.onSurface.withOpacity(0.05)
                : cs.surfaceContainerLow.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (widget.entry.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(widget.entry.icon,
                      size: 16, color: cs.onSurfaceVariant),
                ),
              Expanded(
                child: Text(
                  widget.entry.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: cs.onSurfaceVariant.withOpacity(0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _MenuButton ─────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withOpacity(0.72),
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.8),
          ),
          child: Icon(Icons.menu_rounded, color: cs.onSurface, size: 23),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int unreadCount;
  final bool isSyncing;

  const _NotificationButton(
      {required this.onPressed,
      required this.unreadCount,
      required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withOpacity(0.72),
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: cs.outline.withOpacity(0.14), width: 0.8),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: cs.onSurface, size: 22),
            ),
            if (isSyncing)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.surface, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cs.onError,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal model ───────────────────────────────────────────────────────────

class _CrumbSlot {
  final RouteTrailEntry? entry;
  final bool isCurrent;
  final bool isOverflow;
  final List<RouteTrailEntry>? overflowEntries;

  const _CrumbSlot._({
    this.entry,
    required this.isCurrent,
    required this.isOverflow,
    this.overflowEntries,
  });

  factory _CrumbSlot.entry(RouteTrailEntry entry, {required bool isCurrent}) =>
      _CrumbSlot._(entry: entry, isCurrent: isCurrent, isOverflow: false);

  factory _CrumbSlot.overflow(List<RouteTrailEntry> entries) => _CrumbSlot._(
      isCurrent: false, isOverflow: true, overflowEntries: entries);
}

// ─── Routing (unchanged) ─────────────────────────────────────────────────────

Future<void> _navigateToBreadcrumb(
  BuildContext context,
  WidgetRef ref,
  RouteTrailEntry target,
) async {
  final targetPath = normalizeRouteLocation(target.path);
  final router = GoRouter.of(context);

  var attempts = 0;
  while (context.mounted && attempts < 25) {
    final currentPath =
        normalizeRouteLocation(ref.read(currentRouteProvider) ?? '');
    if (currentPath == targetPath) return;
    if (!router.canPop()) break;
    router.pop();
    attempts++;
    await Future<void>.delayed(Duration.zero);
  }

  if (!context.mounted) return;

  final activePath =
      normalizeRouteLocation(ref.read(currentRouteProvider) ?? '');
  if (activePath != targetPath) router.go(target.path);
}
