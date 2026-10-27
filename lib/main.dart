import 'dart:async';

import 'package:app_links/app_links.dart';
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

final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class WoJobApp extends StatefulWidget {
  const WoJobApp({super.key});

  @override
  State<WoJobApp> createState() => _WoJobAppState();
}

class _WoJobAppState extends State<WoJobApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handlePaymentReturn(uri)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('No se pudo procesar el enlace de retorno: $error');
      },
    );
  }

  Future<void> _handlePaymentReturn(Uri uri) async {
    if (uri.scheme != 'wojob' ||
        !{'payment-success', 'payment-cancelled'}.contains(uri.host)) {
      return;
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handlePaymentReturn(uri));
      });
      return;
    }

    final isSuccessReturn = uri.host == 'payment-success';
    final authState = context.read<app_state.AuthState>();
    final user = authState.currentUser;
    final companyId = user?.empresaId;
    if (isSuccessReturn &&
        authState.isBackendEnabled &&
        user?.isAdmin == true &&
        companyId != null) {
      await context.read<EmpresaState>().loadEmpresaData(companyId);
    }

    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isSuccessReturn
                ? 'Regresaste de Stripe. El plan se activa cuando Supabase '
                      'confirme la suscripción.'
                : 'Cancelaste el pago. No se modificó el plan actual.',
          ),
        ),
      );
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

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
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
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
