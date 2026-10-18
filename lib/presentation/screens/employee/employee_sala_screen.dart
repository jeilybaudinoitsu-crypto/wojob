import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/shared/schedule_view.dart';
import 'package:wojob/presentation/screens/employee/mark_attendance_screen.dart';

class EmployeeSalaScreen extends StatelessWidget {
  const EmployeeSalaScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final horarios = state.horariosDeEmpleado(user.id);
    final asistencias = state.historialDeEmpleado(user.id).take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(empresa.nombreEmpresa),
            Text(
              empresa.idSala,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Mi sala',
            subtitle: 'Dirección: ${empresa.direccionEmpresa}',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      context,
                      title: 'Marcar entrada',
                      icon: Icons.login_outlined,
                      color: theme.colorScheme.primary,
                      onTap: () => _irMarca(context, TipoAsistencia.entrada),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      context,
                      title: 'Marcar salida',
                      icon: Icons.logout_outlined,
                      color: theme.colorScheme.secondary,
                      onTap: () => _irMarca(context, TipoAsistencia.salida),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ScheduleView(horarios: horarios),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Últimos registros',
            subtitle: 'Historial reciente de entrada/salida.',
            children: [
              if (asistencias.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  child: Text('Aún no tienes registros de asistencia.',
                      style: theme.textTheme.bodySmall),
                )
              else
                for (final a in asistencias) ...[
                  ListTile(
                    leading: Icon(
                      a.tipo == TipoAsistencia.entrada
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      color: a.tipo == TipoAsistencia.entrada
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                    title: Text(a.tipo.label),
                    subtitle: Text(
                      '${a.fechaHora.day.toString().padLeft(2, '0')}/${a.fechaHora.month.toString().padLeft(2, '0')}/${a.fechaHora.year} ${a.fechaHora.hour.toString().padLeft(2, '0')}:${a.fechaHora.minute.toString().padLeft(2, '0')} · ${a.latitud.toStringAsFixed(4)}, ${a.longitud.toStringAsFixed(4)}',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (a != asistencias.last) const Divider(),
                ],
            ],
          ),
        ],
      ),
    );
  }

  void _irMarca(BuildContext context, TipoAsistencia tipo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(
          empresa: empresa,
          tipo: tipo,
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
