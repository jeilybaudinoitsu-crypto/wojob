import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// Implementación de [AuthRepository] sobre Supabase Auth + tabla `perfiles`.
///
/// El esquema exige que `perfiles.id` sea el mismo UUID de `auth.users.id`.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'perfiles';

  Perfil? _current;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Perfil? get currentProfile => _current;

  @override
  Future<Perfil> signUp({
    required Perfil perfil,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: perfil.correo,
        password: password,
      );
      final authUser = res.user;
      if (authUser == null) {
        throw const AppException('No se pudo crear la cuenta en Supabase.');
      }

      final row = perfil.toMap()..['id'] = authUser.id;
      await _client.from(_table).insert(row);

      _current = Perfil.fromMap(row);
      return _current!;
    } on AppException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AppException(e.message, cause: e);
    } catch (e) {
      throw AppException('Error al registrar la cuenta.', cause: e);
    }
  }

  @override
  Future<Perfil?> signIn({
    required String correo,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: correo,
        password: password,
      );
      final uid = res.user?.id;
      if (uid == null) return null;

      final data = await _client
          .from(_table)
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data == null) return null;

      _current = Perfil.fromMap(data);
      return _current;
    } on sb.AuthException catch (e) {
      throw AppException(e.message, cause: e);
    } catch (e) {
      throw AppException('Error al iniciar sesión.', cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _current = null;
  }
}
