import 'dia_semana.dart';

/// Mapea `public.horarios`. Cada fila es un día asignado a un empleado.
class Horario {
  Horario({
    required this.id,
    required this.empresaId,
    required this.empleadoId,
    required this.diaSemana,
    required this.horaEntrada,
    required this.horaSalida,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String empresaId;
  final String empleadoId;
  final DiaSemana diaSemana;
  final String horaEntrada;
  final String horaSalida;
  final DateTime createdAt;

  Horario copyWith({
    DiaSemana? diaSemana,
    String? horaEntrada,
    String? horaSalida,
  }) =>
      Horario(
        id: id,
        empresaId: empresaId,
        empleadoId: empleadoId,
        diaSemana: diaSemana ?? this.diaSemana,
        horaEntrada: horaEntrada ?? this.horaEntrada,
        horaSalida: horaSalida ?? this.horaSalida,
        createdAt: createdAt,
      );

  factory Horario.fromMap(Map<String, dynamic> map) => Horario(
        id: map['id'] as String,
        empresaId: map['empresa_id'] as String,
        empleadoId: map['empleado_id'] as String,
        diaSemana: DiaSemana.fromDb(map['dia_semana'] as String),
        horaEntrada: map['hora_entrada'] as String,
        horaSalida: map['hora_salida'] as String,
        createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'empresa_id': empresaId,
        'empleado_id': empleadoId,
        'dia_semana': diaSemana.dbValue,
        'hora_entrada': horaEntrada,
        'hora_salida': horaSalida,
        'created_at': createdAt.toIso8601String(),
      };
}
