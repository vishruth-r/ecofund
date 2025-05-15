import 'package:flutter/material.dart';
import 'package:ecofund/services/users_prefs.dart';
import 'package:ecofund/routes.dart';

import '../../../services/homeonwer_services.dart';
import '../../../services/property_services.dart';
import '../../widgets/homeowner_navbar.dart';
import 'homeowner_detailed_listing_page.dart';

class HomeownerDashboard extends StatefulWidget {
  const HomeownerDashboard({super.key});

  @override
  State<HomeownerDashboard> createState() => _HomeownerDashboardState();
}

class _HomeownerDashboardState extends State<HomeownerDashboard> {
  List<dynamic> properties = [];
  bool isLoading = true;

  double totalOutput = 0;
  double monthlySavings = 0;
  double carbonOffset = 0;

  final double gridRate = 10.0;
  final double carbonPerKwh = 0.82;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final response = await HomeownerServices.fetchProperties();
    if (response['success']) {
      final data = response['data'];
      double output = 0.0;
      double totalSavings = 0.0;

      for (var p in data) {
        final logs = p['energy_logs'] ?? [];
        for (var log in logs) {
          final energy = (log['energy_output'] ?? 0).toDouble();
          output += energy;

          final payment = log['payment'];
          if (payment != null && payment['unit_price'] != null) {
            final unitPrice = (payment['unit_price']).toDouble();
            totalSavings += energy * (gridRate - unitPrice);
          }
        }
      }

      final offset = output * carbonPerKwh;

      setState(() {
        properties = data;
        totalOutput = output;
        monthlySavings = totalSavings;
        carbonOffset = offset;
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Error loading data')),
      );
    }
  }

  void _logout(BuildContext context) async {
    await UserPrefs.clearUser();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeowner Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout),
              onPressed: () => _logout(context)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatDisplay('Total Listings', properties.length.toString()),
              const SizedBox(height: 30),
              _buildStatDisplay(
                  'Total Output', '${totalOutput.toStringAsFixed(1)} kWh'),
              const SizedBox(height: 30),
              _buildStatDisplay(
                  'Total Savings', '₹${monthlySavings.toStringAsFixed(0)}',
                  valueColor: Colors.green),
              const SizedBox(height: 30),
              _buildStatDisplay(
                  'Carbon Offset', '${carbonOffset.toStringAsFixed(1)} kg CO₂'),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              const Text('Your Properties',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...properties.map((p) => _buildPropertyCard(p)).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeownerBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatDisplay(String label, String value,
      {Color valueColor = Colors.black}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: valueColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(dynamic property) {
    const double gridRate = 10.0; // The original grid rate

    double propertyOutput = 0.0;
    double totalSavings = 0.0;

    final logs = property['energy_logs'] ?? [];
    for (var log in logs) {
      final energy = (log['energy_output'] ?? 0).toDouble();
      propertyOutput += energy;

      final payment = log['payment'];
      if (payment != null && payment['unit_price'] != null) {
        final unitPrice = (payment['unit_price']).toDouble();
        final saving = energy * (gridRate - unitPrice);
        totalSavings += saving;
      }
    }

    final logCount = logs.length > 0 ? logs.length : 1;
    final avgMonthlySavings = totalSavings / logCount;
    final avgOutput = propertyOutput / logCount;

    // Get the property status
    final status = property['status'] ?? 'pending'; // Default to 'pending'
    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);

    return InkWell(
      borderRadius: BorderRadius.circular(16), // Set the border radius here
      onTap: () async {
        final status = property['status']?.toLowerCase() ?? 'pending';

        if (status == 'pending') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status pending. Please wait for a vendor quote.')),
            );
          }
          return; // Do not navigate
        }

        final propertyId = property['property_id'];

        final detailedData = await PropertyServices.fetchPropertyDetails(propertyId);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailedListingPage(property: detailedData),
            ),
          );
        }
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Border radius for the card
        ),
        margin: const EdgeInsets.symmetric(vertical: 10),
        elevation: 4,
        // Slightly higher elevation for better shadow effect
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property status
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Property address and panel size
              Text(
                property['address'] ?? 'Unnamed Property',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              if (property['panel_size'] != null)
                Text(
                  'Panel Size: ${property['panel_size']} kW',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 6),
              if(avgOutput!=0)
              Text(
                'Avg Monthly Output: ${avgOutput.toStringAsFixed(1)} kWh',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if(avgMonthlySavings!=0)
              Text(
                'Avg Monthly Savings: ₹${avgMonthlySavings.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'funded':
        return Colors.green;
      case 'quoted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'funded':
        return Icons.battery_charging_full_sharp;
      case 'pending':
        return Icons.lock;
      case 'quoted':
        return Icons.wb_sunny;
      default:
        return Icons.info;
    }
  }
}