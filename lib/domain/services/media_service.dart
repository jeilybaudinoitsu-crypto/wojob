import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'package:wojob/core/config/app_config.dart';

class CapturedPhoto {
  const CapturedPhoto({required this.path, this.file});
  final String path;
  final File? file;
}

/// Captura y prepara imágenes (cámara/galería) para enviarlas a la nube.
class MediaService {
  final _picker = ImagePicker();

  Future<CapturedPhoto?> takePhoto({bool fromGallery = false}) async {
    try {
      final source = fromGallery ? ImageSource.gallery : ImageSource.camera;
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );
      if (xfile == null) return null;
      return CapturedPhoto(
        path: xfile.path,
        file: kIsWeb ? null : File(xfile.path),
      );
    } catch (e) {
      return null;
    }
  }

  Future<CapturedPhoto?> takeFromCamera() => takePhoto(fromGallery: false);
  Future<CapturedPhoto?> takeFromGallery() => takePhoto(fromGallery: true);

  /// Lee los bytes de una captura (para comprimir y subir).
  Future<Uint8List?> readBytes(CapturedPhoto photo) async {
    if (kIsWeb) return null;
    final file = photo.file;
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Comprime la imagen para dejarla por debajo de [maxBytes] (por defecto
  /// `AppConfig.maxPhotoBytes`, es decir < 300 KB).
  ///
  /// En web la compresión nativa no está disponible, por lo que devuelve los
  /// bytes originales sin modificar.
  Future<Uint8List?> compress(
    Uint8List input, {
    int maxBytes = AppConfig.maxPhotoBytes,
  }) async {
    if (kIsWeb) return input;

    var quality = 85;
    var minSide = 1280;
    Uint8List? out = await FlutterImageCompress.compressWithList(
      input,
      quality: quality,
      minWidth: minSide,
      minHeight: minSide,
      format: CompressFormat.jpeg,
    );

    while (out != null && out.lengthInBytes > maxBytes && quality > 25) {
      quality -= 15;
      if (quality <= 40) minSide = 960;
      out = await FlutterImageCompress.compressWithList(
        input,
        quality: quality,
        minWidth: minSide,
        minHeight: minSide,
        format: CompressFormat.jpeg,
      );
    }
    return out ?? input;
  }

  /// Atajo: toma la captura y devuelve sus bytes ya comprimidos.
  Future<Uint8List?> compressPhoto(CapturedPhoto photo) async {
    final bytes = await readBytes(photo);
    if (bytes == null) return null;
    return compress(bytes);
  }
}
