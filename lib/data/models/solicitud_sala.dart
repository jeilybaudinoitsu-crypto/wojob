/// Estado de una solicitud de acceso a una sala (`public.solicitudes_sala`).
enum EstadoSolicitud {
  pendiente('pendiente', 'Pendiente'),
  aceptada('aceptada', 'Aceptada'),
  rechazada('rechazada', 'Rechazada');

  const EstadoSolicitud(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static EstadoSolicitud fromDb(String value) =>
      EstadoSolicitud.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => EstadoSolicitud.pendiente,
      );
}

/// Mapea `public.solicitudes_sala`.
class SolicitudSala {
  SolicitudSala({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    this.estado = EstadoSolicitud.pendiente,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String empresaId;
  final String usuarioId;
  final EstadoSolicitud estado;
  final DateTime createdAt;

  SolicitudSala copyWith({EstadoSolicitud? estado}) => SolicitudSala(
        id: id,
        empresaId: empresaId,
        usuarioId: usuarioId,
        estado: estado ?? this.estado,
        createdAt: createdAt,
      );

  factory SolicitudSala.fromMap(Map<String, dynamic> map) => SolicitudSala(
        id: map['id'] as String,
        empresaId: map['empresa_id'] as String,
        usuarioId: map['usuario_id'] as String,
        estado: EstadoSolicitud.fromDb(map['estado'] as String),
        createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'empresa_id': empresaId,
        'usuario_id': usuarioId,
        'estado': estado.dbValue,
        'created_at': createdAt.toIso8601String(),
      };
}
