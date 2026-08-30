import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating bottom dock used by all contextual welcome screens.
/// Features smooth full-slide entrance/exit and real-time swipe-down dismissal.
class WelcomeScreenRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  WelcomeScreenRoute({required this.child})
    : super(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0x99000000),
        barrierLabel: 'Tutup panduan',
        pageBuilder: (context, animation, secondaryAnimation) {
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                0,
                14,
                bottomInset > 0 ? bottomInset + 6 : 12,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: FractionallySizedBox(
                  widthFactor: 1,
                  // The sheet remains compact, but gives the enlarged
                  // mascot illustration ample room to look prominent and lively.
                  heightFactor: 0.64,
                  child: _WelcomeDismissibleSheet(child: child),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
            return child;
          }
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(curvedAnim),
            child: child,
          );
        },
      );
}

class _WelcomeDismissibleSheet extends StatefulWidget {
  final Widget child;

  const _WelcomeDismissibleSheet({required this.child});

  @override
  State<_WelcomeDismissibleSheet> createState() =>
      _WelcomeDismissibleSheetState();
}

class _WelcomeDismissibleSheetState extends State<_WelcomeDismissibleSheet>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late final AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, 400.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 90 || velocity > 700) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } else {
      _springAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.38)
                          : const Color(0xFF7A7063).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
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
