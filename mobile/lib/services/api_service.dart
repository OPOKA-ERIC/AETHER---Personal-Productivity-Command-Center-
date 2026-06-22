import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your computer's LAN IP for phone testing, or use
  // 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const _base = 'http://192.168.1.130:3000/api';

  Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  Future<List<dynamic>> get(String path) async {
    final h = await _headers();
    final res = await http.get(Uri.parse('$_base$path'), headers: h);
    if (res.statusCode >= 400) {
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSingle(String path) async {
    final h = await _headers();
    final res = await http.get(Uri.parse('$_base$path'), headers: h);
    if (res.statusCode >= 400) {
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: h,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: h,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception('PUT $path failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final h = await _headers();
    final res = await http.delete(Uri.parse('$_base$path'), headers: h);
    if (res.statusCode >= 400) {
      throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
    }
  }
}
