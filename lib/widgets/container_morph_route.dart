import 'package:flutter/cupertino.dart';
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
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  bool get opaque => true;

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
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curvedAnimation);

    final fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      reverseCurve: const Interval(0.15, 1.0, curve: Curves.easeIn),
    ));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: child,
      ),
    );
  }

  static Future<T?> openMorphingSheet<T>({
    required BuildContext context,
    GlobalKey? buttonKey,
    required Widget child,
    Color backgroundColor = const Color(0xFFF8BA38),
  }) {
    HapticFeedback.mediumImpact();
    return Navigator.push<T>(
      context,
      MorphSheetRoute<T>(
        child: child,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
