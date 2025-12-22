import 'package:flash_card/helper/router.dart';
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
  final Color? backgroundColor;

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
    this.backgroundColor,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => _handleBack(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
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
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
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
