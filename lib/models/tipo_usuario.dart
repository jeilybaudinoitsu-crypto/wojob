/// Tipos de usuario soportados por el esquema `public.perfiles`.
enum TipoUsuario {
  empleado('empleado', 'Empleado'),
  adminPrincipal('admin_principal', 'Administrador'),
  adminSecundario('admin_secundario', 'Admin. secundario');

  const TipoUsuario(this.dbValue, this.label);

  final String dbValue;
  final String label;

  bool get isAdmin =>
      this == TipoUsuario.adminPrincipal || this == TipoUsuario.adminSecundario;

  static TipoUsuario fromDb(String value) => TipoUsuario.values.firstWhere(
        (t) => t.dbValue == value,
        orElse: () => TipoUsuario.empleado,
      );
}
