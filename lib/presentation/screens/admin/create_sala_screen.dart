import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/app_state.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/copyable_field.dart';
import 'package:wojob/presentation/screens/admin/admin_sala_screen.dart';

class CreateSalaScreen extends StatefulWidget {
  const CreateSalaScreen({super.key});

  @override
  State<CreateSalaScreen> createState() => _CreateSalaScreenState();
}

class _CreateSalaScreenState extends State<CreateSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  Empresa? _creada;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _crear() {
    if (!_formKey.currentState!.validate()) return;
    final empresa = context.read<AppState>().createSala(
          nombreEmpresa: _nombreCtrl.text,
          direccionEmpresa: _direccionCtrl.text,
          passwordHash: _passCtrl.text,
        );
    setState(() => _creada = empresa);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear sala')),
      body: _creada != null ? _successView(_creada!) : _formView(theme),
    );
  }

  Widget _formView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Datos de la empresa',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa la información para generar el ID de la sala.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nombreCtrl,
                label: 'Nombre de la empresa',
                hint: 'Ej. Logística del Norte S.A.',
                prefixIcon: Icons.business_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _direccionCtrl,
                label: 'Ubicación exacta del lugar',
                hint: 'Calle, número, ciudad',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _passCtrl,
                label: 'Contraseña de la sala',
                hint: 'Entre 8 y 16 chars (mayús, minús, número y . * / _)',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: Validators.passwordStrict,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          onPressed: _crear,
          label: 'Crear sala y generar ID',
        ),
      ],
    );
  }

  Widget _successView(Empresa empresa) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: '¡Sala creada!',
          subtitle: 'Comparte el ID de la sala con tus empleados.',
          children: [
            CopyableField(label: 'ID de la sala', value: empresa.idSala),
            const SizedBox(height: 16),
            _row(theme, Icons.business_outlined, 'Empresa', empresa.nombreEmpresa),
            const SizedBox(height: 12),
            _row(theme, Icons.location_on_outlined, 'Ubicación', empresa.direccionEmpresa),
          ],
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AdminSalaScreen(empresa: empresa),
            ),
          ),
          label: 'Ir a mi sala',
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
