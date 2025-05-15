import 'dart:convert';
import 'package:ecofund/services/users_prefs.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class InvestorServices {
  static Future<Map<String, dynamic>> getMyInvestments() async {
    print("trying to get my investments");
    final url = Uri.parse('${AppAPI.baseUrl}/investments/mine');
    final token = await UserPrefs.getToken(); // Get the token from shared preferences

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Bearer token for authentication
        },
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data, // Access the 'data' key to get the list of investments
        };
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch investments',
        };
      }
    } catch (e) {
      print('Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching investments. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> getPayoutsDetails() async {
    print("trying to get payouts details");
    final url = Uri.parse('${AppAPI.baseUrl}/payments/investor/payouts');
    final token = await UserPrefs.getToken(); // Get the token from shared preferences

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Bearer token for authentication
        },
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data, // Access the 'data' key to get payout details
        };
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch payouts details',
        };
      }
    } catch (e) {
      print('Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching payouts details. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> getAllProperties() async {
    print("Trying to get all properties");
    final url = Uri.parse('${AppAPI.baseUrl}/investments'); // Adjust the endpoint if necessary
    final token = await UserPrefs.getToken(); // Get the token from shared preferences

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Bearer token for authentication
        },
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data, // Access the 'data' key to get the list of properties
        };
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch properties',
        };
      }
    } catch (e) {
      print('Exception: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching properties. Please try again.',
      };
    }
  }
  static Future<bool> makeInvestment(String propertyId, int unitsPurchased) async {
    final url = Uri.parse('${AppAPI.baseUrl}/investments');
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
          'units_purchased': unitsPurchased,
        }),
      );

      if (response.statusCode == 201) {
        print('Investment successful: ${response.body}');
        return true;
      } else {
        print('Investment failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Investment exception: $e');
      return false;
    }
  }


}
