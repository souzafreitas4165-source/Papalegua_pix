class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List).map((item) => fromJson(item)).toList(),
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      hasNext: json['has_next'] ?? false,
    );
  }

  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'current_page': currentPage,
      'total_pages': totalPages,
      'total_items': totalItems,
      'has_next': hasNext,
    };
  }
}
