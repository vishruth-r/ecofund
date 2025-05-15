import 'package:ecofund/views/screens/vendor_page/submit_quotation_page.dart';
import 'package:ecofund/views/screens/vendor_page/vendor_detailed_listing_page.dart';
import 'package:flutter/material.dart';
import 'package:ecofund/services/vendor_services.dart';
import 'package:ecofund/services/property_services.dart';

import '../../../routes.dart';
import '../../../services/users_prefs.dart';
import '../../widgets/vendor_navbar.dart';
import '../homeowner_page/homeowner_detailed_listing_page.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> properties = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  void fetchDashboard() async {
    final result = await VendorServices.fetchAssignedProperties();

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        properties = result['data'];
        dashboardData = {
          'active_projects': properties.where((p) => p['status'] == 'quoted').length,
          'completed_projects': properties.where((p) => p['status'] == 'funded' || p['status'] == 'installed').length,
          'pending_verifications': properties.where((p) => p['status'] == 'pending').length,
          'monthly_revenue': properties
              .where((p) => p['status'] == 'funded') // Only include funded projects
              .fold(0.0, (sum, property) {
            final quoteAmount = double.tryParse(property['quote_amount']) ?? 0.0;
            return sum + quoteAmount;
          }),
        };
      });
    }
  }

  void _logout(BuildContext context) async {
    await UserPrefs.clearUser();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
  Widget buildMetricCard(String title, String value, String subtitle) {
    return Container(
      width: double.infinity,  // Ensure the card takes up full width
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        color: Colors.white,  // Ensure card is white
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        automaticallyImplyLeading: false, // Hide the back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: dashboardData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => fetchDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMetricCard('Active Projects',
                  '${dashboardData!['active_projects']}', 'In progress'),
              buildMetricCard('Completed Projects',
                  '${dashboardData!['completed_projects']}',
                  'Successfully installed or funded'),
              buildMetricCard(
                  'Pending Verifications',
                  '${dashboardData!['pending_verifications']}',
                  'Awaiting review'),
              buildMetricCard('Monthly Revenue',
                  '₹${dashboardData!['monthly_revenue'].toStringAsFixed(0)}', 'Current month'),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),

                child: Text(
                  'Properties',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Pending Projects Section
              if(properties.isEmpty)
                const Center(
                  child: Text(
                    'No properties assigned.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              if (properties.any((property) =>
              property['status'] == 'pending'))
                _buildProjectSection('Pending Projects', properties
                    .where((property) =>
                property['status'] == 'pending')
                    .toList()),
              if (properties.any((property) =>
              property['status'] == 'quoted'))
                _buildProjectSection('Active Projects', properties
                    .where((property) =>
                property['status'] == 'quoted')
                    .toList()),
              // Completed Projects Section
              if (properties.any((property) =>
              property['status'] == 'funded'))
                _buildProjectSection('Completed Projects', properties
                    .where((property) =>
                property['status'] == 'funded')
                    .toList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VendorBottomNavBar(currentIndex: 0),

    );
  }

  Widget _buildProjectSection(String sectionTitle, List<dynamic> filteredProperties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            sectionTitle,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        ...filteredProperties.map((property) => _buildPropertyCard(property)),
      ],
    );
  }
  Widget _buildPropertyCard(dynamic property) {
    const double gridRate = 10.0;

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

    final logCount = logs.isNotEmpty ? logs.length : 1;
    final avgMonthlySavings = totalSavings / logCount;
    final avgOutput = propertyOutput / logCount;

    // Update status logic
    String status = property['status'] ?? 'pending';
    if (status == 'funded') {
      status = 'installed';
    } else if (status == 'quoted') {
      status = 'in progress';
    }

    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if ((property['status'] ?? '').toLowerCase() == 'pending') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorSubmitQuotationPage(property: property),
            ),
          );
        }
        else {

          final propertyId = property['property_id'];

          final detailedData = await PropertyServices.fetchPropertyDetails(propertyId);

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailedVendorListingPage(property: detailedData),
              ),
            );
          }
        }
      },

      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                property['address'] ?? 'Unnamed Property',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 6),
              if (property['panel_size'] != null)
                Text(
                  'Panel Size: ${property['panel_size']} kW',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 6),
              if (avgOutput != 0)
                Text(
                  'Avg Monthly Output: ${avgOutput.toStringAsFixed(1)} kWh',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              if (avgMonthlySavings != 0)
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
      case 'installed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'installed':
        return Icons.battery_charging_full_sharp;
      case 'pending':
        return Icons.lock;
      case 'in progress':
        return Icons.wb_sunny;
      default:
        return Icons.info;
    }
  }
}
