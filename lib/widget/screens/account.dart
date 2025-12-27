import 'package:flash_card/helper/router.dart';
import 'package:flash_card/services/auth_service.dart';
import 'package:flash_card/services/user_profile_service.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const AccountScreen({
    super.key,
    this.showBottomNav = true,
    this.onNavItemSelected,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  UserProfile? _profile;
  String? _error;
  String _selectedAvatar = _defaultAvatar;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await UserProfileService.instance.fetchCurrentProfile();
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString('selected_avatar');
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile?.displayName ?? '';
        _selectedAvatar = savedAvatar ?? _defaultAvatar;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load profile: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await UserProfileService.instance.updateDisplayName(name);
      await AuthService.instance.currentUser?.reload();
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);
    const bgColor = Colors.white;
    const panelColor = Color(0xFFF5F5FB);
    const borderColor = Color(0xFFDDDDDD);
    const textPrimary = Colors.black87;
    const textSecondary = Colors.black54;
    const accent = Color(0xFF9D90FF);
    final profile = _profile;

    return AppScaffold(
      title: 'Account',
      currentItem: BottomNavItem.account,
      showBottomNav: widget.showBottomNav,
      onNavItemSelected: widget.onNavItemSelected,
      body: Container(
        color: bgColor,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withOpacity(0.4),
                              width: 2.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundImage: AssetImage(_selectedAvatar),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _showAvatarSelector,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.displayName ?? 'Learner',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Personal information',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PersonalInfoSection(
                      panelColor: panelColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onEditName: _showEditUsernameDialog,
                      onPassword: _showChangePasswordDialog,
                      displayName: profile?.displayName ?? 'Learner',
                      email: profile?.email ?? 'N/A',
                    ),
                    const SizedBox(height: 32),
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
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: borderColor),
                          ),
                        ),
                        child: const Text(
                          'Log out',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    final email = _profile?.email ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found to reset password.')),
      );
      return;
    }
    final result = await AuthService.instance.sendPasswordResetEmail(email);
    if (!mounted) return;
    final message = result.message ?? 'Password reset email sent.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentUser = AuthService.instance.currentUser;
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found for this account.')),
      );
      return;
    }

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final currentPw = currentController.text.trim();
                          final newPw = newController.text.trim();
                          final confirmPw = confirmController.text.trim();
                          if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields.')),
                            );
                            return;
                          }
                          if (newPw != confirmPw) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New passwords do not match.')),
                            );
                            return;
                          }

                          setState(() => saving = true);
                          try {
                            final cred = EmailAuthProvider.credential(email: email, password: currentPw);
                            await currentUser!.reauthenticateWithCredential(cred);
                            await currentUser.updatePassword(newPw);
                            await currentUser.reload();
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password changed successfully.')),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? 'Password change failed.')),
                            );
                          } catch (e) {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Password change failed: $e')),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<void> _showAvatarSelector() async {
    final options = [_defaultAvatar, ..._presetAvatars];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose an avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final path = options[index];
                  final isSelected = path == _selectedAvatar;
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selected_avatar', path);
                      if (!mounted) return;
                      setState(() => _selectedAvatar = path);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avatar updated.')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF9D90FF) : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditUsernameDialog() async {
    _nameController.text = _profile?.displayName ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) {
        bool localSaving = false;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Change username'),
              content: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter a new username',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: localSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: localSaving
                      ? null
                      : () async {
                          setLocalState(() => localSaving = true);
                          await _saveName();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: localSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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

const List<String> _presetAvatars = [
  'images/avatar/1.jpg',
  'images/avatar/2.jpg',
  'images/avatar/3.jpg',
  'images/avatar/4.jpg',
  'images/avatar/5.jpg',
];

const String _defaultAvatar = 'images/avatar.jpg';

class _PersonalInfoSection extends StatelessWidget {
  final Color panelColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onEditName;
  final VoidCallback onPassword;
  final String displayName;
  final String email;

  const _PersonalInfoSection({
    required this.panelColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onEditName,
    required this.onPassword,
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Username',
            value: displayName,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: onEditName,
          ),
          Divider(height: 1, color: borderColor),
          _InfoRow(
            label: 'Email',
            value: email,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {},
          ),
          Divider(height: 1, color: borderColor),
          _InfoRow(
            label: 'Change password',
            value: '',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: onPassword,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
