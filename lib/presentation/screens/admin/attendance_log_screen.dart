import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/core/utils/formatters.dart';
import 'package:wojob/presentation/widgets/empty_state.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/local_image.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({
    super.key,
    required this.empresa,
    this.embedded = false,
    this.empleadoId,
  });

  final Empresa empresa;
  final bool embedded;
  final String? empleadoId;

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  TipoAsistencia? _filtro;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.empleadoId == null ? 'Llegadas y salidas' : 'Mi historial',
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final asistenciaState = context.watch<AsistenciaState>();
    final empresaState = context.watch<EmpresaState>();
    final authState = context.watch<app_state.AuthState>();
    final empleadoId = widget.empleadoId;
    final todas = empleadoId == null
        ? asistenciaState.asistenciasDeEmpresa(widget.empresa.id)
        : asistenciaState.historialDeEmpleado(empleadoId);
    final lista = _filtro == null
        ? todas
        : todas.where((a) => a.tipo == _filtro).toList();

    final Widget content;
    if (asistenciaState.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (asistenciaState.backendError != null) {
      content = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudieron cargar los registros: '
                '${asistenciaState.backendError}',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              if (asistenciaState.isBackendEnabled) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => empleadoId == null
                      ? asistenciaState.loadAsistenciasEmpresa(
                          widget.empresa.id,
                        )
                      : asistenciaState.loadAsistenciasEmpleado(empleadoId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (lista.isEmpty) {
      content = const EmptyState(
        title: 'Sin registros',
        message: 'No hay marcas de entrada/salida todavía.',
        icon: Icons.schedule_outlined,
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: lista.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _card(context, theme, empresaState, authState, lista[i]),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filtro == null,
                  onSelected: (_) => setState(() => _filtro = null),
                ),
                ChoiceChip(
                  label: const Text('Entradas'),
                  selected: _filtro == TipoAsistencia.entrada,
                  onSelected: (_) =>
                      setState(() => _filtro = TipoAsistencia.entrada),
                ),
                ChoiceChip(
                  label: const Text('Salidas'),
                  selected: _filtro == TipoAsistencia.salida,
                  onSelected: (_) =>
                      setState(() => _filtro = TipoAsistencia.salida),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    ThemeData theme,
    EmpresaState empresaState,
    app_state.AuthState authState,
    Asistencia a,
  ) {
    final perfil =
        empresaState.perfilById(a.empleadoId) ??
        authState.getPerfil(a.empleadoId);
    final nombre = perfil?.nombreCompleto ?? 'Empleado';
    final esEntrada = a.tipo == TipoAsistencia.entrada;
    final color = esEntrada
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              initials: perfil?.iniciales ?? '?',
              imageUrl: perfil?.fotoUrl,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              esEntrada
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              a.tipo.label,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _line(
                    theme,
                    Icons.access_time_outlined,
                    formatDateShort(a.fechaHora),
                  ),
                  const SizedBox(height: 4),
                  _line(
                    theme,
                    Icons.location_on_outlined,
                    formatCoordinates(a.latitud, a.longitud),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _thumb(a.fotoUrl, 'Foto de marcación'),
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
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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
          : Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
    );
  }

  void _verDetalle(
    BuildContext context,
    ThemeData theme,
    String nombre,
    Asistencia a,
  ) {
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
              Text(
                'Detalle de ${a.tipo.label.toLowerCase()}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
