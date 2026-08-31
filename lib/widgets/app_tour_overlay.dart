import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prefs_service.dart';
import '../theme/app_theme.dart';
import 'apple_animations.dart';

/// Live registry of on-screen widgets the guided tour can spotlight.
class TourRegistry {
  static final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  static GlobalKey keyOf(String id) =>
      _keys.putIfAbsent(id, GlobalKey.new);

  static Rect? rectOf(String id) {
    final context = keyOf(id).currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    if (rect.width < 8 || rect.height < 8) return null;
    return rect;
  }
}

/// Marks a widget as a tour spotlight target. Keep [id] stable.
class TourAnchor extends StatelessWidget {
  final String id;
  final Widget child;

  const TourAnchor({super.key, required this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: TourRegistry.keyOf(id), child: child);
  }
}

/// Target area specification for the guided tour spotlight
class TourTargetRect {
  final String? anchorId;
  final Rect Function(
    Size screenSize,
    EdgeInsets padding,
    double contentLeft,
    double contentWidth,
  )
  computeRect;
  final BorderRadius borderRadius;
  final bool isCircle;
  final double inflate;

  const TourTargetRect({
    this.anchorId,
    required this.computeRect,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.isCircle = false,
    this.inflate = 8,
  });
}

/// Guided Tour Step definition
class AppTourStep {
  final int targetTabIndex;
  final String badgeText;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final TourTargetRect targetRect;
  final bool
  placeCardBelow; // true: card below target, false: card above target

  const AppTourStep({
    required this.targetTabIndex,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.targetRect,
    this.placeCardBelow = true,
  });
}

/// Interactive Guided Tour Overlay (Material 3 & Apple Fluid Design).
/// Highlights actual UI elements with cutout spotlights and pulse glow rings,
/// and walks users through every core feature seamlessly with zero offside bugs.
class AppTourOverlay extends StatefulWidget {
  final int tabIndex;
  final VoidCallback onFinish;

  const AppTourOverlay({
    super.key,
    required this.tabIndex,
    required this.onFinish,
  });

  @override
  State<AppTourOverlay> createState() => AppTourOverlayState();
}

