import 'package:flutter/material.dart';
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
      final isRateLimit = msg.toLowerCase().contains('demasiados intentos') ||
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
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
                    validator: (v) => Validators.required(v, 'Campo obligatorio'),
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Contraseña',
                  hint: 'Tu contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v),
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
                            color: _isRateLimited ? AppColors.warning : AppColors.danger,
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