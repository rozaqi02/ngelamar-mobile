import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mascot_state_spec.dart';
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

bool _usesStatusMascot(DelightPreset preset) => switch (preset) {
  DelightPreset.trackerSave ||
  DelightPreset.sent ||
  DelightPreset.test ||
  DelightPreset.interviewHr ||
  DelightPreset.interviewUser ||
  DelightPreset.offering ||
  DelightPreset.accepted ||
  DelightPreset.rejected => true,
  _ => false,
};

/// A short, non-blocking reward for meaningful successful actions.
class DelightCelebration {
  DelightCelebration._();

  static DelightPreset forStatus(String status) {
    switch (MascotStateSpec.forStatus(status).pose) {
      case MascotPose.testing:
        return DelightPreset.test;
      case MascotPose.interviewHr:
        return DelightPreset.interviewHr;
      case MascotPose.interviewUser:
        return DelightPreset.interviewUser;
      case MascotPose.offering:
        return DelightPreset.offering;
      case MascotPose.accepted:
        return DelightPreset.accepted;
      case MascotPose.rejected:
        return DelightPreset.rejected;
      case MascotPose.saved:
      case MascotPose.applied:
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

  double _verticalJourney(double t, double viewportHeight) {
    final travel = viewportHeight * 0.72;
    if (t < 0.30) {
      final enter = Curves.easeOutBack.transform((t / 0.30).clamp(0.0, 1.0));
      return travel * (1 - enter);
    }
    if (t > 0.74) {
      final exit = Curves.easeInCubic.transform(
        ((t - 0.74) / 0.26).clamp(0.0, 1.0),
      );
      return travel * exit;
    }
    return 0;
  }

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
          offset: Offset(
            wave * 8 * enter,
            92 * (1 - enter) - wave.abs() * 7 * enter,
          ),
          rotation: wave * 0.035 * enter,
          scale: 0.62 + enter * 0.38,
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
            final motion = _motion(t);

            return LayoutBuilder(
              builder: (context, constraints) {
                final jumpY = _verticalJourney(t, constraints.maxHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _ArenaConfettiPainter(
                        progress: t,
                        accent: widget.accent,
                        preset: widget.preset,
                      ),
                    ),
                    if (widget.preset == DelightPreset.rejected)
                      CustomPaint(painter: _RejectedTearsPainter(progress: t)),
                    Align(
                      alignment: const Alignment(0, -0.04),
                      child: Transform.translate(
                        offset: motion.offset + Offset(0, jumpY),
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
                                      width: 220,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            widget.accent.withValues(
                                              alpha: 0.24,
                                            ),
                                            widget.accent.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: _usesStatusMascot(widget.preset)
                                            ? _StatusCelebrationMascot(
                                                preset: widget.preset,
                                                progress: t,
                                                width: 188,
                                                height: 148,
                                              )
                                            : const WavingGreetingMascot(
                                                width: 188,
                                                height: 148,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 7,
                                      top: 5,
                                      child: Container(
                                        width: 46,
                                        height: 46,
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
                                          size: 23,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -10),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusCelebrationMascot extends StatelessWidget {
  final DelightPreset preset;
  final double progress;
  final double width;
  final double height;

  const _StatusCelebrationMascot({
    required this.preset,
    required this.progress,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _StatusMascotPainter(preset: preset, progress: progress),
    );
  }
}

/// Seven deliberately different vector poses for recruitment-stage feedback.
/// The props and body language communicate the status before the label is read.
class _StatusMascotPainter extends CustomPainter {
  final DelightPreset preset;
  final double progress;

  const _StatusMascotPainter({required this.preset, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 240, size.height / 190);
    final dx = (size.width - 240 * scale) / 2;
    final dy = (size.height - 190 * scale) / 2;
    final beat = math.sin(progress * math.pi * 8);
    final action = Curves.easeOutBack.transform(
      ((progress - 0.28) / 0.22).clamp(0.0, 1.0),
    );

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final ink = const Color(0xFF19191B);
    final outline = Paint()
      ..color = ink
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final bodyCenter = Offset(120, 99 + beat * 1.8);

    _drawLegs(canvas, outline, bodyCenter, action, beat);
    _drawArms(canvas, outline, bodyCenter, action, beat);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 122, height: 82),
      const Radius.circular(17),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF635BFF).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawRRect(bodyRect, outline..strokeWidth = 4);

    final fold = Path()
      ..moveTo(bodyCenter.dx - 59, bodyCenter.dy - 39)
      ..lineTo(bodyCenter.dx, bodyCenter.dy + 8)
      ..lineTo(bodyCenter.dx + 59, bodyCenter.dy - 39);
    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0xFFD8D2C8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    _drawFace(canvas, bodyCenter, ink, beat);
    _drawProp(canvas, bodyCenter, outline, action, beat);
    canvas.restore();
  }

  void _drawLegs(
    Canvas canvas,
    Paint outline,
    Offset center,
    double action,
    double beat,
  ) {
    var leftFoot = const Offset(89, 178);
    var rightFoot = const Offset(151, 178);
    if (preset == DelightPreset.accepted) {
      leftFoot = Offset(79 - action * 8, 170 - action * 8 - beat.abs() * 4);
      rightFoot = Offset(161 + action * 8, 170 - action * 8 - beat.abs() * 4);
    } else if (preset == DelightPreset.sent) {
      leftFoot = Offset(82, 179);
      rightFoot = Offset(158 + action * 9, 169);
    } else if (preset == DelightPreset.rejected) {
      leftFoot = const Offset(99, 180);
      rightFoot = const Offset(143, 180);
    } else if (preset == DelightPreset.interviewUser) {
      leftFoot = Offset(83 - beat * 2, 177);
      rightFoot = Offset(157 + beat * 2, 177);
    } else if (preset == DelightPreset.trackerSave) {
      leftFoot = Offset(80 - action * 5, 175 - beat.abs() * 3);
      rightFoot = Offset(160 + action * 5, 175 - beat.abs() * 3);
    }

    canvas.drawLine(Offset(center.dx - 25, center.dy + 38), leftFoot, outline);
    canvas.drawLine(Offset(center.dx + 25, center.dy + 38), rightFoot, outline);
    final shoe = Paint()..color = const Color(0xFF19191B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftFoot, width: 25, height: 10),
        const Radius.circular(5),
      ),
      shoe,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightFoot, width: 25, height: 10),
        const Radius.circular(5),
      ),
      shoe,
    );
  }

  void _drawArms(
    Canvas canvas,
    Paint outline,
    Offset c,
    double action,
    double beat,
  ) {
    Offset leftHand;
    Offset rightHand;
    switch (preset) {
      case DelightPreset.trackerSave:
        leftHand = Offset(81 - action * 7, 128 - beat.abs() * 3);
        rightHand = Offset(159 + action * 7, 128 - beat.abs() * 3);
      case DelightPreset.sent:
        leftHand = Offset(54, 118 + beat * 2);
        rightHand = Offset(194 + action * 12, 66 - action * 12);
      case DelightPreset.test:
        leftHand = const Offset(65, 124);
        rightHand = Offset(183, 112 - beat * 2);
      case DelightPreset.interviewHr:
        leftHand = const Offset(62, 128);
        rightHand = Offset(184 + beat * 4, 50 - beat * 7);
      case DelightPreset.interviewUser:
        leftHand = Offset(50 - beat * 3, 91);
        rightHand = Offset(190 + beat * 3, 91);
      case DelightPreset.offering:
        leftHand = Offset(86, 121 - action * 10);
        rightHand = Offset(154, 121 - action * 10);
      case DelightPreset.accepted:
        leftHand = Offset(57 - action * 8, 48 - action * 14 - beat.abs() * 3);
        rightHand = Offset(183 + action * 8, 48 - action * 14 - beat.abs() * 3);
      case DelightPreset.rejected:
        leftHand = Offset(58, 151 + beat.abs() * 2);
        rightHand = Offset(182, 151 + beat.abs() * 2);
      default:
        leftHand = const Offset(60, 120);
        rightHand = const Offset(180, 120);
    }

    canvas.drawLine(Offset(c.dx - 57, c.dy + 6), leftHand, outline);
    canvas.drawLine(Offset(c.dx + 57, c.dy + 6), rightHand, outline);
    canvas.drawCircle(leftHand, 6, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawCircle(leftHand, 6, outline..strokeWidth = 3);
    canvas.drawCircle(rightHand, 6, Paint()..color = const Color(0xFFFFFEFB));
    canvas.drawCircle(rightHand, 6, outline..strokeWidth = 3);
  }

  void _drawFace(Canvas canvas, Offset c, Color ink, double beat) {
    final face = Paint()
      ..color = ink
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final left = Offset(c.dx - 22, c.dy - 8);
    final right = Offset(c.dx + 22, c.dy - 8);

    if (preset == DelightPreset.rejected) {
      canvas.drawLine(left.translate(-5, -5), left.translate(5, -1), face);
      canvas.drawLine(right.translate(-5, -1), right.translate(5, -5), face);
      canvas.drawCircle(left.translate(0, 4), 3.8, Paint()..color = ink);
      canvas.drawCircle(right.translate(0, 4), 3.8, Paint()..color = ink);
      final frown = Path()
        ..moveTo(c.dx - 10, c.dy + 18)
        ..quadraticBezierTo(c.dx, c.dy + 8, c.dx + 10, c.dy + 18);
      canvas.drawPath(frown, face);
      final tear = Paint()
        ..color = const Color(0xFF55B8FF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(left.translate(0, 10), left.translate(-2, 31), tear);
      canvas.drawLine(right.translate(0, 10), right.translate(2, 31), tear);
      return;
    }

    if (preset == DelightPreset.trackerSave ||
        preset == DelightPreset.accepted ||
        preset == DelightPreset.offering) {
      final leftJoy = Path()
        ..moveTo(left.dx - 6, left.dy + 2)
        ..quadraticBezierTo(left.dx, left.dy - 6, left.dx + 6, left.dy + 2);
      final rightJoy = Path()
        ..moveTo(right.dx - 6, right.dy + 2)
        ..quadraticBezierTo(right.dx, right.dy - 6, right.dx + 6, right.dy + 2);
      canvas.drawPath(leftJoy, face);
      canvas.drawPath(rightJoy, face);
    } else if (preset == DelightPreset.test) {
      canvas.drawCircle(left, 4, Paint()..color = ink);
      canvas.drawCircle(right, 4, Paint()..color = ink);
      canvas.drawLine(left.translate(-6, -8), left.translate(5, -6), face);
      canvas.drawLine(right.translate(-5, -6), right.translate(6, -8), face);
    } else {
      canvas.drawCircle(left, 4.5, Paint()..color = ink);
      canvas.drawCircle(right, 4.5, Paint()..color = ink);
      canvas.drawCircle(
        left.translate(-1.4, -1.4),
        1.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        right.translate(-1.4, -1.4),
        1.5,
        Paint()..color = Colors.white,
      );
    }

    final smile = Path()
      ..moveTo(c.dx - 10, c.dy + 13)
      ..quadraticBezierTo(c.dx, c.dy + 23 + beat.abs(), c.dx + 10, c.dy + 13);
    canvas.drawPath(smile, face);
  }

  void _drawProp(
    Canvas canvas,
    Offset c,
    Paint outline,
    double action,
    double beat,
  ) {
    switch (preset) {
      case DelightPreset.trackerSave:
        final inboxY = 151 - action * 5 - beat.abs() * 2;
        final paperX = 174 + beat * 2;
        final paperY = inboxY - 38 - action * 4;
        final inbox = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(120, inboxY), width: 82, height: 40),
          const Radius.circular(8),
        );
        canvas.drawRRect(inbox, Paint()..color = const Color(0xFFBDF39A));
        canvas.drawRRect(inbox, outline..strokeWidth = 3);
        final paper = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(paperX, paperY),
            width: 42,
            height: 44,
          ),
          const Radius.circular(5),
        );
        canvas.drawRRect(paper, Paint()..color = Colors.white);
        canvas.drawRRect(paper, outline..strokeWidth = 3);
        canvas.drawLine(
          Offset(paperX - 10, paperY),
          Offset(paperX + 10, paperY),
          outline,
        );
        final plusPaint = Paint()
          ..color = const Color(0xFF22B573)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(paperX, paperY - 10),
          Offset(paperX, paperY + 10),
          plusPaint,
        );
        canvas.drawLine(
          Offset(paperX - 10, paperY),
          Offset(paperX + 10, paperY),
          plusPaint,
        );
      case DelightPreset.sent:
        final plane = Path()
          ..moveTo(181, 51)
          ..lineTo(225, 35 - action * 3)
          ..lineTo(204, 70)
          ..lineTo(198, 55)
          ..close();
        canvas.drawPath(plane, Paint()..color = const Color(0xFF5C44E4));
        canvas.drawPath(plane, outline..strokeWidth = 3);
      case DelightPreset.test:
        final board = RRect.fromRectAndRadius(
          const Rect.fromLTWH(137, 91, 50, 58),
          const Radius.circular(6),
        );
        canvas.drawRRect(board, Paint()..color = const Color(0xFFFFD65A));
        canvas.drawRRect(board, outline..strokeWidth = 3);
        canvas.drawLine(
          const Offset(148, 109),
          const Offset(177, 109),
          outline,
        );
        canvas.drawLine(
          const Offset(148, 122),
          const Offset(172, 122),
          outline,
        );
        canvas.drawLine(
          const Offset(148, 135),
          const Offset(177, 135),
          outline,
        );
      case DelightPreset.interviewHr:
        canvas.drawCircle(
          Offset(185, 48 + beat * 3),
          11,
          Paint()..color = const Color(0xFFEC4899),
        );
        canvas.drawCircle(
          Offset(185, 48 + beat * 3),
          11,
          outline..strokeWidth = 3,
        );
        canvas.drawLine(
          Offset(185, 59 + beat * 3),
          Offset(185, 77 + beat * 2),
          outline,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(42, 34, 57, 28),
            const Radius.circular(12),
          ),
          Paint()..color = const Color(0xFFDDF7E9),
        );
        canvas.drawCircle(
          const Offset(58, 48),
          3,
          Paint()..color = const Color(0xFF34D399),
        );
        canvas.drawCircle(
          const Offset(70, 48),
          3,
          Paint()..color = const Color(0xFF34D399),
        );
        canvas.drawCircle(
          const Offset(82, 48),
          3,
          Paint()..color = const Color(0xFF34D399),
        );
      case DelightPreset.interviewUser:
        canvas.drawCircle(
          const Offset(45, 84),
          15,
          Paint()..color = const Color(0xFF7DD3FC),
        );
        canvas.drawCircle(
          const Offset(195, 84),
          15,
          Paint()..color = const Color(0xFFA78BFA),
        );
        canvas.drawLine(
          const Offset(66, 91),
          const Offset(92, 103),
          outline..strokeWidth = 4,
        );
        canvas.drawLine(const Offset(174, 91), const Offset(148, 103), outline);
        canvas.drawCircle(
          const Offset(120, 107),
          10,
          Paint()..color = const Color(0xFFF8BA38),
        );
      case DelightPreset.offering:
        final contract = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(120, 130 - action * 12),
            width: 72,
            height: 51,
          ),
          const Radius.circular(7),
        );
        canvas.drawRRect(contract, Paint()..color = const Color(0xFFFFF2B7));
        canvas.drawRRect(contract, outline..strokeWidth = 3);
        canvas.drawLine(
          Offset(100, 120 - action * 12),
          Offset(140, 120 - action * 12),
          outline,
        );
        canvas.drawCircle(
          Offset(143, 137 - action * 12),
          8,
          Paint()..color = const Color(0xFFF8BA38),
        );
      case DelightPreset.accepted:
        final cupY = 24 - action * 8 - beat.abs() * 3;
        final trophy = Path()
          ..moveTo(94, cupY)
          ..lineTo(146, cupY)
          ..lineTo(137, cupY + 37)
          ..quadraticBezierTo(120, cupY + 49, 103, cupY + 37)
          ..close();
        canvas.drawPath(trophy, Paint()..color = const Color(0xFFFFC928));
        canvas.drawPath(trophy, outline..strokeWidth = 3);
        canvas.drawLine(
          Offset(120, cupY + 44),
          Offset(120, cupY + 61),
          outline,
        );
        canvas.drawLine(
          Offset(104, cupY + 61),
          Offset(136, cupY + 61),
          outline,
        );
      case DelightPreset.rejected:
        final heart = Path()
          ..moveTo(120, 55)
          ..cubicTo(92, 32, 75, 68, 120, 92)
          ..cubicTo(165, 68, 148, 32, 120, 55)
          ..close();
        canvas.drawPath(heart, Paint()..color = const Color(0xFFFF6B72));
        final crack = Path()
          ..moveTo(121, 51)
          ..lineTo(113, 64)
          ..lineTo(124, 69)
          ..lineTo(116, 82);
        canvas.drawPath(crack, outline..strokeWidth = 3);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusMascotPainter oldDelegate) =>
      oldDelegate.preset != preset || oldDelegate.progress != progress;
}

