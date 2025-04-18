import 'package:flutter/material.dart';
import 'package:ecofund/constants.dart';
import 'package:ecofund/services/auth_services.dart';
import '../../routes.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}
class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _panCardController = TextEditingController();
  final _citiesController = TextEditingController();  // For serviceable cities
  String _role = 'homeowner';
  bool _isLoading = false;
  String? _error;

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final serviceableCities = _role == 'vendor' ? _citiesController.text.trim() : null;

      final result = await AuthServices.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
        upiId: _upiIdController.text.trim(),
        panCard: _panCardController.text.trim(),
        serviceableCities: serviceableCities,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        final user = result['data']['user'];
        final role = user['role'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful!')),
        );

        // Navigate based on role after successful signup
        switch (role) {
          case 'investor':
            Navigator.pushReplacementNamed(context, AppRoutes.investorDashboard);
            break;
          case 'vendor':
            Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
            break;
          case 'homeowner':
            Navigator.pushReplacementNamed(context, AppRoutes.homeownerDashboard);
            break;
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        setState(() => _error = result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 180,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_nameController, 'Name'),
                  _buildTextField(_emailController, 'Email', validator: _validateEmail),
                  _buildTextField(_passwordController, 'Password', isPassword: true),
                  _buildTextField(_upiIdController, 'UPI ID'),
                  _buildTextField(_panCardController, 'PAN Card'),
                  if (_role == 'vendor') ...[
                    const SizedBox(height: 8),
                    _buildTextField(_citiesController, 'Serviceable Cities (comma separated)',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter serviceable cities';
                          }
                          return null;
                        }
                    ),
                  ],
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: ['homeowner', 'investor', 'vendor']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => _role = value!),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _signup,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                              color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator ?? (value) => (value == null || value.isEmpty)
            ? 'Please enter your $label'
            : null,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}
