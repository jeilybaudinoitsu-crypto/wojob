import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/avatar.dart';
import '../shared/profile_screen.dart';
import 'employee_sala_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final _salaIdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _msg;

  @override
  void dispose() {
    _salaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    final user = app.currentUser;
    if (user == null) return;
    final ok = app.joinSala(_salaIdCtrl.text, usuarioId: user.id);
    setState(() {
      _msg = ok
          ? 'Solicitud enviada. Espera a que el administrador la acepte.'
          : 'No se encontró la sala o ya tienes una solicitud pendiente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final empresa = state.empresaById(user.empresaId);
    final tieneSala = empresa != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Bienvenido, ${user.nombreCompleto}',
            subtitle: 'ID personal: ${user.idPersonal} · Cargo: ${user.cargo ?? 'Empleado'}',
            children: [
              Row(
                children: [
                  AppAvatar(initials: user.iniciales, imageUrl: user.fotoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      tieneSala
                          ? 'Te encuentras en la sala: ${empresa.nombreEmpresa} (${empresa.idSala})'
                          : 'Aún no perteneces a ninguna sala. Únete a una con el ID de la sala.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tieneSala) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmployeeSalaScreen(empresa: empresa),
                  ),
                );
              },
              label: 'Entrar a mi sala',
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '¿Unirte a otra sala?',
              subtitle: 'Puedes enviar una nueva solicitud con otro ID de sala.',
              children: [
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _salaIdCtrl,
                    label: 'ID de sala',
                    hint: 'Ej. NOR-4826',
                    prefixIcon: Icons.meeting_room_outlined,
                    textInputAction: TextInputAction.done,
                    validator: Validators.salaId,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  onPressed: _unirse,
                  label: 'Enviar solicitud',
                ),
                if (_msg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _msg!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),
            SectionCard(
              title: 'Unirte a sala',
              subtitle: 'Ingresa el ID de la sala para solicitar acceso.',
              children: [
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _salaIdCtrl,
                    label: 'ID de sala',
                    hint: 'Ej. NOR-4826',
                    prefixIcon: Icons.meeting_room_outlined,
                    textInputAction: TextInputAction.done,
                    validator: Validators.salaId,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  onPressed: _unirse,
                  label: 'Enviar solicitud para unirme',
                ),
                if (_msg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _msg!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
