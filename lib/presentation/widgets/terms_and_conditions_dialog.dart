import 'package:flutter/material.dart';

import 'package:wojob/presentation/widgets/primary_button.dart';
import 'package:wojob/presentation/widgets/section_card.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  const TermsAndConditionsDialog({super.key, required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  bool _isSaving = false;
  bool _wasRejected = false;
  String? _saveError;

  Future<void> _accept() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.onAccept();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error, stackTrace) {
      debugPrint('No se pudo guardar la aceptación de términos: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError =
              'No se pudo guardar tu aceptación. Comprueba el almacenamiento '
              'del dispositivo e inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Términos y privacidad',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    Text(
                      'Antes de continuar, revisa cómo WoJob utiliza tus '
                      'datos para gestionar la asistencia laboral.',
                    ),
                    SizedBox(height: 16),
                    SectionCard(
                      title: 'Geolocalización',
                      leadingIcon: Icons.location_on_outlined,
                      padding: EdgeInsets.all(16),
                      children: [
                        Text(
                          'WoJob puede solicitar la ubicación GPS al realizar '
                          'una marcación de asistencia para registrar el lugar '
                          'en que se efectúa. La ubicación se utiliza para '
                          'esta función y requiere los permisos del dispositivo.',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SectionCard(
                      title: 'Fotografías de asistencia',
                      leadingIcon: Icons.camera_alt_outlined,
                      padding: EdgeInsets.all(16),
                      children: [
                        Text(
                          'Al marcar asistencia, la aplicación puede capturar '
                          'una fotografía para respaldar la marcación y ayudar '
                          'a verificar la identidad del usuario. La cámara se '
                          'utiliza con tu autorización.',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SectionCard(
                      title: 'Almacenamiento y uso',
                      leadingIcon: Icons.cloud_outlined,
                      padding: EdgeInsets.all(16),
                      children: [
                        Text(
                          'Los datos necesarios para el servicio, incluidas '
                          'las marcaciones y sus fotografías, pueden almacenarse '
                          'en Supabase para que la empresa gestione la asistencia. '
                          'WoJob aplica controles de acceso y medidas de '
                          'seguridad razonables. Los datos se usan para operar '
                          'el servicio y no deben compartirse con terceros salvo '
                          'cuando sea necesario para prestarlo o lo exija la ley.',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Puedes administrar los permisos de ubicación y cámara '
                      'desde la configuración de tu dispositivo. Si rechazas '
                      'estos términos, no podrás acceder a la aplicación. '
                      'Este aviso informativo no sustituye las obligaciones '
                      'legales aplicables ni las políticas de tu empleador.',
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              if (_wasRejected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Para usar WoJob, debes aceptar estos términos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    _saveError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    PrimaryButton(
                      onPressed: _isSaving ? null : _accept,
                      label: _isSaving ? 'Guardando…' : 'Aceptar',
                      icon: Icons.check,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => setState(() => _wasRejected = true),
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
