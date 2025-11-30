import 'package:flash_card/Helper/router.dart';
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
      _showError(context, 'Vui lòng nhập email để đặt lại mật khẩu');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.instance.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      _showSuccess(context, result.message ?? 'Email đặt lại mật khẩu đã được gửi');
    } else {
      _showError(context, result.message ?? 'Gửi email thất bại');
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
              const SizedBox(height: 24),
              const Text(
                'Hey,\nWelcome\nBack',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 32),
              _AuthTextField(
                controller: _emailController,
                hint: 'Username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Forget password ?'),
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
                          _showError(context, 'Vui lòng nhập đầy đủ email và password');
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
                          Navigator.of(context)
                              .pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(context, result.message ?? 'Đăng nhập thất bại');
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
                          Navigator.of(context)
                              .pushReplacementNamed(AppRouter.home);
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
                    "Don't have an account ? Sign up",
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 32),
              _AuthTextField(
                controller: _emailController,
                hint: 'Username',
                icon: Icons.person_outline,
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
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirm = _confirmController.text;

                        if (!_isValidEmail(email)) {
                          _showError(context, 'Vui lòng nhập email hợp lệ');
                          return;
                        }

                        if (password != confirm) {
                          _showError(context, 'Vui lòng nhập mật khẩu đúng');
                          return;
                        }
                        
                        if (password.isEmpty) {
                           _showError(context, 'Vui lòng nhập mật khẩu');
                          return;
                        }

                        setState(() => _loading = true);
                        final result = await AuthService.instance.signUp(
                          email: email,
                          password: password,
                        );
                        if (!mounted) return;
                        setState(() => _loading = false);
                        if (result.ok) {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRouter.home);
                        } else {
                          _showError(context, result.message ?? 'Đăng ký thất bại');
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
                          Navigator.of(context)
                              .pushReplacementNamed(AppRouter.home);
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
                    'Already have an account ? Login',
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Future<void> Function()? onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7B61FF);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading
            ? null
            : (onPressed == null
                ? null
                : () async {
                    await onPressed!.call();
                  }),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/google_logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Google',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
          child: Divider(
            color: Colors.black.withOpacity(0.4),
            thickness: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.black.withOpacity(0.4),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
