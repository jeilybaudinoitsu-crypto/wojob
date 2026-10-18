import 'package:flutter/material.dart';

import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/screens/auth/register_photos_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  TipoUsuario _tipo = TipoUsuario.empleado;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _idCtrl.dispose();
    _cargoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPhotosScreen(
          tipoUsuario: _tipo,
          nombreCompleto: _nombreCtrl.text,
          correo: _correoCtrl.text,
          telefono: _telefonoCtrl.text,
          idPersonal: _idCtrl.text,
          cargo: _cargoCtrl.text,
          password: _passCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos personales',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona tu rol, completa tus datos y continúa al siguiente paso.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Soy',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SegmentedButton<TipoUsuario>(
                  segments: const [
                    ButtonSegment(
                      value: TipoUsuario.empleado,
                      label: Text('Empleado'),
                      icon: Icon(Icons.badge_outlined),
                    ),
                    ButtonSegment(
                      value: TipoUsuario.adminPrincipal,
                      label: Text('Administrador'),
                      icon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (s) => setState(() => _tipo = s.first),
                ),
                const SizedBox(height: 26),
                AppTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre completo',
                  hint: 'Ej. Carlos Reyes',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _correoCtrl,
                  label: 'Correo electrónico',
                  hint: 'correo@empresa.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _telefonoCtrl,
                  label: 'Número de teléfono',
                  hint: '5512345678',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _idCtrl,
                  label: 'ID (se generará visualmente como EMP-XXXX o ADM-XXXX)',
                  hint: 'Ej. EMP-1048',
                  prefixIcon: Icons.qr_code_2_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.idOrText(v, 'ID'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _cargoCtrl,
                  label: 'Cargo',
                  hint: 'Ej. Operador / Gerente',
                  prefixIcon: Icons.work_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Contraseña',
                  hint: 'Mínimo 8 caracteres',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passCtrl.text),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  onPressed: _siguiente,
                  label: 'Siguiente',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
