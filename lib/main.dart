import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/datasources/supabase_service.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/core/theme/app_theme.dart';
import 'package:wojob/presentation/screens/home_router.dart';
import 'package:wojob/data/repositories/supabase_asistencia_repository.dart';
import 'package:wojob/data/repositories/supabase_auth_repository.dart';
import 'package:wojob/data/repositories/supabase_empresa_repository.dart';
import 'package:wojob/data/repositories/supabase_horario_repository.dart';
import 'package:wojob/data/repositories/supabase_solicitud_repository.dart';
import 'package:wojob/data/repositories/supabase_storage_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  // Si hay configuración válida de Supabase se inicializa; de lo contrario la
  // app continúa con los datos locales (mock) sin fallar.
  await SupabaseService.initialize();
  final state = _createAppState();
  runApp(WoJobApp(state: state));
  unawaited(state.initialize());
}

AppState _createAppState() {
  if (!SupabaseService.isEnabled) return AppState();
  final client = SupabaseService.client;
  return AppState(
    authRepository: SupabaseAuthRepository(client),
    empresaRepository: SupabaseEmpresaRepository(client),
    solicitudRepository: SupabaseSolicitudRepository(client),
    horarioRepository: SupabaseHorarioRepository(client),
    asistenciaRepository: SupabaseAsistenciaRepository(client),
    storageRepository: SupabaseStorageRepository(client),
  );
}

class WoJobApp extends StatelessWidget {
  const WoJobApp({super.key, this.state});

  final AppState? state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => state ?? AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'WoJob',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            home: const HomeRouter(),
          );
        },
      ),
    );
  }
}
