import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/session_manager.dart';

/// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  Timer? _tokenRefreshTimer;

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _initializeAuth();
  }

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    try {
      final userJson = await SessionManager.getUserJson();
      final accessToken = await SessionManager.getAccessToken();

      if (userJson != null && accessToken != null) {
        // Check if tokens are still valid
        final isAccessExpired = await SessionManager.isAccessTokenExpired();
        final isRefreshExpired = await SessionManager.isRefreshTokenExpired();

        if (isRefreshExpired) {
          // Refresh token expired, user needs to log in again
          state = const AuthState(isAuthenticated: false);
        } else if (isAccessExpired) {
          // Try to refresh the access token
          final refreshResult = await _authService.refreshAccessToken();
          if (refreshResult['success'] == true) {
            final user = User.fromJsonString(userJson);
            state = AuthState(user: user, isAuthenticated: true);
            _scheduleTokenRefresh();
          } else {
            await _clearAuthState();
          }
        } else {
          // Tokens are valid
          final user = User.fromJsonString(userJson);
          state = AuthState(user: user, isAuthenticated: true);
          _scheduleTokenRefresh();
        }
      } else {
        state = const AuthState(isAuthenticated: false);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      state = const AuthState(isAuthenticated: false);
    }
  }

  /// Login user with email/phone and password
  Future<bool> login(String emailOrPhone, String password) async {
    debugPrint('=== AUTH NOTIFIER LOGIN DEBUG ===');
    debugPrint('EmailOrPhone: $emailOrPhone');
    debugPrint(
      'Password: ${password.replaceRange(2, null, '*' * (password.length - 2))}',
    ); // Mask password
    debugPrint('================================');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authService.login(emailOrPhone, password);

      debugPrint('=== AUTH NOTIFIER RESULT DEBUG ===');
      debugPrint('Result: $result');
      debugPrint('Success: ${result['success']}');
      debugPrint('Message: ${result['message']}');
      debugPrint('Data: ${result['data']}');
      debugPrint('=================================');

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && data['user'] != null) {
          final user = User.fromJson(data['user']);
          debugPrint('=== AUTH NOTIFIER SUCCESS ===');
          debugPrint('User created: ${user.toJson()}');
          debugPrint('=============================');

          state = AuthState(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          _scheduleTokenRefresh();
          return true;
        }
      }

      debugPrint('=== AUTH NOTIFIER FAILURE ===');
      debugPrint('Login failed: ${result['message']}');
      debugPrint('Details: ${result['details']}');
      debugPrint('==============================');

      // Show main message with detail if available
      String errorMessage = result['message'] ?? 'Login failed';
      if (result['details'] != null &&
          result['details'] is List &&
          (result['details'] as List).isNotEmpty) {
        final detail = (result['details'] as List).first.toString();
        errorMessage = '$errorMessage: $detail';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    } catch (e) {
      debugPrint('=== AUTH NOTIFIER EXCEPTION ===');
      debugPrint('Exception: $e');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('===============================');

      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String fullName,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Validate that at least email or phone is provided
      if ((email == null || email.isEmpty) &&
          (phoneNumber == null || phoneNumber.isEmpty)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Email or phone number is required',
        );
        return false;
      }

      final response = await _authService.register(
        fullName: fullName,
        password: password,
        email: email,
        phoneNumber: phoneNumber,
      );

      if (response['success'] == true) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return true;
      }

      // Show main message with detail if available
      String errorMessage = response['message'] ?? 'Registration failed';
      if (response['details'] != null &&
          response['details'] is List &&
          (response['details'] as List).isNotEmpty) {
        final detail = (response['details'] as List).first.toString();
        errorMessage = '$errorMessage: $detail';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _cancelTokenRefreshTimer();
    await _authService.logout();
    await _clearAuthState();
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      final result = await _authService.refreshAccessToken();

      if (result['success'] == true) {
        debugPrint('Token refreshed successfully');
        return true;
      } else {
        debugPrint('Token refresh failed: ${result['message']}');
        // If refresh fails, logout user
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  /// Schedule automatic token refresh before expiry
  void _scheduleTokenRefresh() async {
    _cancelTokenRefreshTimer();

    try {
      final expiresAt = await SessionManager.getAccessTokenExpiresAt();

      if (expiresAt != null) {
        final now = DateTime.now();
        final difference = expiresAt.difference(now);

        // Refresh 2 minutes before expiry, or immediately if already expired
        final refreshIn = difference.inSeconds - 120;

        if (refreshIn > 0) {
          debugPrint('Scheduling token refresh in $refreshIn seconds');
          _tokenRefreshTimer = Timer(Duration(seconds: refreshIn), () async {
            debugPrint('Auto-refreshing token...');
            await refreshToken();
          });
        } else {
          // Token is expired or will expire soon, refresh immediately
          debugPrint('Token expired or expiring soon, refreshing now...');
          await refreshToken();
        }
      }
    } catch (e) {
      debugPrint('Error scheduling token refresh: $e');
    }
  }

  /// Cancel token refresh timer
  void _cancelTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Clear authentication state
  Future<void> _clearAuthState() async {
    await SessionManager.clear();
    state = const AuthState(isAuthenticated: false);
  }

  /// Update user data locally (without backend sync)
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Update user profile with backend sync
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _profileService.updateProfile(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      );

      if (result['success'] == true && result['data'] is User) {
        final updatedUser = result['data'] as User;

        // Update state with new user data
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          errorMessage: null,
        );

        // Persist updated user to session
        await SessionManager.saveUserJson(jsonEncode(updatedUser.toJson()));

        debugPrint('Profile updated successfully: ${updatedUser.toJson()}');

        return {
          "success": true,
          "message": result['message'] ?? "Profile updated successfully",
          "user": updatedUser,
        };
      } else {
        // Show main message with detail if available
        String errorMessage = result['message'] ?? 'Failed to update profile';
        if (result['details'] != null &&
            result['details'] is List &&
            (result['details'] as List).isNotEmpty) {
          final details = (result['details'] as List).join(', ');
          errorMessage = '$errorMessage: $details';
        }

        state = state.copyWith(isLoading: false, errorMessage: errorMessage);

        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      return {"success": false, "message": e.toString()};
    }
  }

  /// Fetch user profile from backend
  Future<void> fetchProfile() async {
    try {
      final result = await _profileService.getProfile();

      if (result['success'] == true && result['data'] is User) {
        final user = result['data'] as User;

        // Update state with fetched user data
        state = state.copyWith(user: user);

        // Persist updated user to session
        await SessionManager.saveUserJson(jsonEncode(user.toJson()));

        debugPrint('Profile fetched successfully: ${user.toJson()}');
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  @override
  void dispose() {
    _cancelTokenRefreshTimer();
    super.dispose();
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience providers for common auth checks
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
