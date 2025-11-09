
import 'package:flutter/material.dart';
import 'package:flash_card/widget/account.dart';

class AppRouter {
  static const String account = '/account';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case account:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for \${settings.name}'),
            ),
          ),
        );
    }
  }
}
