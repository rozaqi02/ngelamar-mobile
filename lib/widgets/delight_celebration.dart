import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'waving_greeting_mascot.dart';

enum DelightPreset {
  homeSave,
  trackerSave,
  smartImport,
  bookmark,
  checklist,
  interviewShuffle,
  template,
  profile,
  cv,
  restore,
  sent,
  test,
  interviewHr,
  interviewUser,
  offering,
  accepted,
  rejected,
}

/// A short, non-blocking reward for meaningful successful actions.
class DelightCelebration {
  DelightCelebration._();

  static DelightPreset forStatus(String status) {
    switch (status) {
      case 'Tes / Psikotes':
        return DelightPreset.test;
      case 'Interview HR':
        return DelightPreset.interviewHr;
      case 'Interview User':
        return DelightPreset.interviewUser;
      case 'Offering':
        return DelightPreset.offering;
      case 'Diterima':
        return DelightPreset.accepted;
      case 'Ditolak':
        return DelightPreset.rejected;
      case 'Dikirim':
      default:
        return DelightPreset.sent;
    }
  }

  static IconData iconForStatus(String status) {
    switch (status) {
      case 'Tes / Psikotes':
        return Icons.fact_check_rounded;
      case 'Interview HR':
        return Icons.support_agent_rounded;
      case 'Interview User':
        return Icons.groups_rounded;
      case 'Offering':
        return Icons.workspace_premium_rounded;
      case 'Diterima':
        return Icons.emoji_events_rounded;
      case 'Ditolak':
        return Icons.favorite_border_rounded;
      case 'Dikirim':
      default:
        return Icons.send_rounded;
    }
  }

