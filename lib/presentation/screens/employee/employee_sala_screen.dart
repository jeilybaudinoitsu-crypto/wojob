import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/screens/admin/attendance_log_screen.dart';
import 'package:wojob/presentation/screens/admin/members_screen.dart';
import 'package:wojob/presentation/screens/employee/mark_attendance_screen.dart';
import 'package:wojob/presentation/screens/shared/profile_screen.dart';
import 'package:wojob/presentation/screens/shared/schedule_view.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/room_menu_drawer.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/wojob_header.dart';

class EmployeeSalaScreen extends StatefulWidget {
  const EmployeeSalaScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<EmployeeSalaScreen> createState() => _EmployeeSalaScreenState();
}

class _EmployeeSalaScreenState extends State<EmployeeSalaScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<app_state.AuthState>().currentUser;
      final state = context.read<AsistenciaState>();
      if (user != null && state.isBackendEnabled) {
        state.loadAsistenciasEmpleado(user.id);
      }
      context.read<EmpresaState>().loadDirectorio(widget.empresa.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<app_state.AuthState>().currentUser;
    final empresaState = context.watch<EmpresaState>();
    if (user == null) return const SizedBox.shrink();
    final sala = empresaState.empresaById(widget.empresa.id) ?? widget.empresa;
    final horarios = empresaState
        .horariosDeEmpleado(user.id)
        .where((h) => h.empresaId == sala.id)
        .toList();
    const titles = [
      'Inicio',
      'Mi historial',
      'Miembros de la sala',
      'Mi perfil',
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        drawer: RoomMenuDrawer(empresa: sala),
        appBar: WoJobHeader(title: titles[_selectedIndex]),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ListView(
              key: const PageStorageKey('employee-inicio'),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Hola, ${user.nombreCompleto}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu jornada comienza aquí.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: sala.nombreEmpresa,
                  leadingIcon: Icons.business_outlined,
                  children: [
                    InfoTile(
                      title: 'Dirección de la empresa',
                      value: sala.direccionEmpresa,
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Mi asistencia',
                  subtitle: 'Registra tu jornada con foto y ubicación.',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _irMarca(sala, TipoAsistencia.entrada),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Marcar entrada'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _irMarca(sala, TipoAsistencia.salida),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Marcar salida'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ScheduleView(horarios: horarios),
              ],
            ),
            AttendanceLogScreen(
              empresa: sala,
              empleadoId: user.id,
              embedded: true,
            ),
            MembersScreen(empresa: sala, embedded: true),
            const ProfileScreen(embedded: true),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Mi historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Miembros',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  void _irMarca(Empresa sala, TipoAsistencia tipo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(empresa: sala, tipo: tipo),
      ),
    );
  }
}
