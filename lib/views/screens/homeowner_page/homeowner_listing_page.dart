import 'package:flutter/material.dart';
import 'package:ecofund/routes.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/homeonwer_services.dart';
import '../../../services/property_services.dart';
import '../../widgets/homeowner_navbar.dart';
import 'homeowner_detailed_listing_page.dart';
import 'add_listing_page.dart'; // Import your AddListingPage

class HomeownerListingPage extends StatefulWidget {
  const HomeownerListingPage({Key? key}) : super(key: key);

  @override
  State<HomeownerListingPage> createState() => _HomeownerListingPageState();
}

class _HomeownerListingPageState extends State<HomeownerListingPage> {
  List<dynamic> properties = [];
  bool isLoading = true;
  int _currentIndex = 1; // This will track the current selected tab

  @override
  void initState() {
    super.initState();
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    final result = await HomeownerServices.fetchProperties();
    if (result['success']) {
      setState(() {
        properties = result['data'];
        isLoading = false;
      });
    } else {
      print('Failed to fetch properties');
    }
  }

  String formatDate(String isoDate) {
    return DateFormat('yyyy-MM-dd').format(DateTime.parse(isoDate));
  }

  double calculateAverageProduction(List<dynamic> energyLogs) {
    if (energyLogs.isEmpty) return 0;
    double total = 0;
    for (var log in energyLogs) {
      total += log['energy_output'] ?? 0;
    }
    return total / energyLogs.length;
  }

  Widget buildPropertyCard(Map<String, dynamic> property) {
    final logs = property['energy_logs'] as List<dynamic>;
    final avgProduction = calculateAverageProduction(logs);
    final lastUpdated = logs.isNotEmpty
        ? formatDate(logs.first['created_at'])
        : formatDate(property['created_at']);
    final status = property['status'] ?? 'Unknown';
    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);
    final isPending = status.toLowerCase() == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isPending
            ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status is Pending')),
          );
        }
            : () async {
          final propertyId = property['property_id']; // or property['_id'] based on your backend
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property['address'] ?? 'No Address',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property['city'] ?? 'Unknown',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 12, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flash_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${avgProduction.toStringAsFixed(0)} kWh/month',
                              style: const TextStyle(fontSize: 13)),
                          if (lastUpdated.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(lastUpdated, style: const TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPending) const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
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

  Widget buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoFund'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Properties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: isLoading
                  ? ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: ListTile(title: Text('Loading...')),
                  ),
                ),
              )
                  : properties.isEmpty
                  ? const Center(
                child: Text(
                  'No properties found.',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) =>
                    buildPropertyCard(properties[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddListingPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Property',
      ),
      bottomNavigationBar: HomeownerBottomNavBar(currentIndex: _currentIndex),
    );
  }
}
