import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prefs_service.dart';
import '../theme/app_theme.dart';
import 'apple_animations.dart';

/// Target area specification for the guided tour spotlight
class TourTargetRect {
  final Rect Function(
    Size screenSize,
    EdgeInsets padding,
    double contentLeft,
    double contentWidth,
  )
  computeRect;
  final BorderRadius borderRadius;
  final bool isCircle;

  const TourTargetRect({
    required this.computeRect,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.isCircle = false,
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
    double horizontalInset = 16,
    bool fromBottom = false,
    bool cardBelow = true,
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
        borderRadius: BorderRadius.circular(24),
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
            top: 12,
            height: 105,
          ),
          _step(
            tab: 0,
            badge: 'Panduan Beranda',
            title: 'Kartu Lamaran',
            description: 'Ketuk kartu untuk membuka detail dan status lengkap.',
            icon: Icons.style_rounded,
            color: Color(0xFFF59E0B),
            top: 132,
            height: 210,
            cardBelow: false,
          ),
          _step(
            tab: 0,
            badge: 'Panduan Beranda',
            title: 'Navigasi Utama',
            description:
                'Berpindah menu atau gunakan tombol plus untuk mencatat lamaran.',
            icon: Icons.add_circle_rounded,
            color: purple,
            top: 104,
            height: 82,
            horizontalInset: 28,
            fromBottom: true,
            cardBelow: false,
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
            top: 70,
            height: 58,
          ),
          _step(
            tab: tabIndex,
            badge: 'Panduan Daftar Lamaran',
            title: 'Urutkan dan Filter',
            description: 'Atur urutan, bentuk daftar, status, dan tipe kerja.',
            icon: Icons.tune_rounded,
            color: Color(0xFF0EA5E9),
            top: 132,
            height: 54,
          ),
          _step(
            tab: tabIndex,
            badge: 'Panduan Daftar Lamaran',
            title: 'Buka Kartu',
            description:
                'Ketuk kartu untuk melihat timeline dan tindakan berikutnya.',
            icon: Icons.work_rounded,
            color: Color(0xFFEC4899),
            top: 195,
            height: 190,
            cardBelow: false,
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
            top: 10,
            height: 132,
          ),
          _step(
            tab: 3,
            badge: 'Panduan Kalender',
            title: 'Penanda Berwarna',
            description:
                'Warna membedakan lamaran, seleksi, tindak lanjut, dan tenggat.',
            icon: Icons.calendar_month_rounded,
            color: Color(0xFF059669),
            top: 155,
            height: 330,
            cardBelow: false,
          ),
          _step(
            tab: 3,
            badge: 'Panduan Kalender',
            title: 'Agenda Harian',
            description:
                'Pilih tanggal untuk melihat seluruh kegiatan hari tersebut.',
            icon: Icons.view_agenda_rounded,
            color: Color(0xFFD97706),
            top: 500,
            height: 120,
            cardBelow: false,
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
            top: 10,
            height: 150,
          ),
          _step(
            tab: 4,
            badge: 'Panduan Profil',
            title: 'Riwayat dan Statistik',
            description: 'Pantau aktivitas serta ringkasan perjalanan lamaran.',
            icon: Icons.insights_rounded,
            color: Color(0xFF0EA5E9),
            top: 172,
            height: 190,
          ),
          _step(
            tab: 4,
            badge: 'Panduan Profil',
            title: 'Pengaturan Aplikasi',
            description:
                'Atur tampilan, notifikasi, backup, bantuan, dan akun.',
            icon: Icons.settings_rounded,
            color: Color(0xFFF59E0B),
            top: 380,
            height: 190,
            cardBelow: false,
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
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
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

    final rawTargetRect = step.targetRect.computeRect(
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

    double cardTop;
    if (step.placeCardBelow) {
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

          // ── 2. ANIMATED TARGET FOCUS POINTER BEACON ──
          Positioned(
            left: targetRect.center.dx - 18,
            top: step.placeCardBelow
                ? targetRect.bottom + 6
                : targetRect.top - 24,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    step.placeCardBelow
                        ? (_pulseAnimation.value - 1.0) * 8
                        : -(_pulseAnimation.value - 1.0) * 8,
                  ),
                  child: Icon(
                    step.placeCardBelow
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: step.accentColor,
                    size: 36,
                  ),
                );
              },
            ),
          ),

          // ── 3. MATERIAL 3 COACHMARK CARD (RESPONSIVE & ZERO OFFSIDE) ──
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
