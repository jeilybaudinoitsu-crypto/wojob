/// Excepción base de dominio de la aplicación.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Errores de red / conectividad.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Errores de autenticación / autorización.
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// Errores de validación de datos de entrada.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// Errores de permisos / RLS.
class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

/// Errores de recurso no encontrado.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

/// Errores de conflicto (recurso duplicado, etc.).
class ConflictException extends AppException {
  const ConflictException(super.message, {super.cause});
}

/// Errores de almacenamiento (Storage).
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Errores genéricos / desconocidos.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}

/// Convierte una excepción genérica en una [AppException] tipada.
AppException toAppException(Object error, {String fallback = 'Error inesperado.'}) {
  if (error is AppException) return error;
  final msg = error.toString().toLowerCase();
  if (msg.contains('network') || msg.contains('socket') || msg.contains('connection') || msg.contains('timeout')) {
    return NetworkException(fallback, cause: error);
  }
  if (msg.contains('unauthorized') || msg.contains('auth') || msg.contains('token') || msg.contains('session')) {
    return AuthException(fallback, cause: error);
  }
  if (msg.contains('permission') || msg.contains('rls') || msg.contains('policy')) {
    return PermissionException(fallback, cause: error);
  }
  if (msg.contains('not found') || msg.contains('no rows')) {
    return NotFoundException(fallback, cause: error);
  }
  if (msg.contains('duplicate') || msg.contains('unique') || msg.contains('already exists')) {
    return ConflictException(fallback, cause: error);
  }
  if (msg.contains('storage') || msg.contains('bucket') || msg.contains('upload')) {
    return StorageException(fallback, cause: error);
  }
  if (msg.contains('validation') || msg.contains('invalid') || msg.contains('constraint')) {
    return ValidationException(fallback, cause: error);
  }
  return UnknownException(fallback, cause: error);
}