import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../enums/multipart_strategy.dart';
import '../models/api_request.dart';
import '../models/upload_file.dart';

/// Helper utility for constructing [http.MultipartRequest] instances from [UploadFile] lists.
class MultipartBuilder {
  /// Builds an [http.MultipartRequest] from the provided [request].
  static Future<http.MultipartRequest> buildRequest(ApiRequest request) async {
    final uri = Uri.parse(request.fullUrl);
    final multipartReq = http.MultipartRequest(request.method.name, uri);

    // Add Headers
    if (request.headers != null) {
      multipartReq.headers.addAll(request.headers!);
    }

    // Add Fields
    if (request.data != null) {
      if (request.data is Map) {
        (request.data as Map).forEach((key, value) {
          if (value != null) {
            multipartReq.fields['$key'] = '$value';
          }
        });
      }
    }

    // Add Files with Naming Strategy
    final files = request.files ?? [];
    if (files.isNotEmpty) {
      final strategy = request.multipartStrategy ?? MultipartFileStrategy.arraySuffix;
      final fileKeyCounts = <String, int>{};
      for (final f in files) {
        fileKeyCounts[f.field] = (fileKeyCounts[f.field] ?? 0) + 1;
      }

      final keyIndexes = <String, int>{};

      for (final file in files) {
        final originalKey = file.field;
        final count = fileKeyCounts[originalKey] ?? 1;

        String formattedKey = originalKey;
        if (count > 1) {
          switch (strategy) {
            case MultipartFileStrategy.arraySuffix:
              if (!formattedKey.endsWith('[]')) {
                formattedKey = '$formattedKey[]';
              }
              break;
            case MultipartFileStrategy.repeatKey:
              formattedKey = originalKey;
              break;
            case MultipartFileStrategy.indexed:
              final idx = keyIndexes[originalKey] ?? 0;
              keyIndexes[originalKey] = idx + 1;
              formattedKey = '$originalKey[$idx]';
              break;
          }
        }

        final httpFile = await _createMultipartFile(formattedKey, file);
        multipartReq.files.add(httpFile);
      }
    }

    return multipartReq;
  }

  static Future<http.MultipartFile> _createMultipartFile(
    String fieldName,
    UploadFile file,
  ) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        fieldName,
        file.bytes!,
        filename: file.filename,
        contentType: file.contentType,
      );
    } else if (file.path != null && file.path!.isNotEmpty) {
      final diskFile = File(file.path!);
      if (!await diskFile.exists()) {
        throw Exception('Upload file path does not exist on disk: ${file.path}');
      }
      return await http.MultipartFile.fromPath(
        fieldName,
        file.path!,
        filename: file.filename,
        contentType: file.contentType,
      );
    } else {
      throw Exception('UploadFile must have either bytes or valid disk path.');
    }
  }

  /// Wraps an [http.MultipartRequest] into a stream that measures send progress.
  static StreamedMultipartRequest createProgressRequest(
    http.MultipartRequest request,
    ProgressCallback onSendProgress,
  ) {
    return StreamedMultipartRequest(request, onSendProgress);
  }
}

/// Extended HTTP multipart request that reports uploaded bytes in real-time.
class StreamedMultipartRequest extends http.BaseRequest {
  final http.MultipartRequest _inner;
  final ProgressCallback onSendProgress;

  StreamedMultipartRequest(this._inner, this.onSendProgress)
      : super(_inner.method, _inner.url);

  @override
  Map<String, String> get headers => _inner.headers;

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int? value) => _inner.contentLength = value ?? 0;

  @override
  http.ByteStream finalize() {
    super.finalize();
    final byteStream = _inner.finalize();
    final totalBytes = contentLength;
    var bytesSent = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (chunk, sink) {
        bytesSent += chunk.length;
        if (totalBytes > 0) {
          onSendProgress(bytesSent, totalBytes);
        }
        sink.add(chunk);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
