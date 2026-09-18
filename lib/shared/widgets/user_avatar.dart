import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

/// Displays the user's profile picture, or falls back to their initials
/// if no picture is set. Reads from AuthService cache in initState.
///
/// Pass [showEditBadge] true to render a small camera badge in the
/// bottom-right corner — used on the Profile screen to hint that the
/// avatar is tappable.
class UserAvatar extends StatefulWidget {
  final double size;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    this.size = 48,
    this.showEditBadge = false,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  static const maroon = Color(0xFF800020);

  final _authService = AuthService();

  String? _pictureUrl;
  String _initials = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AuthService.identityVersion.addListener(_onIdentityChanged);
    _load();
  }

  void _onIdentityChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    AuthService.identityVersion.removeListener(_onIdentityChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _authService.getFullName();
    final url = await _authService.getProfilePicture();
    if (!mounted) return;
    setState(() {
      _initials = _computeInitials(name ?? '');
      _pictureUrl = url;
      _isLoading = false;
    });
  }

  String _computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last =
    parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? maroon.withValues(alpha: 0.15);
    final fg = widget.foregroundColor ?? maroon;

    Widget avatarContent;

    if (_isLoading) {
      avatarContent = Container(
        color: bg,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(maroon),
          ),
        ),
      );
    } else if (_pictureUrl != null && _pictureUrl!.isNotEmpty) {
      avatarContent = Image.network(
        _pictureUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: bg,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(maroon),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => _initialsFallback(bg, fg),
      );
    } else {
      avatarContent = _initialsFallback(bg, fg);
    }

    final circle = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: widget.border,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarContent,
    );

    final wrapped = widget.showEditBadge
        ? Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: maroon,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: widget.size * 0.18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    )
        : circle;

    if (widget.onTap == null) return wrapped;
    return GestureDetector(onTap: widget.onTap, child: wrapped);
  }

  Widget _initialsFallback(Color bg, Color fg) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: widget.size * 0.38,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}