import 'package:flash_card/Helper/router.dart';
import 'package:flutter/material.dart';

enum BottomNavItem { home, decks, account }

class AppBottomNavigationBar extends StatelessWidget {
  final BottomNavItem currentItem;
  final ValueChanged<BottomNavItem>? onItemSelected;

  const AppBottomNavigationBar({
    super.key,
    required this.currentItem,
    this.onItemSelected,
  });

  void _handleTap(BuildContext context, BottomNavItem target) {
    if (target == currentItem) return;

    if (onItemSelected != null) {
      onItemSelected!(target);
      return;
    }

    final routeName = _routeForItem(target);
    Navigator.pushReplacementNamed(context, routeName);
  }

  String _routeForItem(BottomNavItem item) {
    switch (item) {
      case BottomNavItem.home:
        return AppRouter.home;
      case BottomNavItem.decks:
        return AppRouter.decks;
      case BottomNavItem.account:
        return AppRouter.account;
    }
  }

  Color _iconColor(BottomNavItem item) {
    return item == currentItem ? const Color(0xFF7233FE) : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_outlined, size: 32, color: _iconColor(BottomNavItem.home)),
              onPressed: () => _handleTap(context, BottomNavItem.home),
            ),
            IconButton(
              icon: Icon(Icons.folder_open_outlined, size: 32, color: _iconColor(BottomNavItem.decks)),
              onPressed: () => _handleTap(context, BottomNavItem.decks),
            ),
            IconButton(
              icon: Icon(Icons.person_outline, size: 32, color: _iconColor(BottomNavItem.account)),
              onPressed: () => _handleTap(context, BottomNavItem.account),
            ),
          ],
        ),
      ),
    );
  }
}
