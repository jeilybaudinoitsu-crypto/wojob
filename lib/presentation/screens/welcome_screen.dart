import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/settings_state.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/welcome_background.dart';
import 'package:wojob/presentation/screens/auth/login_screen.dart';
import 'package:wojob/presentation/screens/auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GESTIÓN DE EQUIPOS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'WoJob',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control de asistencia, turnos y horarios en un solo lugar.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.96),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Simplifica el registro y mantén a tu equipo organizado cada día.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                PrimaryButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  label: 'Registrarse',
                  icon: Icons.person_add_alt_1_outlined,
                ),
                const SizedBox(height: 14),
                GhostButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  label: 'Iniciar sesión',
                  icon: Icons.login_outlined,
                ),
                const SizedBox(height: 12),
                Consumer<SettingsState>(
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
