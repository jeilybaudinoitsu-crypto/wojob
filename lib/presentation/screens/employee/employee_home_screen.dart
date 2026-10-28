import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/wojob_header.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/screens/shared/profile_screen.dart';
import 'package:wojob/presentation/screens/employee/employee_sala_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final _salaIdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _msg;
  bool _loading = false;

  @override
  void dispose() {
    _salaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<app_state.AuthState>();
    final empresaState = context.read<EmpresaState>();
    final user = authState.currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final ok = await empresaState.joinSala(
        _salaIdCtrl.text,
        usuarioId: user.id,
      );
      if (mounted) {
        setState(() {
          _msg = ok
              ? 'Solicitud enviada. Espera a que el administrador la acepte.'
              : 'No se encontró la sala o ya tienes una solicitud pendiente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = e is AppException ? e.message : e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final user = authState.currentUser;
    if (user == null) return const SizedBox.shrink();

    final empresa = empresaState.empresaById(user.empresaId);
    final tieneSala = empresa != null;

    return Scaffold(
      appBar: WoJobHeader(
        title: 'Panel del empleado',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Bienvenido, ${user.nombreCompleto}',
            subtitle:
                'ID personal: ${user.idPersonal} · Cargo: ${user.cargo ?? 'Empleado'}',
            leadingIcon: Icons.waving_hand_outlined,
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
              subtitle:
                  'Puedes enviar una nueva solicitud con otro ID de sala.',
              leadingIcon: Icons.meeting_room_outlined,
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
                  onPressed: _loading ? null : _unirse,
                  label: _loading ? 'Enviando...' : 'Enviar solicitud',
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
                  onPressed: _loading ? null : _unirse,
                  label: _loading
                      ? 'Enviando...'
                      : 'Enviar solicitud para unirme',
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
