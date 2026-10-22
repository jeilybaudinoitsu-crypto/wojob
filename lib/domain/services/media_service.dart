import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:wojob/core/config/app_config.dart';

class CapturedPhoto {
  const CapturedPhoto({required this.path, required this.source});
  final String path;
  final XFile source;
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
      return CapturedPhoto(path: xfile.path, source: xfile);
    } catch (e) {
      return null;
    }
  }

  Future<CapturedPhoto?> takeFromCamera() => takePhoto(fromGallery: false);
  Future<CapturedPhoto?> takeFromGallery() => takePhoto(fromGallery: true);

  /// Lee los bytes de una captura (para comprimir y subir).
  Future<Uint8List?> readBytes(CapturedPhoto photo) async {
    try {
      return await photo.source.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Comprime la imagen para dejarla por debajo de [maxBytes] (por defecto
  /// `AppConfig.maxPhotoBytes`, es decir < 300 KB).
  Future<Uint8List?> compress(
    Uint8List input, {
    int maxBytes = AppConfig.maxPhotoBytes,
  }) async {
    if (kIsWeb) {
      return _compressWeb(input, maxBytes: maxBytes);
    }

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

  Future<Uint8List> _compressWeb(Uint8List input, {required int maxBytes}) async {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    var quality = 85;
    var resized = decoded;
    List<int>? compressed;

    while (quality > 25) {
      if (resized.width > 1280 || resized.height > 1280) {
        resized = img.copyResize(resized, width: 1280, height: 1280);
      }
      compressed = img.encodeJpg(resized, quality: quality);
      if (compressed.length <= maxBytes) {
        return Uint8List.fromList(compressed);
      }
      quality -= 15;
      if (quality <= 40 && (resized.width > 960 || resized.height > 960)) {
        resized = img.copyResize(resized, width: 960, height: 960);
      }
    }
    return Uint8List.fromList(compressed ?? img.encodeJpg(resized, quality: 25));
  }

  /// Atajo: toma la captura y devuelve sus bytes ya comprimidos.
  Future<Uint8List?> compressPhoto(CapturedPhoto photo) async {
    final bytes = await readBytes(photo);
    if (bytes == null) return null;
    return compress(bytes);
  }
}