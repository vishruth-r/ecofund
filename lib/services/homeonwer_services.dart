import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecofund/constants.dart';
import 'package:ecofund/services/users_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeownerServices {
  static Future<Map<String, dynamic>> fetchProperties() async {
    final url = Uri.parse('${AppAPI.baseUrl}/properties/my-properties');
    final token = await UserPrefs.getToken();

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to load properties'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  static Future<bool> markPaymentAsPaid(String paymentId, String txnId) async {
    final token = await UserPrefs.getToken();

    final url = Uri.parse('${AppAPI.baseUrl}/payments/confirm');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_id': paymentId,
      }),
    );

    return response.statusCode == 200;
  }

  // New function to send property details via POST request
  static Future<Map<String, dynamic>> addProperty({
    required String address,
    required String pincode,
    required String city,
    required int energyConsumption,
  }) async {
    final token = await UserPrefs.getToken();

    final url = Uri.parse('${AppAPI.baseUrl}/properties');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'address': address,
          'pincode': pincode,
          'city': city,
          'energy_consumption': energyConsumption,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to add property'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }
}
