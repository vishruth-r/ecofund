import 'dart:convert';
import 'package:ecofund/services/users_prefs.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class VendorServices {
  static Future<Map<String, dynamic>> fetchAssignedProperties() async {
    print("trying");
    final url = Uri.parse('${AppAPI.baseUrl}/properties/vendor/assigned');
    final token = await UserPrefs.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to load assigned properties'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }
  static Future<Map<String, dynamic>> submitQuotation({
    required String propertyId,
    required String panelSize,
    required int quoteAmount,
  }) async {
    final url = Uri.parse('${AppAPI.baseUrl}/properties/$propertyId/quote');
    final token = await UserPrefs.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'panel_size': panelSize,
          'quote_amount': quoteAmount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to submit quotation'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> submitEnergyLog({
    required String propertyId,
    required String month,
    required int unitsProduced,

  }) async {
    final url = Uri.parse('${AppAPI.baseUrl}/properties/log-energy');
    final token = await UserPrefs.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'property_id': propertyId,
          'month': month,
          'units_produced': unitsProduced,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to submit energy log'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }


}