import 'package:flutter/material.dart';
import '../../models/dia_semana.dart';
import '../../models/horario.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_card.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({
    super.key,
    required this.horarios,
  });

  final List<Horario> horarios;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orden = [
      DiaSemana.lunes,
      DiaSemana.martes,
      DiaSemana.miercoles,
      DiaSemana.jueves,
      DiaSemana.viernes,
      DiaSemana.sabado,
      DiaSemana.domingo,
    ];
    horarios.sort((a, b) => orden.indexOf(a.diaSemana).compareTo(orden.indexOf(b.diaSemana)));

    if (horarios.isEmpty) {
      return SectionCard(
        title: 'Mi horario',
        subtitle: 'Aún no tienes horarios asignados.',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cuando el administrador asigne tus turnos, aparecerán aquí con hora de entrada y salida por día.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SectionCard(
      title: 'Mi horario',
      subtitle: 'Horas de entrada y salida asignadas.',
      children: [
        for (final h in horarios) ...[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              foregroundColor: theme.colorScheme.primary,
              child: Text(h.diaSemana.dbValue),
            ),
            title: Text(weekdayLabel(h.diaSemana.dbValue)),
            subtitle: Text('${h.horaEntrada} – ${h.horaSalida}'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.schedule_outlined),
          ),
          if (h != horarios.last) const Divider(),
        ],
      ],
    );
  }
}
