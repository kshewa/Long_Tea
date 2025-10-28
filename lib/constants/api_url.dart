class ApiUrl {
  ApiUrl._();

  // static String baseUrl = "https://longtea-backend.onrender.com/api/v1";

  // Test backend
  static String baseUrl = "https://longtea-backend-gbzz.onrender.com/api/v1";
  // static String baseUrl = "http://localhost:7000/api/v1";

  // Product endpoints
  static String productUrl = "$baseUrl/product";

  // Auth endpoints
  static String loginUrl = "$baseUrl/auth/login";
  static String registerUrl = "$baseUrl/auth/register";
  static String refreshUrl = "$baseUrl/auth/refresh";
  static String profileUrl = "$baseUrl/auth/profile";

  // Cart endpoints
  static String cartUrl = "$baseUrl/cart";

  // Store endpoints
  static String storeUrl = "$baseUrl/store";
  static String storeProductsUrl = "$baseUrl/store-products";

  // Order endpoints
  static String orderUrl = "$baseUrl/order";

  // Payment endpoints
  static String paymentUrl = "$baseUrl/payment";
}
