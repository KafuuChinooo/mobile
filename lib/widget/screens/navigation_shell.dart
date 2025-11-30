import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/screens/account.dart';
import 'package:flash_card/widget/screens/decks_screen.dart';
import 'package:flash_card/widget/screens/flashcard.dart';
import 'package:flash_card/widget/screens/home_dashboard.dart';
import 'package:flutter/material.dart';

class NavigationShell extends StatefulWidget {
  final BottomNavItem initialItem;

  const NavigationShell({super.key, this.initialItem = BottomNavItem.home});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late BottomNavItem _currentItem;
  late final Map<BottomNavItem, Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.initialItem;
    _tabs = {
      BottomNavItem.home: HomeDashboardScreen(
        showBottomNav: false,
        onNavItemSelected: _onItemSelected,
      ),

      BottomNavItem.decks: DecksScreen(
        showBottomNav: false,
        onNavItemSelected: _onItemSelected,
      ),
      BottomNavItem.account: AccountScreen(
        showBottomNav: false,
        onNavItemSelected: _onItemSelected,
      ),
    };
  }

  void _onItemSelected(BottomNavItem item) {
    setState(() {
      _currentItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderedTabs = BottomNavItem.values.map((item) => _tabs[item]!).toList();

    return Scaffold(
      body: IndexedStack(
        index: _currentItem.index,
        children: orderedTabs,
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentItem: _currentItem,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
