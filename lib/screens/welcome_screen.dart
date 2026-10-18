import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/welcome_background.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'WoJob',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Control de asistencia, gestión de turnos y horarios rotativos en un solo lugar.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simplifica el registro de entradas y salidas, asignación de horarios y seguimiento de tu equipo.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.7,
                  ),
                ),
                const Spacer(flex: 2),
                PrimaryButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  label: 'Registrarse',
                ),
                const SizedBox(height: 14),
                GhostButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  label: 'Iniciar sesión',
                ),
                const SizedBox(height: 12),
                Consumer<AppState>(
                  builder: (context, state, _) => SwitchListTile.adaptive(
                    value: state.themeMode == ThemeMode.dark,
                    onChanged: (_) => state.toggleTheme(),
                    title: const Text(
                      'Modo oscuro',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Cambiar apariencia',
                      style: TextStyle(color: Colors.white70),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
