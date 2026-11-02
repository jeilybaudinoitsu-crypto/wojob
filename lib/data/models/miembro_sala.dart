import 'package:wojob/data/models/tipo_usuario.dart';

class MiembroSala {
  const MiembroSala({
    required this.nombreCompleto,
    this.cargo,
    required this.tipoUsuario,
  });

  final String nombreCompleto;
  final String? cargo;
  final TipoUsuario tipoUsuario;

  factory MiembroSala.fromMap(Map<String, dynamic> map) => MiembroSala(
    nombreCompleto: map['nombre_completo'] as String,
    cargo: map['cargo'] as String?,
    tipoUsuario: TipoUsuario.fromDb(map['tipo_usuario'] as String),
  );
}
