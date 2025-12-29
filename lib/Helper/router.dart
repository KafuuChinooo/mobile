import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/auth/auth_screens.dart';
import 'package:flash_card/widget/screens/navigation_shell.dart';
import 'package:flash_card/widget/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String account = '/account';
  static const String decks = '/decks';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String welcome = '/welcome';

  // Tạo route theo tên, fallback màn not found
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      default:
        break;
    }

    final targetItem = _navItemForRoute(settings.name);
    if (targetItem != null) {
      return MaterialPageRoute(
        builder: (_) => NavigationShell(initialItem: targetItem),
      );
    }

    return MaterialPageRoute(
      builder: (_) => NotFoundScreen(route: settings.name),
    );
  }

  // Map tên route sang tab tương ứng
  static BottomNavItem? _navItemForRoute(String? routeName) {
    switch (routeName) {
      case home:
        return BottomNavItem.home;
      case account:
        return BottomNavItem.account;
      case decks:
        return BottomNavItem.decks;
      default:
        return null;
    }
  }
}

class NotFoundScreen extends StatelessWidget {
  final String? route;

  const NotFoundScreen({super.key, this.route});

  @override
  // Dựng màn báo route không tồn tại
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('No route defined for ${route ?? 'unknown'}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.home),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
