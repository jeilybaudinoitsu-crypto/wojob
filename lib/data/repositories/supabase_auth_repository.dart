import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/auth_error_translator.dart';
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
  Future<Perfil?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from(_table)
        .select()
        .eq('id', user.id)
        .maybeSingle();
    _current = data == null ? null : Perfil.fromMap(data);
    return _current;
  }

  @override
  Future<Perfil> registerAccount({
    required Perfil perfil,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: perfil.correo.trim(),
        password: password,
        data: {
          'tipo_usuario': perfil.tipoUsuario.dbValue,
          'nombre_completo': perfil.nombreCompleto,
          'telefono': perfil.telefono,
          'id_personal': perfil.idPersonal,
          'cargo': perfil.cargo,
        },
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('No se pudo crear la cuenta en Supabase.');
      }
      if (res.session == null) {
        throw const AuthException(
          'Supabase todavía requiere confirmar el correo. Desactiva “Confirm email” en Authentication → Sign In / Providers → Email.',
        );
      }

      final data = await _client
          .from(_table)
          .select()
          .eq('id', user.id)
          .single();
      _current = Perfil.fromMap(data);
      return _current!;
    } on sb.AuthException catch (e) {
      throw AuthException(translateAuthError(e.message), cause: e);
    } on sb.PostgrestException catch (e) {
      if (e.code == '42501') {
        throw AuthException(
          'La cuenta se creó, pero Supabase bloqueó la lectura del perfil. Revisa las políticas RLS de public.perfiles.',
          cause: e,
        );
      }
      if (e.code == 'PGRST116') {
        throw AuthException(
          'La cuenta se creó, pero no se encontró su perfil. Ejecuta supabase/auth_registration.sql y revisa la política de lectura del perfil propio.',
          cause: e,
        );
      }
      throw AuthException(
        'No se pudo obtener el perfil recién creado.',
        cause: e,
      );
    } catch (e) {
      throw AuthException('No se pudo completar el registro.', cause: e);
    }
  }

  @override
  Future<Perfil?> signIn({
    required String correo,
    required String password,
  }) async {
    try {
      String email = correo.trim();

      // If input is not an email, try to find user by phone or id_personal
      if (!email.contains('@')) {
        final userByPhone = await _client
            .from(_table)
            .select('correo')
            .eq('telefono', correo.trim())
            .maybeSingle();
        if (userByPhone != null) {
          email = userByPhone['correo'] as String;
        } else {
          final userById = await _client
              .from(_table)
              .select('correo')
              .eq('id_personal', correo.trim())
              .maybeSingle();
          if (userById != null) {
            email = userById['correo'] as String;
          }
        }
      }

      final res = await _client.auth.signInWithPassword(
        email: email,
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
      throw AuthException(translateAuthError(e.message), cause: e);
    } catch (e) {
      throw AuthException('Error al iniciar sesión.', cause: e);
    }
  }

  @override
  Future<List<Perfil>> byEmpresa(String empresaId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('empresa_id', empresaId);
    return (rows as List)
        .map((row) => Perfil.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Perfil?> findById(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : Perfil.fromMap(data);
  }

  @override
  Future<Perfil> updatePhotos(Perfil perfil) async {
    final data = await _client
        .from(_table)
        .update({'foto_url': perfil.fotoUrl, 'cedula_url': perfil.cedulaUrl})
        .eq('id', perfil.id)
        .select()
        .single();
    final updated = Perfil.fromMap(data);
    if (_client.auth.currentUser?.id == perfil.id) _current = updated;
    return updated;
  }

  @override
  Future<Perfil> updateEmpresa(String userId, String? empresaId) async {
    final data = await _client
        .from(_table)
        .update({'empresa_id': empresaId})
        .eq('id', userId)
        .select()
        .single();
    final updated = Perfil.fromMap(data);
    if (_client.auth.currentUser?.id == userId) _current = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _current = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, cause: e);
    } catch (e) {
      throw AuthException(
        'No se pudo enviar el código de recuperación.',
        cause: e,
      );
    }
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: sb.OtpType.recovery,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, cause: e);
    } catch (e) {
      throw AuthException(
        'El código de verificación no es válido o ha expirado.',
        cause: e,
      );
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, cause: e);
    } catch (e) {
      throw AuthException('No se pudo actualizar la contraseña.', cause: e);
    }
  }
}
