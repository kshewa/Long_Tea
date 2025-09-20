class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json["page"] ?? 1,
      limit: json["limit"] ?? 20,
      total: json["total"] ?? 0,
      totalPages: json["totalPages"] ?? 1,
      hasNextPage: json["hasNextPage"] ?? false,
      hasPreviousPage: json["hasPreviousPage"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "page": page,
      "limit": limit,
      "total": total,
      "totalPages": totalPages,
      "hasNextPage": hasNextPage,
      "hasPreviousPage": hasPreviousPage,
    };
  }
}
