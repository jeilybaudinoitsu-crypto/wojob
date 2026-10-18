import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tipo_usuario.dart';
import '../../services/app_state.dart';
import '../../services/media_service.dart';
import '../../widgets/local_image.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../home_router.dart';

class RegisterPhotosScreen extends StatefulWidget {
  const RegisterPhotosScreen({
    super.key,
    required this.tipoUsuario,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.idPersonal,
    required this.cargo,
  });

  final TipoUsuario tipoUsuario;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String idPersonal;
  final String cargo;

  @override
  State<RegisterPhotosScreen> createState() => _RegisterPhotosScreenState();
}

class _RegisterPhotosScreenState extends State<RegisterPhotosScreen> {
  final _media = MediaService();
  String? _fotoUrl;
  String? _cedulaUrl;
  bool _loading = false;

  Future<void> _tomarFoto(bool esCedula) async {
    final res = await _media.takeFromCamera();
    if (res == null) return;
    setState(() {
      if (esCedula) {
        _cedulaUrl = res.path;
      } else {
        _fotoUrl = res.path;
      }
    });
  }

  Future<void> _galeria(bool esCedula) async {
    final res = await _media.takeFromGallery();
    if (res == null) return;
    setState(() {
      if (esCedula) {
        _cedulaUrl = res.path;
      } else {
        _fotoUrl = res.path;
      }
    });
  }

  Future<void> _finalizar() async {
    setState(() => _loading = true);
    final app = context.read<AppState>();
    app.register(
      tipoUsuario: widget.tipoUsuario,
      nombreCompleto: widget.nombreCompleto,
      correo: widget.correo,
      telefono: widget.telefono,
      idPersonal: widget.idPersonal,
      cargo: widget.cargo,
      fotoUrl: _fotoUrl,
      cedulaUrl: _cedulaUrl,
    );
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeRouter()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación documental')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Sube una foto de tu cara de frente y tu cédula',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Este paso ayuda a verificar tu identidad.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Foto de rostro (frente)',
              subtitle: 'Toma una foto nítida, con buena iluminación.',
              children: [
                _preview(_fotoUrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _tomarFoto(false),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Tomar foto'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _galeria(false),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Cédula de identidad',
              subtitle: 'Sube una foto clara de tu cédula (frente).',
              children: [
                _preview(_cedulaUrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _tomarFoto(true),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Tomar foto'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _galeria(true),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              onPressed: _loading ? null : _finalizar,
              label: _loading ? 'Registrando...' : 'Finalizar registro',
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(String? url) {
    final theme = Theme.of(context);
    if (url == null || url.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
          ),
          color: theme.colorScheme.surface,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.48)),
            const SizedBox(height: 8),
            Text(
              'Sin foto seleccionada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: LocalImage(path: url),
      ),
    );
  }
}
