import 'package:ecofund/services/vendor_services.dart';
import 'package:flutter/material.dart';

class VendorSubmitQuotationPage extends StatefulWidget {
  final Map<String, dynamic> property;

  const VendorSubmitQuotationPage({super.key, required this.property});

  @override
  State<VendorSubmitQuotationPage> createState() => _VendorSubmitQuotationPageState();
}

class _VendorSubmitQuotationPageState extends State<VendorSubmitQuotationPage> {
  final TextEditingController costController = TextEditingController();
  final TextEditingController panelSizeController = TextEditingController();
  bool isSubmitting = false;

  void submitQuote() async {
    final quoteAmount = int.tryParse(costController.text.trim());
    final panelSize = panelSizeController.text.trim();

    if (quoteAmount == null || panelSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid quotation details')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final result = await VendorServices.submitQuotation(
      propertyId: widget.property['property_id'].toString(),
      panelSize: panelSize,
      quoteAmount: quoteAmount,
    );

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Something went wrong')),
    );

    if (result['success']) {
      Navigator.pop(context, true); // Return to previous screen on success
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.property['address'] ?? 'No Address';

    return Scaffold(
      appBar: AppBar(title: Text('Submit Quotation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property: $address', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Enter Quotation Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Estimated Cost (in ₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: panelSizeController,
              decoration: const InputDecoration(
                labelText: 'Panel Size (kW)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isSubmitting ? null : submitQuote,
                child: isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Quotation', style: TextStyle(color: Colors.white, fontSize: 16),)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
