import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/users'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMessages(String otherUserId) async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/messages?otherUserId=$otherUserId'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getGroups() async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/groups'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createGroup(String name, List<String> members) async {
    final response = await http.post(
      Uri.parse('${Constants.apiUrl}/groups'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'members': members}),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getGroupMessages(String groupId) async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/groups/$groupId/messages'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }
}