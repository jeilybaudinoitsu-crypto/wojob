class Validators {
  static const int otpLength = 8;

  static String? required(String? value, [String msg = 'Campo obligatorio']) {
    if (value == null || value.trim().isEmpty) return msg;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa un correo';
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!re.hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa un teléfono';
    final v = value.trim();
    if (v.length < 7) return 'Teléfono inválido';
    return null;
  }

  static String? idOrText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Ingresa $label';
    if (value.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  static String? passwordStrict(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa una contraseña para la sala';
    }
    final v = value;
    if (v.length < 8 || v.length > 16) {
      return 'Entre 8 y 16 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Falta una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Falta una minúscula';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Falta un número';
    if (!RegExp(r'[.*/_]').hasMatch(v)) {
      return 'Debe incluir uno de . * / _';
    }
    return null;
  }

  /// Contraseña de la cuenta (auth). Mínimo 8 caracteres.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Crea una contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  /// Confirmación de contraseña de la cuenta.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Repite la contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? salaId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa ID de sala';
    final v = value.trim().toUpperCase();
    if (v.length < 6) return 'Formato inválido (ej. NOR-4826)';
    return null;
  }
}
