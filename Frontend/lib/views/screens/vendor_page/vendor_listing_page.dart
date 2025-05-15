import 'package:ecofund/views/screens/vendor_page/submit_quotation_page.dart';
import 'package:ecofund/views/screens/vendor_page/vendor_detailed_listing_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecofund/services/vendor_services.dart';
import '../../../services/property_services.dart';
import '../../widgets/vendor_navbar.dart';
import '../homeowner_page/homeowner_detailed_listing_page.dart';

class VendorListingPage extends StatefulWidget {
  const VendorListingPage({Key? key}) : super(key: key);

  @override
  State<VendorListingPage> createState() => _VendorListingPageState();
}

class _VendorListingPageState extends State<VendorListingPage> {
  List<dynamic> properties = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchAssignedProperties();
  }

  Future<void> fetchAssignedProperties() async {
    final result = await VendorServices.fetchAssignedProperties();
    if (result['success']) {
      setState(() {
        properties = result['data'];
        isLoading = false;
      });
    } else {
      print(result['message']);
    }
  }

  String formatDate(String isoDate) {
    return DateFormat('yyyy-MM-dd').format(DateTime.parse(isoDate));
  }

  Widget buildPropertyCard(Map<String, dynamic> property) {
    final status = property['status'] ?? 'Unknown';
    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);
    final createdAt = formatDate(property['created_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (status.toLowerCase() == 'pending') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VendorSubmitQuotationPage(property: property),
              ),
            );
          }
          else {
            final propertyId = property['property_id'];

            final detailedData = await PropertyServices.fetchPropertyDetails(
                propertyId);

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
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(createdAt, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
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
      case 'quoted':
        return Icons.wb_sunny;
      case 'pending':
        return Icons.lock;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Properties'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Assignments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : properties.isEmpty
                  ? const Center(
                child: Text(
                  'No assigned properties found.',
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
      bottomNavigationBar: VendorBottomNavBar(currentIndex: 1),
    );
  }
}
