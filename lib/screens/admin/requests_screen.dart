import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/empresa.dart';
import '../../models/perfil.dart';
import '../../models/solicitud_sala.dart';
import '../../services/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final solicitudes = state.solicitudesParaAdmin(empresa.id);

    if (solicitudes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solicitudes')),
        body: const EmptyState(
          title: 'Sin solicitudes',
          message: 'Cuando alguien solicite unirse a tu sala aparecerá aquí.',
          icon: Icons.mark_email_read_outlined,
        ),
      );
    }

    final pendientes = solicitudes
        .where((s) => s.estado == EstadoSolicitud.pendiente)
        .toList();
    final resueltas = solicitudes
        .where((s) => s.estado != EstadoSolicitud.pendiente)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de solicitudes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _grupo(theme, state, 'Pendientes', pendientes),
          if (resueltas.isNotEmpty) ...[
            const SizedBox(height: 24),
            _grupo(theme, state, 'Historial', resueltas),
          ],
        ],
      ),
    );
  }

  Widget _grupo(
    ThemeData theme,
    AppState state,
    String titulo,
    List<SolicitudSala> lista,
  ) {
    if (lista.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.done_all, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('No hay solicitudes pendientes.')),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final s in lista) ...[
          _solicitudCard(state, s),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Perfil? _perfilPorId(AppState state, String id) {
    for (final p in state.perfiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  Widget _solicitudCard(AppState state, SolicitudSala s) {
    final perfil = _perfilPorId(state, s.usuarioId);
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: AppAvatar(
              initials: perfil?.iniciales ?? '?',
              imageUrl: perfil?.fotoUrl,
              size: 46,
            ),
            title: Text(perfil?.nombreCompleto ?? 'Usuario'),
            subtitle: Text(
              '${perfil?.cargo ?? 'Solicitante'} · ${formatDateShort(s.createdAt)}',
            ),
            trailing: _estadoChip(theme, s.estado),
            onTap: () => _abrirDetalle(context, theme, state, s, perfil),
          ),
        );
      },
    );
  }

  Widget _estadoChip(ThemeData theme, EstadoSolicitud estado) {
    Color color;
    switch (estado) {
      case EstadoSolicitud.pendiente:
        color = const Color(0xFFB7791F);
        break;
      case EstadoSolicitud.aceptada:
        color = const Color(0xFF2E7D5B);
        break;
      case EstadoSolicitud.rechazada:
        color = theme.colorScheme.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  void _abrirDetalle(
    BuildContext context,
    ThemeData theme,
    AppState state,
    SolicitudSala s,
    Perfil? perfil,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final pendiente = s.estado == EstadoSolicitud.pendiente;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: AppAvatar(
                  initials: perfil?.iniciales ?? '?',
                  imageUrl: perfil?.fotoUrl,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(perfil?.nombreCompleto ?? 'Usuario',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(height: 4),
              Center(child: Text(perfil?.cargo ?? 'Solicitante')),
              const SizedBox(height: 20),
              _fila(theme, 'ID', perfil?.idPersonal ?? '-'),
              _fila(theme, 'Correo', perfil?.correo ?? '-'),
              _fila(theme, 'Teléfono', perfil?.telefono ?? '-'),
              _fila(theme, 'Rol', perfil?.tipoUsuario.label ?? '-'),
              _fila(theme, 'Solicitado', formatDateShort(s.createdAt)),
              const SizedBox(height: 22),
              if (pendiente)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          state.rejectSolicitud(s.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        label: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.acceptSolicitud(s.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aceptar'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Estado: ${s.estado.label}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _fila(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          Flexible(
            child: Text(value, style: theme.textTheme.bodyLarge, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
