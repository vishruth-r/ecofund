import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/homeowner_navbar.dart';

class DetailedVendorListingPage extends StatelessWidget {
  final Map<String, dynamic> property;

  const DetailedVendorListingPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    print("Property Details: $property");
    final investments = (property['investments'] ?? []) as List<dynamic>;
    final energyLogs = (property['energy_logs'] ?? []) as List<dynamic>;
    final payments = (property['payments'] ?? []) as List<dynamic>;

    final totalInvestment = investments.fold<double>(
      0,
          (sum, item) => sum + (item['investment_amount'] as num).toDouble(),
    );
    final quoteAmount = double.tryParse(property['quote_amount']) ?? 0.0;


    final investorData = <String, double>{};
    final investorDetails = <String, List<Map<String, dynamic>>>{};
    for (var inv in investments) {
      final id = inv['investor_id'];
      investorData[id] = (investorData[id] ?? 0) +
          (inv['investment_amount'] as num).toDouble();
      investorDetails[id] ??= [];
      investorDetails[id]!.add({
        'units_purchased': inv['units_purchased'],
        'investment_amount': inv['investment_amount'],
      });
    }

    final energyData = <String, double>{};
    for (var log in energyLogs) {
      final month = log['month'];
      energyData[month] = (energyData[month] ?? 0) +
          (log['energy_output'] as num).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyHeader(context),
            const SizedBox(height: 16),
            if (property['property_status'] != 'pending')
              _buildInvestmentPieChart(
                  investorData, quoteAmount, context, investorDetails),
            const SizedBox(height: 16),
            if (property['property_status'] != 'pending' &&
                property['property_status'] != 'quoted')
              _buildEnergyLogChart(energyData),
            if (property['property_status'] == 'funded')
              _buildEnergyLogSubmissionTab(context, energyLogs, property['property_id']),

          ],
        ),
      ),
      bottomNavigationBar: const HomeownerBottomNavBar(currentIndex: 1),

    );
  }

  Widget _buildPropertyHeader(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property['address'],
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${property['city']}, ${property['pincode']}',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Status:', property['property_status']),
            _buildStatusRow('Homeowner:', property['homeowner_name']),
            _buildStatusRow('Contact:', property['homeowner_contact']),
            if (property['property_status'] != 'pending')
              _buildStatusRow('Quote Amount:', '₹${property['quote_amount']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value ?? 'N/A'), // Default to 'N/A' if null
        ],
      ),
    );
  }

  Widget _buildInvestmentPieChart(Map<String, double> data, double quotedAmount,
      BuildContext context,
      Map<String, List<Map<String, dynamic>>> investorDetails) {
    // If there are no investors, show a message instead of the pie chart
    if (data.isEmpty) {
      return SizedBox.shrink(); // Return an empty widget if no data
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey
    ];

    // Calculate total invested amount
    double totalInvested = data.values.reduce((sum, element) => sum + element);

    // Calculate the remaining (pending) investment
    double remainingInvestment = quotedAmount - totalInvested;

    // Create the sections for the pie chart, including a grey section for the pending investment
    List<PieChartSectionData> sections = data.entries.map((e) {
      final index = data.keys.toList().indexOf(e.key);
      final color = colors[index % colors.length];

      // Calculate the percentage of the quoted amount that the user has invested
      double percentage = (e.value / quotedAmount) * 100;

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();

    // If there is remaining investment, add it as a grey section
    if (remainingInvestment > 0) {
      sections.add(PieChartSectionData(
        color: Colors.grey,
        value: remainingInvestment,
        title: '${((remainingInvestment / quotedAmount) * 100).toStringAsFixed(
            1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ));
    }

    return GestureDetector(
      onTap: () {
        _showInvestorDetails(context, investorDetails);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Investments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(sections: sections))),
            ],
          ),
        ),
      ),
    );
  }
  void _showInvestorDetails(BuildContext context,
      Map<String, List<Map<String, dynamic>>> investorDetails) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5, // Bottom half of the screen
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Investor Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: investorDetails.length,
                    itemBuilder: (context, index) {
                      final investorId = investorDetails.keys.elementAt(index);
                      final details = investorDetails[investorId]!;
                      final investorLabel = 'Investor ${index + 1}';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investorLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Divider(height: 20, thickness: 1),
                              ...details.map((detail) {
                                return Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Units Purchased: ${detail['units_purchased']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Investment Amount: ₹${detail['investment_amount']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyLogChart(Map<String, double> data) {
    if (data.isEmpty) {
      return SizedBox.shrink(); // Return an empty widget if no data
    }

    final sortedKeys = data.keys.toList()
      ..sort();
    final spots = sortedKeys
        .asMap()
        .entries
        .map((entry) {
      return FlSpot(entry.key.toDouble(), data[entry.value]!);
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Monthly Energy Output (kWh)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.3),
                      ),
                    )
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedKeys.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(sortedKeys[index]
                              .split('-')
                              .last); // show month only
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyLogSubmissionTab(BuildContext context, List<dynamic> logs, String propertyId) {
    final TextEditingController monthController = TextEditingController();
    final TextEditingController energyOutputController = TextEditingController();

    // Extract already logged months
    final Set<String> loggedMonths = logs.map((log) => log['month'] as String).toSet();

    Future<void> _pickMonth(BuildContext context) async {
      DateTime today = DateTime.now();
      DateTime firstDate = DateTime(today.year - 1, 1);
      DateTime lastDate = DateTime(today.year, today.month - 1, 1); // Last full month
      DateTime initialDate = lastDate; // Set initialDate to a valid date within range

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Select Month for Energy Log',
      );


      if (picked != null) {
        final formatted = DateFormat('MM-yyyy').format(picked);
        if (loggedMonths.contains(formatted)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Log for this month already exists.")),
          );
          return;
        }
        monthController.text = formatted;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Monthly Energy Logs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            logs.isEmpty
                ? const Text("No logs submitted yet.")
                : SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(log['month']),
                    subtitle: Text("${log['energy_output']} units"),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Add New Log", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickMonth(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: monthController,
                  decoration: const InputDecoration(
                    labelText: "Month (MM-yyyy)",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: energyOutputController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Energy Output (kWh)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final month = monthController.text.trim();
                  final output = double.tryParse(energyOutputController.text.trim());

                  if (month.isEmpty || output == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter valid month and output.")),
                    );
                    return;
                  }

                  if (loggedMonths.contains(month)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Log for this month already exists.")),
                    );
                    return;
                  }

                  // TODO: Submit to backend
                  print("Submitting: $month - $output units");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Submitted new log (mock)!")),
                  );

                  // Clear inputs
                  monthController.clear();
                  energyOutputController.clear();
                },
                child: const Text("Submit Log"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}