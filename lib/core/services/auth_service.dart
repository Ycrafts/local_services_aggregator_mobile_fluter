import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  bool _isInitialized = false;
  
  AuthService({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _apiClient = apiClient ?? ApiClient(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(
         aOptions: AndroidOptions(
           encryptedSharedPreferences: true,
         ),
       );
  
  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await _apiClient.initializeSecureStorage();
        _isInitialized = true;
      } catch (e) {
        print('Secure storage initialization failed: $e');
        // Continue without secure storage
        _isInitialized = true;
      }
    }
  }
  
  Future<User> login(String phone, String password) async {
    await initialize();
    
    try {
      final response = await _apiClient.post(
        AppConfig.login,
        data: {
          'phone_number': phone,
          'password': password,
        },
      );
      
      print('Login response: ${response.data}');
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (response.data['token'] == null) {
        throw Exception('Token not found in response');
      }

      final token = response.data['token'];
      
      // Store token securely
      try {
        await _secureStorage.write(key: AppConfig.tokenKey, value: token);
      } catch (e) {
        print('Failed to store token securely: $e');
        // Continue without secure storage
      }

      // Get user data from response
      if (response.data['user'] == null) {
        throw Exception('User data not found in response');
      }

      final user = User.fromJson(response.data['user']);
      
      // Store user data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
      } catch (e) {
        print('Failed to store user data: $e');
        // Continue without shared preferences
      }
      
      notifyListeners();
      return user;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }
  
  Future<void> register(Map<String, dynamic> userData) async {
    await initialize();
    
    try {
      // Convert phone to phone_number in the userData
      final data = Map<String, dynamic>.from(userData);
      if (data.containsKey('phone')) {
        data['phone_number'] = data.remove('phone');
      }

      // Add role field if not present
      if (!data.containsKey('role')) {
        data['role'] = 'customer'; // Default role
      }

      print('Registration data: $data'); // Debug log

      final response = await _apiClient.post(
        AppConfig.register,
        data: data,
      );
      
      print('Registration response: ${response.data}'); // Debug log
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      // Check for success message
      if (response.data['message'] != 'Successfully Registered') {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }

      // Registration successful, no need to handle token or user data
      // User will need to login separately to get the token
      
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }
  
  Future<void> logout() async {
    await initialize();
    
    try {
      // Call logout API endpoint
      await _apiClient.post(AppConfig.logout);
    } catch (e) {
      print('Logout API error: $e');
      // Continue with local logout even if API call fails
    } finally {
      // Clear local storage regardless of API response
      try {
        // Clear token
        await _secureStorage.delete(key: AppConfig.tokenKey);
      } catch (e) {
        print('Failed to clear secure storage: $e');
      }
      
      try {
        // Clear user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConfig.userKey);
      } catch (e) {
        print('Failed to clear shared preferences: $e');
      }
      
      notifyListeners();
    }
  }
  
  Future<String?> getToken() async {
    await initialize();
    try {
      return await _secureStorage.read(key: AppConfig.tokenKey);
    } catch (e) {
      print('Failed to read token: $e');
      return null;
    }
  }
  
  Future<User?> getCurrentUser() async {
    await initialize();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Failed to get current user: $e');
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    await initialize();
    
    try {
      final token = await _secureStorage.read(key: AppConfig.tokenKey);
      return token != null;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }
} 