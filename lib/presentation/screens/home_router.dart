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
    if (state.currentUser == null) {
      return const WelcomeScreen();
    }
    if (state.currentUser!.tipoUsuario == TipoUsuario.empleado) {
      return const EmployeeHomeScreen();
    }
    return const AdminHomeScreen();
  }
}
