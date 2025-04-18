import 'package:flutter/material.dart';

class InvestorDashboard extends StatelessWidget {
  const InvestorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Investor!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
