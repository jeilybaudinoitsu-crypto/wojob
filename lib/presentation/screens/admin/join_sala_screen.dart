import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';

class JoinSalaScreen extends StatefulWidget {
  const JoinSalaScreen({super.key});

  @override
  State<JoinSalaScreen> createState() => _JoinSalaScreenState();
}

class _JoinSalaScreenState extends State<JoinSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaIdCtrl = TextEditingController();
  String? _error;
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
      _error = null;
    });
    try {
      final ok = await empresaState.joinSala(_salaIdCtrl.text, usuarioId: user.id);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'No existe la sala o ya tienes una solicitud pendiente.';
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada. Espera la aprobación del administrador.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is AppException ? e.message : e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a una sala')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Ingresa el ID de la sala',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Pide el ID al administrador principal de la empresa.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 28),
          SectionCard(
            title: 'ID de sala',
            children: [
              Form(
                key: _formKey,
                child: AppTextField(
                  controller: _salaIdCtrl,
                  label: 'ID de la sala',
                  hint: 'Ej. NOR-4826',
                  prefixIcon: Icons.meeting_room_outlined,
                  textInputAction: TextInputAction.done,
                  validator: Validators.salaId,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                onPressed: _loading ? null : _unirse,
                label: _loading ? 'Enviando...' : 'Unirme',
              ),
            ],
          ),
        ],
      ),
    );
  }
}