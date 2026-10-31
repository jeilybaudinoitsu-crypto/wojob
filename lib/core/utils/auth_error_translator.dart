String translateAuthError(String message) {
  final msg = message.toLowerCase();
  if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
  }
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return 'Credenciales inválidas. Verifica tu correo y contraseña.';
  }
  if (msg.contains('email not confirmed') ||
      msg.contains('email not verified')) {
    return 'El correo no está confirmado. Revisa tu bandeja de entrada.';
  }
  if (msg.contains('user not found') || msg.contains('no user found')) {
    return 'Usuario no encontrado.';
  }
  if (msg.contains('email already exists') ||
      msg.contains('user already registered')) {
    return 'El correo ya está registrado.';
  }
  if (msg.contains('weak password') ||
      msg.contains('password should be at least')) {
    return 'Contraseña muy débil. Usa al menos 6 caracteres.';
  }
  if (msg.contains('invalid email') || msg.contains('email format')) {
    return 'Formato de correo inválido.';
  }
  if (msg.contains('signup disabled') ||
      msg.contains('registration disabled')) {
    return 'Registro deshabilitado. Contacta al administrador.';
  }
  if (msg.contains('database error saving new user')) {
    return 'Supabase no pudo crear el perfil. Comprueba que el SQL de registro esté aplicado, que el ID personal no esté repetido y revisa Authentication → Logs.';
  }
  if (msg.contains('403') || msg.contains('forbidden')) {
    return 'Supabase rechazó el registro. Revisa la configuración de Email y las políticas RLS de perfiles.';
  }
  if (msg.contains('anonymous provider disabled')) {
    return 'Acceso anónimo deshabilitado.';
  }
  if (msg.contains('refresh token') || msg.contains('session expired')) {
    return 'Sesión expirada. Inicia sesión de nuevo.';
  }
  return message;
}
