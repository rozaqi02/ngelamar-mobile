import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Motion language shared by the Ngelamar screens.
///
/// Durations provide expressive continuity and clear, delightful transitions
/// without introducing lag or duplicate hero artifacts.
abstract final class AppMotion {
  static const Duration tabFade = Duration(milliseconds: 120);
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration detailDock = Duration(milliseconds: 520);

  static String companyLogoTag(String jobId) => 'company_logo_$jobId';

  static PageRoute<T> fadeScaleRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      transitionDuration: standard,
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// A calm, full-screen route for adding or editing an application. It gives
  /// forms a clear forward direction without the abrupt flash or oversized
  /// morph used by the old edit transition.
  static PageRoute<T> editorRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) return child;

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.045),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Full-screen detail route that rises gracefully with rich ease-out curves
  /// and clear hero trajectory.
  static PageRoute<T> detailDockRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 440),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) return child;

        final curvedAnim = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
          reverseCurve: const Cubic(0.4, 0.0, 0.2, 1.0),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.90),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );
      },
    );
  }
}

/// Shared hero configuration for a company badge. The arc makes the path
/// from the card logo to the detail header smooth, organic, and graceful.
RectTween companyLogoRectTween(Rect? begin, Rect? end) =>
    MaterialRectArcTween(begin: begin, end: end);

/// Rich animated flight shuttle with dynamic elevation and zero-flicker landing.
Widget companyLogoFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final destinationHero = toHeroContext.widget as Hero;
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: const Cubic(0.2, 0.85, 0.25, 1.08),
    reverseCurve: const Cubic(0.35, 0.0, 0.25, 1.0),
  );

  return AnimatedBuilder(
    animation: curvedAnimation,
    builder: (context, _) {
      final t = curvedAnimation.value.clamp(0.0, 1.0);
      final flightIntensity = math.sin(t * math.pi);
      final scale = 1.0 + (flightIntensity * 0.08);
      final extraAlpha = flightIntensity * 0.10;
      final extraElevation = flightIntensity * 12.0;

      return Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: extraAlpha > 0.005
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: extraAlpha),
                      blurRadius: 10 + extraElevation,
                      offset: Offset(0, 3 + (extraElevation * 0.4)),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: destinationHero.child,
          ),
        ),
      );
    },
  );
}

/// Zero-ghost hero placeholder: reserves the layout space without rendering a
/// duplicate visible badge at the origin during mid-air flight.
Widget companyLogoHeroPlaceholder(
  BuildContext context,
  Size heroSize,
  Widget child,
) => SizedBox.fromSize(size: heroSize);

/// A small, accessibility-aware reveal for content that changes in place.
class MotionReveal extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const MotionReveal({
    super.key,
    required this.child,
    this.duration = AppMotion.standard,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.985 + (0.015 * value),
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }
}

/// Reveals repeated cards in a short cascade. The delay is capped so a large
/// application list never feels like it is still loading.
class StaggeredReveal extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const StaggeredReveal({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    final delay = Duration(milliseconds: index.clamp(0, 6) * 32);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Gives a newly changed status one confident, one-time pulse instead of a
/// distracting looping animation.
class StatusPulse extends StatefulWidget {
  final String status;
  final Widget child;
  final Duration duration;

  const StatusPulse({
    super.key,
    required this.status,
    required this.child,
    this.duration = const Duration(milliseconds: 360),
  });

  @override
  State<StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<StatusPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 55),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant StatusPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) =>
          Transform.scale(scale: reduceMotion ? 1 : _scale.value, child: child),
    );
  }
}

/// Material You-inspired profile completion ring. It is intentionally data
/// driven so completion changes animate rather than jump.
class ProfileCompletionRing extends StatelessWidget {
  final double value;
  final Color color;
  final Color trackColor;
  final double size;

  const ProfileCompletionRing({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0, 1) * 100).round();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: 'Profil lengkap $percent persen',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: trackColor,
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
