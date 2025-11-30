import 'package:flash_card/Helper/router.dart';
import 'package:flash_card/services/auth_service.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const AccountScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return AppScaffold(
      title: 'Account',
      currentItem: BottomNavItem.account,
      showBottomNav: showBottomNav,
      onNavItemSelected: onNavItemSelected,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('images/avatar.jpg'),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Kafuu Chino',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 50),
            _buildOptionButton(
              icon: Icons.settings,
              text: 'Setting',
              onTap: () {},
            ),
            const SizedBox(height: 30),
            _buildOptionButton(
              icon: Icons.notifications_none,
              text: 'Activities',
              onTap: () {},
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
