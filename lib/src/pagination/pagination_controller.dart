import 'pagination_result.dart';

/// Configurable parser for extracting paginated response metadata.
class PaginationParser {
  /// Extracts a [PaginationResult] from dynamic json response.
  static PaginationResult<T> parse<T>({
    required dynamic json,
    required T Function(dynamic) parser,
    required int currentPage,
    required int limit,
  }) {
    List<dynamic> rawItems = [];
    int? total;
    int page = currentPage;

    if (json is List) {
      rawItems = json;
    } else if (json is Map) {
      // Find items array
      for (final key in ['data', 'items', 'results', 'posts', 'records', 'content']) {
        if (json[key] is List) {
          rawItems = json[key];
          break;
        }
      }

      // Find total
      for (final key in ['total', 'total_count', 'totalItems', 'count', 'total_records']) {
        if (json[key] is num) {
          total = (json[key] as num).toInt();
          break;
        }
      }

      // Find current page
      for (final key in ['page', 'current_page', 'pageNumber', 'page_number']) {
        if (json[key] is num) {
          page = (json[key] as num).toInt();
          break;
        }
      }
    }

    final parsedItems = rawItems.map((e) => parser(e)).toList();

    bool hasNext = false;
    if (total != null) {
      hasNext = (page * limit) < total;
    } else {
      hasNext = parsedItems.length >= limit;
    }

    return PaginationResult<T>(
      items: parsedItems,
      currentPage: page,
      limit: limit,
      total: total,
      hasNextPage: hasNext,
    );
  }
}
