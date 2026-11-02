import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/widgets/section_card.dart';
import 'package:wojob/presentation/widgets/avatar.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/wojob_header.dart';
import 'package:wojob/presentation/screens/shared/profile_screen.dart';
import 'package:wojob/presentation/screens/admin/create_sala_screen.dart';
import 'package:wojob/presentation/screens/admin/join_sala_screen.dart';
import 'package:wojob/presentation/screens/admin/admin_sala_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<app_state.AuthState>().currentUser;
    final empresaState = context.watch<EmpresaState>();
    if (user == null) return const SizedBox.shrink();
    final empresa = empresaState.empresaById(user.empresaId);
    if (empresa != null) {
      return AdminSalaScreen(key: ValueKey(empresa.id), empresa: empresa);
    }

    return Scaffold(
      appBar: WoJobHeader(
        title: 'Panel de administración',
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Bienvenido, ${user.nombreCompleto}',
            subtitle: 'Rol: ${user.tipoUsuario.label} · ID: ${user.idPersonal}',
            children: [
              Row(
                children: [
                  AppAvatar(initials: user.iniciales, imageUrl: user.fotoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Aún no tienes una sala. Puedes crear una nueva o unirte a una existente.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreateSalaScreen())),
            label: 'Crear una sala',
            icon: Icons.add_business_outlined,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JoinSalaScreen())),
            icon: const Icon(Icons.login_outlined),
            label: const Text('Unirse a una sala'),
          ),
        ],
      ),
    );
  }
}
