import 'dart:io';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// Represents a file payload for multipart uploads.
///
/// Supports files from local disk paths, byte arrays ([Uint8List]), or streams.
class UploadFile {
  /// The form field key name (e.g. "profile_image" or "documents").
  final String field;

  /// The filename sent to the server (e.g. "avatar.jpg").
  final String filename;

  /// The local file path if loaded from disk.
  final String? path;

  /// File raw bytes if loaded in memory (ideal for Web or memory buffers).
  final Uint8List? bytes;

  /// Custom content type/media type for the file header.
  final MediaType? contentType;

  const UploadFile({
    required this.field,
    required this.filename,
    this.path,
    this.bytes,
    this.contentType,
  });

  /// Creates an [UploadFile] from a local file path.
  factory UploadFile.fromPath({
    required String field,
    required String filePath,
    String? filename,
    MediaType? contentType,
  }) {
    final name = filename ?? p.basename(filePath);
    return UploadFile(
      field: field,
      filename: name,
      path: filePath,
      contentType: contentType ?? _guessMediaType(name),
    );
  }

  /// Creates an [UploadFile] from a [File] object.
  factory UploadFile.fromFile({
    required String field,
    required File file,
    String? filename,
    MediaType? contentType,
  }) {
    final filePath = file.path;
    final name = filename ?? p.basename(filePath);
    return UploadFile(
      field: field,
      filename: name,
      path: filePath,
      contentType: contentType ?? _guessMediaType(name),
    );
  }

  /// Creates an [UploadFile] directly from in-memory byte data.
  factory UploadFile.fromBytes({
    required String field,
    required String filename,
    required Uint8List bytes,
    MediaType? contentType,
  }) {
    return UploadFile(
      field: field,
      filename: filename,
      bytes: bytes,
      contentType: contentType ?? _guessMediaType(filename),
    );
  }

  /// Copies this upload file with a modified field key.
  UploadFile copyWithField(String newField) {
    return UploadFile(
      field: newField,
      filename: filename,
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  static MediaType? _guessMediaType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      case '.pdf':
        return MediaType('application', 'pdf');
      case '.json':
        return MediaType('application', 'json');
      case '.txt':
        return MediaType('text', 'plain');
      case '.mp4':
        return MediaType('video', 'mp4');
      case '.mp3':
        return MediaType('audio', 'mpeg');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
