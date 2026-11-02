import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/utils/formatters.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/presentation/screens/admin/assign_shifts_screen.dart';
import 'package:wojob/presentation/screens/admin/attendance_log_screen.dart';
import 'package:wojob/presentation/screens/admin/members_screen.dart';
import 'package:wojob/presentation/screens/admin/requests_screen.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/copyable_field.dart';
import 'package:wojob/presentation/widgets/room_menu_drawer.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/wojob_header.dart';

class AdminSalaScreen extends StatefulWidget {
  const AdminSalaScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<AdminSalaScreen> createState() => _AdminSalaScreenState();
}

class _AdminSalaScreenState extends State<AdminSalaScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AsistenciaState>();
      if (state.isBackendEnabled) {
        state.loadAsistenciasEmpresa(widget.empresa.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.watch<EmpresaState>();
    final sala = empresaState.empresaById(widget.empresa.id) ?? widget.empresa;
    final pendientes = empresaState
        .solicitudesParaAdmin(sala.id)
        .where((s) => s.estado == EstadoSolicitud.pendiente)
        .length;
    const titles = [
      'Inicio',
      'Turnos',
      'Asistencias',
      'Miembros',
      'Solicitudes',
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
            _inicio(context, sala),
            AssignShiftsScreen(empresa: sala, embedded: true),
            AttendanceLogScreen(empresa: sala, embedded: true),
            MembersScreen(empresa: sala, embedded: true),
            RequestsScreen(empresa: sala, embedded: true),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Turnos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Asistencias',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Miembros',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendientes > 0,
                label: Text('$pendientes'),
                child: const Icon(Icons.mail_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendientes > 0,
                label: Text('$pendientes'),
                child: const Icon(Icons.mail_rounded),
              ),
              label: 'Solicitudes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inicio(BuildContext context, Empresa sala) {
    final theme = Theme.of(context);
    final empresaState = context.watch<EmpresaState>();
    final asistenciaState = context.watch<AsistenciaState>();
    final user = context.watch<app_state.AuthState>().currentUser;
    final miembros = empresaState.miembrosDeEmpresa(sala.id);
    final asistencias = asistenciaState.asistenciasDeEmpresa(sala.id);
    final recientes = asistencias.take(5).toList();

    return ListView(
      key: const PageStorageKey('admin-inicio'),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hola, ${user?.nombreCompleto ?? 'administrador'}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'El resumen de tu sala, en un solo lugar.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: sala.nombreEmpresa,
          leadingIcon: Icons.business_outlined,
          children: [
            CopyableField(label: 'ID de sala', value: sala.idSala),
            const SizedBox(height: 8),
            InfoTile(
              title: 'Dirección de la sala',
              value: sala.direccionEmpresa,
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _stat(
                theme,
                'Empleados',
                '${miembros.where((m) => !m.isAdmin).length}',
                Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _stat(
                theme,
                'Administradores',
                '${miembros.where((m) => m.isAdmin).length}',
                Icons.admin_panel_settings_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Asistencias',
          subtitle: '${asistencias.length} registros de entrada y salida',
          leadingIcon: Icons.fact_check_outlined,
          children: [
            if (asistenciaState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (asistenciaState.backendError != null)
              Text(
                asistenciaState.backendError!,
                style: TextStyle(color: theme.colorScheme.error),
              )
            else if (recientes.isEmpty)
              const Text('Aún no hay asistencias en esta sala.')
            else
              for (final a in recientes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    a.tipo == TipoAsistencia.entrada
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                  ),
                  title: Text(
                    empresaState.perfilById(a.empleadoId)?.nombreCompleto ??
                        'Empleado',
                  ),
                  subtitle: Text(
                    '${a.tipo.label} · ${formatDateShort(a.fechaHora)}',
                  ),
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _selectedIndex = 2),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Ver todas las asistencias'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(ThemeData theme, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
