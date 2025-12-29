import 'package:flash_card/helper/router.dart';
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

  // Xử lý chọn tab, điều hướng hoặc callback
  void _handleTap(BuildContext context, BottomNavItem target) {
    if (target == currentItem) return;

    if (onItemSelected != null) {
      onItemSelected!(target);
      return;
    }

    final routeName = _routeForItem(target);
    Navigator.pushReplacementNamed(context, routeName);
  }

  // Map tab sang route tương ứng
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

  // Màu icon tùy tab đang chọn
  Color _iconColor(BottomNavItem item) {
    return item == currentItem ? const Color(0xFF7233FE) : Colors.grey;
  }

  // Nhãn hiển thị cho từng tab
  String _label(BottomNavItem item) {
    switch (item) {
      case BottomNavItem.home:
        return 'Home';
      case BottomNavItem.decks:
        return 'Library';
      case BottomNavItem.account:
        return 'Account';
    }
  }

  @override
  // Dựng thanh điều hướng đáy tuỳ chọn tab
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
            _NavItem(
              icon: Icons.home_outlined,
              label: _label(BottomNavItem.home),
              color: _iconColor(BottomNavItem.home),
              onTap: () => _handleTap(context, BottomNavItem.home),
            ),
            _NavItem(
              icon: Icons.folder_open_outlined,
              label: _label(BottomNavItem.decks),
              color: _iconColor(BottomNavItem.decks),
              onTap: () => _handleTap(context, BottomNavItem.decks),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: _label(BottomNavItem.account),
              color: _iconColor(BottomNavItem.account),
              onTap: () => _handleTap(context, BottomNavItem.account),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  // Vẽ item biểu tượng và nhãn
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
