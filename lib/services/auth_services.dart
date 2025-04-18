import 'dart:convert';
import 'package:ecofund/services/users_prefs.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AuthServices {
  // Perform login with email and password
  static Future<Map<String, dynamic>> login(String email,
      String password) async {
    final url = Uri.parse('${AppAPI.baseUrl}/users/login');
    print('[LOGIN] URL: $url');
    print(' [LOGIN] Payload: {email: $email, password: $password}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('[LOGIN] Status Code: ${response.statusCode}');
      print('[LOGIN] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];

        print('[LOGIN] Login successful. Token: $token');
        print('[LOGIN] User: $user');

        await UserPrefs.saveUser({
          'token': token,
          'email': user['email'],
          'name': user['name'],
          'role': user['role'],
        });

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        print(' [LOGIN] Login failed: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print(' [LOGIN] Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }


  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String upiId,
    required String panCard,
    String? serviceableCities, // Optional parameter for vendors
  }) async {
    final url = Uri.parse('${AppAPI.baseUrl}/users/register');
    print('[SIGNUP] URL: $url');
    print(
        '[SIGNUP] Payload: {name: $name, email: $email, password: $password, role: $role, upi_id: $upiId, pan_card: $panCard, serviceable_cities: $serviceableCities}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'upi_id': upiId,
          'pan_card': panCard,
          'serviceable_cities': serviceableCities != null
              ? serviceableCities.split(',').map((city) =>
              city.trim()).toList()
              : null,
        }),
      );

      print('[SIGNUP] Status Code: ${response.statusCode}');
      print('[SIGNUP] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];

        print('[SIGNUP] Signup successful. Token: $token');
        print('[SIGNUP] User: $user');

        await UserPrefs.saveUser({
          'token': token,
          'email': user['email'],
          'name': user['name'],
          'role': user['role'],
        });

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        print('[SIGNUP] Signup failed: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Signup failed'
        };
      }
    } catch (e) {
      print('[SIGNUP] Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }
}
