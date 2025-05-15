import 'package:ecofund/services/investor_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/homeonwer_services.dart';
import '../../widgets/homeowner_navbar.dart';

class InvestorDetailedListingPage extends StatelessWidget {
  final Map<String, dynamic> property;

  const InvestorDetailedListingPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final investments = (property['investments'] ?? []) as List<dynamic>;
    final energyLogs = (property['energy_logs'] ?? []) as List<dynamic>;
    final payouts = (property['investor_payouts'] ?? []) as List<dynamic>;
    print("Property: ${property['investor_payouts']} ");

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
            if(property['property_status'] == 'funded')
              _buildPayoutCard(
                context,
                payouts
              ),

              const SizedBox(height: 16),
            if (property['property_status'] == 'quoted')
              //show the widget to make the investment
              _buildInvestmentDialog(
                context,
                property
              ),


          ],
        ),
      ),
      bottomNavigationBar: const HomeownerBottomNavBar(currentIndex: 1),

    );
  }

  Widget _buildPayoutCard(BuildContext context, List<dynamic> payouts) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Investor Payouts",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...payouts.map<Widget>((payoutData) {
              final payout = payoutData as Map<String, dynamic>;
              final payoutDate = DateTime.parse(payout['payout_date']);
              final payoutStatus = payout['status'];
              final amount = payout['amount'];
              final amountDue = payout['amount_due'];
              final month = payout['month'];

              final formattedDate =
              DateFormat('MMM d, yyyy - hh:mm a').format(payoutDate);

              final isPaid = payoutStatus == 'paid';
              final statusText = isPaid ? 'RECEIVED' : payoutStatus.toUpperCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Payout for $month",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isPaid
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Amount Paid: ₹$amount",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Payout Date: $formattedDate",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentDialog(
      BuildContext context,
      Map<String, dynamic> property,
      ) {
    final quoteAmount = double.tryParse(property['quote_amount']) ?? 0.0;
    final unitPrice = quoteAmount / 1000;
    final propertyId = property['property_id'];

    final investments = property['investments'] as List;
    final unitsBought = investments.fold(0, (sum, investment) {
      return sum + (investment['units_purchased'] as int);
    });
    final availableUnits = (1000 - unitsBought).clamp(0, 1000);

    int selectedUnits = 1;

    return StatefulBuilder(
      builder: (context, setState) {
        final totalAmount = selectedUnits * unitPrice;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invest",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Unit Price", style: TextStyle(color: Colors.grey[700])),
                    Text("₹${unitPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Available Units", style: TextStyle(color: Colors.grey[700])),
                    Text("$availableUnits",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Select Units to Invest", style: TextStyle(color: Colors.grey[700])),
                Slider(
                  activeColor: Colors.green.shade500,
                  value: selectedUnits.toDouble(),
                  min: 1,
                  max: availableUnits.toDouble(),
                  divisions: availableUnits - 1 > 0 ? availableUnits - 1 : 1,
                  label: "$selectedUnits",
                  onChanged: (value) {
                    setState(() {
                      selectedUnits = value.round();
                    });
                  },
                ),
                Center(
                  child: Text(
                    "$selectedUnits Units = ₹${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showPaymentDialog(
                        context,
                        totalAmount.toInt(),
                        "ecofund@upi",
                        propertyId,
                        selectedUnits,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green.shade500,
                    ),
                    child: const Text(
                      "Proceed to Pay",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showPaymentDialog(
      BuildContext context,
      int amount,
      String upiId,
      String propertyId,
      int units,
      ) {
    final txnController = TextEditingController();
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=$upiId&pn=EcoFund&am=$amount';

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

                  final success = await InvestorServices.makeInvestment(
                    propertyId,
                    units,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Payment marked as paid!' : 'Payment confirmation failed',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        );
      },
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

  Widget _buildInvestmentPieChart(Map<String, double> data,
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
        title: '${((remainingInvestment / quotedAmount) * 100).toStringAsFixed(
            1)}%',
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
              SizedBox(height: 200,
                  child: PieChart(PieChartData(sections: sections))),
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
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.85 *
                            progressPercentage.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            "${(progressPercentage * 100).toStringAsFixed(
                                1)}% funded",
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
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge,
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
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
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
                            '${month.getMonthShortName()} ${month.split(
                                '-')[1]}\n${spot.y.toInt()} kWh',
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
                      curveSmoothness: 0.15,
                      // Fixes unnatural dips
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