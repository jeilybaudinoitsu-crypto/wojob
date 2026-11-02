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
    final user = context.read<app_state.AuthState>().currentUser;
    if (user == null) return;
    final empresaState = context.read<EmpresaState>();
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
        setState(
          () => _msg = ok
              ? 'Solicitud enviada. Espera a que el administrador la acepte.'
              : 'No se encontró la sala o ya tienes una solicitud pendiente.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _msg = e is AppException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<app_state.AuthState>().currentUser;
    final empresaState = context.watch<EmpresaState>();
    if (user == null) return const SizedBox.shrink();
    final empresa = empresaState.empresaById(user.empresaId);
    if (empresa != null) {
      return EmployeeSalaScreen(key: ValueKey(empresa.id), empresa: empresa);
    }

    return Scaffold(
      appBar: WoJobHeader(
        title: 'Panel del empleado',
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Bienvenido, ${user.nombreCompleto}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Unirte a sala',
            subtitle: 'Aún no perteneces a una sala. Ingresa su ID para solicitar acceso.',
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
      ),
    );
  }
}
