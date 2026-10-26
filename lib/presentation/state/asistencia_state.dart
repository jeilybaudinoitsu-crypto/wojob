import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wojob/core/config/app_config.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/domain/repositories/repositories.dart';

const _uuid = Uuid();

/// Estado de asistencias y marcaciones.
class AsistenciaState extends ChangeNotifier {
  AsistenciaState({
    this._asistenciaRepository,
    this._storageRepository,
    this._authRepository,
  }) {
    if (!isBackendEnabled) _seed();
  }

  final AsistenciaRepository? _asistenciaRepository;
  final StorageRepository? _storageRepository;
  final AuthRepository? _authRepository;

  bool get isBackendEnabled => _asistenciaRepository != null;

  final _asistencias = <String, Asistencia>{};

  String? backendError;
  bool isLoading = false;
  bool isMarking = false;

  void _seed() {
    for (final a in MockData.asistencias) {
      _asistencias[a.id] = a;
    }
  }

  List<Asistencia> get asistencias => _asistencias.values.toList();

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

  /// Marca entrada/salida con foto + ubicación.
  Future<Asistencia> markAttendance({
    required String empleadoId,
    required String empresaId,
    required TipoAsistencia tipo,
    required double latitud,
    required double longitud,
    required Uint8List fotoBytes,
  }) async {
    isMarking = true;
    backendError = null;
    notifyListeners();

    try {
      final user = await _authRepository?.findById(empleadoId);
      if (user == null || !user.estadoActivo) {
        throw const ValidationException('El empleado no existe o está inactivo.');
      }

      final id = _uuid.v4();
      var storedPhoto = '';
      if (isBackendEnabled) {
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
      final saved = isBackendEnabled ? await _asistenciaRepository!.create(a) : a;
      final hydrated = isBackendEnabled ? await _hydrateAttendance(saved) : saved;
      _asistencias[id] = hydrated;
      notifyListeners();
      return _asistencias[id]!;
    } on AppException catch (e) {
      backendError = e.message;
      rethrow;
    } catch (e) {
      backendError = 'Error al registrar la asistencia.';
      throw UnknownException(backendError!, cause: e);
    } finally {
      isMarking = false;
      notifyListeners();
    }
  }

  Future<void> loadAsistenciasEmpresa(String empresaId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      _asistencias.clear();
      for (final asistencia in await _asistenciaRepository!.byEmpresa(empresaId)) {
        _asistencias[asistencia.id] = await _hydrateAttendance(asistencia);
      }
    } catch (e) {
      backendError = e is AppException ? e.message : 'Error al cargar asistencias.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAsistenciasEmpleado(String empleadoId) async {
    isLoading = true;
    backendError = null;
    notifyListeners();

    try {
      _asistencias.clear();
      for (final asistencia in await _asistenciaRepository!.byEmpleado(empleadoId)) {
        _asistencias[asistencia.id] = await _hydrateAttendance(asistencia);
      }
    } catch (e) {
      backendError = e is AppException ? e.message : 'Error al cargar historial.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

  void clearError() {
    backendError = null;
    notifyListeners();
  }
}