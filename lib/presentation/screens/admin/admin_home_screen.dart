import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/avatar.dart';
import '../../widgets/primary_button.dart';
import '../shared/profile_screen.dart';
import 'create_sala_screen.dart';
import 'join_sala_screen.dart';
import 'admin_sala_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final empresa = state.empresaById(user.empresaId);
    final tieneSala = empresa != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
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
                      tieneSala
                          ? 'Administras la sala: ${empresa.nombreEmpresa} (${empresa.idSala})'
                          : 'Aún no has creado una sala. Puedes crear una nueva o unirte a una existente.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tieneSala) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminSalaScreen(empresa: empresa),
                ),
              ),
              label: 'Entrar a la sala',
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Acciones rápidas',
              subtitle: 'Crear o unirte a otra sala.',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateSalaScreen()),
                        ),
                        icon: const Icon(Icons.add_business_outlined),
                        label: const Text('Crear sala'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const JoinSalaScreen()),
                        ),
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('Unirse a sala'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateSalaScreen()),
              ),
              label: 'Crear una sala',
              icon: Icons.add_business_outlined,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JoinSalaScreen()),
              ),
              icon: const Icon(Icons.login_outlined),
              label: const Text('Unirse a una sala'),
            ),
          ],
        ],
      ),
    );
  }
}
