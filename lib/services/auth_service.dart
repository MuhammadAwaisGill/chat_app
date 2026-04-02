import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.apiUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.apiUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data['token'] != null) {
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'userId', value: data['user']['id']);
      await _storage.write(key: 'userName', value: data['user']['name']);
    }
    return data;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'userName');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }
}