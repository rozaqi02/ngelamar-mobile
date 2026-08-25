import 'package:flutter/material.dart';

/// Motion language shared by the Ngelamar screens.
///
/// Durations intentionally stay short: motion should explain continuity and
/// state changes, never make an application tracker feel slower to use.
abstract final class AppMotion {
  static const Duration tabFade = Duration(milliseconds: 100);
  static const Duration micro = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration detailDock = Duration(milliseconds: 420);

  static String companyLogoTag(String jobId) => 'company_logo_$jobId';

  static PageRoute<T> fadeScaleRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      transitionDuration: standard,
      reverseTransitionDuration: const Duration(milliseconds: 210),
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

  /// Full-screen detail route that rises from the bottom with the confidence of
  /// a docked surface.  It is deliberately opaque: the primary navigation is
  /// never visible above or through a job-detail page.
  static PageRoute<T> detailDockRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: detailDock,
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) return child;
        final slide = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.72, curve: Curves.easeOut),
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(slide),
            child: child,
          ),
        );
      },
    );
  }
}

/// Shared hero configuration for a company badge.  The arc makes the change
/// from a compact card/logo into the detail header easy to notice without
/// competing with the page's upward transition.
RectTween companyLogoRectTween(Rect? begin, Rect? end) =>
    MaterialRectCenterArcTween(begin: begin, end: end);

Widget companyLogoFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final hero = flightDirection == HeroFlightDirection.push
      ? toHeroContext.widget as Hero
      : fromHeroContext.widget as Hero;
  return Material(type: MaterialType.transparency, child: hero.child);
}

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
