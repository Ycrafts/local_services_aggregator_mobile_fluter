class AppConfig {
  // Replace 192.168.1.100 with your actual local IP address
  static const String baseUrl = 'http://192.168.100.41:8000/api';
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String jobs = '/jobs';
  static const String providerProfile = '/provider-profile';
  static const String notifications = '/notifications';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // App Settings
  static const String appName = 'Local Services';
  static const int apiTimeout = 30000; // 30 seconds
} 