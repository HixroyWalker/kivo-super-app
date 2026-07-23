import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';

class ApiClient {
  final String baseUrl;
  final AuthProvider authProvider;

  ApiClient({required this.baseUrl, required this.authProvider});

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };

    // Unified API Client: Automatically inject session token if authenticated
    if (authProvider.isAuthenticated) {
      headers['Authorization'] = 'Bearer ${authProvider.sessionToken}';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    // Automatic 401 Logout enforcement
    if (response.statusCode == 401) {
      authProvider.logout();
      throw Exception('Unauthorized: Session expired');
    }

    return response;
  }
  
  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };

    if (authProvider.isAuthenticated) {
      headers['Authorization'] = 'Bearer ${authProvider.sessionToken}';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 401) {
      authProvider.logout();
      throw Exception('Unauthorized: Session expired');
    }

    return response;
  }
}
