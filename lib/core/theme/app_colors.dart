import 'package:flutter/material.dart';

/// Paleta corporativa de WoJob.
/// Escala de rojos y grises definida para la identidad de la app.
class AppColors {
  AppColors._();

  /// Rojo vino principal.
  static const Color primary = Color(0xFF800427);

  /// Rojo profundo (sombra / degradados).
  static const Color primaryDark = Color(0xFF54082D);

  /// Casi negro (tinta / fondos oscuros).
  static const Color ink = Color(0xFF190207);

  /// Gris medio (texto secundario / bordes).
  static const Color gray = Color(0xFF6E6B74);

  /// Gris claro (superficies / separadores).
  static const Color lightGray = Color(0xFFBCB8B9);

  // --- Tokens semánticos ---
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFF9E1B32);

  static const Color surfaceLight = Color(0xFFF7F5F6);
  static const Color surfaceDark = Color(0xFF120308);
  static const Color cardDark = Color(0xFF210B12);

  /// Degradado principal para botones y cabeceras.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Degradado oscuro para fondos.
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, ink],
  );
}
