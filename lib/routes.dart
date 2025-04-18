import 'package:ecofund/views/screens/homeowner_page/homeowner_detailed_listing_page.dart';
import 'package:ecofund/views/screens/homeowner_page/homeowner_dashboard_page.dart';
import 'package:ecofund/views/screens/homeowner_page/homeowner_listing_page.dart';
import 'package:ecofund/views/screens/investor_page/investor_dashboard.dart';
import 'package:ecofund/views/screens/login_page.dart';
import 'package:ecofund/views/screens/signup_page.dart';
import 'package:ecofund/views/screens/vendor_page/vendor_dashboard.dart';
import 'package:ecofund/views/screens/vendor_page/vendor_listing_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String investorDashboard = '/investor-dashboard';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String homeownerDashboard = '/homeowner-dashboard';
  static const String homeownerListings = '/homeowner-listings';
  static const String detailedListing = '/detailed_listing';
  static const String vendorListing = '/vendor-listings';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginPage(),
    signup: (context) => SignupPage(),
    investorDashboard: (context) => InvestorDashboard(),
    vendorDashboard: (context) => VendorDashboard(),
    homeownerDashboard: (context) => HomeownerDashboard(),
    homeownerListings: (context) => HomeownerListingPage(),
    detailedListing: (context) => DetailedListingPage(property: {},),
    vendorListing: (context) => VendorListingPage(),
  };


}