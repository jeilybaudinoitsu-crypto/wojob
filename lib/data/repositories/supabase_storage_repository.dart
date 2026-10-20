import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:wojob/core/errors/app_exception.dart';
import 'package:wojob/domain/repositories/repositories.dart';

/// Subida de archivos a Supabase Storage (buckets `asistencias` y `documentos`).
class SupabaseStorageRepository implements StorageRepository {
  SupabaseStorageRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(contentType: contentType),
          );
      return path;
    } catch (e) {
      throw AppException('No se pudo subir la imagen a la nube.', cause: e);
    }
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      return await _client.storage.from(bucket).createSignedUrl(path, 3600);
    } catch (e) {
      throw AppException('No se pudo generar el enlace privado de la imagen.',
          cause: e);
    }
  }
}
