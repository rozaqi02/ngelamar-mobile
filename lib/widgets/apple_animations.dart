import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple iOS Bouncy Touch Feedback Widget
/// Adds a subtle spring-scale effect when tapped or pressed.
class AppleBouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const AppleBouncyCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.965,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<AppleBouncyCard> createState() => _AppleBouncyCardState();
}

class _AppleBouncyCardState extends State<AppleBouncyCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.fastOutSlowIn,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.88 : 1.0,
          duration: widget.duration,
          curve: Curves.fastOutSlowIn,
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

  const FluidBounceButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.935,
    this.duration = const Duration(milliseconds: 130),
  });

  @override
  State<FluidBounceButton> createState() => _FluidBounceButtonState();
}

class _FluidBounceButtonState extends State<FluidBounceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.fastOutSlowIn,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.82 : 1.0,
          duration: widget.duration,
          curve: Curves.fastOutSlowIn,
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
