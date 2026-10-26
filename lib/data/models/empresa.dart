enum PlanSuscripcion {
  free('FREE', 'FREE', 0, 10, 'Hasta 10 empleados'),
  businessGold(
    'BUSINESS_GOLD',
    'BUSINESS GOLD',
    25,
    250,
    'Hasta 250 empleados',
  ),
  ceoDiamond('CEO_DIAMOND', 'CEO DIAMOND', 60, null, 'Empleados ilimitados');

  const PlanSuscripcion(
    this.dbValue,
    this.label,
    this.precioMensual,
    this.limiteEmpleados,
    this.descripcionCapacidad,
  );

  final String dbValue;
  final String label;
  final int precioMensual;
  final int? limiteEmpleados;
  final String descripcionCapacidad;

  static PlanSuscripcion fromDb(String? value) =>
      PlanSuscripcion.values.firstWhere(
        (plan) => plan.dbValue == value,
        orElse: () => PlanSuscripcion.free,
      );
}

/// Mapea `public.empresas` — la "sala" a la que se unen empleados y admins.
class Empresa {
  Empresa({
    required this.id,
    required this.idSala,
    required this.nombreEmpresa,
    required this.direccionEmpresa,
    required this.passwordHash,
    this.planSuscripcion = PlanSuscripcion.free,
    int? limiteEmpleados,
    DateTime? createdAt,
  }) : limiteEmpleados = limiteEmpleados ?? planSuscripcion.limiteEmpleados,
       createdAt = createdAt ?? DateTime.now();

  final String id;

  /// ID público de la sala (ej. NOR-4826).
  final String idSala;
  final String nombreEmpresa;

  /// Ubicación exacta del lugar de trabajo.
  final String direccionEmpresa;
  final String passwordHash;
  final PlanSuscripcion planSuscripcion;
  final int? limiteEmpleados;
  final DateTime createdAt;

  Empresa copyWith({
    String? idSala,
    String? nombreEmpresa,
    String? direccionEmpresa,
    String? passwordHash,
    PlanSuscripcion? planSuscripcion,
    int? limiteEmpleados,
  }) {
    final updatedPlan = planSuscripcion ?? this.planSuscripcion;
    return Empresa(
      id: id,
      idSala: idSala ?? this.idSala,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      direccionEmpresa: direccionEmpresa ?? this.direccionEmpresa,
      passwordHash: passwordHash ?? this.passwordHash,
      planSuscripcion: updatedPlan,
      limiteEmpleados:
          limiteEmpleados ??
          (planSuscripcion == null
              ? this.limiteEmpleados
              : updatedPlan.limiteEmpleados),
      createdAt: createdAt,
    );
  }

  factory Empresa.fromMap(Map<String, dynamic> map) => Empresa(
    id: map['id'] as String,
    idSala: map['id_sala'] as String,
    nombreEmpresa: map['nombre_empresa'] as String,
    direccionEmpresa: map['direccion_empresa'] as String,
    passwordHash: map['password_hash'] as String? ?? '',
    planSuscripcion: PlanSuscripcion.fromDb(map['plan_suscripcion'] as String?),
    limiteEmpleados: map['limite_empleados'] as int?,
    createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'id_sala': idSala,
    'nombre_empresa': nombreEmpresa,
    'direccion_empresa': direccionEmpresa,
    'password_hash': passwordHash,
    'plan_suscripcion': planSuscripcion.dbValue,
    'limite_empleados': limiteEmpleados,
    'created_at': createdAt.toIso8601String(),
  };
}
