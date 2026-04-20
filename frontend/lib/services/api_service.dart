import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int    statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<dynamic> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    final bodyStr = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: bodyStr);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: bodyStr);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: bodyStr);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw ApiException(0, 'Unknown HTTP method: $method');
    }

    if (response.statusCode == 204) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 400) {
      final msg = decoded is Map ? decoded['detail'] ?? 'Request failed' : 'Request failed';
      throw ApiException(response.statusCode, msg.toString());
    }

    return decoded;
  }

  static Future<dynamic> get(String url, {String? token, Map<String, String>? query}) =>
      _request('GET', url, token: token, queryParams: query);

  static Future<dynamic> post(String url, Map<String, dynamic> body, {String? token}) =>
      _request('POST', url, body: body, token: token);

  static Future<dynamic> put(String url, Map<String, dynamic> body, {String? token}) =>
      _request('PUT', url, body: body, token: token);

  static Future<dynamic> patch(String url, Map<String, dynamic> body, {String? token}) =>
      _request('PATCH', url, body: body, token: token);

  static Future<dynamic> delete(String url, {String? token}) =>
      _request('DELETE', url, token: token);
}
