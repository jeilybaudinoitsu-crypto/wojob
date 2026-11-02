import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/data/datasources/supabase_service.dart';
import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/miembro_sala.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/domain/repositories/repositories.dart';

const _uuid = Uuid();

/// Estado de empresas/salas y gestión de miembros.
class EmpresaState extends ChangeNotifier {
  EmpresaState({
    this._empresaRepository,
    this._authRepository,
    this._solicitudRepository,
    this._horarioRepository,
  }) {
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
  final _directorio = <MiembroSala>[];
  String? _directorioEmpresaId;
  int _directorioRequest = 0;

  Empresa? currentEmpresa;
  String? backendError;
  bool isLoading = false;
  bool directorioLoading = false;
  String? directorioError;

  void _seed() {
    _empresas[MockData.empresa.id] = MockData.empresa;
    for (final perfil in [
      MockData.admin,
      MockData.empleado1,
      MockData.empleado2,
    ]) {
      _perfiles[perfil.id] = perfil;
    }
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
  List<MiembroSala> get directorio => List.unmodifiable(_directorio);

  /// empresaId delimita el estado local; la RPC usa exclusivamente auth.uid().
  Future<void> loadDirectorio(String empresaId) async {
    final request = ++_directorioRequest;
    _directorioEmpresaId = empresaId;
    _directorio.clear();
    directorioLoading = true;
    directorioError = null;
    notifyListeners();

    try {
      final miembros = isBackendEnabled
          ? await _empresaRepository!.directorio()
          : ([MockData.admin, MockData.empleado1, MockData.empleado2]
                .where(
                  (perfil) =>
                      perfil.empresaId == empresaId && perfil.estadoActivo,
                )
                .map(
                  (perfil) => MiembroSala(
                    nombreCompleto: perfil.nombreCompleto,
                    cargo: perfil.cargo,
                    tipoUsuario: perfil.tipoUsuario,
                  ),
                )
                .toList()
              ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto)));
      // Ignora respuestas de una carga anterior o de una sala ya limpiada.
      if (request != _directorioRequest || _directorioEmpresaId != empresaId) {
        return;
      }
      _directorio.addAll(miembros);
    } catch (e) {
      if (request != _directorioRequest || _directorioEmpresaId != empresaId) {
        return;
      }
      directorioError = e is AppException
          ? e.message
          : 'No se pudo cargar el directorio de la sala.';
    } finally {
      if (request == _directorioRequest && _directorioEmpresaId == empresaId) {
        directorioLoading = false;
        notifyListeners();
      }
    }
  }

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
    if (!isBackendEnabled) return;
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      _empresas.clear();
      _solicitudes.clear();
      _horarios.clear();
      _perfiles.clear();

      final empresa = await _empresaRepository!.findById(empresaId);
      currentEmpresa = empresa;
      if (empresa != null) {
        _empresas[empresa.id] = empresa;
      }

      final members = await _authRepository!.byEmpresa(empresaId);
      for (final member in members) {
        _perfiles[member.id] = member;
      }

