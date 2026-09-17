import 'package:flutter/material.dart';

/// Small square thumbnail for a hostel card. Shows the first photo if
/// the hostel has one, otherwise a generic home icon. Used in list
/// cards, dashboard tiles, and saved-hostel cards so every surface
/// renders consistently.
class HostelThumbnail extends StatelessWidget {
  final List<String> photos;
  final double size;
  final double radius;
  final double iconSize;

  const HostelThumbnail({
    super.key,
    required this.photos,
    this.size = 60,
    this.radius = 12,
    this.iconSize = 28,
  });

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photos.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: maroon.withValues(alpha: 0.12),
        child: hasPhoto
            ? Image.network(
          photos.first,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(maroon),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Icon(
            Icons.broken_image_outlined,
            color: maroon.withValues(alpha: 0.4),
            size: iconSize,
          ),
        )
            : Icon(
          Icons.home_work_outlined,
          color: maroon,
          size: iconSize,
        ),
      ),
    );
  }
}