import 'package:flutter/material.dart';
import 'package:ecofund/routes.dart';

class HomeownerBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const HomeownerBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _handleNavigation(BuildContext context, int index) {
    // Avoid re-navigating to the same page
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.homeownerDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.homeownerListings);
        break;
      case 2:
     //   Navigator.pushReplacementNamed(context, AppRoutes.homeownerProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'My Listings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
