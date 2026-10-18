/// Excepción de dominio de la aplicación.
///
/// Se usa para envolver errores de la capa de datos (p. ej. Supabase) y
/// exponer a la capa de presentación un mensaje limpio y traducible.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}
