class ApiUrl {
  ApiUrl._();

  static String baseUrl = "https://longtea-backend.onrender.com/api/v1";
  static String productUrl = "$baseUrl/product";
  static String loginUrl = "$baseUrl/auth/login";
  static String registerUrl = "$baseUrl/auth/register"; // fix
  static String refreshUrl = "$baseUrl/auth/refresh";
  static String profileUrl = "$baseUrl/auth/profile";
}