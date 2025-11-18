import 'package:flash_card/widget/account.dart';
import 'package:flash_card/widget/decks_screen.dart';
import 'package:flash_card/widget/flashcard.dart';
import 'package:flash_card/widget/home_dashboard.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String account = '/account';
  static const String flashcard = '/flashcard';
  static const String decks = '/decks';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeDashboardScreen());
      case account:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      case flashcard:
        return MaterialPageRoute(builder: (_) => const FlashcardScreen());
      case decks:
        return MaterialPageRoute(builder: (_) => const DecksScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
