import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fluid Full-Page Route untuk Form Tambah / Edit Lamaran.
/// Membuka halaman secara penuh (full screen edge-to-edge) dengan animasi transisi yang mulus,
/// cepat, responsif, dan bebas efek backdrop blur modal window.
class MorphSheetRoute<T> extends PageRoute<T> {
  final Widget child;
  final Rect? startRect;
  final Color backgroundColor;

  MorphSheetRoute({
    required this.child,
    this.startRect,
    this.backgroundColor = const Color(0xFFF8BA38),
    super.settings,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 360);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInOutCubic,
    );
    final fullRect = Offset.zero & screenSize;
    final origin =
        startRect ??
        Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height),
          width: 72,
          height: 48,
        );

    return AnimatedBuilder(
      animation: curvedAnimation,
      child: ColoredBox(color: backgroundColor, child: child),
      builder: (context, routeChild) {
        final progress = curvedAnimation.value;
        final rect = Rect.lerp(origin, fullRect, progress)!;
        return ClipPath(
          clipper: _MorphRectClipper(rect: rect, radius: 26 * (1 - progress)),
          child: Transform.scale(
            scale: 0.96 + (0.04 * progress),
            child: routeChild,
          ),
        );
      },
    );
  }

  static Future<T?> openMorphingSheet<T>({
    required BuildContext context,
    GlobalKey? buttonKey,
    required Widget child,
    Color? backgroundColor,
  }) {
    HapticFeedback.mediumImpact();
    final routeBackground =
        backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF141418)
            : const Color(0xFFF8BA38));
    Rect? startRect;
    final renderObject = buttonKey?.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      startRect = topLeft & renderObject.size;
    }
    return Navigator.push<T>(
      context,
      MorphSheetRoute<T>(
        child: child,
        startRect: startRect,
        backgroundColor: routeBackground,
      ),
    );
  }
}

class _MorphRectClipper extends CustomClipper<Path> {
  final Rect rect;
  final double radius;

  const _MorphRectClipper({required this.rect, required this.radius});

  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  bool shouldReclip(covariant _MorphRectClipper oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}
