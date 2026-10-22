import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/domain/repositories/repositories.dart';

const _uuid = Uuid();

/// Estado de empresas/salas y gestión de miembros.
class EmpresaState extends ChangeNotifier {
  EmpresaState({
    EmpresaRepository? empresaRepository,
    AuthRepository? authRepository,
    SolicitudRepository? solicitudRepository,
    HorarioRepository? horarioRepository,
  })  : _empresaRepository = empresaRepository,
        _authRepository = authRepository,
        _solicitudRepository = solicitudRepository,
        _horarioRepository = horarioRepository {
    if (!isBackendEnabled) _seed();
  }

  final EmpresaRepository? _empresaRepository;
  final AuthRepository? _authRepository;
  final SolicitudRepository? _solicitudRepository;
  final HorarioRepository? _horarioRepository;

  bool get isBackendEnabled => _empresaRepository != null;

  final _empresas = <String, Empresa>{};
  final _solicitudes = <String, SolicitudSala>{};
  final _horarios = <String, Horario>{};
  final _perfiles = <String, Perfil>{};

  Empresa? currentEmpresa;
  String? backendError;
  bool isLoading = false;

  void _seed() {
    _empresas[MockData.empresa.id] = MockData.empresa;
    for (final s in MockData.solicitudesPendientes) {
      _solicitudes[s.id] = s;
    }
    for (final h in MockData.horarios) {
      _horarios[h.id] = h;
    }
  }

  List<Empresa> get empresas => _empresas.values.toList();
  List<SolicitudSala> get solicitudes => _solicitudes.values.toList();
  List<Horario> get horarios => _horarios.values.toList();
  List<Perfil> get perfiles => _perfiles.values.toList();

  Empresa? findEmpresaBySalaId(String salaId) {
    final v = salaId.trim().toUpperCase();
    for (final e in _empresas.values) {
      if (e.idSala.trim().toUpperCase() == v) return e;
    }
    return null;
  }

  Future<Empresa?> findEmpresaBySalaIdRemote(String salaId) async {
    if (!isBackendEnabled) return findEmpresaBySalaId(salaId);
    return _empresaRepository!.findBySalaId(salaId);
  }

  Future<void> loadEmpresaData(String empresaId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      _empresas.clear();
      _solicitudes.clear();
      _horarios.clear();
      _perfiles.clear();

      final empresa = await _empresaRepository!.findById(empresaId);
      if (empresa != null) {
        _empresas[empresa.id] = empresa;
        currentEmpresa = empresa;
      }

      final members = await _authRepository!.byEmpresa(empresaId);
      for (final member in members) {
        _perfiles[member.id] = member;
      }

      for (final solicitud in await _solicitudRepository!.byEmpresa(empresaId)) {
        _solicitudes[solicitud.id] = solicitud;
        if (!_perfiles.containsKey(solicitud.usuarioId)) {
          final applicant = await _authRepository!.findById(solicitud.usuarioId);
          if (applicant != null) {
            _perfiles[applicant.id] = applicant;
          }
        }
      }

      for (final horario in await _horarioRepository!.byEmpresa(empresaId)) {
        _horarios[horario.id] = horario;
      }
    } catch (e) {
      backendError = e is AppException ? e.message : e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una sala (empresa).
  Future<Empresa> createSala({
    required String nombreEmpresa,
    required String direccionEmpresa,
    required String passwordHash,
    required String currentUserId,
  }) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final id = _uuid.v4();
      final emp = Empresa(
        id: id,
        idSala: _generarIdSala(),
        nombreEmpresa: nombreEmpresa.trim(),
        direccionEmpresa: direccionEmpresa.trim(),
        passwordHash: passwordHash,
        createdAt: DateTime.now(),
      );
      final stored = isBackendEnabled ? await _empresaRepository!.create(emp) : emp;
      _empresas[stored.id] = stored;
      currentEmpresa = stored;

      if (isBackendEnabled) {
        await _authRepository!.updateEmpresa(currentUserId, stored.id);
      }

      return stored;
    } catch (e) {
      backendError = e is AppException ? e.message : 'No se pudo crear la sala.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _generarIdSala() {
    final uuid = _uuid.v4().substring(0, 8).toUpperCase();
    return 'NOR-$uuid';
  }

  Future<bool> joinSala(String salaId, {required String usuarioId}) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final emp = await findEmpresaBySalaIdRemote(salaId);
      if (emp == null) return false;
      _empresas[emp.id] = emp;
      return await sendSolicitud(emp.id, usuarioId);
    } catch (e) {
      backendError = e is AppException ? e.message : 'Error al unirse a la sala.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    final stored = isBackendEnabled ? await _solicitudRepository!.create(s) : s;
    _solicitudes[stored.id] = stored;
    notifyListeners();
    return true;
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

  Future<bool> acceptSolicitud(String solicitudId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final s = _solicitudes[solicitudId];
      if (s == null) return false;

      if (isBackendEnabled) {
        await _authRepository!.updateEmpresa(s.usuarioId, s.empresaId);
        await _solicitudRepository!.updateEstado(solicitudId, EstadoSolicitud.aceptada);
      }
      _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.aceptada);

      final user = _perfiles[s.usuarioId];
      if (user != null) {
        _perfiles[user.id] = user.copyWith(empresaId: s.empresaId, clearEmpresa: false);
      }
      notifyListeners();
      return true;
    } catch (e) {
      backendError = e is AppException ? e.message : 'Error al aceptar solicitud.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectSolicitud(String solicitudId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final s = _solicitudes[solicitudId];
      if (s == null) return false;
      if (isBackendEnabled) {
        await _solicitudRepository!.updateEstado(solicitudId, EstadoSolicitud.rechazada);
      }
      _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.rechazada);
      notifyListeners();
      return true;
    } catch (e) {
      backendError = e is AppException ? e.message : 'Error al rechazar solicitud.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Asigna un turno (horario) a un empleado.
  Future<Horario> assignShift({
    required String empresaId,
    required String empleadoId,
    required DiaSemana diaSemana,
    required String horaEntrada,
    required String horaSalida,
  }) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
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
      final stored = isBackendEnabled ? await _horarioRepository!.create(h) : h;
      _horarios[stored.id] = stored;
      notifyListeners();
      return stored;
    } catch (e) {
      backendError = e is AppException ? e.message : 'No se pudo asignar el turno.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeShift(String horarioId) async {
    if (!_horarios.containsKey(horarioId)) return false;
    if (isBackendEnabled) await _horarioRepository!.delete(horarioId);
    final ok = _horarios.remove(horarioId) != null;
    if (ok) notifyListeners();
    return ok;
  }

  List<Horario> horariosDeEmpleado(String empleadoId) {
    return _horarios.values.where((h) => h.empleadoId == empleadoId).toList();
  }

  List<Horario> horariosDeEmpresa(String empresaId) {
    return _horarios.values.where((h) => h.empresaId == empresaId).toList();
  }

  Empresa? empresaById(String? empresaId) {
    if (empresaId == null) return null;
    return _empresas[empresaId];
  }

  void clearError() {
    backendError = null;
    notifyListeners();
  }
}