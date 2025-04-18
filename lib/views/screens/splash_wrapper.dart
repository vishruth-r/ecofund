import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/users_prefs.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    final user = await UserPrefs.getUser();
    print('User data from SharedPreferences: $user');

    if (!mounted) return; // Prevent setState/navigation after widget disposal

    if (user != null && user['role'] != null) {
      final role = user['role'];
      print('Redirecting based on role: $role');

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
      print('No user or role found, redirecting to login');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
