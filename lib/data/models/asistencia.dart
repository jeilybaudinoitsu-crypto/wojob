import 'package:wojob/data/models/tipo_asistencia.dart';

/// Mapea `public.asistencias`.
class Asistencia {
  Asistencia({
    required this.id,
    required this.empleadoId,
    required this.empresaId,
    required this.tipo,
    required this.fechaHora,
    required this.latitud,
    required this.longitud,
    required this.fotoUrl,
  });

  final String id;
  final String empleadoId;
  final String empresaId;
  final TipoAsistencia tipo;
  final DateTime fechaHora;
  final double latitud;
  final double longitud;
  final String fotoUrl;

  factory Asistencia.fromMap(Map<String, dynamic> map) => Asistencia(
        id: map['id'] as String,
        empleadoId: map['empleado_id'] as String,
        empresaId: map['empresa_id'] as String,
        tipo: TipoAsistencia.fromDb(map['tipo'] as String),
        fechaHora:
            DateTime.tryParse('${map['fecha_hora']}') ?? DateTime.now(),
        latitud: (map['latitud'] as num).toDouble(),
        longitud: (map['longitud'] as num).toDouble(),
        fotoUrl: map['foto_url'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'empleado_id': empleadoId,
        'empresa_id': empresaId,
        'tipo': tipo.dbValue,
        'fecha_hora': fechaHora.toIso8601String(),
        'latitud': latitud,
        'longitud': longitud,
        'foto_url': fotoUrl,
      };
}
