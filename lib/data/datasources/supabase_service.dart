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

  /// Inicializa Supabase si hay configuración válida. Si no la hay, la app
  /// continúa en modo local (datos mock) sin lanzar excepciones.
  static Future<void> initialize() async {
    if (_initialized) return;
    final config = await SupabaseConfig.load();
    if (!config.isConfigured) return;
    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
    );
    _initialized = true;
  }

  /// Cliente de Supabase. Solo debe usarse cuando [isEnabled] es `true`.
  static SupabaseClient get client => Supabase.instance.client;
}
