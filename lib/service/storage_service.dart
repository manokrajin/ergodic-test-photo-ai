import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final storage = FirebaseStorage.instance;

  /// Returns the storage folder path for the currently authenticated user.
  /// Throws a StateError if no user is signed in.
  String _userFolder() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }
    return 'users/$uid/images';
  }

  /// Upload raw bytes (e.g. generated image) to the current user's folder.
  /// [fileName] should include an extension like `.png` or `.jpg`.
  /// Returns the uploaded file's full storage path.
  Future<String> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String contentType = 'image/png',
  }) async {
    final folder = _userFolder();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = '${timestamp}_$fileName';
    final ref = storage.ref().child('$folder/$safeName');

    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, metadata);
    // Ensure upload succeeded
    if (task.state == TaskState.success) {
      return ref.fullPath;
    }
    throw FirebaseException(
      plugin: 'firebase_storage',
      message: 'Failed to upload bytes for $safeName',
    );
  }

  /// Upload a local [File] (mobile platforms) to the current user's folder.
  /// Returns the uploaded file's full storage path.
  Future<String> uploadFile(File file, {String? fileName}) async {
    final folder = _userFolder();
    final name = fileName ?? file.path.split(Platform.pathSeparator).last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = '${timestamp}_$name';
    final ref = storage.ref().child('$folder/$safeName');

    final metadata = SettableMetadata(contentType: _contentTypeFromName(name));
    final task = await ref.putFile(file, metadata);
    if (task.state == TaskState.success) {
      return ref.fullPath;
    }
    throw FirebaseException(
      plugin: 'firebase_storage',
      message: 'Failed to upload file $safeName',
    );
  }

  Future<List<Map<String, dynamic>>> uploadFiles(List<File> files) async {
    final List<Map<String, dynamic>> results = [];
    for (final file in files) {
      final path = await uploadFile(file);
      results.add({'file': file, 'path': path});
    }
    return results;
  }

  String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  /// List items in the current user's image folder.
  /// Returns a list of maps with keys: name, path, size, updated, downloadUrl (may be null initially).
  Future<List<Map<String, dynamic>>> listUserImages({
    bool includeDownloadUrl = true,
  }) async {
    final folder = _userFolder();
    final ref = storage.ref().child(folder);

    final result = await ref.listAll();
    final items = result.items;

    final List<Map<String, dynamic>> files = [];
    for (final item in items) {
      final meta = await item.getMetadata();
      String? url;
      if (includeDownloadUrl) {
        try {
          url = await item.getDownloadURL();
        } catch (_) {
          url = null;
        }
      }
      files.add({
        'name': item.name,
        'path': item.fullPath,
        'size': meta.size,
        'updated': meta.updated,
        'contentType': meta.contentType,
        'downloadUrl': url,
      });
    }
    return files;
  }

  /// Get a download URL for a file given its full storage path (or name within user folder).
  Future<String> getDownloadUrl(String pathOrName) async {
    final folder = _userFolder();
    late Reference ref;
    if (pathOrName.contains('/')) {
      // treat as full path
      ref = storage.ref().child(pathOrName);
    } else {
      ref = storage.ref().child('$folder/$pathOrName');
    }
    return await ref.getDownloadURL();
  }

  /// Delete a file by its full storage path or by name within the user's folder.
  Future<void> deleteImage(String pathOrName) async {
    final folder = _userFolder();
    Reference ref;
    if (pathOrName.contains('/')) {
      ref = storage.ref().child(pathOrName);
    } else {
      ref = storage.ref().child('$folder/$pathOrName');
    }
    await ref.delete();
  }
}