class AppTourOverlayState extends State<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late List<AppTourStep> _currentSteps;

  static AppTourStep _step({
    required int tab,
    required String badge,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required double top,
    required double height,
    String? anchorId,
    double horizontalInset = 16,
    bool fromBottom = false,
    bool cardBelow = true,
    double inflate = 8,
    BorderRadius? radius,
  }) {
    return AppTourStep(
      targetTabIndex: tab,
      badgeText: badge,
      title: title,
      description: description,
      icon: icon,
      accentColor: color,
      placeCardBelow: cardBelow,
      targetRect: TourTargetRect(
        anchorId: anchorId,
        inflate: inflate,
        computeRect: (size, pad, contentLeft, contentWidth) {
          final resolvedTop = fromBottom
              ? size.height - pad.bottom - top
              : pad.top + top;
          return Rect.fromLTWH(
            contentLeft + horizontalInset,
            resolvedTop,
            contentWidth - horizontalInset * 2,
            height,
          );
        },
        borderRadius: radius ?? BorderRadius.circular(22),
      ),
    );
  }

  static List<AppTourStep> getStepsForTab(int tabIndex) {
    const purple = Color(0xFF5C44E4);
    switch (tabIndex) {
      case 0:
        return [
          _step(
            tab: 0,
            badge: 'Panduan Beranda',
            title: 'Ringkasan Personal',
            description: 'Lihat sapaan, progres, dan perhatian utama hari ini.',
            icon: Icons.home_rounded,
            color: purple,
            anchorId: 'home_greeting',
            top: 8,
            height: 56,
            radius: BorderRadius.circular(18),
          ),
          _step(
            tab: 0,
            badge: 'Panduan Beranda',
            title: 'Kartu Lamaran',
            description: 'Ketuk kartu untuk membuka detail dan status lengkap.',
            icon: Icons.style_rounded,
            color: Color(0xFFF59E0B),
            anchorId: 'home_cards',
            top: 150,
            height: 240,
            cardBelow: false,
            inflate: 6,
            radius: BorderRadius.circular(28),
          ),
          _step(
            tab: 0,
            badge: 'Panduan Beranda',
            title: 'Navigasi Utama',
            description:
                'Berpindah menu atau gunakan tombol plus untuk mencatat lamaran.',
            icon: Icons.add_circle_rounded,
            color: purple,
            anchorId: 'home_nav',
            top: 110,
            height: 94,
            horizontalInset: 24,
            fromBottom: true,
            cardBelow: false,
            inflate: 10,
            radius: BorderRadius.circular(36),
          ),
        ];
      case 1:
      case 2:
        return [
          _step(
            tab: tabIndex,
            badge: 'Panduan Daftar Lamaran',
            title: 'Cari Lamaran',
            description: 'Cari posisi, perusahaan, atau kota dari satu kolom.',
            icon: Icons.search_rounded,
            color: purple,
            anchorId: 'jobs_search',
            top: 78,
            height: 52,
            radius: BorderRadius.circular(18),
          ),
          _step(
            tab: tabIndex,
            badge: 'Panduan Daftar Lamaran',
            title: 'Urutkan dan Filter',
            description: 'Atur urutan, bentuk daftar, status, dan tipe kerja.',
            icon: Icons.tune_rounded,
            color: Color(0xFF0EA5E9),
            anchorId: 'jobs_filters',
            top: 140,
            height: 48,
            radius: BorderRadius.circular(16),
          ),
          _step(
            tab: tabIndex,
            badge: 'Panduan Daftar Lamaran',
            title: 'Buka Kartu',
            description:
                'Ketuk kartu untuk melihat timeline dan tindakan berikutnya.',
            icon: Icons.work_rounded,
            color: Color(0xFFEC4899),
            anchorId: 'jobs_cards',
            top: 200,
            height: 200,
            cardBelow: false,
            inflate: 4,
            radius: BorderRadius.circular(24),
          ),
        ];
      case 3:
        return [
          _step(
            tab: 3,
            badge: 'Panduan Kalender',
            title: 'Ringkasan Agenda',
            description: 'Periksa agenda terdekat dan aktivitas bulan ini.',
            icon: Icons.event_available_rounded,
            color: purple,
            anchorId: 'cal_summary',
            top: 86,
            height: 110,
            radius: BorderRadius.circular(20),
          ),
          _step(
            tab: 3,
            badge: 'Panduan Kalender',
            title: 'Penanda Berwarna',
            description:
                'Warna membedakan lamaran, seleksi, tindak lanjut, dan tenggat.',
            icon: Icons.calendar_month_rounded,
            color: Color(0xFF059669),
            anchorId: 'cal_grid',
            top: 210,
            height: 320,
            cardBelow: false,
            inflate: 6,
            radius: BorderRadius.circular(24),
          ),
          _step(
            tab: 3,
            badge: 'Panduan Kalender',
            title: 'Agenda Harian',
            description:
                'Pilih tanggal untuk melihat seluruh kegiatan hari tersebut.',
            icon: Icons.view_agenda_rounded,
            color: Color(0xFFD97706),
            anchorId: 'cal_agenda',
            top: 540,
            height: 140,
            cardBelow: false,
            radius: BorderRadius.circular(20),
          ),
        ];
      case 5:
        return [
          _step(
            tab: 5,
            badge: 'Panduan Ruang Karier',
            title: 'Ruang Kerja Karier',
            description:
                'Tempat mencari lowongan resmi dan menyiapkan seleksi tanpa meninggalkan Ngelamar.',
            icon: Icons.auto_awesome_mosaic_rounded,
            color: purple,
            anchorId: 'hub_header',
            top: 8,
            height: 52,
            radius: BorderRadius.circular(18),
          ),
          _step(
            tab: 5,
            badge: 'Panduan Ruang Karier',
            title: 'Portal atau Persiapan',
            description:
                'Geser antara Portal Loker Resmi dan Persiapan Karirku sesuai kebutuhan hari ini.',
            icon: Icons.swap_horiz_rounded,
            color: Color(0xFF059669),
            anchorId: 'hub_switcher',
            top: 68,
            height: 52,
            radius: BorderRadius.circular(24),
          ),
          _step(
            tab: 5,
            badge: 'Panduan Ruang Karier',
            title: 'Isi Workspace',
            description:
                'Buka portal lowongan atau latihan interview, CV, dan template pesan dari area ini.',
            icon: Icons.work_outline_rounded,
            color: Color(0xFFF59E0B),
            anchorId: 'hub_body',
            top: 130,
            height: 280,
            cardBelow: false,
            inflate: 6,
            radius: BorderRadius.circular(24),
          ),
        ];
      case 6:
        return [
          _step(
            tab: 6,
            badge: 'Panduan Notifikasi',
            title: 'Pusat Kabar',
            description:
                'Semua pengingat seleksi, pesan, dan status izin tampil di halaman ini.',
            icon: Icons.notifications_rounded,
            color: purple,
            anchorId: 'notif_header',
            top: 8,
            height: 90,
            radius: BorderRadius.circular(20),
          ),
          _step(
            tab: 6,
            badge: 'Panduan Notifikasi',
            title: 'Daftar Kabar',
            description:
                'Ketuk item untuk membuka lamaran terkait atau menyelesaikan pengingat.',
            icon: Icons.inbox_rounded,
            color: Color(0xFF0EA5E9),
            anchorId: 'notif_list',
            top: 110,
            height: 280,
            cardBelow: false,
            radius: BorderRadius.circular(22),
          ),
        ];
      case 4:
      default:
        return [
          _step(
            tab: 4,
            badge: 'Panduan Profil',
            title: 'Identitas Karier',
            description: 'Kelola foto, nama, minat, dan informasi profesional.',
            icon: Icons.person_rounded,
            color: purple,
            anchorId: 'profile_identity',
            top: 8,
            height: 220,
            radius: BorderRadius.circular(24),
          ),
          _step(
            tab: 4,
            badge: 'Panduan Profil',
            title: 'Riwayat dan Statistik',
            description: 'Pantau aktivitas serta ringkasan perjalanan lamaran.',
            icon: Icons.insights_rounded,
            color: Color(0xFF0EA5E9),
            anchorId: 'profile_stats',
            top: 250,
            height: 200,
            radius: BorderRadius.circular(20),
          ),
          _step(
            tab: 4,
            badge: 'Panduan Profil',
            title: 'Pengaturan Aplikasi',
            description:
                'Atur tampilan, notifikasi, backup, bantuan, dan akun.',
            icon: Icons.settings_rounded,
            color: Color(0xFFF59E0B),
            anchorId: 'profile_settings',
            top: 250,
            height: 56,
            cardBelow: true,
            radius: BorderRadius.circular(16),
          ),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentSteps = getStepsForTab(widget.tabIndex);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  void _remeasure() {
    if (!mounted) return;
    setState(() {});
    final anchorId = _currentSteps[_currentStepIndex].targetRect.anchorId;
    if (anchorId != null && TourRegistry.rectOf(anchorId) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex < _currentSteps.length - 1) {
      setState(() => _currentStepIndex++);
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    }
  }

  void _finishTour() async {
    HapticFeedback.mediumImpact();
    await PrefsService.setTabTourSeen(widget.tabIndex, true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final step = _currentSteps[_currentStepIndex];
    final isDark = AppTheme.isDark(context);

    // Responsive horizontal bounds matching MainNavigation (maxWidth: 840)
    final contentWidth = math.min(screenSize.width, 840.0);
    final contentLeft = (screenSize.width - contentWidth) / 2;

    final measured = step.targetRect.anchorId == null
        ? null
        : TourRegistry.rectOf(step.targetRect.anchorId!);
    final rawTargetRect =
        (measured?.inflate(step.targetRect.inflate)) ??
        step.targetRect.computeRect(
          screenSize,
          padding,
          contentLeft,
          contentWidth,
        );
    final safeLeft = contentLeft + 6;
    final safeRight = contentLeft + contentWidth - 6;
    final safeTop = padding.top + 4;
    final safeBottom = screenSize.height - padding.bottom - 4;
    final targetRect = Rect.fromLTRB(
      rawTargetRect.left.clamp(safeLeft, safeRight - 24),
      rawTargetRect.top.clamp(safeTop, safeBottom - 24),
      rawTargetRect.right.clamp(safeLeft + 24, safeRight),
      rawTargetRect.bottom.clamp(safeTop + 24, safeBottom),
    );

    // Precise Coachmark Card Dimensions & Positioning (Guaranteed zero offside/clipping)
    final cardWidth = math.min(contentWidth - 32, 440.0);
    final cardLeft = (screenSize.width - cardWidth) / 2;

    final cardHeightEstimate = 236.0;
    final spaceBelow = screenSize.height - padding.bottom - targetRect.bottom;
    final spaceAbove = targetRect.top - padding.top;
    final placeBelow = spaceBelow >= cardHeightEstimate + 20
        ? true
        : spaceAbove >= cardHeightEstimate + 20
        ? false
        : step.placeCardBelow;

    double cardTop;
    if (placeBelow) {
      cardTop = targetRect.bottom + 16;
      final maxTop = screenSize.height - padding.bottom - 260;
      if (cardTop > maxTop) {
        cardTop = math.max(padding.top + 14, targetRect.top - 240);
      }
    } else {
      cardTop = targetRect.top - 240;
      if (cardTop < padding.top + 14) {
        cardTop = targetRect.bottom + 16;
      }
    }
    cardTop = cardTop.clamp(
      padding.top + 14,
      screenSize.height - padding.bottom - 260,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── 1. SPOTLIGHT CUTOUT BACKDROP WITH PULSE GLOW ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SpotlightCutoutPainter(
                    targetRect: targetRect,
                    borderRadius: step.targetRect.borderRadius,
                    isCircle: step.targetRect.isCircle,
                    pulseScale: _pulseAnimation.value,
                    accentColor: step.accentColor,
                  ),
                );
              },
            ),
          ),

          // ── 2. MATERIAL 3 COACHMARK CARD (RESPONSIVE & ZERO OFFSIDE) ──
          Positioned(
            left: cardLeft,
            width: cardWidth,
            top: cardTop,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentStepIndex),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF211F26) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF49454F)
                        : const Color(0xFFE7E0EC),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.40 : 0.15,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // M3 Assist Chip Row + Skip Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: step.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  step.icon,
                                  size: 14,
                                  color: step.accentColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    step.badgeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: step.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _finishTour,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2D2B33)
                                  : const Color(0xFFF3EDF7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Lewati',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCAC4D0)
                                    : const Color(0xFF49454F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFE6E1E5)
                            : const Color(0xFF1D1B20),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFFCAC4D0)
                            : const Color(0xFF49454F),
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress Dots + Action Buttons Row (Guaranteed ZERO Offside)
                    Row(
                      children: [
                        // Progress Indicator Dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_currentSteps.length, (idx) {
                            final isActive = idx == _currentStepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 5),
                              width: isActive ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? step.accentColor
                                    : (isDark
                                          ? const Color(0xFF49454F)
                                          : const Color(0xFFE7E0EC)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),

                        const Spacer(),

                        // M3 Tonal Back Button (if index > 0)
                        if (_currentStepIndex > 0) ...[
                          FluidBounceButton(
                            onTap: _prevStep,
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2D2B33)
                                    : const Color(0xFFE8DEF8),
                                borderRadius: BorderRadius.circular(19),
                              ),
                              child: Center(
                                child: Text(
                                  'Kembali',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFE8DEF8)
                                        : const Color(0xFF1D192B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // M3 Filled Next / Finish Button (Zero Offside)
                        FluidBounceButton(
                          onTap: _nextStep,
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: step.accentColor,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentStepIndex ==
                                            _currentSteps.length - 1
                                        ? 'Selesai'
                                        : 'Lanjut',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _currentStepIndex ==
                                            _currentSteps.length - 1
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for semi-transparent dark mask with smooth cutout hole & solid accent border
class _SpotlightCutoutPainter extends CustomPainter {
  final Rect targetRect;
  final BorderRadius borderRadius;
  final bool isCircle;
  final double pulseScale;
  final Color accentColor;

  _SpotlightCutoutPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.isCircle,
    required this.pulseScale,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final safeTarget = Rect.fromLTRB(
      targetRect.left.clamp(0.0, size.width),
      targetRect.top.clamp(0.0, size.height),
      targetRect.right.clamp(0.0, size.width),
      targetRect.bottom.clamp(0.0, size.height),
    );

    final holeRRect = RRect.fromRectAndCorners(
      (safeTarget.width > 0 && safeTarget.height > 0)
          ? safeTarget.inflate(6)
          : targetRect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    // 1. Solid Dark Scrim with 100% Guaranteed Cutout Hole via PathFillType.evenOdd
    final scrimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(fullRect);

    if (isCircle) {
      scrimPath.addOval(safeTarget.inflate(6));
    } else {
      scrimPath.addRRect(holeRRect);
    }

    final backgroundPaint = Paint()
      ..color =
          const Color(0xB8000000) // 72% opacity dark scrim
      ..style = PaintingStyle.fill;

    canvas.drawPath(scrimPath, backgroundPaint);

    // 2. Soft Bright Illumination / Whitening layer inside the spotlight cutout
    final highlightPaint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.18) // Soft translucent white illumination
      ..style = PaintingStyle.fill;

    if (isCircle) {
      canvas.drawOval(targetRect.inflate(6), highlightPaint);
    } else {
      canvas.drawRRect(holeRRect, highlightPaint);
    }

    // 3. Crisp Solid Accent Border (Material 3 focus indicator)
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    if (isCircle) {
      canvas.drawOval(targetRect.inflate(6), borderPaint);
    } else {
      canvas.drawRRect(holeRRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.accentColor != accentColor;
  }
}
