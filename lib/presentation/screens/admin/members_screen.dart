import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/admin/member_detail_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key, required this.empresa});

  final Empresa empresa;

  Future<void> _removeMember(BuildContext context, Perfil miembro) async {
    final theme = Theme.of(context);
    final authState = context.read<app_state.AuthState>();
    final currentUser = authState.currentUser;
    if (currentUser == null || !currentUser.isAdmin) return;
    if (miembro.id == currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminarte a ti mismo. Usa la opción Salir de la sala.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text(
          '¿Seguro que deseas eliminar a ${miembro.nombreCompleto} de la sala?\n\n'
          'El usuario ya no aparecerá en la lista ni se le podrá asignar horario. '
          'Su cuenta y su historial de entradas y salidas se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await context.read<EmpresaState>().removeMember(empresa.id, miembro.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${miembro.nombreCompleto} fue eliminado de la sala.')),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e is AppException ? e.message : 'No se pudo eliminar al miembro.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final miembros = empresaState.miembrosDeEmpresa(empresa.id);
    final empleados = miembros.where((m) => !m.isAdmin).toList();
    final admins = miembros.where((m) => m.isAdmin).toList();
    final isAdmin = authState.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Miembros de la sala')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section(
            context,
            theme,
            empresa,
            'Empleados registrados',
            Icons.groups_outlined,
            empleados,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 20),
          _section(
            context,
            theme,
            empresa,
            'Administradores',
            Icons.admin_panel_settings_outlined,
            admins,
            isAdmin: isAdmin,
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    ThemeData theme,
    Empresa empresa,
    String titulo,
    IconData icon,
    List<Perfil> lista, {
    bool isAdmin = false,
  }) {
    final authState = context.read<app_state.AuthState>();
    final currentUserId = authState.currentUser?.id;
    return SectionCard(
      title: titulo,
      subtitle: '${lista.length} miembro(s)',
      children: [
        if (lista.isEmpty)
          Text('Sin miembros en esta categoría.',
              style: theme.textTheme.bodyMedium)
        else
          for (final p in lista) ...[
            ListTile(
              leading: AppAvatar(initials: p.iniciales, imageUrl: p.fotoUrl),
              title: Text(p.nombreCompleto),
              subtitle: Text('${p.idPersonal} · ${p.cargo ?? p.tipoUsuario.label}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (p.estadoActivo ? theme.colorScheme.primary : theme.colorScheme.error)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.estadoActivo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.estadoActivo
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                  if (isAdmin && !p.isAdmin && p.id != currentUserId)
                    IconButton(
                      icon: Icon(Icons.person_remove_outlined, color: theme.colorScheme.error),
                      tooltip: 'Eliminar de la sala',
                      onPressed: () => _removeMember(context, p),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemberDetailScreen(
                    empresa: empresa,
                    miembro: p,
                  ),
                ),
              ),
            ),
            if (p != lista.last) const Divider(),
          ],
      ],
    );
  }
}