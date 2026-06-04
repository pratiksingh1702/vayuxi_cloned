import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/adaptive_name_display.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'package:untitled2/typeProvider/work_type.dart';
import 'features/noti_system/updates/presentation/navigation/updates_routes.dart';
import 'core/router/routes.dart';
import 'core/utlis/widgets/language_first_time_popup.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/language/model/language_storage.dart';
import 'features/language/service/lang_providers.dart';
import 'features/modules/all_Modules/dpr/dpr_insu/model/dpr_model_insu.dart';
import 'features/modules/all_Modules/dpr/dpr_insu/screens/testing.dart';
import 'features/modules/all_Modules/more/language.dart';
import 'features/noti_system/noti_providers/noti_provider.dart';
import 'features/noti_system/updates/application/providers/notification_providers.dart';
import 'features/profile_page/screens/profilePage.dart';
import 'features/profile_page/provider/userProvider.dart';
import 'features/tour/domain/tour_controller.dart';
import 'features/tour/domain/tour_registery.dart';
import 'core/screens/settings_screen.dart';
import 'core/screens/theme_switcher.dart';
import 'core/api/sync_job.dart';

const String kUserProfileHeroTag = 'user-profile-hero-card';

class WorkCategoryScreen extends ConsumerStatefulWidget {
  const WorkCategoryScreen({super.key});

  @override
  ConsumerState<WorkCategoryScreen> createState() => _WorkCategoryScreenState();
}

class _WorkCategoryScreenState extends ConsumerState<WorkCategoryScreen> {
  String? selectedImage;
  bool showLanguagePopup = false;
  bool languagePopupChecked = false; // avoid re-show loop
  bool _languageFlowDone = false; // <-- add this
  bool _showcaseStarted = false;
  bool _isNavigating = false;
  BuildContext? _showcaseContext;
  bool _requiresProfileCompletionFlag = false;

