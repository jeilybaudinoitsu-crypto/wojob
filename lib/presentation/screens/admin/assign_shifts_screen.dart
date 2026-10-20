import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/core/utils/formatters.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/empty_state.dart';
import 'package:wojob/presentation/widgets/avatar.dart';

class AssignShiftsScreen extends StatefulWidget {
  const AssignShiftsScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<AssignShiftsScreen> createState() => _AssignShiftsScreenState();
}

class _AssignShiftsScreenState extends State<AssignShiftsScreen> {
  String? _empleadoId;
  DiaSemana _dia = DiaSemana.lunes;
  TimeOfDay _entrada = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _salida = const TimeOfDay(hour: 17, minute: 0);
  bool _loading = false;
  String? _error;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool entrada) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: entrada ? _entrada : _salida,
    );
    if (picked == null) return;
    setState(() {
      if (entrada) {
        _entrada = picked;
      } else {
        _salida = picked;
      }
    });
  }

  Future<void> _agregar() async {
    if (_empleadoId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().assignShift(
          empresaId: widget.empresa.id,
          empleadoId: _empleadoId!,
          diaSemana: _dia,
          horaEntrada: _fmt(_entrada),
          horaSalida: _fmt(_salida),
        );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Turno asignado (${_dia.label} ${_fmt(_entrada)}–${_fmt(_salida)})')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is AppException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await context.read<AppState>().removeShift(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is AppException ? e.message : e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final empleados = state
        .miembrosDeEmpresa(widget.empresa.id)
        .where((p) => !p.isAdmin)
        .toList();

    if (empleados.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asignar turnos')),
        body: const EmptyState(
          title: 'Sin empleados',
          message: 'Aún no hay empleados registrados en esta sala.',
          icon: Icons.groups_outlined,
        ),
      );
    }

    final seleccionado = _empleadoId ?? empleados.first.id;
    final horarios = state
        .horariosDeEmpleado(seleccionado)
        .toList()
      ..sort((a, b) =>
          DiaSemana.values.indexOf(a.diaSemana).compareTo(DiaSemana.values.indexOf(b.diaSemana)));

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar turnos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Selecciona un empleado',
            subtitle: 'Asigna horarios rotativos por día.',
            children: [
              for (final e in empleados)
                ListTile(
                  leading: AppAvatar(initials: e.iniciales, imageUrl: e.fotoUrl, size: 42),
                  title: Text(e.nombreCompleto),
                  subtitle: Text('${e.idPersonal} · ${e.cargo ?? 'Empleado'}'),
                  trailing: Icon(
                    e.id == seleccionado
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: e.id == seleccionado
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  selected: e.id == seleccionado,
                  onTap: () => setState(() => _empleadoId = e.id),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Nuevo turno',
            subtitle: 'Elige el día y las horas de entrada y salida.',
            children: [
              DropdownButtonFormField<DiaSemana>(
                initialValue: _dia,
                decoration: const InputDecoration(
                  labelText: 'Día de la semana',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                items: [
                  for (final d in DiaSemana.values)
                    DropdownMenuItem(value: d, child: Text(d.label)),
                ],
                onChanged: (v) => setState(() => _dia = v ?? _dia),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _timeField(theme, 'Entrada', _fmt(_entrada), () => _pick(true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(theme, 'Salida', _fmt(_salida), () => _pick(false)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                onPressed: _loading ? null : _agregar,
                label: _loading ? 'Guardando...' : 'Asignar turno',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Horarios asignados',
            subtitle: _nombreEmpleado(state, seleccionado),
            children: [
              if (horarios.isEmpty)
                Text('Este empleado no tiene horarios asignados.',
                    style: theme.textTheme.bodyMedium)
              else
                for (final h in horarios) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(h.diaSemana.dbValue),
                    ),
                    title: Text(weekdayLabel(h.diaSemana.dbValue)),
                    subtitle: Text('${h.horaEntrada} – ${h.horaSalida}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      onPressed: () => _eliminar(h.id),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (h != horarios.last) const Divider(),
                ],
            ],
          ),
        ],
      ),
    );
  }

  String _nombreEmpleado(AppState state, String id) {
    for (final p in state.perfiles) {
      if (p.id == id) return '${p.nombreCompleto} (${p.idPersonal})';
    }
    return '';
  }

  Widget _timeField(
      ThemeData theme, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_outlined),
        ),
        child: Text(value, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}
