import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import 'auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// Email the OTP was sent to.
  final String email;

  /// The verified 6-digit code — sent along with the new password so the
  /// backend can re-validate it (defense in depth: this prevents someone
  /// from calling /auth/reset-password directly without ever verifying).
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in.'),
        ),
      );

      // Clear the whole stack — user must log in fresh with the new password.
      NavigationService.navigateAndRemoveUntil(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    const maroon = Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  onPressed: () => NavigationService.goBack(),
                  icon: Icon(Icons.arrow_back, color: fg),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: maroon.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: maroon,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Set New Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a new password for ${widget.email}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 36),
                AuthTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  fg: fg,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: fg.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  fg: fg,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: fg.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      foregroundColor: const Color(0xFFF3E6D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(
                          Color(0xFFF3E6D5),
                        ),
                      ),
                    )
                        : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}