import 'package:get_it/get_it.dart';

import 'package:wojob/data/datasources/supabase_service.dart';
import 'package:wojob/data/repositories/supabase_auth_repository.dart';
import 'package:wojob/data/repositories/supabase_empresa_repository.dart';
import 'package:wojob/data/repositories/supabase_horario_repository.dart';
import 'package:wojob/data/repositories/supabase_solicitud_repository.dart';
import 'package:wojob/data/repositories/supabase_asistencia_repository.dart';
import 'package:wojob/data/repositories/supabase_storage_repository.dart';
import 'package:wojob/domain/repositories/repositories.dart';
import 'package:wojob/domain/services/location_service.dart';
import 'package:wojob/domain/services/media_service.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/settings_state.dart';

final sl = GetIt.instance;

Future<void> setupDependencies({bool isTest = false}) async {
  if (!isTest) {
    await SupabaseService.initialize();
  }

  // Domain services
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<MediaService>(() => MediaService());

  if (SupabaseService.isEnabled && !isTest) {
    final client = SupabaseService.client;

    // Repositories
    sl.registerLazySingleton<AuthRepository>(() => SupabaseAuthRepository(client));
    sl.registerLazySingleton<EmpresaRepository>(() => SupabaseEmpresaRepository(client));
    sl.registerLazySingleton<SolicitudRepository>(() => SupabaseSolicitudRepository(client));
    sl.registerLazySingleton<HorarioRepository>(() => SupabaseHorarioRepository(client));
    sl.registerLazySingleton<AsistenciaRepository>(() => SupabaseAsistenciaRepository(client));
    sl.registerLazySingleton<StorageRepository>(() => SupabaseStorageRepository(client));

    // State (singletons - shared across app)
    sl.registerLazySingleton<app_state.AuthState>(() => app_state.AuthState(
      authRepository: sl<AuthRepository>(),
      storageRepository: sl<StorageRepository>(),
    ));
    sl.registerLazySingleton<EmpresaState>(() => EmpresaState(
      empresaRepository: sl<EmpresaRepository>(),
      authRepository: sl<AuthRepository>(),
      solicitudRepository: sl<SolicitudRepository>(),
      horarioRepository: sl<HorarioRepository>(),
    ));
    sl.registerLazySingleton<AsistenciaState>(() => AsistenciaState(
      asistenciaRepository: sl<AsistenciaRepository>(),
      storageRepository: sl<StorageRepository>(),
      authRepository: sl<AuthRepository>(),
    ));
    sl.registerLazySingleton<SettingsState>(() => SettingsState());
  } else {
    // Mock mode - no repositories
    sl.registerLazySingleton<app_state.AuthState>(() => app_state.AuthState());
    sl.registerLazySingleton<EmpresaState>(() => EmpresaState());
    sl.registerLazySingleton<AsistenciaState>(() => AsistenciaState());
    sl.registerLazySingleton<SettingsState>(() => SettingsState());
  }
}

void resetDependencies() {
  sl.reset();
}