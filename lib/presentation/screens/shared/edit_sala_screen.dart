import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';

/// Edición de la información de la sala, verificando su contraseña.
class EditSalaScreen extends StatefulWidget {
  const EditSalaScreen({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<EditSalaScreen> createState() => _EditSalaScreenState();
}

class _EditSalaScreenState extends State<EditSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  final _passwordCtrl = TextEditingController();
  final _nuevaPasswordCtrl = TextEditingController();
  final _confirmarPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.empresa.nombreEmpresa);
    _direccionCtrl = TextEditingController(
      text: widget.empresa.direccionEmpresa,
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _passwordCtrl.dispose();
    _nuevaPasswordCtrl.dispose();
    _confirmarPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<EmpresaState>().updateSalaInfo(
        empresaId: widget.empresa.id,
        passwordSala: _passwordCtrl.text,
        nombreEmpresa: _nombreCtrl.text,
        direccionEmpresa: _direccionCtrl.text,
        nuevaPassword: _nuevaPasswordCtrl.text.trim().isEmpty
            ? null
            : _nuevaPasswordCtrl.text,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Información de la sala actualizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar sala')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Información de la sala',
            subtitle: 'Sala ${widget.empresa.idSala}',
            leadingIcon: Icons.edit_outlined,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre de la sala',
                      hint: 'Ej. Sucursal Norte',
                      prefixIcon: Icons.business_outlined,
                      validator: (value) => Validators.required(
                        value,
                        'Ingresa el nombre de la sala',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _direccionCtrl,
                      label: 'Dirección',
                      hint: 'Dirección exacta del lugar de trabajo',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (value) => Validators.required(
                        value,
                        'Ingresa la dirección de la sala',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: 'Contraseña actual de la sala',
                      hint: 'Confirma que administras esta sala',
                      prefixIcon: Icons.key_outlined,
                      obscureText: _obscureActual,
                      validator: (value) => Validators.required(
                        value,
                        'Ingresa la contraseña de la sala',
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureActual
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureActual = !_obscureActual),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cambiar contraseña de la sala (opcional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Entre 8 y 16 caracteres, con mayúscula, minúscula, '
                        'número y uno de estos símbolos: . * / _',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nuevaPasswordCtrl,
                      label: 'Nueva contraseña de la sala',
                      hint: 'Déjala vacía para conservar la actual',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureNueva,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        return Validators.passwordStrict(text);
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNueva
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNueva = !_obscureNueva),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmarPasswordCtrl,
                      label: 'Confirmar nueva contraseña',
                      hint: 'Repite la nueva contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmar,
                      validator: (value) {
                        final nueva = _nuevaPasswordCtrl.text.trim();
                        if (nueva.isEmpty) return null;
                        return Validators.confirmPassword(value, nueva);
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmar = !_obscureConfirmar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La contraseña de la sala es distinta de la contraseña de '
                    'tu cuenta. Si la cambias, compártela con las personas '
                    'que necesiten administrar la sala.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed: _loading ? null : _guardar,
            label: _loading ? 'Guardando...' : 'Guardar cambios',
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}
