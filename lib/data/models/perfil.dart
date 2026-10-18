import 'tipo_usuario.dart';

/// Mapea `public.perfiles`.
class Perfil {
  Perfil({
    required this.id,
    this.empresaId,
    required this.tipoUsuario,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.idPersonal,
    this.cargo,
    this.estadoActivo = true,
    this.verificado = false,
    this.fotoUrl,
    this.cedulaUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String? empresaId;
  final TipoUsuario tipoUsuario;
  final String nombreCompleto;
  final String correo;
  final String telefono;

  /// ID único del usuario (ej. EMP-1048, ADM-001).
  final String idPersonal;
  final String? cargo;
  final bool estadoActivo;
  final bool verificado;
  final String? fotoUrl;
  final String? cedulaUrl;
  final DateTime createdAt;

  bool get isAdmin => tipoUsuario.isAdmin;

  String get iniciales {
    final partes = nombreCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  Perfil copyWith({
    String? empresaId,
    bool clearEmpresa = false,
    TipoUsuario? tipoUsuario,
    String? nombreCompleto,
    String? correo,
    String? telefono,
    String? idPersonal,
    String? cargo,
    bool? estadoActivo,
    bool? verificado,
    String? fotoUrl,
    String? cedulaUrl,
  }) {
    return Perfil(
      id: id,
      empresaId: clearEmpresa ? null : (empresaId ?? this.empresaId),
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      idPersonal: idPersonal ?? this.idPersonal,
      cargo: cargo ?? this.cargo,
      estadoActivo: estadoActivo ?? this.estadoActivo,
      verificado: verificado ?? this.verificado,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      cedulaUrl: cedulaUrl ?? this.cedulaUrl,
      createdAt: createdAt,
    );
  }

  factory Perfil.fromMap(Map<String, dynamic> map) => Perfil(
        id: map['id'] as String,
        empresaId: map['empresa_id'] as String?,
        tipoUsuario: TipoUsuario.fromDb(map['tipo_usuario'] as String),
        nombreCompleto: map['nombre_completo'] as String,
        correo: map['correo'] as String,
        telefono: map['telefono'] as String,
        idPersonal: map['id_personal'] as String,
        cargo: map['cargo'] as String?,
        estadoActivo: map['estado_activo'] as bool? ?? true,
        verificado: map['verificado'] as bool? ?? false,
        fotoUrl: map['foto_url'] as String?,
        cedulaUrl: map['cedula_url'] as String?,
        createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'empresa_id': empresaId,
        'tipo_usuario': tipoUsuario.dbValue,
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'id_personal': idPersonal,
        'cargo': cargo,
        'estado_activo': estadoActivo,
        'verificado': verificado,
        'foto_url': fotoUrl,
        'cedula_url': cedulaUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
