import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tipo_usuario.dart';
import '../services/app_state.dart';
import 'welcome_screen.dart';
import 'employee/employee_home_screen.dart';
import 'admin/admin_home_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.currentUser == null) {
      return const WelcomeScreen();
    }
    if (state.currentUser!.tipoUsuario == TipoUsuario.empleado) {
      return const EmployeeHomeScreen();
    }
    return const AdminHomeScreen();
  }
}
