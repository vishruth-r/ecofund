import 'package:flutter/material.dart';
import '../../../services/homeonwer_services.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({Key? key}) : super(key: key);

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController consumptionController = TextEditingController();

  String propertyType = 'Residential';

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      final address = addressController.text.trim();
      final pincode = pincodeController.text.trim();
      final city = cityController.text.trim();
      final energyConsumption = int.tryParse(consumptionController.text.trim()) ?? 0;

      final result = await HomeownerServices.addProperty(
        address: address,
        pincode: pincode,
        city: city,
        energyConsumption: energyConsumption,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Property added successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  Widget buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: (value) =>
        value == null || value.isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildTextField(
                  label: 'Address',
                  hintText: 'e.g. 123 Green Street, Sector 7',
                  controller: addressController,
                ),
                buildTextField(
                  label: 'Pincode',
                  hintText: 'e.g. 110085',
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                ),
                buildTextField(
                  label: 'City',
                  hintText: 'e.g. New Delhi',
                  controller: cityController,
                ),
                buildTextField(
                  label: 'Monthly Energy Consumption (kWh)',
                  hintText: 'e.g. 350',
                  controller: consumptionController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Property Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Residential'),
                        value: 'Residential',
                        groupValue: propertyType,
                        onChanged: (value) {
                          setState(() {
                            propertyType = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Commercial'),
                        value: 'Commercial',
                        groupValue: propertyType,
                        onChanged: (value) {
                          setState(() {
                            propertyType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green[400],
                  ),
                  child: const Text(
                    'Submit Property',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
