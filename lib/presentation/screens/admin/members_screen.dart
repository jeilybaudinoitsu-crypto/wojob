import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/admin/member_detail_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final miembros = state.miembrosDeEmpresa(empresa.id);
    final empleados = miembros.where((m) => !m.isAdmin).toList();
    final admins = miembros.where((m) => m.isAdmin).toList();

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
          ),
          const SizedBox(height: 20),
          _section(
            context,
            theme,
            empresa,
            'Administradores',
            Icons.admin_panel_settings_outlined,
            admins,
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
    List<Perfil> lista,
  ) {
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
