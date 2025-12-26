import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      showBackButton: true,
      showBottomNav: false,
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                // TODO: Add logic to save notification preference
              });
            },
            secondary: const Icon(Icons.notifications_outlined),
          ),
          const Divider(),
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
                // TODO: Add logic to change and save theme
              });
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            leading: const Icon(Icons.language_outlined),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to a language selection screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
