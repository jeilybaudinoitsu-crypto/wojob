import 'dart:typed_data';

import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';

/// Contratos de la capa de dominio.
///
/// La presentación depende de estas interfaces, no de las implementaciones
/// concretas (Supabase, mock, etc.). Así se puede cambiar el origen de datos
/// sin tocar las pantallas.
abstract class AuthRepository {
  bool get isAuthenticated;

  /// Perfil del usuario con sesión activa (si existe).
  Perfil? get currentProfile;

  Future<Perfil?> restoreSession();

  /// Envía el código de confirmación al correo y devuelve si debe verificarse.
  Future<bool> sendSignUpCode({
    required String email,
    required String password,
  });

  /// Verifica el código de confirmación del registro.
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  });

  /// Crea el perfil de la cuenta ya autenticada.
  Future<Perfil> createProfile(Perfil perfil);

  /// Inicia sesión y devuelve el perfil del usuario.
  Future<Perfil?> signIn({required String correo, required String password});

  Future<List<Perfil>> byEmpresa(String empresaId);
  Future<Perfil?> findById(String userId);
  Future<Perfil> updatePhotos(Perfil perfil);
  Future<Perfil> updateEmpresa(String userId, String? empresaId);

  Future<void> signOut();

  /// Envía un código OTP de recuperación de contraseña al correo.
  Future<void> sendPasswordResetEmail(String email);

  /// Verifica el código OTP enviado por correo para recuperación.
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// Actualiza la contraseña tras verificar el código (usuario autenticado).
  Future<void> updatePassword({required String newPassword});
}

abstract class EmpresaRepository {
  Future<Empresa> create(Empresa empresa);
  Future<Empresa?> findById(String id);
  Future<Empresa?> findBySalaId(String idSala);
  Future<List<Empresa>> all();
}

abstract class SolicitudRepository {
  Future<SolicitudSala> create(SolicitudSala solicitud);
  Future<List<SolicitudSala>> byEmpresa(String empresaId);
  Future<void> updateEstado(String solicitudId, EstadoSolicitud estado);
}

abstract class HorarioRepository {
  Future<Horario> create(Horario horario);
  Future<List<Horario>> byEmpleado(String empleadoId);
  Future<List<Horario>> byEmpresa(String empresaId);
  Future<void> delete(String horarioId);
}

abstract class AsistenciaRepository {
  Future<Asistencia> create(Asistencia asistencia);
  Future<List<Asistencia>> byEmpleado(String empleadoId);
  Future<List<Asistencia>> byEmpresa(String empresaId);
}

abstract class StorageRepository {
  /// Sube bytes a un bucket privado y devuelve la ruta del objeto.
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
  });

  /// Actualiza un archivo existente (sobrescribe).
  Future<String> update({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });

  /// Elimina un archivo.
  Future<void> delete({
    required String bucket,
    required String path,
  });
}