import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/datasources/supabase_service.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/core/theme/app_theme.dart';
import 'package:wojob/presentation/screens/home_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  // Si hay configuración válida de Supabase se inicializa; de lo contrario la
  // app continúa con los datos locales (mock) sin fallar.
  await SupabaseService.initialize();
  runApp(const WoJobApp());
}

class WoJobApp extends StatelessWidget {
  const WoJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
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
