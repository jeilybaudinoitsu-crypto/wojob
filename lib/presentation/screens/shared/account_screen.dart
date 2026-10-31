import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/core/utils/validators.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/app_text_field.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';

/// Gestión de la cuenta: correo, teléfono, verificación y eliminación.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<void> _editEmail(app_state.AuthState authState) async {
    final user = authState.currentUser;
    if (user == null) return;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmailDialog(correo: user.correo),
    );
    if (updated != true || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Correo electrónico actualizado correctamente.'),
        ),
      );
  }

  Future<void> _editPhone(app_state.AuthState authState) async {
    final user = authState.currentUser;
    if (user == null) return;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PhoneDialog(telefono: user.telefono),
    );
    if (updated != true || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Número de teléfono actualizado correctamente.'),
        ),
      );
  }

  Future<void> _deleteAccount(app_state.AuthState authState) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(authState: authState),
    );
    if (deleted != true || !mounted) return;

    context.read<EmpresaState>().clearSalaData();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final user = authState.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tu cuenta')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No hay una sesión activa.'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tu cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Datos de contacto',
            subtitle: 'El correo y el teléfono asociados a tu cuenta.',
            leadingIcon: Icons.alternate_email_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Correo electrónico'),
                subtitle: Text(user.correo),
                trailing: TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _editEmail(authState),
                  child: const Text('Editar correo'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Teléfono'),
                subtitle: Text(user.telefono),
                trailing: TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _editPhone(authState),
                  child: const Text('Editar teléfono'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                'Por seguridad, te pediremos tu contraseña actual antes de '
                'realizar cualquier cambio.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Eliminar mi cuenta',
            subtitle: 'Esta acción no se puede deshacer.',
            leadingIcon: Icons.warning_amber_outlined,
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
                  'Se eliminarán tu perfil, tus datos de acceso y tus fotos. '
                  'El historial de entradas y salidas de la sala se conservará '
                  'para que el registro de asistencia no se pierda.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _deleteAccount(authState),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Eliminar mi cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog({required this.correo});

  final String correo;

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoCtrl;
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  int _step = 0; // 0: nuevo correo + contraseña, 1: código, 2: confirmar
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _correoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final newEmail = _correoCtrl.text.trim().toLowerCase();
    if (newEmail == widget.correo.trim().toLowerCase()) {
      setState(() {
        _error = 'El nuevo correo debe ser diferente al actual.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authState = context.read<app_state.AuthState>();
      if (!authState.isBackendEnabled) {
        throw const AuthException(
          'Esta acción solo está disponible con Supabase.',
        );
      }
      await authState.verifyCurrentPassword(_passwordCtrl.text);
      if (!mounted) return;
      setState(() => _step = 1);
      await authState.requestEmailChange(newEmail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authState = context.read<app_state.AuthState>();
      final newEmail = _correoCtrl.text.trim();
      await authState.verifyEmailChangeCode(
        email: newEmail,
        code: _codeCtrl.text.trim(),
      );
      await authState.updateContact(
        correo: newEmail,
        telefono: authState.currentUser?.telefono ?? '',
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text(
        _step == 0 ? 'Editar correo electrónico' : 'Verificar código',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_step == 0) ...[
                AppTextField(
                  controller: _correoCtrl,
                  label: 'Nuevo correo electrónico',
                  hint: 'ej. maria@wojob.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña actual',
                  hint: 'Confirma que eres tú',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: (value) => Validators.required(
                    value,
                    'Ingresa tu contraseña actual',
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ],
              if (_step == 1) ...[
                Text(
                  'Ingresa el código de 8 dígitos enviado a ${_correoCtrl.text.trim()}.',
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        PrimaryButton(
          onPressed: _loading
              ? null
              : (_step == 0 ? _sendCode : _verifyAndSave),
          label: _loading
              ? (_step == 0 ? 'Verificando...' : 'Enviando...')
              : (_step == 0 ? 'Siguiente' : 'Guardar cambios'),
          expand: false,
        ),
      ],
    );
  }
}

class _PhoneDialog extends StatefulWidget {
  const _PhoneDialog({required this.telefono});

  final String telefono;

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _telefonoCtrl;
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _telefonoCtrl = TextEditingController(text: widget.telefono);
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newPhone = _telefonoCtrl.text.trim();
    if (newPhone == widget.telefono.trim()) {
      setState(() {
        _error = 'El nuevo teléfono debe ser diferente al actual.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authState = context.read<app_state.AuthState>();
      if (!authState.isBackendEnabled) {
        throw const AuthException(
          'Esta acción solo está disponible con Supabase.',
        );
      }
      await authState.verifyCurrentPassword(_passwordCtrl.text);
      await authState.updateContact(
        correo: authState.currentUser?.correo ?? '',
        telefono: newPhone,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Editar número de teléfono'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _telefonoCtrl,
                label: 'Nuevo teléfono',
                hint: 'Ej. +58 412 1234567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Contraseña actual',
                hint: 'Confirma que eres tú',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                validator: (value) =>
                    Validators.required(value, 'Ingresa tu contraseña actual'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        PrimaryButton(
          onPressed: _loading ? null : _save,
          label: _loading ? 'Guardando...' : 'Siguiente',
          expand: false,
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.authState});

  final app_state.AuthState authState;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authState.deleteAccount(password: _passwordCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Eliminar mi cuenta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta acción es permanente. Se borrarán tu perfil, tus datos '
                'de acceso y tus fotos. No podrás volver a iniciar sesión con '
                'esta cuenta.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'El historial de entradas y salidas de la sala se conservará, '
                'porque forma parte del registro de asistencia del lugar de '
                'trabajo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Contraseña actual',
                hint: 'Escríbela para confirmar',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                validator: (value) =>
                    Validators.required(value, 'Ingresa tu contraseña actual'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _loading ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: Text(_loading ? 'Eliminando...' : 'Eliminar cuenta'),
        ),
      ],
    );
  }
}
