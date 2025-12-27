import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/auth/auth_screens.dart';
import 'package:flash_card/widget/screens/add_deck_screen.dart';
import 'package:flash_card/widget/screens/navigation_shell.dart';
import 'package:flash_card/widget/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String account = '/account';
  static const String flashcard = '/flashcard';
  static const String decks = '/decks';
  static const String addDeck = '/addDeck';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String welcome = '/welcome';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case addDeck:
        return MaterialPageRoute(builder: (_) => const AddDeckScreen());
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
      builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }

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
