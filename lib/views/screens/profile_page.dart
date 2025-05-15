import 'package:ecofund/services/users_prefs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecofund/services/auth_services.dart';  // Same for vendor
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/homeowner_navbar.dart';
import '../widgets/investor_navbar.dart';
import '../widgets/vendor_navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    loadProfile();
    UserPrefs.getRole().then((role) {
      setState(() {
        userRole = role;
      });
    });
  }

  Future<void> loadProfile() async {
    final response = await AuthServices.fetchUserDetails();
    if (mounted) {
      setState(() {
        userData = response['user'];
        isLoading = false;
      });
    }
  }



  Widget _getBottomNavigationBar(String? role) {
    if (role == null) {
      return BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      );
    }

    switch (role) {
      case 'investor':
        return InvestorBottomNavBar(currentIndex: 2);  // Example index
      case 'homeowner':
        return HomeownerBottomNavBar(currentIndex: 2);  // Example index
      case 'vendor':
        return VendorBottomNavBar(currentIndex: 2);  // Example index
      default:
        return BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        );  // Default BottomNavBar if no role is found
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("Failed to load profile."))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userData!),
            const SizedBox(height: 24),
            _buildInfoTile("Email", userData!['email']),
            _buildInfoTile("Role", _capitalize(userData!['role'])),
            _buildInfoTile("UPI ID", userData!['upi_id']),
            _buildInfoTile("PAN Card", userData!['pan_card']),
            _buildInfoTile(
              "Member Since",
              DateFormat.yMMMMd().format(
                DateTime.parse(userData!['created_at']),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _getBottomNavigationBar(userRole),  // Conditional Bottom Navigation
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.green.shade100,
          child: Text(
            user['name'].substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user['email'],
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? '' : text[0].toUpperCase() + text.substring(1);
}
