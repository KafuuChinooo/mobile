import 'package:flash_card/Helper/router.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final BottomNavItem? currentItem;
  final ValueChanged<BottomNavItem>? onNavItemSelected;
  final bool showBottomNav;
  final bool showBackButton;
  final bool showAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? actions;
  final Color backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentItem,
    this.onNavItemSelected,
    this.showBottomNav = true,
    this.showBackButton = false,
    this.showAppBar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.actions,
    this.backgroundColor = Colors.white,
  });

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (!showAppBar) return null;
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => _handleBack(context),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: currentItem == null || !showBottomNav
          ? null
          : AppBottomNavigationBar(
              currentItem: currentItem!,
              onItemSelected: onNavItemSelected,
            ),
    );
  }
}
