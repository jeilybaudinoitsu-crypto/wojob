/// Tipo de marcación de asistencia (`public.asistencias.tipo`).
enum TipoAsistencia {
  entrada('entrada', 'Entrada'),
  salida('salida', 'Salida');

  const TipoAsistencia(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TipoAsistencia fromDb(String value) =>
      TipoAsistencia.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => TipoAsistencia.entrada,
      );
}
