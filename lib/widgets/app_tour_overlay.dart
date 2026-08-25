import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prefs_service.dart';
import '../theme/app_theme.dart';
import 'apple_animations.dart';

/// Target area specification for the guided tour spotlight
class TourTargetRect {
  final Rect Function(Size screenSize, EdgeInsets padding) computeRect;
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
  final bool placeCardBelow; // true: card below target, false: card above target

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

/// MyTelkomsel / Gojek style Interactive Guided Tour Overlay.
/// Takes over the application, switches tabs programmatically,
/// highlights actual UI elements with cutout spotlights and pulse glow rings,
/// and walks users through every core feature seamlessly.
class AppTourOverlay extends StatefulWidget {
  final Function(int tabIndex) onSwitchTab;
  final VoidCallback onFinish;

  const AppTourOverlay({
    super.key,
    required this.onSwitchTab,
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

  static final List<AppTourStep> steps = [
    // Step 1: Beranda - Tumpukan Kartu Lamaran
    AppTourStep(
      targetTabIndex: 0,
      badgeText: 'Langkah 1/5 • Beranda',
      title: 'Tumpukan Kartu Lamaran',
      description:
          'Semua lowongan yang kamu catat tersusun rapi di sini. Ketuk kartu untuk melihat progres, status seleksi, dan aksi follow-up cepat.',
      icon: Icons.style_rounded,
      accentColor: const Color(0xFFF59E0B),
      placeCardBelow: false,
      targetRect: TourTargetRect(
        computeRect: (size, pad) {
          // Highlight the primary job card stack in Dashboard
          final top = pad.top + 260;
          return Rect.fromLTWH(16, top, size.width - 32, 230);
        },
        borderRadius: BorderRadius.circular(28),
      ),
    ),

    // Step 2: Beranda - Filter & Pencarian
    AppTourStep(
      targetTabIndex: 0,
      badgeText: 'Langkah 2/5 • Filter & Cari',
      title: 'Filter & Cari Cepat',
      description:
          'Saring lowongan kerja idamanmu atau lakukan pencarian instan dengan tombol Filter dan Pencarian di pojok kanan atas.',
      icon: Icons.tune_rounded,
      accentColor: const Color(0xFF0288D1),
      placeCardBelow: true,
      targetRect: TourTargetRect(
        computeRect: (size, pad) {
          final top = pad.top + 74;
          return Rect.fromLTWH(size.width - 116, top, 96, 46);
        },
        borderRadius: BorderRadius.circular(23),
      ),
    ),

    // Step 3: Portal Loker Resmi & Persiapan Karirku
    AppTourStep(
      targetTabIndex: 1,
      badgeText: 'Langkah 3/5 • Portal & Karir',
      title: 'Portal Loker & Persiapan Karir',
      description:
          'Jelajahi lowongan terverifikasi di Portal Loker Resmi, serta akses panduan wawancara dan simulasi gaji di tab Persiapan Karirku.',
      icon: Icons.travel_explore_rounded,
      accentColor: const Color(0xFF10B981),
      placeCardBelow: true,
      targetRect: TourTargetRect(
        computeRect: (size, pad) {
          final top = pad.top + 10;
          return Rect.fromLTWH(18, top, size.width - 36, 52);
        },
        borderRadius: BorderRadius.circular(26),
      ),
    ),

    // Step 4: Daftar Lamaranku - Pelacak Lengkap
    AppTourStep(
      targetTabIndex: 2,
      badgeText: 'Langkah 4/5 • Daftar Lamaranku',
      title: 'Manajemen Status Lengkap',
      description:
          'Pantau riwayat berkas dari Dikirim, Tes / Psikotes, Interview HR, hingga Penawaran Gaji (Offering) dalam tampilan List atau Grid.',
      icon: Icons.dashboard_customize_rounded,
      accentColor: const Color(0xFF8B5CF6),
      placeCardBelow: true,
      targetRect: TourTargetRect(
        computeRect: (size, pad) {
          final top = pad.top + 120;
          return Rect.fromLTWH(16, top, size.width - 32, 48);
        },
        borderRadius: BorderRadius.circular(22),
      ),
    ),

    // Step 5: Tombol Tambah Lamaran (+)
    AppTourStep(
      targetTabIndex: 2,
      badgeText: 'Langkah 5/5 • Catat Lamaran',
      title: 'Tombol Aksi Cepat (+)',
      description:
          'Catat lamaran baru dalam hitungan detik. Mendukung Mode Cepat, autofill dari tautan loker, dan lampiran dokumen PDF CV.',
      icon: Icons.add_circle_rounded,
      accentColor: const Color(0xFFEC4899),
      placeCardBelow: true,
      targetRect: TourTargetRect(
        computeRect: (size, pad) {
          final top = pad.top + 12;
          return Rect.fromLTWH(size.width - 64, top, 46, 46);
        },
        borderRadius: BorderRadius.circular(23),
        isCircle: true,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial switch to first step tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSwitchTab(steps[0].targetTabIndex);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex < steps.length - 1) {
      final nextIdx = _currentStepIndex + 1;
      setState(() => _currentStepIndex = nextIdx);
      widget.onSwitchTab(steps[nextIdx].targetTabIndex);
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex > 0) {
      final prevIdx = _currentStepIndex - 1;
      setState(() => _currentStepIndex = prevIdx);
      widget.onSwitchTab(steps[prevIdx].targetTabIndex);
    }
  }

  void _finishTour() async {
    HapticFeedback.mediumImpact();
    await PrefsService.setAppTourSeen(true);
    widget.onSwitchTab(0); // Return to Home
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final step = steps[_currentStepIndex];
    final isDark = AppTheme.isDark(context);

    final targetRect = step.targetRect.computeRect(screenSize, padding);

    // Precise Coachmark Card Positioning (Guaranteed zero offside/clipping)
    double cardTop;
    if (step.placeCardBelow) {
      cardTop = targetRect.bottom + 16;
      final maxTop = screenSize.height - padding.bottom - 245;
      if (cardTop > maxTop) {
        cardTop = math.max(padding.top + 14, targetRect.top - 225);
      }
    } else {
      cardTop = targetRect.top - 225;
      if (cardTop < padding.top + 14) {
        cardTop = targetRect.bottom + 16;
      }
    }
    cardTop = cardTop.clamp(padding.top + 14, screenSize.height - padding.bottom - 245);

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
                        : -( _pulseAnimation.value - 1.0) * 8,
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

          // ── 3. MATERIAL YOU (MATERIAL 3) COACHMARK CARD ──
          Positioned(
            left: 16,
            right: 16,
            top: cardTop,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentStepIndex),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
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
                      color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // M3 Assist Chip Row + Skip
                    Row(
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
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFCAC4D0)
                            : const Color(0xFF49454F),
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Progress Dots + Action Buttons Row
                    Row(
                      children: [
                        // Progress Indicator Dots
                        Row(
                          children: List.generate(steps.length, (idx) {
                            final isActive = idx == _currentStepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 5),
                              width: isActive ? 20 : 6,
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
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2D2B33)
                                    : const Color(0xFFE8DEF8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'Kembali',
                                  style: TextStyle(
                                    fontSize: 13,
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

                        // M3 Filled Next / Finish Button
                        FluidBounceButton(
                          onTap: _nextStep,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: step.accentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentStepIndex == steps.length - 1
                                        ? 'Mulai Gunakan'
                                        : 'Lanjut',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _currentStepIndex == steps.length - 1
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 16,
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

    // 1. Solid Dark Scrim with Cutout Hole
    final backgroundPaint = Paint()
      ..color = const Color(0xB8000000) // 72% opacity dark scrim
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()..addRect(fullRect);

    final holeRRect = RRect.fromRectAndCorners(
      targetRect.inflate(6),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    final holePath = Path();
    if (isCircle) {
      holePath.addOval(targetRect.inflate(6));
    } else {
      holePath.addRRect(holeRRect);
    }

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);

    // 2. Crisp Solid Accent Border (Material 3 focus indicator)
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

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
