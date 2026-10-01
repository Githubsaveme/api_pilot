/// Defines how multiple files under the same key are named in multipart requests.
enum MultipartFileStrategy {
  /// Appends '[]' to the field name (e.g. `images[]`). Most standard backends (PHP, Rails, Express).
  arraySuffix,

  /// Repeats the exact same field key (e.g. `images`, `images`).
  repeatKey,

  /// Uses zero-indexed bracket notation (e.g. `images[0]`, `images[1]`).
  indexed,
}
