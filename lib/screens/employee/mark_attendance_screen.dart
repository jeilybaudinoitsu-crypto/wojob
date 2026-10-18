import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/empresa.dart';
import '../../models/tipo_asistencia.dart';
import '../../services/app_state.dart';
import '../../services/location_service.dart';
import '../../services/media_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/local_image.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({
    super.key,
    required this.empresa,
    required this.tipo,
  });

  final Empresa empresa;
  final TipoAsistencia tipo;

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _media = MediaService();
  final _location = LocationService();

  String? _fotoUrl;
  GeoPoint? _geo;
  bool _loading = false;
  bool _gettingLoc = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _tomarFoto() async {
    final res = await _media.takeFromCamera();
    if (res == null) return;
    setState(() => _fotoUrl = res.path);
  }

  Future<void> _galeria() async {
    final res = await _media.takeFromGallery();
    if (res == null) return;
    setState(() => _fotoUrl = res.path);
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _gettingLoc = true);
    final geo = await _location.getCurrentLocation();
    setState(() {
      _geo = geo;
      _gettingLoc = false;
    });
  }

  Future<void> _marcar() async {
    if (_fotoUrl == null || _fotoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar una foto para marcar.')),
      );
      return;
    }
    final user = context.read<AppState>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    context.read<AppState>().markAttendance(
          empleadoId: user.id,
          empresaId: widget.empresa.id,
          tipo: widget.tipo,
          latitud: _geo?.latitude ?? 0.0,
          longitud: _geo?.longitude ?? 0.0,
          fotoUrl: _fotoUrl!,
        );
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.tipo.label} registrada correctamente a las ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hora = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text('Marcar ${widget.tipo.label.toLowerCase()}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Datos del registro',
            subtitle: 'Hora exacta, ubicación y fotografía requeridas.',
            children: [
              ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: const Text('Hora exacta'),
                subtitle: Text(
                  '${hora.day.toString().padLeft(2, '0')}/${hora.month.toString().padLeft(2, '0')}/${hora.year} ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Ubicación exacta'),
                subtitle: Text(
                  _gettingLoc
                      ? 'Obteniendo ubicación...'
                      : _geo == null
                          ? 'No se pudo obtener ubicación'
                          : formatCoordinates(_geo!.latitude, _geo!.longitude),
                ),
                contentPadding: EdgeInsets.zero,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: _obtenerUbicacion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Foto al momento de ${widget.tipo.dbValue}',
            subtitle: 'Toma una foto de tu ubicación actual.',
            children: [
              _preview(_fotoUrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Tomar foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _galeria,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            onPressed: _loading ? null : _marcar,
            label: _loading
                ? 'Registrando...'
                : 'Confirmar ${widget.tipo.label.toLowerCase()}',
          ),
        ],
      ),
    );
  }

  Widget _preview(String? url) {
    final theme = Theme.of(context);
    if (url == null || url.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          color: theme.colorScheme.surface,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 42, color: theme.colorScheme.onSurface.withValues(alpha: 0.48)),
            const SizedBox(height: 8),
            Text('Sin foto',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                )),
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
