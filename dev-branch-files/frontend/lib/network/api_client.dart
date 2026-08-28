import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:3000/api';
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    try {
      final response = await http.get(uri, headers: _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      debugPrint('ApiClient GET error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> post(String endpoint, {Object? body}) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('ApiClient POST error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> patch(String endpoint, {Object? body}) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('ApiClient PATCH error on $endpoint: $e');
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    try {
      final response = await http.delete(uri, headers: _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      debugPrint('ApiClient DELETE error on $endpoint: $e');
      rethrow;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyStr = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (bodyStr.isEmpty) return null;
      return jsonDecode(bodyStr);
    } else {
      String errorMessage = 'HTTP Error $statusCode';
      try {
        final decoded = jsonDecode(bodyStr);
        if (decoded is Map && decoded.containsKey('error')) {
          errorMessage = decoded['error'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
