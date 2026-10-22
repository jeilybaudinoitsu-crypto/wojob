import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/core/utils/formatters.dart';
import 'package:wojob/presentation/widgets/empty_state.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/local_image.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  TipoAsistencia? _filtro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asistenciaState = context.watch<AsistenciaState>();
    final authState = context.watch<app_state.AuthState>();
    final todas = asistenciaState.asistenciasDeEmpresa(widget.empresa.id);
    final lista = _filtro == null
        ? todas
        : todas.where((a) => a.tipo == _filtro).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Llegadas y salidas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filtro == null,
                  onSelected: (_) => setState(() => _filtro = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entradas'),
                  selected: _filtro == TipoAsistencia.entrada,
                  onSelected: (_) => setState(() => _filtro = TipoAsistencia.entrada),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Salidas'),
                  selected: _filtro == TipoAsistencia.salida,
                  onSelected: (_) => setState(() => _filtro = TipoAsistencia.salida),
                ),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? const EmptyState(
                    title: 'Sin registros',
                    message: 'No hay marcas de entrada/salida todavía.',
                    icon: Icons.schedule_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: lista.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(context, theme, authState, lista[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    ThemeData theme,
    app_state.AuthState authState,
    Asistencia a,
  ) {
    String nombre = 'Empleado';
    String? foto;
    for (final p in authState.perfiles) {
      if (p.id == a.empleadoId) {
        nombre = p.nombreCompleto;
        foto = p.fotoUrl;
        break;
      }
    }
    final esEntrada = a.tipo == TipoAsistencia.entrada;
    final color = esEntrada ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              initials: nombre.substring(0, 1).toUpperCase(),
              imageUrl: foto,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nombre,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              esEntrada ? Icons.login_rounded : Icons.logout_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(a.tipo.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _line(theme, Icons.access_time_outlined, formatDateShort(a.fechaHora)),
                  const SizedBox(height: 4),
                  _line(theme, Icons.location_on_outlined,
                      formatCoordinates(a.latitud, a.longitud)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _thumb(a.fotoUrl, 'Foto de marcación'),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _verDetalle(context, theme, nombre, a),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Ver detalle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _thumb(String? path, String label) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: localPhotoExists(path)
          ? LocalImage(path: path!)
          : Icon(Icons.image_not_supported_outlined,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
    );
  }

  void _verDetalle(
      BuildContext context, ThemeData theme, String nombre, Asistencia a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final exists = localPhotoExists(a.fotoUrl);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle de ${a.tipo.label.toLowerCase()}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(nombre, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              if (exists)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: LocalImage(path: a.fotoUrl),
                  ),
                )
              else
                Container(
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  child: const Text('Sin foto adjunta'),
                ),
              const SizedBox(height: 20),
              _detalleRow(theme, 'Hora', formatDateShort(a.fechaHora)),
              _detalleRow(theme, 'Latitud', a.latitud.toStringAsFixed(6)),
              _detalleRow(theme, 'Longitud', a.longitud.toStringAsFixed(6)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detalleRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}