  static void show(
    BuildContext context, {
    required String message,
    Color accent = const Color(0xFF5C44E4),
    IconData icon = Icons.auto_awesome_rounded,
    DelightPreset preset = DelightPreset.homeSave,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(
        message: message,
        accent: accent,
        icon: icon,
        preset: preset,
        onComplete: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final String message;
  final Color accent;
  final IconData icon;
  final DelightPreset preset;
  final VoidCallback onComplete;

  const _CelebrationOverlay({
    required this.message,
    required this.accent,
    required this.icon,
    required this.preset,
    required this.onComplete,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.preset == DelightPreset.accepted ? 2300 : 2050,
      ),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _bounce(double t) => Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

  ({Offset offset, double rotation, double scale}) _motion(double t) {
    final enter = _bounce(t / 0.34);
    final wave = math.sin(t * math.pi * 5);
    switch (widget.preset) {
      case DelightPreset.homeSave:
        return (
          offset: Offset(0, 108 * (1 - enter)),
          rotation: wave * 0.018,
          scale: 0.72 + enter * 0.28,
        );
      case DelightPreset.trackerSave:
        return (
          offset: Offset(-130 * (1 - enter), 12 * (1 - enter)),
          rotation: -0.08 * (1 - enter),
          scale: 0.86 + enter * 0.14,
        );
      case DelightPreset.smartImport:
        return (
          offset: Offset(0, 28 * (1 - enter)),
          rotation: (1 - enter) * -0.55,
          scale: 0.5 + enter * 0.5,
        );
      case DelightPreset.bookmark:
        return (
          offset: Offset(0, 50 * (1 - enter)),
          rotation: wave * 0.035,
          scale: 0.7 + enter * 0.3 + math.sin(t * math.pi * 2) * 0.025,
        );
      case DelightPreset.checklist:
        return (
          offset: Offset(0, 92 * (1 - enter) - wave.abs() * 4),
          rotation: 0,
          scale: 0.68 + enter * 0.32,
        );
      case DelightPreset.interviewShuffle:
        return (
          offset: Offset(wave * 7 * (1 - t), 48 * (1 - enter)),
          rotation: wave * 0.045 * (1 - t),
          scale: 0.75 + enter * 0.25,
        );
      case DelightPreset.template:
        return (
          offset: Offset(88 * (1 - enter), 70 * (1 - enter)),
          rotation: 0.09 * (1 - enter),
          scale: 0.8 + enter * 0.2,
        );
      case DelightPreset.profile:
        return (
          offset: Offset(0, 64 * (1 - enter)),
          rotation: wave * 0.025,
          scale: 0.64 + enter * 0.36,
        );
      case DelightPreset.cv:
        return (
          offset: Offset(0, 72 * (1 - enter)),
          rotation: math.pi * 0.08 * (1 - enter),
          scale: 0.62 + enter * 0.38,
        );
      case DelightPreset.restore:
        return (
          offset: Offset(0, 45 * (1 - enter)),
          rotation: -math.pi * 0.65 * (1 - enter),
          scale: 0.6 + enter * 0.4,
        );
      case DelightPreset.sent:
        return (
          offset: Offset(-145 * (1 - enter), 80 * (1 - enter)),
          rotation: -0.16 * (1 - enter),
          scale: 0.78 + enter * 0.22,
        );
      case DelightPreset.test:
        return (
          offset: Offset(0, 55 * (1 - enter)),
          rotation: 0,
          scale: 0.65 + enter * 0.35 + math.sin(t * math.pi * 4) * 0.018,
        );
      case DelightPreset.interviewHr:
        return (
          offset: Offset(-70 * (1 - enter), 55 * (1 - enter)),
          rotation: wave * 0.025,
          scale: 0.72 + enter * 0.28,
        );
      case DelightPreset.interviewUser:
        return (
          offset: Offset(70 * (1 - enter), 55 * (1 - enter)),
          rotation: -wave * 0.025,
          scale: 0.56 + enter * 0.44,
        );
      case DelightPreset.offering:
        return (
          offset: Offset(0, 115 * (1 - enter) - wave.abs() * 5),
          rotation: wave * 0.02,
          scale: 0.68 + enter * 0.32,
        );
      case DelightPreset.accepted:
        return (
          offset: Offset(0, 135 * (1 - enter) - wave.abs() * 7),
          rotation: wave * 0.03,
          scale: 0.48 + enter * 0.52,
        );
      case DelightPreset.rejected:
        final soft = Curves.easeOutCubic.transform((t / 0.45).clamp(0.0, 1.0));
        return (
          offset: Offset(0, 34 * (1 - soft)),
          rotation: 0,
          scale: 0.9 + soft * 0.1,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final fadeOut =
                1 -
                Curves.easeInCubic.transform(
                  ((t - 0.78) / 0.22).clamp(0.0, 1.0),
                );
            final opacity =
                Curves.easeOut.transform((t / 0.10).clamp(0.0, 1.0)) * fadeOut;
            final motion = _motion(t);

            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _ArenaConfettiPainter(
                      progress: t,
                      accent: widget.accent,
                      preset: widget.preset,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.04),
                    child: Transform.translate(
                      offset: motion.offset,
                      child: Transform.rotate(
                        angle: motion.rotation,
                        child: Transform.scale(
                          scale: motion.scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 178,
                                    height: 138,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          widget.accent.withValues(alpha: 0.24),
                                          widget.accent.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: WavingGreetingMascot(
                                        width: 150,
                                        height: 118,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 3,
                                    top: 3,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: widget.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.accent.withValues(
                                              alpha: 0.38,
                                            ),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        widget.icon,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Transform.translate(
                                offset: const Offset(0, -6),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 290,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 17,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF19191B),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.24,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Large, arena-like confetti launched from both sides instead of a top drizzle.
class _ArenaConfettiPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final DelightPreset preset;

  const _ArenaConfettiPainter({
    required this.progress,
    required this.accent,
    required this.preset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isSoft = preset == DelightPreset.rejected;
    final isGold =
        preset == DelightPreset.accepted || preset == DelightPreset.offering;
    final palette = <Color>[
      accent,
      const Color(0xFFFFC928),
      const Color(0xFFFF5C5C),
      const Color(0xFF3DDC84),
      const Color(0xFF4CA7FF),
      if (isGold) const Color(0xFFFFE08A),
    ];
    final count = isSoft ? 16 : (preset == DelightPreset.accepted ? 44 : 34);
    final seed = preset.index * 29;

    for (var i = 0; i < count; i++) {
      final delay = (i % 9) * 0.018;
      final phase = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (phase <= 0) continue;

      final fromLeft = i.isEven;
      final seconds = phase * 1.72;
      final startX = fromLeft ? -18.0 : size.width + 18;
      final startY = size.height * (0.63 + ((i * 7 + seed) % 17) / 100);
      final horizontalSpeed = 95.0 + ((i * 43 + seed) % 205);
      final verticalSpeed = isSoft
          ? 170.0 + ((i * 29 + seed) % 120)
          : 285.0 + ((i * 53 + seed) % 315);
      final gravity = isSoft ? 300.0 : 445.0;
      final x = startX + (fromLeft ? 1 : -1) * horizontalSpeed * seconds;
      final y =
          startY - verticalSpeed * seconds + 0.5 * gravity * seconds * seconds;
      if (x < -40 || x > size.width + 40 || y > size.height + 45) continue;

      final width = 8.0 + ((i * 3 + seed) % 8);
      final height = 16.0 + ((i * 5 + seed) % 12);
      final flutter = math.sin(phase * math.pi * (5 + i % 4) + i) * 0.38;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((phase * (7 + i % 6)) + i * 0.7);
      canvas.scale(1, math.cos(phase * math.pi * 4 + i).abs() * 0.68 + 0.32);
      final paint = Paint()
        ..color = palette[(i + seed) % palette.length].withValues(
          alpha: (isSoft ? 0.62 : 0.96) * (1 - phase * 0.16),
        );
      final rect = Rect.fromCenter(
        center: Offset(flutter * 5, 0),
        width: width,
        height: height,
      );
      if (i % 5 == 0) {
        final path = Path()
          ..moveTo(0, -height / 2)
          ..lineTo(width / 2, 0)
          ..lineTo(0, height / 2)
          ..lineTo(-width / 2, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.preset != preset;
}
