import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/investor_services.dart';
import '../../../services/property_services.dart';
import '../homeowner_page/homeowner_detailed_listing_page.dart';
import 'investor_detailed_listing_page.dart';

class InvestmentsPage extends StatefulWidget {
  @override
  _InvestmentsPageState createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> allInvestments = [];
  List<Map<String, dynamic>> myInvestments = [];
  List<Map<String, dynamic>> filteredAll = [];
  List<Map<String, dynamic>> filteredMy = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredAll = allInvestments.where((i) =>
          i['address'].toLowerCase().contains(query)).toList();
      filteredMy = myInvestments.where((i) =>
          i['address'].toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final allResponse = await InvestorServices.getAllProperties();
      final myResponse = await InvestorServices.getMyInvestments();

      if (allResponse['success']) {
        allInvestments = List<Map<String, dynamic>>.from(allResponse['data']);
        filteredAll = List.from(allInvestments);
      } else {
        allInvestments = [];
        filteredAll = [];
      }

      if (myResponse['success']) {
        myInvestments = List<Map<String, dynamic>>.from(myResponse['data']);
        filteredMy = List.from(myInvestments);
      } else {
        myInvestments = [];
        filteredMy = [];
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching data: $e");
    }
  }

  String formatDate(String iso) {
    return DateFormat("dd MMM yyyy").format(DateTime.parse(iso));
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

  Widget _buildLabelValue(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.black87,
        )),
      ],
    );
  }

  Widget buildMyInvestmentCard(Map<String, dynamic> data) {
    final unitsPurchased = double.tryParse('${data['total_units_purchased'] ?? '0'}') ?? 0.0;
    final totalInvested = double.tryParse('${data['total_amount_invested'] ?? '0'}') ?? 0.0;
    final totalReturned = double.tryParse('${data['total_paid_out'] ?? '0'}') ?? 0.0;

    double annualizedYield = 0;
    if (totalInvested > 0) {
      annualizedYield = (totalReturned / totalInvested) * 12;
    }

    final status = data['property_status'] ?? 'active';
    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);

    return GestureDetector(
      onTap: () async {
        final propertyId = data['property_id'];
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(data['address'] ?? 'No address',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabelValue("Units", unitsPurchased.toStringAsFixed(0)),
                  _buildLabelValue("Invested", "₹${totalInvested.toStringAsFixed(0)}"),
                  _buildLabelValue("Returned", "₹${totalReturned.toStringAsFixed(0)}", valueColor: Colors.teal),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    "Est. Annual Yield: ${annualizedYield.toStringAsFixed(1)}x",
                    style: const TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 1.2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Pincode: ${data['pincode'] ?? '-'}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    "Invested on ${formatDate(data['first_investment_at'])}",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget buildAllInvestmentCard(Map<String, dynamic> data) {
    // Only display the card if the status is 'quoted'
    if (data['status'] != 'quoted') {
      return SizedBox.shrink(); // Return an empty widget if not quoted
    }

    // Calculate the funding progress as a percentage
    double fundedPercentage = data['funded_units'] / 1000;
    int percentage = (fundedPercentage * 100).toInt(); // Convert to percentage

    // Calculate the price per unit
    double pricePerUnit = data['quote_amount'] / 1000;

    return GestureDetector(
      onTap: () async {
        final propertyId = data['property_id'];
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.1), // Soft shadow for depth
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for address and price per unit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Address
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['address'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['city']}, ${data['pincode'] ?? ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  // Price per unit
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${pricePerUnit.toStringAsFixed(2)}/unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrangeAccent, // Prominent color for price
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 20, color: Colors.grey[300]),

              // Panel and quote amount in a more modern row style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Panel: ${data['panel_size']} kW',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  Text(
                    '₹${data['quote_amount']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar with a modern design
              LinearProgressIndicator(
                value: fundedPercentage, // Value ranges from 0.0 to 1.0
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),

              // Percentage funded text in a clean and modern style
              Text(
                '$percentage% funded',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),

              // Unit funded count and status chip in a cleaner layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data['funded_units']} / 1000 units funded',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  Chip(
                    label: Text(
                      data['status'] == 'quoted' ? 'ONGOING' : 'FUNDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: data['status'] == 'quoted'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
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
        title: const Text('Investments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "All Properties"),
            Tab(text: "My Investments"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: filteredAll.length,
                  itemBuilder: (context, index) {
                    return buildAllInvestmentCard(filteredAll[index]);
                  },
                ),
                ListView.builder(
                  itemCount: filteredMy.length,
                  itemBuilder: (context, index) {
                    return buildMyInvestmentCard(filteredMy[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
