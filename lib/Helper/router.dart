import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/add_deck_screen.dart';
import 'package:flash_card/widget/navigation_shell.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String account = '/account';
  static const String flashcard = '/flashcard';
  static const String decks = '/decks';
  static const String addDeck = '/addDeck';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case addDeck:
        return MaterialPageRoute(builder: (_) => const AddDeckScreen());
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
      case flashcard:
        return BottomNavItem.flashcard;
      case decks:
        return BottomNavItem.decks;
      default:
        return null;
    }
  }
}
