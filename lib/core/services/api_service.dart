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
      Uri.parse('$baseUrl/jobs?limit=5'),
      headers: await _getHeaders(),
    );

    print('Raw response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Decoded response: $responseData'); // Debug log
      
      if (responseData is Map && responseData.containsKey('data')) {
        final data = responseData['data'];
        print('Data from response: $data'); // Debug log
        return data;
      }
      return responseData;
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

  Future<void> updateJobStatus(int jobId, String status) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/jobs/$jobId'),
      headers: await _getHeaders(),
      body: json.encode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update job status: ${response.body}');
    }
  }

  Future<void> completeJob(int jobId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/jobs/$jobId/complete'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete job: ${response.body}');
    }
  }

  Future<void> cancelJob(int jobId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/jobs/$jobId/cancel'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel job: ${response.body}');
    }
  }

  Future<List<dynamic>> getJobProviderRequests(int jobId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/jobs/$jobId/interested-providers'),
        headers: await _getHeaders(),
      );

      print('Raw response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Decoded response: $responseData'); // Debug log

        // Check if responseData is a List
        if (responseData is List) {
          return responseData;
        }
        // Check if responseData is a Map with 'data' key
        else if (responseData is Map && responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            return data;
          }
        }
        // If we get here, return empty list
        return [];
      } else {
        throw Exception('Failed to load provider requests: ${response.body}');
      }
    } catch (e) {
      print('Error in getJobProviderRequests: $e'); // Debug log
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJobDetails(int jobId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/jobs/$jobId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['data'] != null) {
        return responseData['data'];
      }
      return responseData;
    } else {
      throw Exception('Failed to load job details: ${response.body}');
    }
  }

  Future<void> acceptProvider(int jobId, int providerId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/jobs/$jobId/select-provider'),
      headers: await _getHeaders(),
      body: json.encode({
        'provider_profile_id': providerId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept provider: ${response.body}');
    }
  }

  Future<void> declineProvider(int jobId, int providerId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/jobs/$jobId/decline-provider'),
      headers: await _getHeaders(),
      body: json.encode({
        'provider_profile_id': providerId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to decline provider: ${response.body}');
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