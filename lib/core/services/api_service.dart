import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/job_type.dart';
import '../models/user.dart';
import '../../config/app_config.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  ApiService({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  }) : _client = client ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<List<JobType>> getJobTypes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/job-types'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => JobType.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load job types: ${response.body}');
    }
  }

  Future<void> postJob({
    required int jobTypeId,
    required String description,
    required double proposedPrice,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/jobs'),
      headers: await _getHeaders(),
      body: json.encode({
        'job_type_id': jobTypeId,
        'description': description,
        'proposed_price': proposedPrice,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post job: ${response.body}');
    }
  }

  Future<List<dynamic>> getActiveJobs() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/jobs'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data;
    } else {
      throw Exception('Failed to load active jobs: ${response.body}');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/notifications/$id/mark-as-read'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.body}');
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