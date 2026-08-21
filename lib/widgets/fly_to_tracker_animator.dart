import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper to trigger a delightful Fly-to-Tracker parabolic particle animation
/// from the saved job card to the bottom navigation bar tracker tab.
class FlyToTrackerAnimator {
  static void runFlyAnimation({
    required BuildContext context,
    GlobalKey? sourceKey,
    Offset? startOffset,
    String? companyName,
    Color accentColor = const Color(0xFF5C44E4),
  }) {
    try {
      Offset? startPos = startOffset;
      if (startPos == null && sourceKey != null) {
        final renderBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.attached) {
          startPos = renderBox.localToGlobal(Offset.zero);
        }
      }

      final size = MediaQuery.of(context).size;
      startPos ??= Offset(size.width * 0.8, size.height * 0.4);

      // Destination: bottom navigation bar tab "Lamaran" (approx center-left at 50% width on 5 items)
      final endPos = Offset(size.width * 0.50, size.height - 55);

      final overlay = Overlay.of(context, rootOverlay: true);
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (ctx) => _FlyParticleWidget(
          startPos: startPos!,
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
      // Fallback gracefully
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
      duration: const Duration(milliseconds: 700),
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

        // Quadratic Bezier curve calculation with an obvious arched flight trajectory
        final controlPoint = Offset(
          (widget.startPos.dx + widget.endPos.dx) / 2 - 60,
          math.min(widget.startPos.dy, widget.endPos.dy) - 120,
        );

        final x = (1 - t) * (1 - t) * widget.startPos.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * widget.endPos.dx;

        final y = (1 - t) * (1 - t) * widget.startPos.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * widget.endPos.dy;

        final scale = (1.25 - (t * 0.70)).clamp(0.4, 1.35);
        final opacity = (1.0 - (t * 0.25)).clamp(0.0, 1.0);
        final rotation = t * math.pi * 1.8;

        return Positioned(
          left: x - 45,
          top: y - 20,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.65),
                            blurRadius: 18,
                            spreadRadius: 3,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
                          if (widget.companyName != null && widget.companyName!.isNotEmpty && t < 0.5) ...[
                            const SizedBox(width: 8),
                            Text(
                              widget.companyName!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                decoration: TextDecoration.none,
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
          ),
        );
      },
    );
  }
}
