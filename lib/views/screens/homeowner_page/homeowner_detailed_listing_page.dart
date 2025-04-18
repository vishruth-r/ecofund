import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../services/homeonwer_services.dart';
import '../../widgets/homeowner_navbar.dart';

class DetailedListingPage extends StatelessWidget {
  final Map<String, dynamic> property;

  const DetailedListingPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            if (property['property_status'] != 'pending' &&
                property['property_status'] != 'quoted')
              _buildPaymentDetails(context, payments),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${property['city']}, ${property['pincode']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Status:', property['property_status']),
            _buildStatusRow('Vendor:', property['vendor_name']),
            _buildStatusRow('Contact:', property['vendor_contact']),
            if (property['property_status'] != 'pending')
              _buildStatusRow('Quote Amount:', '₹${property['quote_amount']}'),

          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInvestmentPieChart(Map<String, double> data, double quotedAmount,
      BuildContext context, Map<String, List<Map<String, dynamic>>> investorDetails) {
    // If there are no investors, show a message instead of the pie chart
    if (data.isEmpty) {
      return SizedBox.shrink(); // Return an empty widget if no data
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.grey];

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
        title: '${((remainingInvestment / quotedAmount) * 100).toStringAsFixed(1)}%',
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
                  height: 200, child: PieChart(PieChartData(sections: sections))),
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
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: investorDetails.length,
          itemBuilder: (context, index) {
            final investorId = investorDetails.keys.elementAt(index);
            final details = investorDetails[investorId]!;

            // Generate a generic "Investor 1", "Investor 2", etc.
            final investorLabel = 'Investor ${index + 1}';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      investorLabel, // Display the investor label here
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...details.map((detail) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            // Displaying the investment details in a clean way
                            Text(
                                'Units Purchased: ${detail['units_purchased']}'),
                            const SizedBox(width: 8),
                            Text(
                                'Investment Amount: ₹${detail['investment_amount']}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
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
  Widget _buildPaymentDetails(BuildContext context, List<dynamic> payments) {
    if (payments.isEmpty) {
      return SizedBox.shrink(); // Return an empty widget if no payments
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Payment Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...payments.map((p) {
              final status = p['status'].toString().toUpperCase();
              final isPaid = status == 'PAID';
              final date = DateTime.parse(p['created_at']);
              final amount = p['amount_due'];
              final paymentId = p['payment_id'];

              return InkWell(
                onTap: () {
                  if (!isPaid) {
                    _showPaymentDialog(
                      context,
                      amount,
                      'company@upi', // Replace with actual UPI ID if dynamic
                      paymentId,
                    );
                  }
                },
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                      leading: Icon(
                        isPaid ? Icons.check_circle : Icons.error,
                        color: isPaid ? Colors.green : Colors.red,
                      ),
                      title: Text('₹$amount'),
                      subtitle: Text('Invoice Raised: ${date.day}/${date.month}/${date.year}'),
                      trailing: Chip(
                        label: Text(status),
                        backgroundColor: isPaid
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, int amount, String upiId, String paymentId) {
    final txnController = TextEditingController();
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=$upiId&pn=EcoFund&am=$amount';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(qrUrl, height: 180, width: 180),
              const SizedBox(height: 12),
              Text('Amount Due: ₹$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('UPI ID: $upiId', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: txnController,
                decoration: const InputDecoration(
                  labelText: 'Enter Transaction ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final txnId = txnController.text.trim();
                  if (txnId.isEmpty) return;

                  final success = await HomeownerServices.markPaymentAsPaid(paymentId, txnId);
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment marked as paid!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment confirmation failed')),
                    );
                  }
                },
                child: const Text('Confirm Payment', style: TextStyle( color: Colors.white),),
              )
            ],
          ),
        );
      },
    );
  }

}