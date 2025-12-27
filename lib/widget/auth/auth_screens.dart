import 'package:flash_card/helper/router.dart';
import 'package:flash_card/services/auth_service.dart';
import 'package:flutter/material.dart';

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError(context, 'Please enter an email to reset your password');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.instance.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      _showSuccess(context, result.message ?? 'Password reset email has been sent.');
    } else {
      _showError(context, result.message ?? 'Failed to send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7B61FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              const Text(
                'Hey,\nWelcome Back',
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 50),
              _AuthTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 22),
              _AuthTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: 'Login',
                loading: _loading,
                onPressed: _loading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;

                        if (email.isEmpty || password.isEmpty) {
                          _showError(context, 'Please enter both email and password');
                          return;
                        }

                        setState(() => _loading = true);
                        final result = await AuthService.instance.signIn(
                          email: email,
                          password: password,
                        );
                        if (!mounted) return;
                        setState(() => _loading = false);
                        if (result.ok) {
                          Navigator.of(context).pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(context, result.message ?? 'Login failed');
                        }
                      },
              ),
              const SizedBox(height: 16),
              const _ContinueDivider(),
              const SizedBox(height: 12),
              _GoogleButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        final result = await AuthService.instance.signInAnon();
                        if (!mounted) return;
                        setState(() => _loading = false);
                        if (result.ok) {
                          Navigator.of(context).pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(
                            context,
                            result.message ?? 'Google/Guest sign-in failed',
                          );
                        }
                      },
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  String? _validateInputs({
    required String username,
    required String email,
    required String password,
    required String confirm,
  }) {
    if (username.isEmpty) return 'Please enter a username';
    if (email.isEmpty) return 'Please enter an email';
    if (!_isValidEmail(email)) return 'Please enter a valid email';
    if (password.isEmpty) return 'Please enter a password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7B61FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 12),
              const Text(
                "Let's get\nstarted",
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 40),
              _AuthTextField(
                controller: _usernameController,
                hint: 'Username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _AuthTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _AuthTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),
              _AuthTextField(
                controller: _confirmController,
                hint: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: 'Sign up',
                loading: _loading,
                onPressed: _loading
                    ? null
                    : () async {
                        final username = _usernameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirm = _confirmController.text;

                        final validationError = _validateInputs(
                          username: username,
                          email: email,
                          password: password,
                          confirm: confirm,
                        );
                        if (validationError != null) {
                          _showError(context, validationError);
                          return;
                        }

                        setState(() => _loading = true);
                        final result = await AuthService.instance.signUp(
                          email: email,
                          password: password,
                          username: username,
                        );
                        if (!mounted) return;
                        setState(() => _loading = false);
                        if (result.ok) {
                          Navigator.of(context).pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(context, result.message ?? 'Sign up failed');
                        }
                      },
              ),
              const SizedBox(height: 16),
              const _ContinueDivider(),
              const SizedBox(height: 12),
              _GoogleButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        final result = await AuthService.instance.signInAnon();
                        if (!mounted) return;
                        setState(() => _loading = false);
                        if (result.ok) {
                          Navigator.of(context).pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(
                            context,
                            result.message ?? 'Google/Guest sign-in failed',
                          );
                        }
                      },
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: suffix,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.black12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lightbulb_outline, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Continue as guest',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueDivider extends StatelessWidget {
  const _ContinueDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or continue with',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
