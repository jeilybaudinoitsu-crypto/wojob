import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// CRUD de salas/empresas sobre la tabla `public.empresas`.
class SupabaseEmpresaRepository implements EmpresaRepository {
  SupabaseEmpresaRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'empresas';
  static const String _columns =
      'id,id_sala,nombre_empresa,direccion_empresa,created_at';

  @override
  Future<Empresa> create(Empresa empresa) async {
    try {
      final data = await _client
          .from(_table)
          .insert(empresa.toMap())
          .select(_columns)
          .single();
      return Empresa.fromMap(data);
    } catch (e) {
      throw AppException('No se pudo crear la sala.', cause: e);
    }
  }

  @override
  Future<Empresa?> findById(String id) async {
    final data =
        await _client
            .from(_table)
            .select(_columns)
            .eq('id', id)
            .maybeSingle();
    return data == null ? null : Empresa.fromMap(data);
  }

  @override
  Future<Empresa?> findBySalaId(String idSala) async {
    final data = await _client
        .from(_table)
        .select(_columns)
        .eq('id_sala', idSala.trim().toUpperCase())
        .maybeSingle();
    return data == null ? null : Empresa.fromMap(data);
  }

  @override
  Future<List<Empresa>> all() async {
    final rows = await _client.from(_table).select(_columns);
    return (rows as List)
        .map((e) => Empresa.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
