import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple iOS Bouncy Touch Feedback Widget
/// Adds a subtle spring-scale effect when tapped or pressed.
class AppleBouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final String? semanticLabel;

  const AppleBouncyCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.965,
    this.duration = const Duration(milliseconds: 140),
    this.semanticLabel,
  });

  @override
  State<AppleBouncyCard> createState() => _AppleBouncyCardState();
}

class _AppleBouncyCardState extends State<AppleBouncyCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: !reduceMotion && _isPressed ? widget.scaleFactor : 1.0,
          duration: reduceMotion ? Duration.zero : widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Ultra-fluid Bouncy Scale Button with Spring Curve & Haptic Feedback.
/// Wrap any Button, Chip, Pill, or Icon with fluid micro-spring bounce on tap.
class FluidBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final bool hapticEnabled;
  final String? semanticLabel;
  final bool? selected;

  const FluidBounceButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.935,
    this.duration = const Duration(milliseconds: 130),
    this.hapticEnabled = true,
    this.semanticLabel,
    this.selected,
  });

  @override
  State<FluidBounceButton> createState() => _FluidBounceButtonState();
}

class _FluidBounceButtonState extends State<FluidBounceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) {
                if (widget.hapticEnabled) HapticFeedback.selectionClick();
                setState(() => _isPressed = true);
              },
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: !reduceMotion && _isPressed ? widget.scaleFactor : 1.0,
          duration: reduceMotion ? Duration.zero : widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// YouTube Mobile App Style Entrance Animation
/// Elements slide up smoothly from bottom (35px) with spring scale & subtle fade in.
class YouTubeStyleEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const YouTubeStyleEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + (delay * index),
      curve: Curves.fastOutSlowIn,
      builder: (context, value, child) {
        final scale = 0.94 + (0.06 * value);
        final offsetY = (1.0 - value) * 35.0;

        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// Apple Staggered Entrance (Alias for backward compatibility)
typedef AppleStaggeredEntrance = YouTubeStyleEntrance;
