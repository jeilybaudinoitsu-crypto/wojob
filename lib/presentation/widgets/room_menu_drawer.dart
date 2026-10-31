import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/theme/app_colors.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/screens/home_router.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';
import 'package:wojob/presentation/screens/shared/profile_screen.dart';
import 'package:wojob/presentation/screens/shared/settings_screen.dart';
import 'package:wojob/presentation/screens/shared/sala_info_screen.dart';
import 'package:wojob/presentation/screens/admin/members_screen.dart';
import 'package:wojob/presentation/widgets/avatar.dart';

/// Menú lateral de la sala. Muestra opciones distintas para empleados y
/// administradores, pero siempre dentro del contexto de la sala actual.
class RoomMenuDrawer extends StatelessWidget {
  const RoomMenuDrawer({super.key, required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final sala = empresaState.empresaById(empresa.id) ?? empresa;
    final user = authState.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initials: user?.iniciales ?? '?',
                        imageUrl: user?.fotoUrl,
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nombreCompleto ?? 'Sin sesión',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.tipoUsuario.label ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    sala.nombreEmpresa,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sala ${sala.idSala}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _tile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Ver mi información',
                    subtitle: 'Foto de perfil y datos personales',
                    onTap: () => _open(context, const ProfileScreen()),
                  ),
                  _tile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    subtitle: 'Cuenta, apariencia y privacidad',
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                  _tile(
                    context,
                    icon: Icons.meeting_room_outlined,
                    title: 'Salas',
                    subtitle: 'Información de la sala y cambio de sala',
                    onTap: () => _open(
                      context,
                      SalaInfoScreen(empresa: sala),
                    ),
                  ),
                  if (user?.isAdmin ?? false)
                    _tile(
                      context,
                      icon: Icons.people_outline,
                      title: 'Miembros de la sala',
                      subtitle: 'Consulta y quita empleados de la sala',
                      onTap: () => _open(
                        context,
                        MembersScreen(empresa: sala),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _tile(
              context,
              icon: Icons.exit_to_app_outlined,
              title: 'Salir de la sala',
              subtitle: 'Tus turnos se eliminan; el historial se conserva',
              onTap: () => _leaveRoom(context),
            ),
            _tile(
              context,
              icon: Icons.logout,
              title: 'Cerrar sesión',
              color: theme.colorScheme.error,
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final tone = color ?? theme.colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: tone),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
    );
  }

  void _open(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _leaveRoom(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authState = context.read<app_state.AuthState>();
    final empresaState = context.read<EmpresaState>();
    navigator.pop();

    final confirmado = await showDialog<bool>(
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salir de la sala'),
        content: const Text(
          'Dejarás de pertenecer a esta sala y se eliminarán los turnos que '
          'tengas asignados en ella. Tu cuenta y tu historial de entradas y '
          'salidas se conservarán.\n\n'
          'Para volver, necesitarás enviar una nueva solicitud y que un '
          'administrador la acepte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Salir de la sala'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await authState.leaveRoom();
      empresaState.clearSalaData();
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeRouter()),
        (route) => false,
      );
    } catch (e) {
      if (!navigator.mounted) return;
      ScaffoldMessenger.of(navigator.context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'No se pudo salir de la sala.',
            ),
          ),
        );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authState = context.read<app_state.AuthState>();
    final empresaState = context.read<EmpresaState>();
    navigator.pop();

    final confirmado = await showDialog<bool>(
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Quieres cerrar sesión? Podrás volver a entrar con tu correo y '
          'contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await authState.logout();
    } catch (e) {
      if (!navigator.mounted) return;
      ScaffoldMessenger.of(navigator.context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.message
                  : 'No se pudo cerrar la sesión.',
            ),
          ),
        );
      return;
    }
    empresaState.clearSalaData();
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}
