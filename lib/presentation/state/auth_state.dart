import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

import 'package:wojob/core/config/app_config.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/auth_error_translator.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/data/datasources/supabase_service.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/domain/repositories/repositories.dart';

const _uuid = Uuid();

const _seedPassword = 'WoJob1234';

/// Estado de autenticación y perfil de usuario.
class AuthState extends ChangeNotifier {
  AuthState({
    this._authRepository,
    this._storageRepository,
  }) {
    if (!isBackendEnabled) _seed();
  }

  final AuthRepository? _authRepository;
  final StorageRepository? _storageRepository;

  bool get isBackendEnabled => _authRepository != null;

  final _perfiles = <String, Perfil>{};
  final _passwords = <String, String>{};

  Perfil? currentUser;
  String? backendError;
  bool isLoading = false;

  void _seed() {
    _perfiles[MockData.admin.id] = MockData.admin;
    _perfiles[MockData.empleado1.id] = MockData.empleado1;
    _perfiles[MockData.empleado2.id] = MockData.empleado2;
    for (final p in [MockData.admin, MockData.empleado1, MockData.empleado2]) {
      _passwords[p.id] = _seedPassword;
    }
  }

  List<Perfil> get perfiles => _perfiles.values.toList();

  Perfil? getPerfil(String id) => _perfiles[id];

  /// Login: acepta correo, teléfono o ID personal y valida la contraseña.
  Future<Perfil?> login(String credential, String password) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      Perfil? profile;
      if (isBackendEnabled) {
        profile = await _authRepository!.signIn(
          correo: credential.trim(),
          password: password,
        );
      } else {
        final q = credential.trim().toLowerCase();
        for (final p in _perfiles.values) {
          if (!p.estadoActivo) continue;
          final coincide =
              p.correo.trim().toLowerCase() == q ||
              p.telefono.trim() == credential.trim() ||
              p.idPersonal.trim().toLowerCase() == q;
          if (!coincide) continue;
          final esperada = _passwords[p.id];
          if (esperada != null && esperada != password) {
            throw const AuthException('Contraseña incorrecta.');
          }
          profile = p;
          break;
        }
      }

