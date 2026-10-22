import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// Historial de asistencias (`public.asistencias`).
class SupabaseAsistenciaRepository implements AsistenciaRepository {
  SupabaseAsistenciaRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'asistencias';

  @override
  Future<Asistencia> create(Asistencia asistencia) async {
    try {
      await _client.from(_table).insert(asistencia.toMap());
      return asistencia;
    } catch (e) {
      throw UnknownException('No se pudo registrar la asistencia.', cause: e);
    }
  }

  @override
  Future<List<Asistencia>> byEmpleado(String empleadoId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('empleado_id', empleadoId)
        .order('fecha_hora', ascending: false);
    return (rows as List)
        .map((e) => Asistencia.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Asistencia>> byEmpresa(String empresaId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('empresa_id', empresaId)
        .order('fecha_hora', ascending: false);
    return (rows as List)
        .map((e) => Asistencia.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}