  Future<void> _showPendingProfilePromptIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool('show_complete_profile_prompt') ?? false;
    final requiresProfileCompletion =
        prefs.getBool('requires_profile_completion') ?? false;
    if (!shouldShow || !requiresProfileCompletion || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Please complete your profile to unlock full access.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open Profile',
          onPressed: _openProfileWithHeroTransition,
        ),
      ),
    );

    await prefs.remove('show_complete_profile_prompt');
  }

  Future<void> _loadProfileCompletionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final requiresProfileCompletion =
        prefs.getBool('requires_profile_completion') ?? false;
    if (!mounted) return;
    setState(() {
      _requiresProfileCompletionFlag = requiresProfileCompletion;
    });
  }

  Future<void> _ensureEnglishDefault() async {
    const englishCode = 'en-IN';
    final storage = LanguageStorage();

    // Keep a deterministic fallback language so UI text is always available.
    if (storage.getActiveLanguage().trim().isEmpty) {
      await storage.setActiveLanguage(englishCode);
    }

    final user = ref.read(currentUserProvider);
    if (user != null && !storage.isLanguageDownloaded(englishCode)) {
      try {
        await ref
            .read(languageRepositoryProvider)
            .downloadAndStoreLanguage(user.id, englishCode);
      } catch (_) {
        // If network/download fails, fallback still remains English code locally.
      }
    }

    if (!storage.isLanguageDownloaded(storage.getActiveLanguage()) &&
        storage.getActiveLanguage() != englishCode) {
      await storage.setActiveLanguage(englishCode);
    }

    ref.invalidate(activeLanguageProvider);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(userNotifierProvider.notifier).getCurrentUser();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.id);
      }

      await _ensureEnglishDefault();
      await _loadProfileCompletionFlag();

      final alreadySeen = await LanguagePopupPrefs.hasSeen();

      if (!mounted) return;

      if (!alreadySeen) {
        setState(() => showLanguagePopup = true);
      } else {
        setState(() => _languageFlowDone = true);
      }

      await _showPendingProfilePromptIfNeeded();
    });
  }

  Future<void> handlePress({
    required String id,
    required String title,
    required String imagePath,
  }) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      setState(() => selectedImage = id);

      // Ensure the active highlight/overlay is fully removed before route push
      // so users don't see leftover placeholders during screen transition.
      if (_showcaseContext != null) {
        ShowCaseWidget.of(_showcaseContext!)?.dismiss();
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 90));
      }

      final typeNotifier = ref.read(typeProvider.notifier);

      final workType = WorkType.values.firstWhere(
        (e) => e.name == id,
        orElse: () => WorkType.mechanical,
      );
      typeNotifier.setType(workType.apiValue);

      ref.read(siteProvider.notifier).fetchSites();

      await context.push(
        Routes.selectModule,
        extra: {"title": title, "image": imagePath},
      );
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  Future<void> _openProfileWithHeroTransition() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1050),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubicEmphasized,
            reverseCurve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: Tween<double>(begin: 0.75, end: 1).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.995, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => context.pop(true),
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

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _focusSubtitle() {
    return 'Choose your work stream and continue today\'s execution in one tap.';
  }

  Color _adaptiveElevationColor(ColorScheme colorScheme, Brightness brightness,
      {double lightOpacity = 0.08, double darkOpacity = 0.16}) {
    return brightness == Brightness.dark ? Colors.white : colorScheme.shadow;
  }

  bool _shouldRecommendProfileCompletion({
    required bool isLoggedIn,
    required String? role,
    required bool requiresProfileCompletion,
    required String? fullName,
    required String? email,
  }) {
    if (!isLoggedIn || role != 'user') {
      return false;
    }

    if (requiresProfileCompletion) {
      return true;
    }

    final hasName = (fullName ?? '').trim().isNotEmpty;
    final hasEmail = (email ?? '').trim().isNotEmpty;

    // complete-profile requires fullName + email. companyName is optional.
    return !(hasName && hasEmail);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final profileName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'complete your profile to get started';
    final profilePhoto = user?.profilePhoto?.trim();
    final greetingTitle = _timeGreeting();

    final appBarTitle = greetingTitle;
    final appBarSubtitle = profileName;
    final showCompleteProfileRecommendation = _shouldRecommendProfileCompletion(
      isLoggedIn: authState.isLoggedIn,
      role: authState.role,
      requiresProfileCompletion: _requiresProfileCompletionFlag,
      fullName: user?.fullName,
      email: user?.email,
    );

    if (!authState.isLoggedIn) {
      Future.microtask(() => context.go(Routes.login));
    }

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _showcaseContext = showcaseContext;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          // ✅ Gate 1: Language flow must complete first
          if (!_languageFlowDone) {
            debugPrint('⏳ Showcase blocked: language flow not done');
            return;
          }

          // ✅ Gate 2: Don't re-trigger if already started
          if (_showcaseStarted) {
            debugPrint('⏳ Showcase blocked: already started');
            return;
          }

          final ctrl = ref.read(tourControllerProvider.notifier);
          ctrl.syncToRoute(AppRoutes.workCategory);

          final step = ctrl.currentStep;
          if (step == null) {
            debugPrint('⏳ Showcase blocked: no current step');
            return;
          }

          if (!step.autoShowcase) {
            debugPrint('⏳ Showcase blocked: autoShowcase false');
            return;
          }

          final sc = ShowCaseWidget.of(showcaseContext);
          if (sc == null) {
            debugPrint('⏳ Showcase blocked: no showcase context');
            return;
          }

          _showcaseStarted = true;
          debugPrint('✅ Showcase started on work category');
          sc.startShowCase([step.showcaseKey]);
        });

        return Stack(
          children: [
            Scaffold(
              backgroundColor: colorScheme.surface,
              body: Container(
                color: colorScheme.surface,
                child: SafeArea(
                  top: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LandingHeaderRow(
                              photoUrl: profilePhoto,
                              userName: profileName,
                              title: appBarTitle,
                              subtitle: appBarSubtitle,
                              onAvatarTap: _openProfileWithHeroTransition,
                              onNotificationsTap: () =>
                                  context.push(UpdatesRoutes.list),
                            ),
                            if (showCompleteProfileRecommendation) ...[
                              const SizedBox(height: 12),
                              _ProfileCompletionRecommendationCard(
                                onCompleteProfile:
                                    _openProfileWithHeroTransition,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _CategorySpotlightCard(
                            selectedImage: selectedImage,
                            elevationColor: _adaptiveElevationColor(
                              colorScheme,
                              Theme.of(context).brightness,
                              lightOpacity: 0.06,
                              darkOpacity: 0.14,
                            ),
                            onSelect: (workType) => handlePress(
                              id: workType.name,
                              title: workType.displayName,
                              imagePath: workType.imagePath,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: _TipQuoteCard(
                          tip:
                              'Tip: choose one category first, then update progress continuously in short steps.',
                          elevationColor: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _LandingBottomNavBar(
                onHomeTap: () {},
                onSettingsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            // ✅ Overlay popup
            if (showLanguagePopup)
              LanguageFirstTimePopup(
                onSelectLanguage: () async {
                  await LanguagePopupPrefs.markSeen(); // ⭐ add this
                  await _ensureEnglishDefault();

                  setState(() => showLanguagePopup = false);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );

                  if (!mounted) return;
                  setState(() => _languageFlowDone = true);
                },
                onSkip: () async {
                  await LanguagePopupPrefs.markSeen(); // ⭐ add this
                  await _ensureEnglishDefault();

                  setState(() {
                    showLanguagePopup = false;
                    _languageFlowDone = true;
                  });
                },
              ),

/**/
          ],
        );
      },
    );
  }
}

Widget DraftCard(InsulationDprModel draft, BuildContext context) {
  return Card(
    color: Colors.orange[50],
    child: ListTile(
      leading: Icon(Icons.save, color: Colors.orange),
      title: Text(draft.workDescription),
      subtitle: Text("Unsaved changes • ${draft.date}"),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInsulationDescriptionScreen(
              work: draft,
            ),
          ),
        );
      },
    ),
  );
}

class CompanyCard extends StatelessWidget {
  final String imagePath;
  final String companyName;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;
  final Color elevationColor;
  final VoidCallback? onTap;

  const CompanyCard({
    super.key,
    required this.imagePath,
    required this.companyName,
    required this.subtitle,
    required this.accentColor,
    required this.elevationColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 250 || constraints.maxHeight < 230;
        final colorScheme = Theme.of(context).colorScheme;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: elevationColor.withOpacity(isSelected ? 0.16 : 0.1),
                blurRadius: isSelected ? 7 : 5,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainerLow,
                    ],
                  ),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isSelected ? 1.8 : 1.1,
                  ),
                ),
                child: compact
                    ? _CompactCardBody(
                        imagePath: imagePath,
                        companyName: companyName,
                        subtitle: subtitle,
                        accentColor: accentColor,
                        isSelected: isSelected,
                      )
                    : _WideCardBody(
                        imagePath: imagePath,
                        companyName: companyName,
                        subtitle: subtitle,
                        accentColor: accentColor,
                        isSelected: isSelected,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactCardBody extends StatelessWidget {
  const _CompactCardBody({
    required this.imagePath,
    required this.companyName,
    required this.subtitle,
    required this.accentColor,
    required this.isSelected,
  });

  final String imagePath;
  final String companyName;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight <= 186;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              accentColor.withOpacity(0.25),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tight ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.15,
                ),
              ),
              if (!tight) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.15,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isSelected ? 'Selected' : 'Tap to Continue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: tight ? 10 : 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: tight ? 14 : 15,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WideCardBody extends StatelessWidget {
  const _WideCardBody({
    required this.imagePath,
    required this.companyName,
    required this.subtitle,
    required this.accentColor,
    required this.isSelected,
  });

  final String imagePath;
  final String companyName;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  width: 110,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          accentColor.withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isSelected ? 'Selected' : 'Tap to Continue',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PremiumWelcomeHeader extends StatelessWidget {
  const _PremiumWelcomeHeader({
    required this.userName,
    required this.userEmail,
    required this.greetingTitle,
    required this.greetingSubtitle,
    required this.companyName,
    required this.userAddress,
    required this.profilePhoto,
    required this.totalServices,
    required this.elevationColor,
    this.onTap,
  });

  final String userName;
  final String userEmail;
  final String greetingTitle;
  final String greetingSubtitle;
  final String companyName;
  final String userAddress;
  final String? profilePhoto;
  final int totalServices;
  final Color elevationColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = profilePhoto != null && profilePhoto!.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHigh,
                colorScheme.surfaceContainer,
              ],
            ),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: elevationColor.withOpacity(0.08),
                blurRadius: 6,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      backgroundImage:
                          hasImage ? NetworkImage(profilePhoto!) : null,
                      child: hasImage
                          ? null
                          : Text(
                              _initials(userName),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          greetingSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ProfileMetaChip(
                    icon: Icons.apartment_rounded,
                    text: companyName,
                  ),
                  _ProfileMetaChip(
                    icon: Icons.handyman_rounded,
                    text: '$totalServices services',
                  ),
                  _ProfileMetaChip(
                    icon: Icons.location_on_outlined,
                    text: userAddress,
                  ),
                  _ProfileMetaChip(
                    icon: Icons.mail_outline_rounded,
                    text: userEmail,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'U';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _AppBarProfileAction extends StatelessWidget {
  const _AppBarProfileAction({
    required this.photoUrl,
    required this.userName,
    required this.onTap,
    this.padding = const EdgeInsets.only(left: 2, right: 6),
    this.outerRadius = 16,
    this.innerRadius = 14,
  });

  final String? photoUrl;
  final String userName;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double outerRadius;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    final hasImage = photoUrl != null && photoUrl!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: CircleAvatar(
          radius: outerRadius,
          backgroundColor: colorScheme.primaryContainer,
          child: CircleAvatar(
            radius: innerRadius,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: hasImage ? NetworkImage(photoUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    _initials(userName),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'U';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpotlightCard extends StatelessWidget {
  const _CategorySpotlightCard({
    required this.selectedImage,
    required this.elevationColor,
    required this.onSelect,
  });

  final String? selectedImage;
  final Color elevationColor;
  final Function(WorkType) onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 12) / 2;
        final targetHeight = (tileWidth / 0.88).clamp(190.0, 248.0);
        final aspectRatio = (tileWidth / targetHeight).clamp(0.72, 0.96);

        return GridView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 6),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: WorkType.values.length,
          itemBuilder: (context, index) {
            final type = WorkType.values[index];
            final card = CompanyCard(
              imagePath: type.imagePath,
              companyName: type.displayName,
              subtitle: type.subtitle,
              accentColor: type.accentColor,
              elevationColor: elevationColor,
              isSelected: selectedImage == type.name,
              onTap: () => onSelect(type),
            );

            if (index == 0) {
              return Showcase(
                key: TourRegistry.workCategoryKey,
                description: 'Select any Work Type to continue 🚀',
                child: card,
              );
            }
            return card;
          },
        );
      },
    );
  }
}

