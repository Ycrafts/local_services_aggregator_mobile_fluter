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
       ) {
    // Initialize immediately in constructor
    _initialize();
  }
  
  Future<void> _initialize() async {
    if (!_isInitialized) {
      try {
        await _apiClient.initializeSecureStorage();
        _isInitialized = true;
      } catch (e) {
        print('Secure storage initialization failed: $e');
        _isInitialized = true;
      }
    }
  }
  
  Future<User> login(String phone, String password) async {
    try {
      final response = await _apiClient.post(
        AppConfig.login,
        data: {
          'phone_number': phone,
          'password': password,
        },
      );
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (response.data['token'] == null) {
        throw Exception('Token not found in response');
      }

      final token = response.data['token'];
      final user = User.fromJson(response.data['user']);
      
      // Batch storage operations
      await Future.wait([
        _secureStorage.write(key: AppConfig.tokenKey, value: token),
        SharedPreferences.getInstance().then((prefs) => 
          prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()))
        ),
      ]);
      
      notifyListeners();
      return user;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }
  
  Future<void> register(Map<String, dynamic> userData) async {
    try {
      final data = Map<String, dynamic>.from(userData);
      if (data.containsKey('phone')) {
        data['phone_number'] = data.remove('phone');
      }

      if (!data.containsKey('role')) {
        data['role'] = 'customer';
      }

      final response = await _apiClient.post(
        AppConfig.register,
        data: data,
      );
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (response.data['message'] != 'Successfully Registered') {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }
  
  Future<void> logout() async {
    notifyListeners();
    
    // Start background cleanup
    Future(() async {
      try {
        // Run API call and storage cleanup in parallel
        await Future.wait([
          _apiClient.post(AppConfig.logout).catchError((e) {
            print('Logout API error: $e');
            return null;
          }),
          _secureStorage.delete(key: AppConfig.tokenKey).catchError((e) {
            print('Failed to clear secure storage: $e');
            return null;
          }),
          SharedPreferences.getInstance().then((prefs) => 
            prefs.remove(AppConfig.userKey)
          ).catchError((e) {
            print('Failed to clear shared preferences: $e');
            return null;
          }),
        ]);
      } catch (e) {
        print('Error during background cleanup: $e');
      }
    });
  }
  
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.tokenKey);
    } catch (e) {
      print('Failed to read token: $e');
      return null;
    }
  }
  
  Future<User?> getCurrentUser() async {
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
    try {
      final token = await _secureStorage.read(key: AppConfig.tokenKey);
      return token != null;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }
} 