import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';

/// Flujo de recuperación/cambio de contraseña por código de correo.
///
/// Se usa tanto en el inicio de sesión ("¿Olvidaste tu contraseña?") como en
/// Configuración. Al terminar, cierra la sesión para que el usuario vuelva a
/// entrar con la nueva contraseña.
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    super.key,
    required this.authState,
    this.initialEmail,
  });

  final app_state.AuthState authState;
  final String? initialEmail;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0: pedir correo, 1: código, 2: nueva contraseña
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authState.sendPasswordResetEmail(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authState.verifyPasswordResetCode(
        email: _emailCtrl.text,
        code: _codeCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    var passwordUpdated = false;
    try {
      await widget.authState.updatePassword(newPassword: _passCtrl.text);
      passwordUpdated = true;
      await widget.authState.logout();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña actualizada correctamente. Ya puedes iniciar sesión.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = passwordUpdated
            ? 'La contraseña se actualizó, pero no se pudo cerrar la sesión automáticamente. '
                  'Cierra la aplicación y vuelve a iniciar sesión.'
            : e is AppException
            ? e.message
            : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _step == 0
            ? 'Recuperar contraseña'
            : _step == 1
            ? 'Verificar código'
            : 'Nueva contraseña',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 0) ...[
              const Text(
                'Te enviaremos un código de verificación a tu correo electrónico.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                hint: 'ej. maria@wojob.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
            ],
            if (_step == 1) ...[
              Text(
                'Ingresa el código que recibiste en ${_emailCtrl.text.trim()}.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _codeCtrl,
                label: 'Código de verificación',
                hint: '12345678',
                prefixIcon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(Validators.otpLength),
                ],
                validator: (value) {
                  final code = value?.trim() ?? '';
                  return RegExp('^[0-9]{${Validators.otpLength}}\$')
                          .hasMatch(code)
                      ? null
                      : 'Ingresa el código de ${Validators.otpLength} dígitos';
                },
              ),
            ],
            if (_step == 2) ...[
              const Text('Ingresa y confirma tu nueva contraseña.'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passCtrl,
                label: 'Nueva contraseña',
                hint: 'Mínimo 8 caracteres',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                validator: Validators.password,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmCtrl,
                label: 'Confirmar contraseña',
                hint: 'Repite la contraseña',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure2,
                validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure2
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (_step == 0)
          PrimaryButton(
            onPressed: _loading ? null : _sendCode,
            label: _loading ? 'Enviando...' : 'Enviar código',
          ),
        if (_step == 1)
          PrimaryButton(
            onPressed: _loading ? null : _verifyCode,
            label: _loading ? 'Verificando...' : 'Verificar',
          ),
        if (_step == 2)
          PrimaryButton(
            onPressed: _loading ? null : _updatePassword,
            label: _loading ? 'Guardando...' : 'Restablecer contraseña',
          ),
      ],
    );
  }
}
