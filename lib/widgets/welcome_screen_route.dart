import 'package:flutter/material.dart';

/// Floating bottom dock used by all contextual welcome screens.
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
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.82,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.22),
              end: Offset.zero,
            ).animate(curvedAnim),
            child: child,
          );
        },
      );
}
