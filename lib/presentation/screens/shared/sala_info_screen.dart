import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/screens/home_router.dart';
import 'package:wojob/presentation/screens/shared/edit_sala_screen.dart';
import 'package:wojob/presentation/screens/admin/members_screen.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/copyable_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';

/// Información de la sala actual, cambio de sala y salida.
class SalaInfoScreen extends StatefulWidget {
  const SalaInfoScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<SalaInfoScreen> createState() => _SalaInfoScreenState();
}

class _SalaInfoScreenState extends State<SalaInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaIdCtrl = TextEditingController();
  bool _sendingRequest = false;
  bool _leaving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _salaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarCambio() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<app_state.AuthState>();
    final empresaState = context.read<EmpresaState>();
    final user = authState.currentUser;
    if (user == null) return;

    setState(() {
      _sendingRequest = true;
      _message = null;
    });
    try {
      final ok = await empresaState.joinSala(
        _salaIdCtrl.text,
        usuarioId: user.id,
      );
      if (!mounted) return;
      setState(() {
        _messageIsError = !ok;
        _message = ok
            ? 'Solicitud enviada. Un administrador de la nueva sala debe '
                  'aceptarla para que el cambio se complete.'
            : 'No se encontró la sala o ya tienes una solicitud pendiente.';
        if (ok) _salaIdCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = e is AppException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Future<void> _salirDeLaSala() async {
    final authState = context.read<app_state.AuthState>();
    final empresaState = context.read<EmpresaState>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salir de la sala'),
        content: const Text(
          'Dejarás de pertenecer a esta sala y se eliminarán los turnos que '
          'tengas asignados en ella. Tu cuenta y tu historial de entradas y '
          'salidas se conservarán.\n\n'
          'Para volver, necesitarás enviar una nueva solicitud y que un '
          'administrador la acepte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Salir de la sala'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _leaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await authState.leaveRoom();
      empresaState.clearSalaData();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeRouter()),
        (route) => false,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Saliste de la sala correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leaving = false;
        _messageIsError = true;
        _message = e is AppException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final empresa = empresaState.empresaById(widget.empresa.id) ?? widget.empresa;
    final user = authState.currentUser;
    final esAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Salas')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: empresa.nombreEmpresa,
            subtitle: 'Información de la sala a la que perteneces.',
            leadingIcon: Icons.meeting_room_outlined,
            children: [
              CopyableField(label: 'ID de sala', value: empresa.idSala),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Dirección'),
                subtitle: Text(empresa.direccionEmpresa),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Plan de la sala'),
                subtitle: Text(
                  '${empresa.planSuscripcion.label} · '
                  '${empresa.planSuscripcion.descripcionCapacidad}',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          if (esAdmin) ...[
            const SizedBox(height: 20),
            SectionCard(
              title: 'Administración',
              subtitle: 'Solo los administradores de la sala ven estas opciones.',
              leadingIcon: Icons.admin_panel_settings_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar información de la sala'),
                  subtitle: const Text(
                    'Nombre, dirección y contraseña de la sala',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditSalaScreen(empresa: empresa),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Miembros de la sala'),
                  subtitle: const Text(
                    'Consulta los miembros y quita empleados de la sala',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MembersScreen(empresa: empresa),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SectionCard(
            title: 'Cambiar de sala',
            subtitle: 'Envía una solicitud a otra sala con su ID.',
            leadingIcon: Icons.swap_horiz_outlined,
            children: [
              Form(
                key: _formKey,
                child: AppTextField(
                  controller: _salaIdCtrl,
                  label: 'ID de la sala nueva',
                  hint: 'Ej. NOR-4826',
                  prefixIcon: Icons.meeting_room_outlined,
                  textInputAction: TextInputAction.done,
                  validator: Validators.salaId,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                onPressed: _sendingRequest ? null : _solicitarCambio,
                label: _sendingRequest
                    ? 'Enviando solicitud...'
                    : 'Enviar solicitud de cambio',
                icon: Icons.send_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Seguirás en tu sala actual hasta que un administrador de la '
                'nueva sala acepte la solicitud. Al aceptarla, tus turnos de '
                'la sala anterior se eliminan y tu historial de asistencias '
                'se conserva.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _messageIsError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Salir de la sala',
            subtitle: 'Deja de pertenecer a esta sala.',
            leadingIcon: Icons.exit_to_app_outlined,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  'Se eliminarán tus turnos de esta sala. Tu cuenta y el '
                  'historial de entradas y salidas se conservan.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _leaving ? null : _salirDeLaSala,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  _leaving ? 'Saliendo...' : 'Salir de la sala',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
