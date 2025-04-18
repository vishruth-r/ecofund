import 'dart:convert';
import 'package:ecofund/services/users_prefs.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class PropertyServices {
  static Future<dynamic> fetchPropertyDetails(String propertyId) async {
    final url = Uri.parse('${AppAPI.baseUrl}/properties/$propertyId/details');
    final token = await UserPrefs.getToken();

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("works");
        final data = jsonDecode(response.body);
        return data; // Directly returning the data
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to load property details'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }
}