      for (final solicitud in await _solicitudRepository!.byEmpresa(
        empresaId,
      )) {
        _solicitudes[solicitud.id] = solicitud;
        if (!_perfiles.containsKey(solicitud.usuarioId)) {
          final applicant = await _authRepository.findById(solicitud.usuarioId);
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
      final stored = isBackendEnabled
          ? await _empresaRepository!.create(emp)
          : emp;
      _empresas[stored.id] = stored;
      currentEmpresa = stored;

      return stored;
    } catch (e) {
      backendError = e is AppException
          ? e.message
          : 'No se pudo crear la sala.';
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
      backendError = e is AppException
          ? e.message
          : 'Error al unirse a la sala.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendSolicitud(String empresaId, String usuarioId) async {
    final empresaExiste = _empresas.containsKey(empresaId);
    final user = _perfiles[usuarioId];
    if (!isBackendEnabled && (!empresaExiste || user == null)) return false;
    final yaExiste = isBackendEnabled
        ? await _solicitudRepository!.hasPending(
            empresaId: empresaId,
            usuarioId: usuarioId,
          )
        : _solicitudes.values.any(
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

  Perfil? perfilById(String userId) {
    for (final profile in _perfiles.values) {
      if (profile.id == userId) return profile;
    }
    return null;
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

  int empleadosActivosDeEmpresa(String empresaId) {
    return miembrosDeEmpresa(empresaId)
        .where((profile) => !profile.isAdmin && profile.estadoActivo)
        .length;
  }

  Future<bool> acceptSolicitud(String solicitudId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      final s = _solicitudes[solicitudId];
      if (s == null) return false;

      final applicant = _perfiles[s.usuarioId];
      final empresa = _empresas[s.empresaId];
      final employeeLimit = empresa?.limiteEmpleados;
      if (applicant != null &&
          !applicant.isAdmin &&
          applicant.estadoActivo &&
          applicant.empresaId != s.empresaId &&
          employeeLimit != null &&
          empleadosActivosDeEmpresa(s.empresaId) >= employeeLimit) {
        throw ValidationException(
          'La sala alcanzó el límite de $employeeLimit empleados de su plan '
          '${empresa!.planSuscripcion.label}.',
        );
      }

      if (isBackendEnabled) {
        await _authRepository!.updateEmpresa(s.usuarioId, s.empresaId);
        await _solicitudRepository!.updateEstado(
          solicitudId,
          EstadoSolicitud.aceptada,
        );
      }
      _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.aceptada);

      final user = _perfiles[s.usuarioId];
      if (user != null) {
        _perfiles[user.id] = user.copyWith(
          empresaId: s.empresaId,
          clearEmpresa: false,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      backendError = e is AppException
          ? e.message
          : 'Error al aceptar solicitud.';
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
        await _solicitudRepository!.updateEstado(
          solicitudId,
          EstadoSolicitud.rechazada,
        );
      }
      _solicitudes[solicitudId] = s.copyWith(estado: EstadoSolicitud.rechazada);
      notifyListeners();
      return true;
    } catch (e) {
      backendError = e is AppException
          ? e.message
          : 'Error al rechazar solicitud.';
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
      backendError = e is AppException
          ? e.message
          : 'No se pudo asignar el turno.';
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

  Future<void> updateSalaInfo({
    required String empresaId,
    required String passwordSala,
    required String nombreEmpresa,
    required String direccionEmpresa,
    String? nuevaPassword,
  }) async {
    if (isBackendEnabled && _empresaRepository != null) {
      try {
        final client = SupabaseService.isEnabled
            ? SupabaseService.client
            : null;
        if (client != null) {
          await client.rpc(
            'update_empresa_info',
            params: {
              'p_empresa_id': empresaId,
              'p_password': passwordSala,
              'p_nombre_empresa': nombreEmpresa.trim(),
              'p_direccion_empresa': direccionEmpresa.trim(),
              if (nuevaPassword != null && nuevaPassword.isNotEmpty)
                'p_nueva_password': nuevaPassword,
            },
          );
          // Reload empresa data
          final empresa = await _empresaRepository.findById(empresaId);
          if (empresa != null) {
            _empresas[empresa.id] = empresa;
            if (currentEmpresa?.id == empresa.id) currentEmpresa = empresa;
            notifyListeners();
          }
          return;
        }
      } catch (e) {
        if (e is AppException) rethrow;
        throw UnknownException(
          'No se pudo actualizar la información de la sala.',
          cause: e,
        );
      }
    }
    throw const UnknownException(
      'Esta acción solo está disponible con Supabase.',
    );
  }

  Future<void> removeMember(String empresaId, String memberId) async {
    if (isBackendEnabled && _empresaRepository != null) {
      try {
        final client = SupabaseService.isEnabled
            ? SupabaseService.client
            : null;
        if (client != null) {
          await client.rpc(
            'remove_room_member',
            params: {'p_empresa_id': empresaId, 'p_member_id': memberId},
          );
          // Update local state
          final member = _perfiles[memberId];
          if (member != null) {
            _perfiles[memberId] = member.copyWith(
              empresaId: null,
              clearEmpresa: true,
            );
          }
          // Remove schedules for this member in this empresa
          _horarios.removeWhere(
            (key, value) =>
                value.empresaId == empresaId && value.empleadoId == memberId,
          );
          notifyListeners();
          return;
        }
      } catch (e) {
        if (e is AppException) rethrow;
        throw UnknownException('No se pudo eliminar al miembro.', cause: e);
      }
    }
    throw const UnknownException(
      'Esta acción solo está disponible con Supabase.',
    );
  }

  void clearError() {
    backendError = null;
    notifyListeners();
  }

  void clearSalaData() {
    _empresas.clear();
    _solicitudes.clear();
    _horarios.clear();
    _perfiles.clear();
    _directorio.clear();
    _directorioEmpresaId = null;
    _directorioRequest++;
    directorioLoading = false;
    directorioError = null;
    currentEmpresa = null;
    backendError = null;
    notifyListeners();
  }
}
