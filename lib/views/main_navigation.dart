import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';
import '../models/job_application.dart';
import '../widgets/apple_animations.dart';
import '../widgets/app_back_policy.dart';
import '../widgets/app_layout_metrics.dart';
import '../widgets/app_motion.dart';
import '../widgets/app_tour_overlay.dart';
import '../widgets/app_toast.dart';
import '../widgets/delight_celebration.dart';
import 'calendar/calendar_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'hub/career_hub_screen.dart';
import 'jobs/add_edit_job_screen.dart';
import 'jobs/job_detail_screen.dart';
import 'jobs/job_list_screen.dart';
import 'settings/settings_screen.dart';
import '../services/android_home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_command_service.dart';
import '../providers/job_provider.dart';

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

/// Floating Capsule navigation with four destinations and one primary action.
/// Siapkan Karir and Portal Loker remain accessible from Beranda, so the dock
/// can stay focused on the user's daily workflow.
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  StreamSubscription<Map<String, dynamic>>? _launchSubscription;
  StreamSubscription<NotificationActionEvent>? _notificationSubscription;
  DateTime? _lastBackPressTime;
  bool _isAppTourVisible = false;

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const _items = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: Icons.mail_rounded,
      inactiveIcon: Icons.mail_outline_rounded,
      label: 'Daftar Lamaran',
    ),
    _NavItem(
      activeIcon: Icons.add_rounded,
      inactiveIcon: Icons.add_rounded,
      label: 'Catat Lamaran',
    ),
    _NavItem(
      activeIcon: Icons.calendar_month_rounded,
      inactiveIcon: Icons.calendar_month_outlined,
      label: 'Kalender',
    ),
    _NavItem(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profil',
    ),
  ];

  late final List<Widget> _screens;
  int _currentTourTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        key: const ValueKey(0),
        onNavigateTab: (index) => _onTabTapped(index),
        onOpenCareerHub: _openCareerHub,
      ),
      const JobListScreen(key: ValueKey(1)),
      const SizedBox(key: ValueKey(2)),
      CalendarScreen(key: const ValueKey(3), onOpenCareerHub: _openCareerHub),
      SettingsScreen(
        key: const ValueKey(4),
        onStartAppTour: () => _startAppTour(4),
      ),
    ];

    _scaleControllers = List.generate(
      _items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 140),
      ),
    );
    _scaleAnimations = _scaleControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.86), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.05), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();

    _scaleControllers[_currentIndex].value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTabTour(_currentIndex);
      _checkWidgetLaunch();
    });
    _launchSubscription = AndroidHomeWidgetService.launchEvents.listen(
      _handleLaunchData,
    );
    _notificationSubscription = NotificationService.actionEvents.listen(
      _handleNotificationAction,
    );
    for (final action in NotificationService.drainPendingActions()) {
      unawaited(_handleNotificationAction(action));
    }
  }

  Future<void> _handleNotificationAction(NotificationActionEvent event) async {
    NotificationService.acknowledgeAction(event);
    final commandType = switch (event.actionId) {
      'complete' => ReminderCommandType.complete,
      'snooze_tomorrow' => ReminderCommandType.snoozeTomorrow,
      _ => null,
    };
    if (commandType == null) return;
    final exists = ref
        .read(jobProvider)
        .jobs
        .any((job) => job.id == event.jobId);
    if (!exists) {
      if (mounted) _onTabTapped(0);
      return;
    }
    final success = await ReminderCommandService.execute(
      ref.read(jobProvider.notifier),
      ReminderCommand(type: commandType, jobId: event.jobId),
    );
    if (!mounted) return;
    AppToast.success(
      context,
      success
          ? (commandType == ReminderCommandType.complete
                ? 'Tindakan ditandai selesai.'
                : 'Pengingat ditunda sampai besok.')
          : 'Tindakan tidak dapat diperbarui.',
    );
  }

  Future<void> _checkWidgetLaunch() async {
    final launchData = await AndroidHomeWidgetService.getInitialLaunchData();
    if (launchData == null || !mounted) return;
    await _handleLaunchData(launchData);
  }

  Future<void> _handleLaunchData(Map<String, dynamic> launchData) async {
    if (!mounted) return;
    final fromShare = launchData['from_share'] as bool? ?? false;
    final sharedText = launchData['shared_text'] as String? ?? '';
    if (fromShare && sharedText.trim().isNotEmpty) {
      await _openSharedJob(sharedText);
      return;
    }
    final fromWidget = launchData['from_home_widget'] as bool? ?? false;
    if (!fromWidget) return;

    final openAddJob = launchData['open_add_job'] as bool? ?? false;
    final jobId = launchData['job_id'] as String? ?? '';

    if (openAddJob) {
      _openAddJob();
    } else if (jobId.isNotEmpty) {
      final jobs = ref.read(jobProvider).jobs;
      final target = jobs.where((j) => j.id == jobId).firstOrNull;
      if (target != null && mounted) {
        Navigator.push(
          context,
          AppMotion.detailDockRoute(
            builder: (_) => JobDetailScreen(job: target),
          ),
        );
      }
    }
  }

  Future<void> _openSharedJob(String sharedText) async {
    final result = await Navigator.of(context).push<JobApplication>(
      AppMotion.editorRoute(
        builder: (_) => AddEditJobScreen(
          startQuickMode: true,
          initialSharedText: sharedText,
        ),
      ),
    );
    if (result != null && mounted) {
      _onTabTapped(1);
      DelightCelebration.show(
        context,
        message: 'Lowongan sudah masuk ke tracker!',
        accent: const Color(0xFF6750E8),
        icon: Icons.inbox_rounded,
        preset: DelightPreset.trackerSave,
      );
    }
  }

  @override
  void dispose() {
    _launchSubscription?.cancel();
    _notificationSubscription?.cancel();
    for (var ctrl in _scaleControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _openAddJob();
      return;
    }
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _scaleControllers[index].forward(from: 0.0);
      }
      setState(() {
        _currentIndex = index;
      });
      _maybeShowTabTour(index);
    }
  }

  Future<void> _openAddJob() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push<JobApplication>(
      AppMotion.editorRoute(
        builder: (_) => const AddEditJobScreen(startQuickMode: true),
      ),
    );
    if (result != null && mounted) {
      _onTabTapped(1);
      DelightCelebration.show(
        context,
        message: 'Lamaran baru masuk ke tracker!',
        accent: const Color(0xFF8B5CF6),
        icon: Icons.inbox_rounded,
        preset: DelightPreset.trackerSave,
      );
    }
  }

  void _openCareerHub() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(AppMotion.hubRoute(builder: (_) => const CareerHubScreen()));
  }

  Future<void> _maybeShowTabTour(int tabIndex) async {
    if (!mounted || _isAppTourVisible) return;
    final seen = await PrefsService.isTabTourSeen(tabIndex);
    if (!mounted || seen || _isAppTourVisible) return;
    setState(() {
      _currentTourTabIndex = tabIndex;
      _isAppTourVisible = true;
    });
  }

  void _startAppTour(int tabIndex) {
    if (!mounted) return;
    setState(() {
      _currentTourTabIndex = tabIndex;
      _isAppTourVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockColor = isDark
        ? const Color(0xFF202024)
        // A clear warm cream makes the dock and the plus-button rim read as
        // one surface instead of leaving a near-white halo around the action.
        : const Color(0xFFF7F1E8);
    final dockBorderColor = isDark
        ? const Color(0xFF38383E)
        : const Color(0xFFE5E0D5);
    return AppBackScope(
      isRootShell: true,
      currentTabIndex: _currentIndex,
      onSwitchTab: _onTabTapped,
      lastBackPressTime: _lastBackPressTime,
      onUpdateBackPressTime: (time) => _lastBackPressTime = time,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Every tab stays mounted so its scroll, search, filters, and
            // expanded-card state survive while a shared cross-fade carries
            // the user between destinations.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: SizedBox(
                    width: math.min(constraints.maxWidth, 840),
                    height: constraints.maxHeight,
                    child: _FadeTabStack(
                      activeIndex: _currentIndex,
                      children: _screens,
                    ),
                  ),
                ),
              ),
            ),

            // Subtle dark fading gradient scrim behind the floating navbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppLayoutMetrics.floatingNavigationBottom(context) + 90,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                        Colors.black.withValues(alpha: isDark ? 0.70 : 0.30),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Four destinations plus a raised central "Catat Lamaran" action.
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  // A compact dock has a more deliberate capsule shape than
                  // a bar stretched edge-to-edge on wide phone screens.
                  width: math.min(constraints.maxWidth, 380),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppLayoutMetrics.floatingNavigationBottom(
                        context,
                      ),
                      left: 20,
                      right: 20,
                    ),
                    child: SizedBox(
                      height: 94,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: dockColor,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: dockBorderColor,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _buildTabItem(index: 0, isDark: isDark),
                                  _buildTabItem(index: 1, isDark: isDark),
                                  const SizedBox(width: 60),
                                  _buildTabItem(index: 3, isDark: isDark),
                                  _buildTabItem(index: 4, isDark: isDark),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            // Let the action sit a little deeper in the dock;
                            // it still rises above the capsule, but no longer
                            // looks detached from it.
                            top: -9,
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: Center(
                                child: Semantics(
                                  button: true,
                                  label: _items[2].label,
                                  child: Tooltip(
                                    message: _items[2].label,
                                    child: FluidBounceButton(
                                      onTap: _openAddJob,
                                      scaleFactor: 0.92,
                                      child: Hero(
                                        tag: 'main_nav_action_button',
                                        createRectTween: actionButtonRectTween,
                                        flightShuttleBuilder:
                                            actionButtonFlightShuttle,
                                        placeholderBuilder:
                                            actionButtonHeroPlaceholder,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF5C44E4)
                                                : const Color(0xFF19191B),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: dockBorderColor,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: isDark ? 0.28 : 0.20,
                                                ),
                                                blurRadius: 14,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isAppTourVisible)
              AppTourOverlay(
                tabIndex: _currentTourTabIndex,
                onFinish: () {
                  if (mounted) setState(() => _isAppTourVisible = false);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required bool isDark}) {
    final item = _items[index];
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: Tooltip(
          message: item.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTabTapped(index),
            child: Center(
              child: SizedBox.square(
                dimension: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      scale: isSelected ? 1 : 0.72,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: isSelected ? 1 : 0,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.16 : 0.22,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimations[index],
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isSelected ? item.activeIcon : item.inactiveIcon,
                          key: ValueKey('${item.label}_$isSelected'),
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white)
                              : (isDark
                                    ? const Color(0xFFAEAEB2)
                                    : const Color(0xFF8E8E93)),
                          size: isSelected ? 22 : 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeTabStack extends StatefulWidget {
  final int activeIndex;
  final List<Widget> children;

  const _FadeTabStack({required this.activeIndex, required this.children});

  @override
  State<_FadeTabStack> createState() => _FadeTabStackState();
}

class _FadeTabStackState extends State<_FadeTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final Animation<double> _transition;
  late int _incomingIndex;
  late int _outgoingIndex;

  @override
  void initState() {
    super.initState();
    _incomingIndex = widget.activeIndex;
    _outgoingIndex = widget.activeIndex;
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _transition = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void didUpdateWidget(covariant _FadeTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex == widget.activeIndex) return;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _incomingIndex = widget.activeIndex;
      _outgoingIndex = widget.activeIndex;
      _transitionController.value = 1.0;
      return;
    }

    // One shared timeline guarantees the outgoing page is fully visible when
    // the incoming page starts. This removes the brief blank flash caused by
    // two independent opacity controllers racing each other.
    _outgoingIndex = _incomingIndex;
    _incomingIndex = widget.activeIndex;
    _transitionController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transition,
      builder: (context, _) {
        final progress = _transition.value;
        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isIncoming = index == _incomingIndex;
            final isOutgoing =
                index == _outgoingIndex &&
                _outgoingIndex != _incomingIndex &&
                progress < 1.0;
            final isVisible = isIncoming || isOutgoing;
            final opacity = isIncoming ? progress : (1.0 - progress);

            return Offstage(
              offstage: !isVisible,
              child: IgnorePointer(
                ignoring: !isIncoming,
                child: ExcludeSemantics(
                  excluding: !isIncoming,
                  child: HeroMode(
                    // Heroes only belong to the destination tab while the
                    // cross-fade is running, preventing duplicate flights.
                    enabled: isIncoming,
                    child: TickerMode(
                      enabled: isVisible,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: RepaintBoundary(child: widget.children[index]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
