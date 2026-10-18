import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/datasources/mock_data.dart';

const _uuid = Uuid();

/// Contraseña por defecto de los usuarios de ejemplo (mock).
const _seedPassword = 'WoJob1234';

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

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
  Perfil? login(String credential, String password) {
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

  /// Registra un usuario nuevo.
  Perfil register({
    required TipoUsuario tipoUsuario,
    required String nombreCompleto,
    required String correo,
    required String telefono,
    required String idPersonal,
    required String cargo,
    required String password,
    String? fotoUrl,
    String? cedulaUrl,
  }) {
    final id = _uuid.v4();
    final nuevo = Perfil(
      id: id,
      empresaId: null,
      tipoUsuario: tipoUsuario,
      nombreCompleto: nombreCompleto.trim(),
      correo: correo.trim(),
      telefono: telefono.trim(),
      idPersonal: idPersonal.trim(),
      cargo: cargo.trim().isEmpty ? null : cargo.trim(),
      estadoActivo: true,
      verificado: false,
      fotoUrl: fotoUrl,
      cedulaUrl: cedulaUrl,
      createdAt: DateTime.now(),
    );
    _perfiles[id] = nuevo;
    _passwords[id] = password;
    currentUser = nuevo;
    notifyListeners();
    return nuevo;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  bool sendSolicitud(String empresaId, String usuarioId) {
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
    _solicitudes[id] = s;
    notifyListeners();
    return true;
  }

  bool acceptSolicitud(String solicitudId) {
    final s = _solicitudes[solicitudId];
    if (s == null) return false;
    final user = _perfiles[s.usuarioId];
    if (user == null) return false;
    _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.aceptada);
    _perfiles[user.id] = user.copyWith(empresaId: s.empresaId, clearEmpresa: false);
    if (currentUser?.id == user.id) {
      currentUser = _perfiles[user.id];
    }
    notifyListeners();
    return true;
  }

  bool rejectSolicitud(String solicitudId) {
    final s = _solicitudes[solicitudId];
    if (s == null) return false;
    _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.rechazada);
    notifyListeners();
    return true;
  }

  /// Crea una sala (empresa).
  Empresa createSala({
    required String nombreEmpresa,
    required String direccionEmpresa,
    required String passwordHash,
  }) {
    final id = _uuid.v4();
    final emp = Empresa(
      id: id,
      idSala: _generarIdSala(),
      nombreEmpresa: nombreEmpresa.trim(),
      direccionEmpresa: direccionEmpresa.trim(),
      passwordHash: passwordHash,
      createdAt: DateTime.now(),
    );
    _empresas[id] = emp;
    final user = currentUser;
    if (user != null) {
      _perfiles[user.id] = user.copyWith(empresaId: emp.id);
      currentUser = _perfiles[user.id];
    }
    notifyListeners();
    return emp;
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

  bool joinSala(String salaId, {required String usuarioId}) {
    final emp = findEmpresaBySalaId(salaId);
    if (emp == null) return false;
    return sendSolicitud(emp.id, usuarioId);
  }

  /// Asigna un turno (horario) a un empleado.
  Horario assignShift({
    required String empresaId,
    required String empleadoId,
    required DiaSemana diaSemana,
    required String horaEntrada,
    required String horaSalida,
  }) {
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
    _horarios[id] = h;
    notifyListeners();
    return h;
  }

  bool removeShift(String horarioId) {
    final ok = _horarios.remove(horarioId) != null;
    if (ok) notifyListeners();
    return ok;
  }

  /// Marca entrada/salida con foto + ubicación.
  Asistencia markAttendance({
    required String empleadoId,
    required String empresaId,
    required TipoAsistencia tipo,
    required double latitud,
    required double longitud,
    required String fotoUrl,
  }) {
    final id = _uuid.v4();
    final a = Asistencia(
      id: id,
      empleadoId: empleadoId,
      empresaId: empresaId,
      tipo: tipo,
      fechaHora: DateTime.now(),
      latitud: latitud,
      longitud: longitud,
      fotoUrl: fotoUrl,
    );
    _asistencias[id] = a;
    notifyListeners();
    return a;
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
