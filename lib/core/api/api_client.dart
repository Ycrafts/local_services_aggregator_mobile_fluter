import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage;
  bool _isSecureStorageInitialized = false;
  
  ApiClient({FlutterSecureStorage? secureStorage}) 
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    // Enable logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Add auth token if available
          if (_isSecureStorageInitialized) {
            final token = await _secureStorage.read(key: AppConfig.tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        } catch (e) {
          print('Error reading secure storage: $e');
          return handler.next(options);
        }
      },
      onError: (DioException e, handler) {
        // Handle errors
        if (e.response?.statusCode == 401) {
          // Handle unauthorized error
          // You might want to logout the user here
        }
        return handler.next(e);
      },
    ));
  }

  // Initialize secure storage
  Future<void> initializeSecureStorage() async {
    try {
      await _secureStorage.read(key: 'test');
      _isSecureStorageInitialized = true;
    } catch (e) {
      print('Secure storage initialization failed: $e');
      _isSecureStorageInitialized = false;
    }
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Response> post(String path, {dynamic data}) async {
    try {
      print('Making POST request to: ${AppConfig.baseUrl}$path');
      print('Request data: $data');
      final response = await _dio.post(path, data: data);
      print('Response received: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('Error in POST request: ${e.message}');
      print('Error response: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    String errorMessage = 'An error occurred';
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Could not connect to the server. Please check your internet connection and try again.';
    } else if (e.response?.data != null && e.response?.data['message'] != null) {
      errorMessage = e.response?.data['message'];
    } else if (e.message != null) {
      errorMessage = e.message!;
    }
    
    throw Exception(errorMessage);
  }
} 