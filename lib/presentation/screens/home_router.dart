import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';
import 'package:wojob/presentation/screens/employee/employee_home_screen.dart';
import 'package:wojob/presentation/screens/admin/admin_home_screen.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  String? _loadingCompanyFor;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final user = authState.currentUser;
    final companyId = user?.empresaId;
    if (companyId != null) {
      final loadKey = '${user!.id}:$companyId';
      if (_loadingCompanyFor != loadKey) {
        _loadingCompanyFor = loadKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<EmpresaState>().loadEmpresaData(companyId);
          }
        });
      }
    } else {
      _loadingCompanyFor = null;
    }

    final Widget screen;
    if (user == null) {
      screen = const WelcomeScreen();
    } else if (user.tipoUsuario == TipoUsuario.empleado) {
      screen = const EmployeeHomeScreen();
    } else {
      screen = const AdminHomeScreen();
    }

    final notice = authState.isBackendEnabled
        ? authState.backendError ?? empresaState.backendError
        : 'Modo local: Supabase no está configurado. '
              'Los cambios no se guardan en la nube y se perderán al cerrar.';
    if (notice == null) return screen;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: screen),
      ],
    );
  }
}
