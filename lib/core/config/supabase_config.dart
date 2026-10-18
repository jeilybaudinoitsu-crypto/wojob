import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Configuración de conexión con Supabase.
///
/// Los valores se resuelven en este orden de prioridad:
///   1. Variables de compilación:
///        flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///   2. Archivo `assets/config/supabase_config.json`.
///
/// La `anonKey` es una llave PÚBLICA (se puede exponer en el cliente), pero
/// nunca debes subir la `service_role key` a la app ni al repositorio.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  /// `true` cuando hay una URL y una anon key reales (no los placeholders).
  bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('TU-PROYECTO') &&
      !anonKey.contains('PEGA_AQUI') &&
      !anonKey.contains('TU_ANON_KEY') &&
      !anonKey.contains('TU_PUBLISHABLE_KEY');

  static const String _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _definePub =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String _assetPath = 'assets/config/supabase_config.json';

  static SupabaseConfig? _instance;

  /// Última configuración cargada (o los valores por defecto de `--dart-define`).
  static SupabaseConfig get instance => _instance ?? _fromDefines();

  static SupabaseConfig _fromDefines() => SupabaseConfig(
        url: _defineUrl.trim(),
        anonKey: (_definePub.isNotEmpty ? _definePub : _defineKey).trim(),
      );

  /// Carga la configuración combinando `--dart-define` y el JSON de assets.
  static Future<SupabaseConfig> load() async {
    if (_instance != null) return _instance!;

    var url = _defineUrl.trim();
    var key = _definePub.isNotEmpty ? _definePub.trim() : _defineKey.trim();

    if (url.isEmpty || key.isEmpty) {
      try {
        final raw = await rootBundle.loadString(_assetPath);
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (url.isEmpty) url = (map['SUPABASE_URL'] as String? ?? '').trim();
        if (key.isEmpty) {
          key = (map['SUPABASE_PUBLISHABLE_KEY'] as String? ??
                  map['SUPABASE_ANON_KEY'] as String? ??
                  '')
              .trim();
        }
      } catch (_) {
        // Si el asset no existe o es inválido se mantienen los --dart-define.
      }
    }

    return _instance = SupabaseConfig(url: url, anonKey: key);
  }
}
