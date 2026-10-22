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
      throw StorageException('No se pudo subir la imagen a la nube.', cause: e);
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
      throw StorageException('No se pudo generar el enlace privado de la imagen.',
          cause: e);
    }
  }

  @override
  Future<String> update({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await _client.storage.from(bucket).updateBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(contentType: contentType),
          );
      return path;
    } catch (e) {
      throw StorageException('No se pudo actualizar la imagen.', cause: e);
    }
  }

  @override
  Future<void> delete({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw StorageException('No se pudo eliminar la imagen.', cause: e);
    }
  }
}