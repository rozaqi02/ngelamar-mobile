import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// A supporting workspace slides in from the right and leaves to the right
  /// on back navigation. Its source remains visible underneath—no fade.
  static PageRoute<T> hubRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      // The non-opaque route preserves Kalender as the continuous surface
      // underneath the workspace while it slides horizontally.
      opaque: false,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) return child;
        final curve = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
    );
  }

  /// The application form travels vertically like a sheet modal: it rises
  /// gracefully from the bottom with a subtle background veil and returns
  /// there upon dismissal, moving as a single cohesive unit with zero flicker.
  static PageRoute<T> editorRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 460),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) return child;

        final curved = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
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
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 650),
      reverseTransitionDuration: const Duration(milliseconds: 560),
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
            begin: const Offset(0, 0.96),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
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

/// Shared hero configuration for primary action button morphing.
RectTween actionButtonRectTween(Rect? begin, Rect? end) =>
    MaterialRectArcTween(begin: begin, end: end);

/// One immutable visual contract for the label at both ends of the add-job
/// Hero. Keeping the exact family variant and metrics prevents Flutter from
/// swapping from a synthesized in-flight face to the button's final face.
TextStyle actionButtonLabelTextStyle() => GoogleFonts.plusJakartaSans(
  color: Colors.white,
  fontSize: 15,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.2,
  height: 1,
  decoration: TextDecoration.none,
);

String statusActionHeroTag(String jobId) => 'status_action_$jobId';

/// Carries the endpoint colors into the status-action Hero without changing
/// how either endpoint is laid out or receives taps.
class StatusActionHeroMetadata extends StatelessWidget {
  const StatusActionHeroMetadata({
    super.key,
    required this.isExpanded,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
  });

  final bool isExpanded;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

TextStyle statusActionLabelTextStyle(BuildContext context) {
  final buttonStyle = Theme.of(
    context,
  ).elevatedButtonTheme.style?.textStyle?.resolve(const <WidgetState>{});
  return (buttonStyle ?? DefaultTextStyle.of(context).style).copyWith(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1,
    decoration: TextDecoration.none,
  );
}

RectTween statusActionRectTween(Rect? begin, Rect? end) =>
    MaterialRectArcTween(begin: begin, end: end);

Widget statusActionFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  StatusActionHeroMetadata metadataOf(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as StatusActionHeroMetadata;
  }

  final from = metadataOf(fromHeroContext);
  final to = metadataOf(toHeroContext);
  final compact = from.isExpanded ? to : from;
  final expanded = from.isExpanded ? from : to;

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final forwardTime = flightDirection == HeroFlightDirection.push
          ? animation.value
          : 1 - animation.value;
      final t = Curves.easeInOutCubicEmphasized.transform(forwardTime);
      final expansion = flightDirection == HeroFlightDirection.push ? t : 1 - t;
      final arrowOpacity = 1 - const Interval(0.12, 0.38).transform(expansion);
      final labelOpacity = const Interval(0.54, 0.82).transform(expansion);
      final background = Color.lerp(
        compact.backgroundColor,
        expanded.backgroundColor,
        expansion,
      )!;
      final foreground = Color.lerp(
        compact.foregroundColor,
        expanded.foregroundColor,
        expansion,
      )!;

      return Material(
        type: MaterialType.transparency,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18 + (10 * expansion)),
            boxShadow: expansion > 0.02
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22 * expansion),
                      blurRadius: 12 * expansion,
                      offset: Offset(0, 5 * expansion),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: arrowOpacity,
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: foreground,
                ),
              ),
              Opacity(
                opacity: labelOpacity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Perbarui Status Lamaran',
                        style: statusActionLabelTextStyle(flightContext),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget statusActionHeroPlaceholder(
  BuildContext context,
  Size heroSize,
  Widget child,
) => SizedBox.fromSize(size: heroSize);

/// Rich animated flight shuttle for morphing between dock '+' icon and form save button.
Widget actionButtonFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final isDark = Theme.of(flightContext).brightness == Brightness.dark;
  final actionColor = isDark
      ? const Color(0xFF5C44E4)
      : const Color(0xFF19191B);
  final dockRim = isDark ? const Color(0xFF38383E) : const Color(0xFFE5E0D5);

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      // Flutter plays a returning Hero's animation backwards (1 → 0). Normalize
      // it first, then describe both flights in the same visual direction.
      // Without this, a pop renders CTA → plus → CTA → plus in quick succession.
      final forwardTime = flightDirection == HeroFlightDirection.push
          ? animation.value
          : 1 - animation.value;
      final t = Curves.easeInOutCubicEmphasized.transform(forwardTime);
      final expansion = flightDirection == HeroFlightDirection.push ? t : 1 - t;
      final plusOpacity = 1 - const Interval(0.16, 0.42).transform(expansion);
      final labelOpacity = const Interval(0.50, 0.76).transform(expansion);

      return Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: actionColor,
            borderRadius: BorderRadius.circular(32 - (4 * expansion)),
            border: Border.all(
              color: dockRim.withValues(alpha: 1 - expansion),
              width: 3 * (1 - expansion),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: plusOpacity,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              Opacity(
                opacity: labelOpacity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Catat Lamaran Cepat',
                      style: actionButtonLabelTextStyle(),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Zero-ghost hero placeholder for the primary action button.
Widget actionButtonHeroPlaceholder(
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