class _AppBarWelcomeTitle extends StatelessWidget {
  const _AppBarWelcomeTitle({
    required this.photoUrl,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.onAvatarTap,
  });

  final String? photoUrl;
  final String userName;
  final String title;
  final String subtitle;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _AppBarProfileAction(
          photoUrl: photoUrl,
          userName: userName,
          onTap: onAvatarTap,
          padding: const EdgeInsets.only(right: 10),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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

class _TipQuoteCard extends StatelessWidget {
  const _TipQuoteCard({required this.tip, this.elevationColor});

  final String tip;
  final Color? elevationColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (elevationColor != null)
            BoxShadow(
              color: elevationColor!,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: colorScheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBottomNavBar extends StatelessWidget {
  const _LandingBottomNavBar({
    required this.onHomeTap,
    required this.onSettingsTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _BottomNavPill(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: onHomeTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BottomNavPill(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: false,
                onTap: onSettingsTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionRecommendationCard extends StatelessWidget {
  const _ProfileCompletionRecommendationCard({
    required this.onCompleteProfile,
  });

  final VoidCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended: complete your profile first',
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your basic details before continuing so all modules and reports work correctly.',
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onCompleteProfile,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      'Complete Profile',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavPill extends StatelessWidget {
  const _BottomNavPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumAnimatedGreeting extends StatefulWidget {
  const _PremiumAnimatedGreeting({required this.text});

  final String text;

  @override
  State<_PremiumAnimatedGreeting> createState() =>
      _PremiumAnimatedGreetingState();
}

class _PremiumAnimatedGreetingState extends State<_PremiumAnimatedGreeting>
    with TickerProviderStateMixin {
  late final AnimationController _typeController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _PremiumAnimatedGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _typeController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([_typeController, _shimmerController]),
      builder: (context, child) {
        final chars = (widget.text.length * _typeController.value)
            .floor()
            .clamp(1, widget.text.length);
        final visibleText = widget.text.substring(0, chars);
        final shift = _shimmerController.value;

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1 + (2 * shift), 0),
              end: Alignment(1 + (2 * shift), 0),
              colors: [
                colorScheme.primary,
                colorScheme.tertiary,
                colorScheme.primary,
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            visibleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LandingHeaderRow extends ConsumerWidget {
  const _LandingHeaderRow({
    required this.photoUrl,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  final String? photoUrl;
  final String userName;
  final String title;
  final String subtitle;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final unreadCount = ref.watch(unreadCountProvider);
    final syncJobs = ref.watch(syncJobsProvider);
    final isSyncing = syncJobs.any(
      (j) =>
          j.status == SyncJobStatus.running || j.status == SyncJobStatus.queued,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AppBarProfileAction(
                photoUrl: photoUrl,
                userName: userName,
                onTap: onAvatarTap,
                padding: const EdgeInsets.only(right: 0),
                outerRadius: 22,
                innerRadius: 19,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BeautifulThemeSwitcher(compact: true),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PremiumActionIcon(
                        icon: isSyncing
                            ? Icons.sync_rounded
                            : Icons.notifications_rounded,
                        tooltip: 'Notifications',
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        iconColor: colorScheme.onSurface,
                        borderColor: colorScheme.outlineVariant,
                        onPressed: onNotificationsTap,
                      ),
                      if (isSyncing)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onError,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PremiumAnimatedGreeting(
                text: '$title,',
              ),
              const SizedBox(height: 4),
              AdaptiveNameDisplay(
                name: subtitle,
                minFontSize: 13,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
