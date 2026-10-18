import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/empresa.dart';
import '../../models/solicitud_sala.dart';
import '../../services/app_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/copyable_field.dart';
import '../shared/profile_screen.dart';
import '../welcome_screen.dart';
import 'assign_shifts_screen.dart';
import 'attendance_log_screen.dart';
import 'members_screen.dart';
import 'requests_screen.dart';

class AdminSalaScreen extends StatelessWidget {
  const AdminSalaScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final miembros = state.miembrosDeEmpresa(empresa.id);
    final empleados = miembros.where((m) => !m.isAdmin).toList();
    final admins = miembros.where((m) => m.isAdmin).toList();
    final solicitudesPend = state
        .solicitudesParaAdmin(empresa.id)
        .where((s) => s.estado == EstadoSolicitud.pendiente)
        .toList();
    final asistencias = state.asistenciasDeEmpresa(empresa.id);

    return Scaffold(
      drawer: _drawer(context, empresa),
      appBar: AppBar(title: Text(empresa.nombreEmpresa)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Sala ${empresa.idSala}',
            subtitle: empresa.direccionEmpresa,
            children: [
              CopyableField(label: 'ID de sala', value: empresa.idSala),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat(theme, 'Empleados', '${empleados.length}', Icons.groups_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _stat(theme, 'Administradores', '${admins.length}', Icons.admin_panel_settings_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _stat(theme, 'Asistencias', '${asistencias.length}', Icons.fact_check_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _stat(theme, 'Solicitudes', '${solicitudesPend.length}', Icons.mark_email_unread_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Acciones principales',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _menuTile(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Ver y asignar turnos',
            subtitle: 'Asigna horarios y días a cada empleado',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AssignShiftsScreen(empresa: empresa),
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.schedule_outlined,
            title: 'Ver horas de llegada y salida',
            subtitle: 'Historial con hora, foto y ubicación exacta',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttendanceLogScreen(empresa: empresa),
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.people_outline,
            title: 'Ver empleados y administradores',
            subtitle: 'Miembros registrados en la sala',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MembersScreen(empresa: empresa),
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.mark_email_unread_outlined,
            title: 'Ver lista de solicitudes',
            subtitle: '${solicitudesPend.length} pendientes',
            badge: solicitudesPend.length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RequestsScreen(empresa: empresa),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                )),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      )),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context, Empresa empresa) {
    final theme = Theme.of(context);
    final state = context.read<AppState>();
    final user = state.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF800427), Color(0xFF54082D)],
                      ),
                    ),
                    child: const Icon(Icons.work_outline, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    empresa.nombreEmpresa,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Sala ${empresa.idSala}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: const Text('Ver lista de solicitudes'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RequestsScreen(empresa: empresa)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Ver mi información'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Salir',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AppState>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Sesión: ${user.nombreCompleto}\n${user.tipoUsuario.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
