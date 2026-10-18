import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Renderiza una imagen local (archivo) de forma segura en móvil y web.
/// En web usa `Image.network` (blob/localhost URL); en el resto, `Image.file`.
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stack) => _placeholder(context),
      );
    }
    final file = File(path);
    if (!file.existsSync()) return _placeholder(context);
    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stack) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: color),
    );
  }
}

/// Indica si una ruta de foto local existe (siempre true en web).
bool localPhotoExists(String? path) {
  if (path == null || path.isEmpty) return false;
  if (kIsWeb) return true;
  return File(path).existsSync();
}
