import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class CapturedPhoto {
  const CapturedPhoto({required this.path, this.file});
  final String path;
  final File? file;
}

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
}
