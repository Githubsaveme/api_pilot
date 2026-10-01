/// Defines the encoding type for the HTTP request body.
enum BodyType {
  /// Encoded as application/json.
  json,

  /// Encoded as multipart/form-data.
  formData,

  /// Encoded as application/x-www-form-urlencoded.
  urlEncoded,

  /// Raw byte payload (application/octet-stream or custom).
  rawBytes,

  /// Plain text payload (text/plain).
  rawString,
}
