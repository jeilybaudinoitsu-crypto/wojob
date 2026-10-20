import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';
import 'package:wojob/presentation/screens/employee/employee_home_screen.dart';
import 'package:wojob/presentation/screens/admin/admin_home_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final Widget screen;
    if (state.currentUser == null) {
      screen = const WelcomeScreen();
    } else if (state.currentUser!.tipoUsuario == TipoUsuario.empleado) {
      screen = const EmployeeHomeScreen();
    } else {
      screen = const AdminHomeScreen();
    }

    final notice = state.isBackendEnabled
        ? state.backendError
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
                Icon(Icons.cloud_off_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer),
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
