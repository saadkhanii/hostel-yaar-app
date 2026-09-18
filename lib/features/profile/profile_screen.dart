import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/session_manager.dart';

/// Account screen reached from the drawer. Shows the current user's
/// info and lets them update their name, phone, and password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const maroon = Color(0xFF800020);

  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _originalName = '';
  String _originalPhone = '';
  String _email = '';
  String _role = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final name = await _authService.getFullName();
    final email = await _authService.getEmail();
    final role = await _authService.getRole();
    final phone = await _authService.getPhone();

    if (!mounted) return;
    setState(() {
      _originalName = name ?? '';
      _originalPhone = phone ?? '';
      _nameCtrl.text = _originalName;
      _phoneCtrl.text = _originalPhone;
      _email = email ?? '';
      _role = role ?? 'seeker';
      _isLoading = false;
    });
  }

  bool get _hasChanges =>
      _nameCtrl.text.trim() != _originalName ||
          _phoneCtrl.text.trim() != _originalPhone;

  // ── Save profile ────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final newName = _nameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    if (newName.isEmpty) {
      _snack('Name cannot be empty');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        fullName: newName,
        phone: newPhone,
      );
      if (!mounted) return;
      setState(() {
        _originalName = newName;
        _originalPhone = newPhone;
        _isLoading = false;
      });
      _snack('Profile updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Change password ─────────────────────────────────────────────────
  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorText;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
          isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Change Password',
            style: TextStyle(color: maroon, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _passwordField(
                  controller: oldCtrl,
                  label: 'Current Password',
                  obscure: obscureOld,
                  onToggle: () =>
                      setDialogState(() => obscureOld = !obscureOld),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: newCtrl,
                  label: 'New Password',
                  obscure: obscureNew,
                  onToggle: () =>
                      setDialogState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: confirmCtrl,
                  label: 'Confirm New Password',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setDialogState(() => obscureConfirm = !obscureConfirm),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: maroon.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                final old = oldCtrl.text;
                final newPw = newCtrl.text;
                final confirm = confirmCtrl.text;

                if (old.isEmpty || newPw.isEmpty || confirm.isEmpty) {
                  setDialogState(
                          () => errorText = 'All fields are required');
                  return;
                }
                if (newPw.length < 6) {
                  setDialogState(() => errorText =
                  'New password must be at least 6 characters');
                  return;
                }
                if (newPw != confirm) {
                  setDialogState(
                          () => errorText = 'New passwords do not match');
                  return;
                }
                if (old == newPw) {
                  setDialogState(() => errorText =
                  'New password must be different from current');
                  return;
                }

                // Capture these BEFORE the await so we don't touch
                // context across an async gap.
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(this.context);

                setDialogState(() {
                  isSaving = true;
                  errorText = null;
                });

                try {
                  await _authService.changePassword(
                    oldPassword: old,
                    newPassword: newPw,
                  );
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setDialogState(() {
                    isSaving = false;
                    errorText =
                        e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              style: TextButton.styleFrom(foregroundColor: maroon),
              child: isSaving
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(maroon),
                ),
              )
                  : const Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: maroon),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 13, color: maroon.withValues(alpha: 0.7)),
        filled: true,
        fillColor: maroon.withValues(alpha: 0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: maroon.withValues(alpha: 0.5),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: maroon),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: fg, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
              color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(maroon),
          ),
        )
            : SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 48,
                backgroundColor: maroon.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: maroon, size: 52),
              ),
              const SizedBox(height: 16),
              Text(
                _originalName.isEmpty ? 'User' : _originalName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role == 'warden' ? 'Warden' : 'Hostel Seeker',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: maroon.withValues(alpha: 0.85),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Editable fields ──────────────────────
              _sectionTitle('Account Details', fg),
              const SizedBox(height: 12),
              _textField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      padding:
                      const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // ── Actions ──────────────────────────────
              _sectionTitle('Security', fg),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
              _Tile(
                icon: Icons.logout,
                label: 'Log Out',
                danger: true,
                onTap: () =>
                    SessionManager.confirmAndLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color fg) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: fg.withValues(alpha: 0.7),
      ),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: maroon),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(fontSize: 13, color: maroon.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: maroon.withValues(alpha: 0.6), size: 20),
        filled: true,
        fillColor: maroon.withValues(alpha: 0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: maroon),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final color = danger ? Colors.red : maroon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: maroon.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: maroon.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: color.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}