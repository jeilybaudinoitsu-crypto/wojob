import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/core/theme/app_colors.dart';
import 'package:wojob/presentation/screens/home_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _credCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isRateLimited = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _credCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRateLimited) return;

    setState(() {
      _loading = true;
      _error = null;
      _isRateLimited = false;
    });
    final authState = context.read<app_state.AuthState>();
    try {
      final user = await authState.login(_credCtrl.text, _passCtrl.text);
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Credenciales incorrectas. Verifica tu correo y contraseña.';
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppException ? e.message : e.toString();
      final isRateLimit =
          msg.toLowerCase().contains('demasiados intentos') ||
          msg.toLowerCase().contains('rate limit');
      setState(() {
        _loading = false;
        _error = msg;
        _isRateLimited = isRateLimit;
      });
      if (isRateLimit) {
        _startRateLimitCooldown();
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeRouter()),
      (route) => false,
    );
  }

  void _startRateLimitCooldown() {
    // Supabase rate limits typically last 15-60 minutes.
    // We disable the button for 5 minutes to prevent repeated attempts.
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() => _isRateLimited = false);
      }
    });
  }

  Future<void> _openForgotPassword(BuildContext context) async {
    final authState = context.read<app_state.AuthState>();
    if (!authState.isBackendEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La recuperación de contraseña está disponible solo con Supabase configurado.',
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ForgotPasswordDialog(authState: authState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido de vuelta',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<app_state.AuthState>(
                  builder: (context, authState, _) => Text(
                    authState.isBackendEnabled
                        ? 'Inicia sesión con el correo y contraseña de Supabase.'
                        : 'Puedes iniciar sesión con tu correo, número de teléfono o ID.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Consumer<app_state.AuthState>(
                  builder: (context, authState, _) => AppTextField(
                    controller: _credCtrl,
                    label: authState.isBackendEnabled
                        ? 'Correo electrónico'
                        : 'Correo / Teléfono / ID',
                    hint: authState.isBackendEnabled
                        ? 'ej. maria@wojob.com'
                        : 'ej. maria@wojob.com o EMP-1048',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.required(v, 'Campo obligatorio'),
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Contraseña',
                  hint: 'Tu contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    tooltip: _obscurePass
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => _openForgotPassword(context),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isRateLimited
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _isRateLimited
                                ? AppColors.warning
                                : AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isRateLimited) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Por seguridad, el botón estará deshabilitado por 5 minutos. '
                            'Intenta de nuevo más tarde o usa otra red.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  onPressed: (_loading || _isRateLimited) ? null : _submit,
                  label: _loading
                      ? 'Ingresando...'
                      : _isRateLimited
                      ? 'Espera unos minutos...'
                      : 'Iniciar sesión',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.authState});
  final app_state.AuthState authState;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0: pedir correo, 1: código, 2: nueva contraseña
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscure2 = true;

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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
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
