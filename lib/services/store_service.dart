import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:longtea_mobile/models/store.dart';
import 'package:longtea_mobile/services/http_client.dart';
import 'package:longtea_mobile/constants/api_url.dart';

class StoreService {
  StoreService._();
  static final StoreService instance = StoreService._();

  static const Duration timeout = Duration(seconds: 30);

  /// Get all stores
  Future<List<Store>> getAllStores() async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/store");
      final response = await authHttpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final stores = (jsonResponse['data'] as List)
              .map((store) => Store.fromJson(store))
              .toList();
          return stores;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch stores');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Get store by ID
  Future<Store> getStoreById(String storeId) async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/store/$storeId");
      final response = await authHttpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return Store.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch store');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Get stores where a product is available
  Future<List<Store>> getStoresForProduct(String productId) async {
    try {
      final uri = Uri.parse(
        "${ApiUrl.baseUrl}/store-products/$productId/available-stores",
      );
      final response = await authHttpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          final storesList = data['stores'] as List? ?? [];
          return storesList.map((store) => Store.fromJson(store)).toList();
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to fetch available stores',
          );
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }
}
