import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:longtea_mobile/models/product.dart';
import 'package:longtea_mobile/models/api_response.dart';
import 'package:longtea_mobile/services/http_client.dart';

class ApiService {
  static const String baseUrl = "https://longtea-backend.onrender.com/api/v1";
  static const Duration timeout = Duration(seconds: 30);

  // Fetch products with pagination and search
  static Future<ProductListResponse> fetchProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? series,
    String? sortBy,
    bool? isFastingFriendly,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (series != null && series.isNotEmpty) {
        queryParams['series'] = series;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      if (isFastingFriendly != null) {
        queryParams['isFastingFriendly'] = isFastingFriendly.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/product",
      ).replace(queryParameters: queryParams);
      final response = await authHttpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse["success"] == true) {
          return ProductListResponse.fromJson(jsonResponse);
        } else {
          throw Exception(
            jsonResponse["message"] ?? "Failed to fetch products",
          );
        }
      } else {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Network error: ${e.message}");
      } else if (e is FormatException) {
        throw Exception("Invalid response format");
      } else {
        throw Exception("Error fetching products: $e");
      }
    }
  }

  // Fetch a single product by ID
  static Future<Product> fetchProductById(String productId) async {
    try {
      final response = await authHttpClient
          .get(Uri.parse("$baseUrl/product/$productId"))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse["success"] == true) {
          return Product.fromJson(jsonResponse["data"]);
        } else {
          throw Exception(jsonResponse["message"] ?? "Failed to fetch product");
        }
      } else {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Network error: ${e.message}");
      } else if (e is FormatException) {
        throw Exception("Invalid response format");
      } else {
        throw Exception("Error fetching product: $e");
      }
    }
  }

  // Get all available series for filtering
  static Future<List<String>> fetchSeries() async {
    try {
      final response = await authHttpClient
          .get(Uri.parse("$baseUrl/product/series"))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse["success"] == true) {
          return List<String>.from(jsonResponse["data"] ?? []);
        } else {
          throw Exception(jsonResponse["message"] ?? "Failed to fetch series");
        }
      } else {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Network error: ${e.message}");
      } else if (e is FormatException) {
        throw Exception("Invalid response format");
      } else {
        throw Exception("Error fetching series: $e");
      }
    }
  }
}

// Backward compatibility function
Future<List<Product>> fetchProducts() async {
  try {
    final response = await ApiService.fetchProducts();
    return response.products;
  } catch (e) {
    throw Exception(e);
  }
}
