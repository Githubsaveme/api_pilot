/// Contains paginated items and navigation metadata.
class PaginationResult<T> {
  /// List of items for current page.
  final List<T> items;

  /// Current page index (1-based or 0-based).
  final int currentPage;

  /// Number of items requested per page.
  final int limit;

  /// Total count of items on backend if provided.
  final int? total;

  /// Whether another page is available.
  final bool hasNextPage;

  /// Next page index if available.
  int? get nextPage => hasNextPage ? currentPage + 1 : null;

  const PaginationResult({
    required this.items,
    required this.currentPage,
    required this.limit,
    this.total,
    required this.hasNextPage,
  });

  @override
  String toString() =>
      'PaginationResult<$T>(page: $currentPage, items: ${items.length}, total: $total, hasNext: $hasNextPage)';
}
