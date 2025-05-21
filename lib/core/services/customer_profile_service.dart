import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class CustomerProfileService {
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  CustomerProfileService({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  }) : _client = client ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/customer-profile'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['profile'];
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/customer-profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData['profile'];
    } else {
      throw Exception('Failed to create profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/customer-profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['profile'];
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<void> deleteProfile() async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/customer-profile'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete profile: ${response.body}');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: AppConfig.tokenKey);
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
} 