/// A playful exaggerated sadness effect for rejected applications. Tears fall
/// from the mascot at centre and collect as a small animated wave at the foot
/// of the screen; both arrive and leave by motion, never opacity.
class _RejectedTearsPainter extends CustomPainter {
  final double progress;

  const _RejectedTearsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final arrive = Curves.easeOutCubic.transform(
      ((progress - 0.22) / 0.22).clamp(0.0, 1.0),
    );
    final leave =
        1 -
        Curves.easeInCubic.transform(
          ((progress - 0.76) / 0.24).clamp(0.0, 1.0),
        );
    final strength = math.min(arrive, leave).clamp(0.0, 1.0);
    if (strength <= 0) return;

    const tearColor = Color(0xFF55B8FF);
    final tearPaint = Paint()
      ..color = tearColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final lane = ((i * 17) % 35) - 17;
      final phase = (progress * 3.2 + i * 0.11) % 1.0;
      final x = size.width / 2 + side * (18 + lane.abs() * 0.7);
      final startY = size.height * 0.43;
      final y = startY + phase * size.height * 0.5;
      canvas.drawLine(Offset(x, y), Offset(x + side * 2, y + 16), tearPaint);
    }

    final floodHeight = 86 * strength;
    final waterPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width + 12; x += 12) {
      final wave = math.sin(x / 26 + progress * math.pi * 8) * 7;
      final y = size.height - floodHeight + wave;
      if (x == 0) {
        waterPath.lineTo(x, y);
      } else {
        waterPath.lineTo(x, y);
      }
    }
    waterPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      waterPath,
      Paint()..color = tearColor.withValues(alpha: 0.78),
    );
  }

  @override
  bool shouldRepaint(covariant _RejectedTearsPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