      if (profile != null) {
        currentUser = profile;
        _perfiles[profile.id] = profile;
      }
      return profile;
    } on AppException catch (e) {
      backendError = e.message;
      rethrow;
    } catch (e) {
      backendError = 'Error al iniciar sesión.';
      throw AuthException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Perfil?> restoreSession() async {
    if (!isBackendEnabled) return null;
    isLoading = true;
    notifyListeners();
    try {
      final profile = await _authRepository!.restoreSession();
      if (profile != null) {
        currentUser = profile;
        _perfiles[profile.id] = profile;
      }
      return profile;
    } catch (e) {
      backendError = 'Error al restaurar sesión.';
      throw AuthException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (!isBackendEnabled) return;
    try {
      await restoreSession();
    } catch (e) {
      backendError = e is AppException ? e.message : e.toString();
      notifyListeners();
    }
  }

  Future<Perfil> _hydrateProfile(
    Perfil profile, {
    bool refreshPhotoCache = false,
  }) async {
    if (!isBackendEnabled) return profile;
    final storage = _storageRepository!;
    var photoUrl = profile.fotoUrl == null
        ? null
        : await storage.createSignedUrl(
            bucket: AppConfig.avataresBucket,
            path: profile.fotoUrl!,
          );
    if (photoUrl != null && refreshPhotoCache) {
      final uri = Uri.parse(photoUrl);
      photoUrl = uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              'v': DateTime.now().microsecondsSinceEpoch.toString(),
            },
          )
          .toString();
    }
    final identityUrl = profile.cedulaUrl == null
        ? null
        : await storage.createSignedUrl(
            bucket: AppConfig.documentosBucket,
            path: profile.cedulaUrl!,
          );
    return profile.copyWith(fotoUrl: photoUrl, cedulaUrl: identityUrl);
  }

  /// Registra un usuario nuevo.
  Future<Perfil> register({
    required TipoUsuario tipoUsuario,
    required String nombreCompleto,
    required String correo,
    required String telefono,
    required String idPersonal,
    required String cargo,
    required String password,
    Uint8List? fotoBytes,
    Uint8List? cedulaBytes,
  }) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final nuevo = Perfil(
        id: isBackendEnabled ? '' : _uuid.v4(),
        empresaId: null,
        tipoUsuario: tipoUsuario,
        nombreCompleto: nombreCompleto.trim(),
        correo: correo.trim(),
        telefono: telefono.trim(),
        idPersonal: idPersonal.trim(),
        cargo: cargo.trim().isEmpty ? null : cargo.trim(),
        estadoActivo: true,
        verificado: false,
        fotoUrl: isBackendEnabled ? null : null,
        cedulaUrl: isBackendEnabled ? null : null,
        createdAt: DateTime.now(),
      );

      Perfil profile;
      if (isBackendEnabled) {
        profile = await _authRepository!.registerAccount(
          perfil: nuevo,
          password: password,
        );
        final photoPath = fotoBytes == null
            ? null
            : await _storageRepository!.upload(
                bucket: AppConfig.avataresBucket,
                path: '${profile.id}/foto.jpg',
                bytes: fotoBytes,
              );
        final identityPath = cedulaBytes == null
            ? null
            : await _storageRepository!.upload(
                bucket: AppConfig.documentosBucket,
                path: '${profile.id}/cedula.jpg',
                bytes: cedulaBytes,
              );
        if (photoPath != null || identityPath != null) {
          profile = await _authRepository.updatePhotos(
            profile.copyWith(fotoUrl: photoPath, cedulaUrl: identityPath),
          );
        }
        profile = await _hydrateProfile(profile);
      } else {
        profile = nuevo;
        _passwords[profile.id] = password;
      }

      _perfiles[profile.id] = profile;
      currentUser = profile;
      return profile;
    } on AppException catch (e) {
      backendError = e.message;
      rethrow;
    } catch (e) {
      backendError = 'Error al registrar la cuenta.';
      throw AuthException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (isBackendEnabled) {
      try {
        await _authRepository!.signOut();
      } catch (_) {}
    }
    currentUser = null;
    notifyListeners();
  }

  Future<Perfil> leaveRoom() async {
    if (isBackendEnabled && _authRepository != null) {
      try {
        final client = await _getSupabaseClient();
        if (client != null) {
          final res = await client.rpc('leave_room');
          if (res != null) {
            final updated = Perfil.fromMap(res as Map<String, dynamic>);
            final hydrated = await _hydrateProfile(updated);
            _perfiles[hydrated.id] = hydrated;
            if (currentUser?.id == hydrated.id) currentUser = hydrated;
            notifyListeners();
            return hydrated;
          }
        }
      } catch (e) {
        if (e is AppException) rethrow;
        throw AuthException('No se pudo salir de la sala.', cause: e);
      }
    }
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(empresaId: null, clearEmpresa: true);
      _perfiles[currentUser!.id] = currentUser!;
      notifyListeners();
      return currentUser!;
    }
    throw const AuthException('No hay sesión activa.');
  }

  Future<Perfil> deleteAccount({required String password}) async {
    if (isBackendEnabled && _authRepository != null) {
      try {
        final client = await _getSupabaseClient();
        if (client != null) {
          // Verify password by re-authenticating
          if (currentUser?.correo != null) {
            try {
              await client.auth.signInWithPassword(
                email: currentUser!.correo,
                password: password,
              );
            } catch (e) {
              throw const AuthException('Contraseña incorrecta.');
            }
          }
          await client.rpc('delete_own_account');
          currentUser = null;
          notifyListeners();
          return currentUser ?? (throw const AuthException('Cuenta eliminada.'));
        }
      } catch (e) {
        if (e is AppException) rethrow;
        throw AuthException('No se pudo eliminar la cuenta.', cause: e);
      }
    }
    throw const AuthException('Esta acción solo está disponible con Supabase.');
  }

  Future<void> verifyCurrentPassword(String password) async {
    if (!isBackendEnabled) return;
    try {
      final client = await _getSupabaseClient();
      if (client != null && currentUser?.correo != null) {
        await client.auth.signInWithPassword(
          email: currentUser!.correo,
          password: password,
        );
      }
    } catch (e) {
      throw const AuthException('Contraseña incorrecta.');
    }
  }

  Future<void> sendContactChangeCode(String currentEmail) async {
    if (!isBackendEnabled) return;
    try {
      final client = await _getSupabaseClient();
      if (client != null) {
        await client.auth.resetPasswordForEmail(currentEmail);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('No se pudo enviar el código de verificación.', cause: e);
    }
  }

  Future<void> verifyContactChangeCode({
    required String email,
    required String code,
  }) async {
    if (!isBackendEnabled) return;
    try {
      final client = await _getSupabaseClient();
      if (client != null) {
        await client.auth.verifyOTP(
          email: email,
          token: code,
          type: sb.OtpType.recovery,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AuthException('El código de verificación no es válido o ha expirado.');
    }
  }

  Future<void> requestEmailChange(String newEmail) async {
    if (!isBackendEnabled) return;
    try {
      final client = await _getSupabaseClient();
      if (client != null) {
        await client.auth.updateUser(sb.UserAttributes(email: newEmail.trim()));
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException(translateAuthError(e.toString()), cause: e);
    }
  }

  Future<void> verifyEmailChangeCode({
    required String email,
    required String code,
  }) async {
    if (!isBackendEnabled) return;
    try {
      final client = await _getSupabaseClient();
      if (client != null) {
        await client.auth.verifyOTP(
          email: email.trim(),
          token: code.trim(),
          type: sb.OtpType.emailChange,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException(translateAuthError(e.toString()), cause: e);
    }
  }

  Future<void> updateContact({
    required String correo,
    required String telefono,
    required String password,
  }) async {
    if (isBackendEnabled) {
      try {
        final client = await _getSupabaseClient();
        if (client != null && currentUser != null) {
          final res = await client.rpc('update_own_contact', params: {
            'p_correo': correo.trim(),
            'p_telefono': telefono.trim(),
          });
          if (res != null) {
            final updated = Perfil.fromMap(res as Map<String, dynamic>);
            final hydrated = await _hydrateProfile(updated);
            _perfiles[hydrated.id] = hydrated;
            if (currentUser?.id == hydrated.id) currentUser = hydrated;
            notifyListeners();
            return;
          }
        }
        throw const AuthException('No se pudo actualizar la información de contacto.');
      } catch (e) {
        if (e is AppException) rethrow;
        throw AuthException(translateAuthError(e.toString()), cause: e);
      }
    } else {
      if (currentUser != null) {
        final updated = currentUser!.copyWith(correo: correo.trim(), telefono: telefono.trim());
        _perfiles[updated.id] = updated;
        currentUser = updated;
        notifyListeners();
      }
    }
  }

  Future<sb.SupabaseClient?> _getSupabaseClient() async {
    try {
      if (SupabaseService.isEnabled) {
        return SupabaseService.client;
      }
    } catch (_) {}
    return null;
  }

  /// Envía código OTP por correo para restablecer la contraseña (solo backend).
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isBackendEnabled || _authRepository == null) {
      throw const AuthException(
        'Recuperación de contraseña solo disponible con Supabase.',
      );
    }
    await _authRepository.sendPasswordResetEmail(email);
  }

  /// Verifica el código OTP enviado por correo.
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    if (!isBackendEnabled || _authRepository == null) {
      throw const AuthException(
        'Recuperación de contraseña solo disponible con Supabase.',
      );
    }
    await _authRepository.verifyPasswordResetCode(email: email, code: code);
  }

  /// Actualiza la contraseña tras la verificación del código.
  Future<void> updatePassword({required String newPassword}) async {
    if (!isBackendEnabled || _authRepository == null) {
      throw const AuthException(
        'Recuperación de contraseña solo disponible con Supabase.',
      );
    }
    await _authRepository.updatePassword(newPassword: newPassword);
  }

  Future<Perfil?> findById(String userId) async {
    if (!isBackendEnabled) return _perfiles[userId];
    final profile = await _authRepository!.findById(userId);
    if (profile != null) return _hydrateProfile(profile);
    return null;
  }

  Future<List<Perfil>> byEmpresa(String empresaId) async {
    if (!isBackendEnabled) {
      return _perfiles.values.where((p) => p.empresaId == empresaId).toList();
    }
    final profiles = await _authRepository!.byEmpresa(empresaId);
    return Future.wait(profiles.map(_hydrateProfile));
  }

  Future<Perfil> updateProfile(
    Perfil profile, {
    bool refreshPhotoCache = false,
  }) async {
    if (isBackendEnabled) {
      profile = await _authRepository!.updatePhotos(profile);
      profile = await _hydrateProfile(
        profile,
        refreshPhotoCache: refreshPhotoCache,
      );
    }
    _perfiles[profile.id] = profile;
    if (currentUser?.id == profile.id) currentUser = profile;
    notifyListeners();
    return profile;
  }

  Future<Perfil> updateProfilePhoto(Uint8List bytes) async {
    if (isBackendEnabled && _storageRepository != null && currentUser != null) {
      final photoPath = await _storageRepository.upload(
        bucket: AppConfig.avataresBucket,
        path: '${currentUser!.id}/foto.jpg',
        bytes: bytes,
        upsert: true,
      );
      final updatedProfile = currentUser!.copyWith(fotoUrl: photoPath);
      return updateProfile(updatedProfile, refreshPhotoCache: true);
    }
    throw const AuthException('Esta acción solo está disponible con Supabase.');
  }

  Future<Perfil> updateEmpresa(String userId, String? empresaId) async {
    Perfil? profile;
    if (isBackendEnabled) {
      profile = await _authRepository!.updateEmpresa(userId, empresaId);
      profile = await _hydrateProfile(profile);
    } else {
      profile = _perfiles[userId]?.copyWith(empresaId: empresaId);
    }
    if (profile != null) {
      _perfiles[profile.id] = profile;
      if (currentUser?.id == profile.id) currentUser = profile;
      notifyListeners();
    }
    return profile!;
  }

  void clearError() {
    backendError = null;
    notifyListeners();
  }
}
