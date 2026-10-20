/// Mapea `public.empresas` — la "sala" a la que se unen empleados y admins.
class Empresa {
  Empresa({
    required this.id,
    required this.idSala,
    required this.nombreEmpresa,
    required this.direccionEmpresa,
    required this.passwordHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;

  /// ID público de la sala (ej. NOR-4826).
  final String idSala;
  final String nombreEmpresa;

  /// Ubicación exacta del lugar de trabajo.
  final String direccionEmpresa;
  final String passwordHash;
  final DateTime createdAt;

  Empresa copyWith({
    String? idSala,
    String? nombreEmpresa,
    String? direccionEmpresa,
    String? passwordHash,
  }) {
    return Empresa(
      id: id,
      idSala: idSala ?? this.idSala,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      direccionEmpresa: direccionEmpresa ?? this.direccionEmpresa,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt,
    );
  }

  factory Empresa.fromMap(Map<String, dynamic> map) => Empresa(
    id: map['id'] as String,
    idSala: map['id_sala'] as String,
    nombreEmpresa: map['nombre_empresa'] as String,
    direccionEmpresa: map['direccion_empresa'] as String,
    passwordHash: map['password_hash'] as String? ?? '',
    createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'id_sala': idSala,
    'nombre_empresa': nombreEmpresa,
    'direccion_empresa': direccionEmpresa,
    'password_hash': passwordHash,
    'created_at': createdAt.toIso8601String(),
  };
}
