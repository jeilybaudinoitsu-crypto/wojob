import 'package:flutter/material.dart';

import 'package:wojob/presentation/widgets/section_card.dart';

/// Política de privacidad y explicación de los permisos que usa la app.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.45);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y permisos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Qué datos usamos',
            subtitle: 'Solo la información necesaria para operar tu sala.',
            leadingIcon: Icons.dataset_outlined,
            children: [
              _paragraph(
                theme,
                'Para crear y mantener tu cuenta guardamos tu nombre, correo '
                'electrónico, teléfono, ID personal, cargo y el rol que tienes '
                'en la sala (empleado o administrador).',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'Si subes una foto de perfil o una foto de tu cédula para la '
                'verificación de identidad, esas imágenes se guardan en '
                'almacenamiento privado y solo se comparten con los '
                'administradores de tu sala cuando corresponde.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'Cada marcación de entrada o salida registra la fecha y hora, '
                'tu ubicación GPS (latitud y longitud) y una foto del momento. '
                'La ubicación se consulta al preparar una marcación; WoJob no '
                'la recopila en segundo plano. Estos datos forman el historial '
                'de asistencia de la sala.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'El estado de bienvenida y la aceptación de los términos se '
                'guardan localmente en el dispositivo.',
                bodyStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Permisos del dispositivo',
            subtitle: 'Te los pedimos únicamente cuando los necesitas.',
            leadingIcon: Icons.verified_user_outlined,
            children: [
              _permission(
                theme,
                Icons.camera_alt_outlined,
                'Cámara',
                'Para tomar tu foto de perfil, la foto de tu cédula y la foto '
                    'de cada marcación.',
              ),
              _permission(
                theme,
                Icons.photo_library_outlined,
                'Fotos seleccionadas',
                'Puedes elegir una foto de perfil o de tu cédula mediante el '
                    'selector del sistema. WoJob accede solo a la imagen que '
                    'eliges; no necesita permiso para leer toda tu galería.',
              ),
              _permission(
                theme,
                Icons.location_on_outlined,
                'Ubicación',
                'Para registrar el lugar exacto de entrada y salida. Sin este '
                    'permiso no se puede completar una marcación.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Para qué usamos los datos',
            subtitle: 'Finalidades concretas, sin venta de información.',
            leadingIcon: Icons.fact_check_outlined,
            children: [
              _paragraph(
                theme,
                '• Autenticar tu cuenta y proteger el acceso.\n'
                '• Gestionar tu pertenencia a una sala y tus horarios.\n'
                '• Registrar y mostrar el historial de entradas y salidas.\n'
                '• Verificar tu identidad cuando la sala lo requiera.\n'
                '• Enviar correos de verificación o recuperación de contraseña.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'No vendemos tus datos ni los usamos para publicidad de '
                'terceros. El acceso a la información está limitado por las '
                'políticas de seguridad de la base de datos y del '
                'almacenamiento.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'Si un administrador inicia la contratación de un plan, '
                'compartimos con Stripe el correo de la cuenta y los datos '
                'necesarios para identificar la empresa y el plan. El pago se '
                'procesa en el checkout de Stripe; WoJob no recibe ni guarda '
                'los datos de la tarjeta.',
                bodyStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Cuándo se eliminan tus datos',
            subtitle: 'Tú controlas la eliminación de tu cuenta.',
            leadingIcon: Icons.delete_outline,
            children: [
              _paragraph(
                theme,
                'Puedes eliminar tu cuenta desde Configuración → Tu cuenta. '
                'Se borran tu perfil, tus fotos y tus datos de acceso. La '
                'cuenta deja de estar activa de inmediato.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'El historial de entradas y salidas de la sala se conserva '
                'aunque la cuenta se elimine, porque la sala necesita mantener '
                'su registro de asistencia. En esos registros se guarda el '
                'nombre y el ID personal que tenías al momento de marcar; ya '
                'no se muestra tu cuenta activa ni tus fotos de perfil.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'Si sales de una sala sin eliminar tu cuenta, tu historial de '
                'asistencias de esa sala también permanece. Tus horarios de '
                'esa sala sí se eliminan.',
                bodyStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Seguridad y derechos',
            subtitle: 'Cómo protegemos tu información.',
            leadingIcon: Icons.lock_outline,
            children: [
              _paragraph(
                theme,
                'La autenticación y el almacenamiento se apoyan en Supabase. '
                'Las contraseñas las gestiona Supabase Auth y no se guardan en '
                'el perfil. Las fotos y documentos viven en buckets privados '
                'con acceso mediante enlaces firmados.',
                bodyStyle,
              ),
              _paragraph(
                theme,
                'Puedes consultar y corregir tu correo y teléfono desde '
                'Configuración → Tu cuenta. Para ejercer otros derechos sobre '
                'tus datos, contacta al administrador de tu sala o usa los '
                'canales de soporte de la app.',
                bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Última actualización: noviembre de 2026.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paragraph(ThemeData theme, String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: style),
    );
  }

  Widget _permission(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
