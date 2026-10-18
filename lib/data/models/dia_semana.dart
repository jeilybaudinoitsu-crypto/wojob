/// Días de la semana tal como los define `public.horarios.dia_semana`.
enum DiaSemana {
  lunes('L', 'Lunes'),
  martes('M', 'Martes'),
  miercoles('Mi', 'Miércoles'),
  jueves('J', 'Jueves'),
  viernes('V', 'Viernes'),
  sabado('S', 'Sábado'),
  domingo('D', 'Domingo');

  const DiaSemana(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static DiaSemana fromDb(String value) => DiaSemana.values.firstWhere(
        (d) => d.dbValue == value,
        orElse: () => DiaSemana.lunes,
      );
}
