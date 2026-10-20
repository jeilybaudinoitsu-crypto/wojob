/// Constantes globales de configuración de la aplicación WoJob.
class AppConfig {
  const AppConfig._();

  static const String appName = 'WoJob';

  /// Bucket (Supabase Storage) donde se suben las fotos de las asistencias.
  static const String asistenciasBucket = 'asistencias';

  /// Bucket privado donde se guardan las fotos de perfil.
  static const String avataresBucket = 'avatares';

  /// Bucket privado donde se guardan cédulas y documentos de identidad.
  static const String documentosBucket = 'documentos';

  /// Tamaño máximo objetivo de una foto antes de subirla a la nube (< 300 KB).
  static const int maxPhotoBytes = 300 * 1024;

  /// Mínimo y máximo de la contraseña de la cuenta.
  static const int minPasswordLength = 8;
}
