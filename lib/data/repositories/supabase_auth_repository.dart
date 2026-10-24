import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/domain/repositories/repositories.dart';

String _translateAuthError(String message) {
  final msg = message.toLowerCase();
  if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
  }
  if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
    return 'Credenciales inválidas. Verifica tu correo y contraseña.';
  }
  if (msg.contains('email not confirmed') || msg.contains('email not verified')) {
    return 'El correo no está confirmado. Revisa tu bandeja de entrada.';
  }
  if (msg.contains('user not found') || msg.contains('no user found')) {
    return 'Usuario no encontrado.';
  }
  if (msg.contains('email already exists') || msg.contains('user already registered')) {
    return 'El correo ya está registrado.';
  }
  if (msg.contains('weak password') || msg.contains('password should be at least')) {
    return 'Contraseña muy débil. Usa al menos 6 caracteres.';
  }
  if (msg.contains('invalid email') || msg.contains('email format')) {
    return 'Formato de correo inválido.';
  }
  if (msg.contains('signup disabled') || msg.contains('registration disabled')) {
    return 'Registro deshabilitado. Contacta al administrador.';
  }
  if (msg.contains('anonymous provider disabled')) {
    return 'Acceso anónimo deshabilitado.';
  }
  if (msg.contains('refresh token') || msg.contains('session expired')) {
    return 'Sesión expirada. Inicia sesión de nuevo.';
  }
  return message;
}

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

    final data =
        await _client.from(_table).select().eq('id', user.id).maybeSingle();
    _current = data == null ? null : Perfil.fromMap(data);
    return _current;
  }

  @override
  Future<bool> sendSignUpCode({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) {
        throw const AuthException('No se pudo crear la cuenta en Supabase.');
      }
      return res.session == null;
    } on AppException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthException(_translateAuthError(e.message), cause: e);
    } catch (e) {
      throw AuthException('No se pudo iniciar el registro.', cause: e);
    }
  }

  @override
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: sb.OtpType.signup,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, cause: e);
    } catch (e) {
      throw AuthException(
        'El código de registro no es válido o ha expirado.',
        cause: e,
      );
    }
  }

  @override
  Future<Perfil> createProfile(Perfil perfil) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException(
          'Verifica primero el código enviado a tu correo.',
        );
      }

      final existing = await _client
          .from(_table)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) {
        _current = Perfil.fromMap(existing);
        return _current!;
      }

      final row = perfil.toMap()..['id'] = user.id;
      await _client.from(_table).insert(row);

      _current = Perfil.fromMap(row);
      return _current!;
    } on AppException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthException(_translateAuthError(e.message), cause: e);
    } catch (e) {
      throw AuthException('Error al crear el perfil.', cause: e);
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
      throw AuthException(_translateAuthError(e.message), cause: e);
    } catch (e) {
      throw AuthException('Error al iniciar sesión.', cause: e);
    }
  }

  @override
  Future<List<Perfil>> byEmpresa(String empresaId) async {
    final rows =
        await _client.from(_table).select().eq('empresa_id', empresaId);
    return (rows as List)
        .map((row) => Perfil.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Perfil?> findById(String userId) async {
    final data =
        await _client.from(_table).select().eq('id', userId).maybeSingle();
    return data == null ? null : Perfil.fromMap(data);
  }

  @override
  Future<Perfil> updatePhotos(Perfil perfil) async {
    final data = await _client
        .from(_table)
        .update({
          'foto_url': perfil.fotoUrl,
          'cedula_url': perfil.cedulaUrl,
        })
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
      throw AuthException('No se pudo enviar el código de recuperación.', cause: e);
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
      throw AuthException('El código de verificación no es válido o ha expirado.', cause: e);
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, cause: e);
    } catch (e) {
      throw AuthException('No se pudo actualizar la contraseña.', cause: e);
    }
  }
}