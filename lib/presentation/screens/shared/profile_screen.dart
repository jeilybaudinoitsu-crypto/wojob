import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/settings_state.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final settingsState = context.watch<SettingsState>();
    final user = authState.currentUser;
    if (user == null) return const WelcomeScreen();

    final List<Widget> children = <Widget>[
      SectionCard(
        title: 'Datos del perfil',
        subtitle: 'Informacion de tu cuenta en WoJob.',
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(initials: user.iniciales, imageUrl: user.fotoUrl, size: 64),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.nombreCompleto,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(user.cargo ?? user.tipoUsuario.label,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text('ID: ${user.idPersonal}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('Correo'),
        subtitle: Text(user.correo),
        contentPadding: EdgeInsets.zero,
      ),
      ListTile(
        leading: const Icon(Icons.phone_outlined),
        title: const Text('Telefono'),
        subtitle: Text(user.telefono),
        contentPadding: EdgeInsets.zero,
      ),
      ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: const Text('Verificado'),
        subtitle: Text(user.verificado ? 'Si' : 'Pendiente'),
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 20),
      SectionCard(
        title: 'Configuracion',
        subtitle: 'Apariencia y preferencias.',
        children: <Widget>[
          Consumer<SettingsState>(
            builder: (context, s, _) => SwitchListTile.adaptive(
              value: s.themeMode == ThemeMode.dark,
              onChanged: (_) => s.toggleTheme(),
              title: const Text('Modo oscuro'),
              subtitle: const Text('Cambia entre claro y oscuro'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        onPressed: () {
          authState.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        },
        label: 'Cerrar sesion',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mi informacion')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: children,
      ),
    );
  }
}