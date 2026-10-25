import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/di/service_locator.dart';
import 'package:wojob/core/theme/app_theme.dart';
import 'package:wojob/presentation/screens/home_router.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await setupDependencies();
  await sl<app_state.AuthState>().initialize();
  runApp(const WoJobApp());
}

class WoJobApp extends StatelessWidget {
  const WoJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_state.AuthState>.value(
          value: sl<app_state.AuthState>(),
        ),
        ChangeNotifierProvider<EmpresaState>.value(value: sl<EmpresaState>()),
        ChangeNotifierProvider<AsistenciaState>.value(
          value: sl<AsistenciaState>(),
        ),
        ChangeNotifierProvider<SettingsState>.value(value: sl<SettingsState>()),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'WoJob',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const HomeRouter(),
          );
        },
      ),
    );
  }
}
