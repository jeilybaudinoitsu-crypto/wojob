import 'package:flutter/material.dart';

/// Fondo animado y minimalista para la pantalla de bienvenida.
class WelcomeBackground extends StatelessWidget {
  const WelcomeBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/welcome_bg.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF190207).withValues(alpha: 0.22),
                const Color(0xFF190207).withValues(alpha: 0.78),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}
