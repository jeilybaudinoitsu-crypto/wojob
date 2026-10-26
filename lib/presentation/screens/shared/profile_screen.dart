import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/state/settings_state.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/screens/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<app_state.AuthState>();
    final empresaState = context.watch<EmpresaState>();
    final user = authState.currentUser;
    if (user == null) return const WelcomeScreen();
    final empresa = user.isAdmin
        ? empresaState.empresaById(user.empresaId)
        : null;

    final List<Widget> children = <Widget>[
      SectionCard(
        title: 'Datos del perfil',
        subtitle: 'Informacion de tu cuenta en WoJob.',
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                initials: user.iniciales,
                imageUrl: user.fotoUrl,
                size: 64,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.nombreCompleto,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.cargo ?? user.tipoUsuario.label,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${user.idPersonal}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('Correo'),
        subtitle: Text(user.correo),
        contentPadding: EdgeInsets.zero,
      ),
      ListTile(
        leading: const Icon(Icons.phone_outlined),
        title: const Text('Telefono'),
        subtitle: Text(user.telefono),
        contentPadding: EdgeInsets.zero,
      ),
      ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: const Text('Verificado'),
        subtitle: Text(user.verificado ? 'Si' : 'Pendiente'),
        contentPadding: EdgeInsets.zero,
      ),
      if (empresa != null) ...[
        const SizedBox(height: 20),
        _SubscriptionSection(empresa: empresa),
      ],
      const SizedBox(height: 20),
      SectionCard(
        title: 'Configuracion',
        subtitle: 'Apariencia y preferencias.',
        children: <Widget>[
          Consumer<SettingsState>(
            builder: (context, s, _) => SwitchListTile.adaptive(
              value: s.themeMode == ThemeMode.dark,
              onChanged: (_) => s.toggleTheme(),
              title: const Text('Modo oscuro'),
              subtitle: const Text('Cambia entre claro y oscuro'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        onPressed: () {
          authState.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        },
        label: 'Cerrar sesion',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mi informacion')),
      body: ListView(padding: const EdgeInsets.all(24), children: children),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.empresa});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empresaState = context.watch<EmpresaState>();
    final planActual = empresa.planSuscripcion;
    final empleadosActivos = empresaState.empleadosActivosDeEmpresa(empresa.id);
    final limite = empresa.limiteEmpleados;

    return SectionCard(
      title: 'Suscripción de la sala',
      subtitle: empresa.nombreEmpresa,
      leadingIcon: Icons.workspace_premium_outlined,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAN ACTUAL',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                planActual.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${planActual.precioMensual == 0 ? 'Gratis' : '\$${planActual.precioMensual}/mes'}'
                ' · ${planActual.descripcionCapacidad}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                limite == null
                    ? '$empleadosActivos empleados activos · sin límite'
                    : '$empleadosActivos de $limite empleados activos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Planes disponibles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final plan in PlanSuscripcion.values.skip(1)) ...[
          _PlanOption(
            plan: plan,
            isCurrent: plan == planActual,
            onSelect: plan == planActual
                ? null
                : () => _showPaymentNotice(context, plan),
          ),
          if (plan != PlanSuscripcion.values.last) const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Text(
          'La activación de planes de pago estará disponible cuando se integre '
          'el procesamiento de pagos. Elegir un plan aquí no genera un cobro '
          'ni modifica la suscripción actual.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }

  Future<void> _showPaymentNotice(BuildContext context, PlanSuscripcion plan) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagos próximamente'),
        content: Text(
          'La activación de ${plan.label} requiere completar el pago. '
          'No se ha cambiado el plan actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final PlanSuscripcion plan;
  final bool isCurrent;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.25),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCurrent)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${plan.precioMensual}/mes · ${plan.descripcionCapacidad}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSelect,
            child: Text(isCurrent ? 'Plan actual' : 'Elegir ${plan.label}'),
          ),
        ],
      ),
    );
  }
}
