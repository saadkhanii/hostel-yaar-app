import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

/// Renders a circular avatar.
///
/// Two modes:
///  1. Data passed in: `Avatar(name: 'Ahmed', imageUrl: 'https://...')`
///  2. Current user:   `Avatar.current()` — reads from AuthService and
///     re-renders when the profile changes.
class Avatar extends StatefulWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final double borderWidth;
  final bool showEditBadge;
  final VoidCallback? onTap;

  /// When true, this avatar tracks the logged-in user. Ignores [name] and
  /// [imageUrl] and pulls from AuthService instead.
  final bool _tracksCurrentUser;

  const Avatar({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
    this.backgroundColor,
    this.borderColor,
    this.textColor = Colors.white,
    this.borderWidth = 1.5,
    this.showEditBadge = false,
    this.onTap,
  }) : _tracksCurrentUser = false;

  const Avatar.current({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.borderColor,
    this.textColor = Colors.white,
    this.borderWidth = 1.5,
    this.showEditBadge = false,
    this.onTap,
  })  : name = null,
        imageUrl = null,
        _tracksCurrentUser = true;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  final _authService = AuthService();

  String? _resolvedName;
  String? _resolvedImageUrl;
  bool _loaded = false;

  bool get _isCurrentUserMode => widget._tracksCurrentUser;

  @override
  void initState() {
    super.initState();
    if (_isCurrentUserMode) {
      AuthService.identityVersion.addListener(_reload);
      _reload();
    } else {
      _resolvedName = widget.name;
      _resolvedImageUrl = widget.imageUrl;
      _loaded = true;
    }
  }

  @override
  void didUpdateWidget(covariant Avatar old) {
    super.didUpdateWidget(old);
    if (!_isCurrentUserMode) {
      _resolvedName = widget.name;
      _resolvedImageUrl = widget.imageUrl;
    }
  }

  @override
  void dispose() {
    if (_isCurrentUserMode) {
      AuthService.identityVersion.removeListener(_reload);
    }
    super.dispose();
  }

  Future<void> _reload() async {
    final name = await _authService.getFullName();
    final url = await _authService.getProfilePicture();
    if (!mounted) return;
    setState(() {
      _resolvedName = name ?? '';
      _resolvedImageUrl = url;
      _loaded = true;
    });
  }

  String get _initials {
    final name = (_resolvedName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.black.withValues(alpha: 0.15);
    final hasImage =
        _resolvedImageUrl != null && _resolvedImageUrl!.trim().isNotEmpty;

    Widget content = !_loaded
        ? Container(color: bg)
        : hasImage
        ? Image.network(
      _resolvedImageUrl!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _initialsText(),
      loadingBuilder: (context, child, progress) =>
      progress == null ? child : _initialsText(),
    )
        : _initialsText();

    Widget avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: hasImage ? null : bg,
        shape: BoxShape.circle,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: content,
    );

    if (widget.showEditBadge) {
      // ... badge code from before ...
    }

    if (widget.onTap == null) return avatar;
    return GestureDetector(onTap: widget.onTap, child: avatar);
  }

  Widget _initialsText() => Text(
    _initials,
    style: TextStyle(
      fontSize: widget.size * 0.36,
      fontWeight: FontWeight.w700,
      color: widget.textColor,
    ),
  );
}