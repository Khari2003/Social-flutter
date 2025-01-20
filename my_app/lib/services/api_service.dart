import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://example.com/api/login'), // Thay đổi URL thành API của bạn
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    return response.statusCode == 200;
  }
}