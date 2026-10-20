import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wojob/core/config/app_config.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/domain/repositories/repositories.dart';

const _uuid = Uuid();

/// Contraseña por defecto de los usuarios de ejemplo (mock).
const _seedPassword = 'WoJob1234';

class AppState extends ChangeNotifier {
  AppState({
    AuthRepository? authRepository,
    EmpresaRepository? empresaRepository,
    SolicitudRepository? solicitudRepository,
    HorarioRepository? horarioRepository,
    AsistenciaRepository? asistenciaRepository,
    StorageRepository? storageRepository,
  })  : _authRepository = authRepository,
        _empresaRepository = empresaRepository,
        _solicitudRepository = solicitudRepository,
        _horarioRepository = horarioRepository,
        _asistenciaRepository = asistenciaRepository,
        _storageRepository = storageRepository {
    if (!isBackendEnabled) _seed();
  }

  final AuthRepository? _authRepository;
  final EmpresaRepository? _empresaRepository;
  final SolicitudRepository? _solicitudRepository;
  final HorarioRepository? _horarioRepository;
  final AsistenciaRepository? _asistenciaRepository;
  final StorageRepository? _storageRepository;

  bool get isBackendEnabled => _authRepository != null;

  final _empresas = <String, Empresa>{};
  final _perfiles = <String, Perfil>{};
  final _solicitudes = <String, SolicitudSala>{};
  final _horarios = <String, Horario>{};
  final _asistencias = <String, Asistencia>{};

  /// Almacén de contraseñas (mock).
  ///
  /// En producción la contraseña la gestiona Supabase Auth y NO se guarda aquí.
  final _passwords = <String, String>{};

  Perfil? currentUser;
  String? backendError;
  ThemeMode themeMode = ThemeMode.light;

  void _seed() {
    _empresas[MockData.empresa.id] = MockData.empresa;
    _perfiles[MockData.admin.id] = MockData.admin;
    _perfiles[MockData.empleado1.id] = MockData.empleado1;
    _perfiles[MockData.empleado2.id] = MockData.empleado2;
    for (final p in [MockData.admin, MockData.empleado1, MockData.empleado2]) {
      _passwords[p.id] = _seedPassword;
    }
    for (final s in MockData.solicitudesPendientes) {
      _solicitudes[s.id] = s;
    }
    for (final h in MockData.horarios) {
      _horarios[h.id] = h;
    }
    for (final a in MockData.asistencias) {
      _asistencias[a.id] = a;
    }
  }

  List<Empresa> get empresas => _empresas.values.toList();

  List<Perfil> get perfiles => _perfiles.values.toList();
  List<SolicitudSala> get solicitudes => _solicitudes.values.toList();
  List<Horario> get horarios => _horarios.values.toList();
  List<Asistencia> get asistencias => _asistencias.values.toList();

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  /// Login: acepta correo, teléfono o ID personal y valida la contraseña.
  Future<Perfil?> login(String credential, String password) async {
    if (isBackendEnabled) {
      if (!credential.contains('@')) {
        throw const AppException(
          'Con Supabase inicia sesión con correo electrónico. '
          'El teléfono y el ID solo funcionan en modo de demostración.',
        );
      }
      final profile = await _authRepository!
          .signIn(correo: credential.trim(), password: password);
      if (profile == null) return null;
      await _loadUserData(profile);
      notifyListeners();
      return currentUser;
    }

    final q = credential.trim().toLowerCase();
    for (final p in _perfiles.values) {
      if (!p.estadoActivo) continue;
      final coincide = p.correo.trim().toLowerCase() == q ||
          p.telefono.trim() == credential.trim() ||
          p.idPersonal.trim().toLowerCase() == q;
      if (!coincide) continue;
      final esperada = _passwords[p.id];
      if (esperada != null && esperada != password) {
        return null; // credencial correcta, contraseña incorrecta
      }
      currentUser = p;
      notifyListeners();
      return currentUser;
    }
    return null;
  }

