import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  /// The email the code was sent to, shown to the user and passed along
  /// to the resend/verify calls.
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 60;

  final List<TextEditingController> _controllers =
  List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(_codeLength, (_) => FocusNode());
  final _authService = AuthService();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _secondsLeft = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (_errorText != null) setState(() => _errorText = null);

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == _codeLength) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _handleVerify() async {
    if (_code.length != _codeLength) {
      setState(() => _errorText = 'Enter the full 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      await _authService.verifyOtp(widget.email, _code);

      if (!mounted) return;

      // OTP is valid — push the ResetPasswordScreen with the email + code
      // so the next screen can submit them along with the new password.
      NavigationService.navigateTo(
        AppRoutes.resetPassword,
        arguments: {
          'email': widget.email,
          'code': _code,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.forgotPassword(widget.email);

      if (!mounted) return;

      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
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
                  Icons.mark_email_read_outlined,
                  color: maroon,
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: fg.withValues(alpha: 0.7),
                  ),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                        color: maroon,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: maroon.withValues(alpha: 0.08),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          BorderSide(color: maroon.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          const BorderSide(color: maroon, width: 1.5),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  );
                }),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: const Color(0xFFF3E6D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
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
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: _secondsLeft == 0 ? _handleResend : null,
                    child: _isResending
                        ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(maroon),
                      ),
                    )
                        : Text(
                      _secondsLeft == 0
                          ? 'Resend'
                          : 'Resend in ${_secondsLeft}s',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _secondsLeft == 0
                            ? maroon
                            : fg.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}