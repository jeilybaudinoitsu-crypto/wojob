import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/settings_state.dart';
import 'package:wojob/presentation/widgets/password_reset_dialog.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/shared/account_screen.dart';
import 'package:wojob/presentation/screens/shared/privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openPasswordChange(BuildContext context) async {
    final authState = context.read<app_state.AuthState>();
    if (!authState.isBackendEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El cambio de contraseña está disponible solo con Supabase configurado.',
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordResetDialog(
        authState: authState,
        initialEmail: authState.currentUser?.correo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<app_state.AuthState>();
    final user = authState.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Apariencia',
            subtitle: 'Elige cómo se ve WoJob en tu dispositivo.',
            leadingIcon: Icons.palette_outlined,
            children: [
              Consumer<SettingsState>(
                builder: (context, settings, _) => SwitchListTile.adaptive(
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (_) => settings.toggleTheme(),
                  title: const Text('Modo oscuro'),
                  subtitle: const Text('Cambia entre claro y oscuro'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Tu cuenta',
            subtitle: 'Correo, teléfono, verificación y eliminación.',
            leadingIcon: Icons.manage_accounts_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Datos de la cuenta'),
                subtitle: Text(
                  user == null
                      ? 'Sin sesión activa'
                      : '${user.correo} · ${user.telefono}',
                ),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Seguridad',
            subtitle: 'Protege el acceso a tu cuenta.',
            leadingIcon: Icons.lock_outline,
            children: [
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text(
                  'Te enviaremos un código al correo para confirmar el cambio.',
                ),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () => _openPasswordChange(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Privacidad',
            subtitle: 'Conoce cómo usamos tus datos y permisos.',
            leadingIcon: Icons.privacy_tip_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Política de privacidad y permisos'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
