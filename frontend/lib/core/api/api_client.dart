import 'dart:convert';
<<<<<<< HEAD
import 'dart:typed_data';
=======
>>>>>>> origin/main

import 'package:http/http.dart' as http;
import 'package:urbancare_frontend/core/utils/token_storage.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.tokenStorage});

  final String baseUrl;
  final TokenStorage tokenStorage;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders(authRequired: authRequired);

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeMapResponse(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool authRequired = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders(authRequired: authRequired);
    final response = await http.get(uri, headers: headers);

    return _decodeMapResponse(response);
  }

<<<<<<< HEAD
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders(authRequired: authRequired);

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeMapResponse(response);
  }

=======
>>>>>>> origin/main
  Future<List<dynamic>> getList(
    String path, {
    bool authRequired = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders(authRequired: authRequired);
    final response = await http.get(uri, headers: headers);

    if (!_isSuccess(response.statusCode)) {
      throw ApiException.fromResponse(response);
    }

    if (response.body.isEmpty) {
      return const [];
    }

    final dynamic data = jsonDecode(response.body);
    if (data is List<dynamic>) {
      return data;
    }

    throw const ApiException(
      statusCode: 500,
      message: 'Unexpected list response from server.',
    );
  }

<<<<<<< HEAD
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filename,
    required Uint8List bytes,
    bool authRequired = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders(authRequired: authRequired);

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );

    // Let multipart request set content-type with boundary.
    request.headers.remove('Content-Type');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMapResponse(response);
  }

=======
>>>>>>> origin/main
  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParams);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authRequired,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authRequired) {
      final token = await tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Authentication token not found.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeMapResponse(http.Response response) {
    if (!_isSuccess(response.statusCode)) {
      throw ApiException.fromResponse(response);
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const ApiException(
      statusCode: 500,
      message: 'Unexpected JSON object response from server.',
    );
  }

  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.raw,
  });

  final int statusCode;
  final String message;
  final String? raw;

  factory ApiException.fromResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}.';

    if (response.body.isNotEmpty) {
      try {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } catch (_) {
        message = response.body;
      }
    }

    return ApiException(
      statusCode: response.statusCode,
      message: message,
      raw: response.body,
    );
  }

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
