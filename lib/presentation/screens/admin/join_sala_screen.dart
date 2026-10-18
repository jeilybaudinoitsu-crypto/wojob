import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/screens/admin/admin_sala_screen.dart';

class JoinSalaScreen extends StatefulWidget {
  const JoinSalaScreen({super.key});

  @override
  State<JoinSalaScreen> createState() => _JoinSalaScreenState();
}

class _JoinSalaScreenState extends State<JoinSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaIdCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _salaIdCtrl.dispose();
    super.dispose();
  }

  void _unirse() {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    final user = app.currentUser;
    if (user == null) return;
    final empresa = app.findEmpresaBySalaId(_salaIdCtrl.text);
    if (empresa == null) {
      setState(() => _error = 'No existe una sala con ese ID.');
      return;
    }
    _error = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AdminSalaScreen(empresa: empresa)),
    );
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
                onPressed: _unirse,
                label: 'Unirme',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
