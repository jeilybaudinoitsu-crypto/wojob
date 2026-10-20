import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// Turnos/horarios (`public.horarios`).
class SupabaseHorarioRepository implements HorarioRepository {
  SupabaseHorarioRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'horarios';

  @override
  Future<Horario> create(Horario horario) async {
    try {
      await _client.from(_table).insert(horario.toMap());
      return horario;
    } catch (e) {
      throw AppException('No se pudo asignar el turno.', cause: e);
    }
  }

  @override
  Future<List<Horario>> byEmpleado(String empleadoId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('empleado_id', empleadoId);
    return (rows as List)
        .map((e) => Horario.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Horario>> byEmpresa(String empresaId) async {
    final rows =
        await _client.from(_table).select().eq('empresa_id', empresaId);
    return (rows as List)
        .map((e) => Horario.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> delete(String horarioId) async {
    await _client.from(_table).delete().eq('id', horarioId);
  }
}
