import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/core/utils/formatters.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/shared/schedule_view.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({
    super.key,
    required this.empresa,
    required this.miembro,
  });

  final Empresa empresa;
  final Perfil miembro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empresaState = context.watch<EmpresaState>();
    final asistenciaState = context.watch<AsistenciaState>();
    final horarios = empresaState.horariosDeEmpleado(miembro.id);
    final historial = asistenciaState.historialDeEmpleado(miembro.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del miembro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Información del usuario',
            subtitle: miembro.tipoUsuario.label,
            children: [
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      initials: miembro.iniciales,
                      imageUrl: miembro.fotoUrl,
                      size: 88,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      miembro.nombreCompleto,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(miembro.cargo ?? miembro.tipoUsuario.label),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _row(theme, 'ID personal', miembro.idPersonal, Icons.badge_outlined),
              _row(theme, 'Correo', miembro.correo, Icons.mail_outline),
              _row(theme, 'Teléfono', miembro.telefono, Icons.phone_outlined),
              _row(theme, 'Rol', miembro.tipoUsuario.label, Icons.verified_user_outlined),
              _row(theme, 'Estado', miembro.estadoActivo ? 'Activo' : 'Inactivo', Icons.toggle_on_outlined),
              _row(theme, 'Verificado', miembro.verificado ? 'Sí' : 'No', Icons.fact_check_outlined),
              _row(theme, 'Registrado', formatDateShort(miembro.createdAt), Icons.event_available_outlined),
            ],
          ),
          const SizedBox(height: 20),
          ScheduleView(horarios: horarios),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Historial de asistencia',
            subtitle: '${historial.length} registro(s)',
            children: [
              if (historial.isEmpty)
                Text('Sin registros de asistencia.',
                    style: theme.textTheme.bodyMedium)
              else
                for (final a in historial) ...[
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
                      '${formatDateShort(a.fechaHora)}\n${formatCoordinates(a.latitud, a.longitud)}',
                    ),
                    isThreeLine: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (a != historial.last) const Divider(),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}