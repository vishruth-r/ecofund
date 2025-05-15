import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/vendor_services.dart';
import '../../../services/vendor_services.dart';
import '../../widgets/homeowner_navbar.dart';

class DetailedVendorListingPage extends StatelessWidget {

  final TextEditingController monthController = TextEditingController();
  final TextEditingController energyOutputController = TextEditingController();

  @override
  void dispose() {
    monthController.dispose();
    energyOutputController.dispose();
  }

  final Map<String, dynamic> property;

  DetailedVendorListingPage({super.key, required this.property});

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
            if (property['property_status'] == 'funded')
              _buildEnergyLogSubmissionTab(context, energyLogs, property['property_id']),
            const SizedBox(height: 16),
            if (property['property_status'] == 'funded')
              _buildEnergyLogChart(energyData),
            const SizedBox(height: 16),
            if (property['property_status'] != 'pending')
              _buildInvestmentPieChart(
                  investorData, quoteAmount, context, investorDetails),

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

  Widget _buildInvestmentPieChart(
      Map<String, double> data,
      double quotedAmount,
      BuildContext context,
      Map<String, List<Map<String, dynamic>>> investorDetails) {
    if (data.isEmpty) {
      return SizedBox.shrink();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal
    ];

    double totalInvested = data.values.fold(0, (sum, element) => sum + element);
    double remainingInvestment = quotedAmount - totalInvested;

    List<PieChartSectionData> sections = data.entries.map((e) {
      final index = data.keys.toList().indexOf(e.key);
      final color = colors[index % colors.length];
      double percentage = (e.value / quotedAmount) * 100;

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();

    if (remainingInvestment > 0) {
      sections.add(PieChartSectionData(
        color: Colors.grey.shade300,
        value: remainingInvestment,
        title: '${((remainingInvestment / quotedAmount) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ));
    }

    double progressPercentage = totalInvested / quotedAmount;

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
              SizedBox(height: 200, child: PieChart(PieChartData(sections: sections))),
              const SizedBox(height: 24),

              // Progress Bar Below
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Funding Progress",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 28,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Container(
                        height: 28,
                        width: MediaQuery.of(context).size.width * 0.85 *
                            progressPercentage.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            "${(progressPercentage * 100).toStringAsFixed(1)}% funded",
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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


  Widget _buildEnergyLogChart(Map<String, double> energyData) {
    final sortedKeys = energyData.keys.toList()
      ..sort((a, b) => a.toMonthDate().compareTo(b.toMonthDate()));

    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), energyData[sortedKeys[i]]!));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Energy Output",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final month = sortedKeys[spot.x.toInt()];
                          return LineTooltipItem(
                            '${month.getMonthShortName()} ${month.split('-')[1]}\n${spot.y.toInt()} kWh',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.15, // Fixes unnatural dips
                      color: Colors.green,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.4),
                            Colors.green.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                sortedKeys[index].getMonthShortName(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(),
                      left: BorderSide(),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget to submit energy logs
Widget _buildEnergyLogSubmissionTab(BuildContext context, List<dynamic> logs, String propertyId) {

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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
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

                  // Call the submitEnergyLog function
                  final result = await VendorServices.submitEnergyLog(
                    propertyId: propertyId,
                    month: month,
                    unitsProduced: output.toInt(),
                  );

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }

                  // Clear inputs after submission
                  monthController.clear();
                  energyOutputController.clear();
                },
                child: const Text("Submit Log", style: TextStyle(color: Colors.white),)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension MonthName on String {
  String getMonthShortName() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = split('-'); // "mm-yyyy"
    if (parts.length != 2) return this;
    final monthIndex = int.tryParse(parts[0]) ?? 1;
    return monthNames[monthIndex - 1];
  }

  DateTime toMonthDate() {
    final parts = split('-'); // "mm-yyyy"
    return DateTime(int.parse(parts[1]), int.parse(parts[0]));
  }
}