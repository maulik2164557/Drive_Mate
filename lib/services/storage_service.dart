import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(
    String path, {
    File? file,
    Uint8List? bytes,
    String? customContentType,
  }) async {
    try {
      String? contentType = customContentType;
      if (contentType == null) {
        final lower = path.toLowerCase();
        if (lower.endsWith('.pdf')) {
          contentType = 'application/pdf';
        } else if (lower.endsWith('.png')) {
          contentType = 'image/png';
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        }
      }

      final metadata = contentType != null ? SettableMetadata(contentType: contentType) : null;
      UploadTask task;

      if (bytes != null) {
        task = _storage.ref().child(path).putData(bytes, metadata);
      } else if (file != null) {
        if (kIsWeb) {
          final fileBytes = await file.readAsBytes();
          task = _storage.ref().child(path).putData(fileBytes, metadata);
        } else {
          task = _storage.ref().child(path).putFile(file, metadata);
        }
      } else {
        throw Exception('Neither file nor bytes were provided for upload.');
      }

      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('StorageService error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('StorageService delete error: $e');
    }
  }
}
