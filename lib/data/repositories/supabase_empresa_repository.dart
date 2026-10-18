import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// CRUD de salas/empresas sobre la tabla `public.empresas`.
class SupabaseEmpresaRepository implements EmpresaRepository {
  SupabaseEmpresaRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'empresas';

  @override
  Future<Empresa> create(Empresa empresa) async {
    try {
      await _client.from(_table).insert(empresa.toMap());
      return empresa;
    } catch (e) {
      throw AppException('No se pudo crear la sala.', cause: e);
    }
  }

  @override
  Future<Empresa?> findById(String id) async {
    final data =
        await _client.from(_table).select().eq('id', id).maybeSingle();
    return data == null ? null : Empresa.fromMap(data);
  }

  @override
  Future<Empresa?> findBySalaId(String idSala) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('id_sala', idSala.trim().toUpperCase())
        .maybeSingle();
    return data == null ? null : Empresa.fromMap(data);
  }

  @override
  Future<List<Empresa>> all() async {
    final rows = await _client.from(_table).select();
    return (rows as List)
        .map((e) => Empresa.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