  Future<Perfil?> restoreSession() async {
    if (!isBackendEnabled) return null;
    final profile = await _authRepository!.restoreSession();
    if (profile == null) return null;
    await _loadUserData(profile);
    notifyListeners();
    return currentUser;
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

  Future<void> _loadUserData(Perfil profile) async {
    _empresas.clear();
    _perfiles.clear();
    _solicitudes.clear();
    _horarios.clear();
    _asistencias.clear();

    final user = await _hydrateProfile(profile);
    currentUser = user;
    _perfiles[user.id] = user;
    final empresaId = user.empresaId;
    if (empresaId == null) return;

    final empresa = await _empresaRepository!.findById(empresaId);
    if (empresa != null) _empresas[empresa.id] = empresa;

    final members = await _authRepository!.byEmpresa(empresaId);
    for (final member in members) {
      _perfiles[member.id] = await _hydrateProfile(member);
    }
    if (user.isAdmin) {
      for (final solicitud
          in await _solicitudRepository!.byEmpresa(empresaId)) {
        _solicitudes[solicitud.id] = solicitud;
        if (!_perfiles.containsKey(solicitud.usuarioId)) {
          final applicant =
              await _authRepository.findById(solicitud.usuarioId);
          if (applicant != null) {
            _perfiles[applicant.id] = await _hydrateProfile(applicant);
          }
        }
      }
      for (final horario in await _horarioRepository!.byEmpresa(empresaId)) {
        _horarios[horario.id] = horario;
      }
      for (final asistencia in await _asistenciaRepository!.byEmpresa(empresaId)) {
        _asistencias[asistencia.id] = await _hydrateAttendance(asistencia);
      }
    } else {
      for (final horario in await _horarioRepository!.byEmpleado(user.id)) {
        _horarios[horario.id] = horario;
      }
      for (final asistencia
          in await _asistenciaRepository!.byEmpleado(user.id)) {
        _asistencias[asistencia.id] = await _hydrateAttendance(asistencia);
      }
    }
  }

  Future<Perfil> _hydrateProfile(Perfil profile) async {
    if (!isBackendEnabled) return profile;
    final storage = _storageRepository!;
    final photoUrl = profile.fotoUrl == null
        ? null
        : await storage.createSignedUrl(
            bucket: AppConfig.avataresBucket,
            path: profile.fotoUrl!,
          );
    final identityUrl = profile.cedulaUrl == null
        ? null
        : await storage.createSignedUrl(
            bucket: AppConfig.documentosBucket,
            path: profile.cedulaUrl!,
          );
    return profile.copyWith(fotoUrl: photoUrl, cedulaUrl: identityUrl);
  }

  Future<Asistencia> _hydrateAttendance(Asistencia asistencia) async {
    if (!isBackendEnabled) return asistencia;
    final photoUrl = await _storageRepository!.createSignedUrl(
      bucket: AppConfig.asistenciasBucket,
      path: asistencia.fotoUrl,
    );
    return Asistencia(
      id: asistencia.id,
      empleadoId: asistencia.empleadoId,
      empresaId: asistencia.empresaId,
      tipo: asistencia.tipo,
      fechaHora: asistencia.fechaHora,
      latitud: asistencia.latitud,
      longitud: asistencia.longitud,
      fotoUrl: photoUrl,
    );
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
    String? fotoUrl,
    String? cedulaUrl,
    Uint8List? fotoBytes,
    Uint8List? cedulaBytes,
  }) async {
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
      fotoUrl: isBackendEnabled ? null : fotoUrl,
      cedulaUrl: isBackendEnabled ? null : cedulaUrl,
      createdAt: DateTime.now(),
    );
    if (isBackendEnabled) {
      var profile =
          await _authRepository!.signUp(perfil: nuevo, password: password);
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
          profile.copyWith(
            fotoUrl: photoPath,
            cedulaUrl: identityPath,
          ),
        );
      }
      final displayedProfile = await _hydrateProfile(profile);
      _perfiles[profile.id] = displayedProfile;
      currentUser = displayedProfile;
      notifyListeners();
      return displayedProfile;
    }

    final id = nuevo.id;
    _perfiles[id] = nuevo;
    _passwords[id] = password;
    currentUser = nuevo;
    notifyListeners();
    return nuevo;
  }

  Future<void> logout() async {
    if (isBackendEnabled) await _authRepository!.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<bool> sendSolicitud(String empresaId, String usuarioId) async {
    final empresaExiste = _empresas.containsKey(empresaId);
    final user = _perfiles[usuarioId];
    if (!empresaExiste || user == null) return false;
    final yaExiste = _solicitudes.values.any(
      (s) =>
          s.empresaId == empresaId &&
          s.usuarioId == usuarioId &&
          s.estado == EstadoSolicitud.pendiente,
    );
    if (yaExiste) return false;
    final id = _uuid.v4();
    final s = SolicitudSala(
      id: id,
      empresaId: empresaId,
      usuarioId: usuarioId,
      estado: EstadoSolicitud.pendiente,
      createdAt: DateTime.now(),
    );
    final stored = isBackendEnabled
        ? await _solicitudRepository!.create(s)
        : s;
    _solicitudes[stored.id] = stored;
    notifyListeners();
    return true;
  }

  Future<bool> acceptSolicitud(String solicitudId) async {
    final s = _solicitudes[solicitudId];
    if (s == null) return false;
    var user = _perfiles[s.usuarioId];
    if (user == null && isBackendEnabled) {
      final profile = await _authRepository!.findById(s.usuarioId);
      if (profile != null) user = await _hydrateProfile(profile);
    }
    if (user == null) return false;
    if (isBackendEnabled) {
      await _authRepository!.updateEmpresa(user.id, s.empresaId);
      await _solicitudRepository!
          .updateEstado(solicitudId, EstadoSolicitud.aceptada);
    }
    _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.aceptada);
    _perfiles[user.id] =
        user.copyWith(empresaId: s.empresaId, clearEmpresa: false);
    if (currentUser?.id == user.id) {
      currentUser = _perfiles[user.id];
    }
    notifyListeners();
    return true;
  }

  Future<bool> rejectSolicitud(String solicitudId) async {
    final s = _solicitudes[solicitudId];
    if (s == null) return false;
    if (isBackendEnabled) {
      await _solicitudRepository!
          .updateEstado(solicitudId, EstadoSolicitud.rechazada);
    }
    _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.rechazada);
    notifyListeners();
    return true;
  }

  /// Crea una sala (empresa).
  Future<Empresa> createSala({
    required String nombreEmpresa,
    required String direccionEmpresa,
    required String passwordHash,
  }) async {
    final id = _uuid.v4();
    final emp = Empresa(
      id: id,
      idSala: _generarIdSala(),
      nombreEmpresa: nombreEmpresa.trim(),
      direccionEmpresa: direccionEmpresa.trim(),
      passwordHash: passwordHash,
      createdAt: DateTime.now(),
    );
    final stored =
        isBackendEnabled ? await _empresaRepository!.create(emp) : emp;
    _empresas[stored.id] = stored;
    final user = currentUser;
    if (user != null) {
      if (isBackendEnabled) {
        await _authRepository!.updateEmpresa(user.id, stored.id);
      }
      _perfiles[user.id] = user.copyWith(empresaId: stored.id);
      currentUser = _perfiles[user.id];
    }
    notifyListeners();
    return stored;
  }

  String _generarIdSala() {
    final rnd = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();
    return 'NOR-$rnd';
  }

  Empresa? findEmpresaBySalaId(String salaId) {
    final v = salaId.trim().toUpperCase();
    for (final e in _empresas.values) {
      if (e.idSala.trim().toUpperCase() == v) return e;
    }
    return null;
  }

  Future<bool> joinSala(String salaId, {required String usuarioId}) async {
    final emp = isBackendEnabled
        ? await _empresaRepository!.findBySalaId(salaId)
        : findEmpresaBySalaId(salaId);
    if (emp == null) return false;
    _empresas[emp.id] = emp;
    return sendSolicitud(emp.id, usuarioId);
  }

  /// Asigna un turno (horario) a un empleado.
  Future<Horario> assignShift({
    required String empresaId,
    required String empleadoId,
    required DiaSemana diaSemana,
    required String horaEntrada,
    required String horaSalida,
  }) async {
    final id = _uuid.v4();
    final h = Horario(
      id: id,
      empresaId: empresaId,
      empleadoId: empleadoId,
      diaSemana: diaSemana,
      horaEntrada: horaEntrada,
      horaSalida: horaSalida,
      createdAt: DateTime.now(),
    );
    final stored =
        isBackendEnabled ? await _horarioRepository!.create(h) : h;
    _horarios[stored.id] = stored;
    notifyListeners();
    return stored;
  }

  Future<bool> removeShift(String horarioId) async {
    if (!_horarios.containsKey(horarioId)) return false;
    if (isBackendEnabled) await _horarioRepository!.delete(horarioId);
    final ok = _horarios.remove(horarioId) != null;
    if (ok) notifyListeners();
    return ok;
  }

  /// Marca entrada/salida con foto + ubicación.
  Future<Asistencia> markAttendance({
    required String empleadoId,
    required String empresaId,
    required TipoAsistencia tipo,
    required double latitud,
    required double longitud,
    required String fotoUrl,
    Uint8List? fotoBytes,
  }) async {
    final id = _uuid.v4();
    var storedPhoto = fotoUrl;
    if (isBackendEnabled) {
      if (fotoBytes == null) {
        throw const AppException(
          'No se pudieron leer los bytes de la foto para subirla.',
        );
      }
      storedPhoto = await _storageRepository!.upload(
        bucket: AppConfig.asistenciasBucket,
        path: '$empresaId/$empleadoId/$id.jpg',
        bytes: fotoBytes,
      );
    }
    final a = Asistencia(
      id: id,
      empleadoId: empleadoId,
      empresaId: empresaId,
      tipo: tipo,
      fechaHora: DateTime.now(),
      latitud: latitud,
      longitud: longitud,
      fotoUrl: storedPhoto,
    );
    final saved =
        isBackendEnabled ? await _asistenciaRepository!.create(a) : a;
    _asistencias[id] =
        isBackendEnabled ? await _hydrateAttendance(saved) : saved;
    notifyListeners();
    return _asistencias[id]!;
  }

  List<SolicitudSala> solicitudesParaAdmin(String empresaId) {
    return _solicitudes.values
        .where((s) => s.empresaId == empresaId)
        .toList()
        .reversed
        .toList();
  }

  List<Perfil> miembrosDeEmpresa(String empresaId) {
    return _perfiles.values.where((p) => p.empresaId == empresaId).toList();
  }

  List<Horario> horariosDeEmpleado(String empleadoId) {
    return _horarios.values.where((h) => h.empleadoId == empleadoId).toList();
  }

  List<Asistencia> historialDeEmpleado(String empleadoId) {
    return _asistencias.values
        .where((a) => a.empleadoId == empleadoId)
        .toList()
        .reversed
        .toList();
  }

  List<Asistencia> asistenciasDeEmpresa(String empresaId) {
    return _asistencias.values
        .where((a) => a.empresaId == empresaId)
        .toList()
        .reversed
        .toList();
  }

  Empresa? empresaById(String? empresaId) {
    if (empresaId == null) return null;
    return _empresas[empresaId];
  }
}
