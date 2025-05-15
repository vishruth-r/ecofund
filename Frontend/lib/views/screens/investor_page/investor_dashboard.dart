import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/investor_services.dart';
import '../../../services/property_services.dart';
import '../../widgets/investor_navbar.dart';
import '../login_page.dart';
import 'investor_detailed_listing_page.dart';

class InvestorDashboardPage extends StatefulWidget {
  const InvestorDashboardPage({Key? key}) : super(key: key);

  @override
  State<InvestorDashboardPage> createState() => _InvestorDashboardPageState();
}

class _InvestorDashboardPageState extends State<InvestorDashboardPage> {
  List<dynamic> properties = [];
  bool isLoading = true;

  double totalInvested = 0;
  double totalReturns = 0;
  int totalProperties = 0;
  double annualYield = 0;

  int _currentIndex = 0; // Track the current index for bottom nav

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final response = await InvestorServices.getMyInvestments(); // returns list of properties

    if (response['success']) {
      final List<dynamic> data = response['data'];
      double invested = 0;
      double returns = 0;

      for (var prop in data) {
        invested += double.tryParse(prop['total_amount_invested'].toString()) ?? 0;
        returns += double.tryParse(prop['total_paid_out'].toString()) ?? 0;
      }

      double _yield = 0;
      if (invested > 0) {
        _yield = (returns / invested) * 12; // crude annualized yield
      }

      setState(() {
        properties = data;
        totalProperties = data.length;
        totalInvested = invested;
        totalReturns = returns;
        annualYield = _yield;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to load data')),
      );
    }
  }

  Widget buildSummaryCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      color: color ?? Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.green[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPropertyCard(dynamic prop) {
    final investedAmount = double.tryParse(prop['total_amount_invested'] ?? '0') ?? 0.0;
    final paidOutAmount = double.tryParse(prop['total_paid_out'] ?? '0') ?? 0.0;
    final returnPercentage = investedAmount > 0 ? (paidOutAmount / investedAmount) * 100 : 0.0;

    final propertyStatus = prop['status'] ?? 'pending';
    final statusColor = getStatusColor(propertyStatus);
    final statusIcon = getStatusIcon(propertyStatus);

    return GestureDetector(
      onTap: () async {
        final propertyId = prop['property_id'];
        final detailedData = await PropertyServices.fetchPropertyDetails(propertyId);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvestorDetailedListingPage(property: detailedData),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prop['address'] ?? 'No address',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Investment and Returns Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabelValue("Invested", "₹${investedAmount.toStringAsFixed(0)}"),
                  _buildLabelValue("Returns", "₹${paidOutAmount.toStringAsFixed(0)}"),
                  _buildLabelValue(
                    "ROI",
                    "${returnPercentage.toStringAsFixed(1)}%",
                    valueColor: returnPercentage >= 100 ? Colors.green : Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(thickness: 1.2),

              // Location and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.location_pin, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(prop['city'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ]),
                  Text(
                    "Invested on ${formatDate(prop['first_investment_at'])}",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  String formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat.yMMM().format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Dashboard'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
          ? const Center(child: Text('No investments found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Summary
            const Text(
              "Investment Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            buildSummaryCard("Total Properties", "$totalProperties", Icons.home),
            buildSummaryCard("Invested", "₹${totalInvested.toStringAsFixed(0)}", Icons.attach_money),
            buildSummaryCard("Returns", "₹${totalReturns.toStringAsFixed(0)}", Icons.arrow_upward),
            buildSummaryCard("Annual Yield", "${annualYield.toStringAsFixed(2)}x", Icons.trending_up),

            const SizedBox(height: 24),
            const Text(
              "Invested Properties",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            ...properties.map((prop) => buildPropertyCard(prop)).toList(),
          ],
        ),
      ),
      bottomNavigationBar: InvestorBottomNavBar(currentIndex: 0), // Add the bottom nav bar here
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
