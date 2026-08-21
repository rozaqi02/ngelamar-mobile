import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper to trigger a delightful Fly-to-Tracker parabolic particle animation
/// from the saved job card to the bottom navigation bar tracker tab.
class FlyToTrackerAnimator {
  static void runFlyAnimation({
    required BuildContext context,
    required GlobalKey sourceKey,
    String? companyName,
    Color accentColor = const Color(0xFF5C44E4),
  }) {
    try {
      final renderBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final overlay = Overlay.of(context);
      final startPos = renderBox.localToGlobal(Offset.zero);
      final size = MediaQuery.of(context).size;

      // Destination: bottom navigation bar Daftar Lamaran icon
      final endPos = Offset(size.width * 0.40, size.height - 65);

      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (ctx) => _FlyParticleWidget(
          startPos: startPos,
          endPos: endPos,
          companyName: companyName,
          accentColor: accentColor,
          onComplete: () {
            entry.remove();
            HapticFeedback.selectionClick();
          },
        ),
      );

      overlay.insert(entry);
    } catch (_) {
      // Fallback gracefully if overlay not accessible
    }
  }
}

class _FlyParticleWidget extends StatefulWidget {
  final Offset startPos;
  final Offset endPos;
  final String? companyName;
  final Color accentColor;
  final VoidCallback onComplete;

  const _FlyParticleWidget({
    required this.startPos,
    required this.endPos,
    required this.companyName,
    required this.accentColor,
    required this.onComplete,
  });

  @override
  State<_FlyParticleWidget> createState() => _FlyParticleWidgetState();
}

class _FlyParticleWidgetState extends State<_FlyParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;

        // Quadratic Bezier curve calculation for a natural arched flight path
        final controlPoint = Offset(
          (widget.startPos.dx + widget.endPos.dx) / 2 - 30,
          math.min(widget.startPos.dy, widget.endPos.dy) - 50,
        );

        final x = (1 - t) * (1 - t) * widget.startPos.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * widget.endPos.dx;

        final y = (1 - t) * (1 - t) * widget.startPos.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * widget.endPos.dy;

        final scale = (1.15 - (t * 0.75)).clamp(0.2, 1.2);
        final opacity = (1.0 - (t * 0.35)).clamp(0.0, 1.0);
        final rotation = t * math.pi * 1.5;

        return Positioned(
          left: x,
          top: y,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_special_rounded, color: Colors.white, size: 16),
                        if (widget.companyName != null && widget.companyName!.isNotEmpty && t < 0.4) ...[
                          const SizedBox(width: 6),
                          Text(
                            widget.companyName!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
