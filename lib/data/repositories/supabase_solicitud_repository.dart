import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// Solicitudes de acceso a una sala (`public.solicitudes_sala`).
class SupabaseSolicitudRepository implements SolicitudRepository {
  SupabaseSolicitudRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'solicitudes_sala';

  @override
  Future<SolicitudSala> create(SolicitudSala solicitud) async {
    try {
      await _client.from(_table).insert(solicitud.toMap());
      return solicitud;
    } catch (e) {
      throw UnknownException('No se pudo enviar la solicitud.', cause: e);
    }
  }

  @override
  Future<List<SolicitudSala>> byEmpresa(String empresaId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('empresa_id', empresaId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => SolicitudSala.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateEstado(
    String solicitudId,
    EstadoSolicitud estado,
  ) async {
    await _client
        .from(_table)
        .update({'estado': estado.dbValue}).eq('id', solicitudId);
  }
}