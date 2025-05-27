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
    // First try the regular jobs endpoint
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/jobs/$jobId'),
        headers: await _getHeaders(),
      );

      print('Job details response status: ${response.statusCode}'); // Debug print
      print('Job details response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Raw job details response: $responseData'); // Debug print
        
        // If the response has a 'data' key, use that
        if (responseData is Map && responseData.containsKey('data')) {
          final jobData = responseData['data'];
          print('Job data with data key: $jobData'); // Debug print
          return jobData;
        }
        
        // If the response is the job data directly
        print('Job data without data key: $responseData'); // Debug print
        return responseData;
      }
    } catch (e) {
      print('Error with regular jobs endpoint: $e');
    }

    // If regular endpoint fails, try the provider-specific endpoint
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/provider/jobs/$jobId'),
        headers: await _getHeaders(),
      );

      print('Provider job details response status: ${response.statusCode}'); // Debug print
      print('Provider job details response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Raw provider job details response: $responseData'); // Debug print
        
        // If the response has a 'data' key, use that
        if (responseData is Map && responseData.containsKey('data')) {
          final jobData = responseData['data'];
          print('Provider job data with data key: $jobData'); // Debug print
          return jobData;
        }
        
        // If the response is the job data directly
        print('Provider job data without data key: $responseData'); // Debug print
        return responseData;
      }
    } catch (e) {
      print('Error with provider jobs endpoint: $e');
    }

    // If both endpoints fail, throw an error
    throw Exception('Failed to load job details: Job not found or not authorized');
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

  Future<List<dynamic>> getAvailableJobs() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/jobs/available'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body)['data'] ?? [];
    } catch (e) {
      print('Error fetching available jobs: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getProviderActiveJobs() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/jobs/provider/active'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body)['data'] ?? [];
    } catch (e) {
      print('Error fetching provider active jobs: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRequestedJobs({int page = 1}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/requested-jobs?page=$page'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load requested jobs: ${response.body}');
    }
  }

  Future<void> expressInterest(int jobId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/jobs/$jobId/express-interest'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to express interest: ${response.body}');
      }
    } catch (e) {
      print('Error expressing interest: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProviderProfile({
    required String skills,
    required int experienceYears,
    required String bio,
    required String location,
    required List<int> jobTypeIds,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/provider-profile'),
      headers: await _getHeaders(),
      body: json.encode({
        'skills': skills,
        'experience_years': experienceYears,
        'bio': bio,
        'location': location,
        'job_type_ids': jobTypeIds,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create provider profile: ${response.body}');
    }
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getProviderProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/provider-profile'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get provider profile: ${response.body}');
    }
    return json.decode(response.body);
  }

  Future<void> updateProviderProfile({
    required String skills,
    required int experienceYears,
    required String bio,
    required String location,
    required List<int> jobTypeIds,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/provider-profile'),
      headers: await _getHeaders(),
      body: json.encode({
        'skills': skills,
        'experience_years': experienceYears,
        'bio': bio,
        'location': location,
        'job_type_ids': jobTypeIds,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update provider profile: \\${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProviderSelectedJobs({int page = 1}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/selected-jobs?page=$page'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load selected jobs: \\${response.body}');
    }
  }

  Future<void> markJobAsDone(int jobId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/jobs/$jobId/provider-done'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark job as done');
      }
    } catch (e) {
      print('Error marking job as done: $e');
      rethrow;
    }
  }
} 