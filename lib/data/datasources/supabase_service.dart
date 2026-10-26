import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wojob/core/config/supabase_config.dart';

/// Punto único de acceso al cliente de Supabase.
///
/// Es la puerta de entrada de la capa de datos hacia `supabase_flutter`
/// (Auth, consultas SQL / PostgREST y Storage).
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// `true` si Supabase quedó inicializado (hay URL + anon key válidas).
  static bool get isEnabled => _initialized;

  static void reset() {
    _initialized = false;
    SupabaseConfig.clearCache();
  }

  /// Inicializa Supabase si hay configuración válida. Si no la hay, la app
  /// continúa en modo local (datos mock) sin lanzar excepciones.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      final config = await SupabaseConfig.load();
      if (!config.isConfigured) return false;

      await Supabase.initialize(
        url: config.url,
        publishableKey: config.publishableKey,
      );
      _initialized = true;
      return true;
    } on Exception {
      _initialized = false;
      return false;
    }
  }

  /// Cliente de Supabase. Solo debe usarse cuando [isEnabled] es `true`.
  static SupabaseClient get client => Supabase.instance.client;
}
