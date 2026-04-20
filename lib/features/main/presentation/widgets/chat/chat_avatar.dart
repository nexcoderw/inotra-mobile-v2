import "package:flutter/material.dart";

import "../../../../../core/widgets/app_cached_image.dart";

/// Circular avatar: shows network image when available, falls back to
/// a coloured gradient with initials derived from [name].
class ChatAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const ChatAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
  });

  // Deterministic gradient palette — same hashing as iOS Messages.
  static const _gradients = [
    [Color(0xFF007AFF), Color(0xFF34AADC)], // blue
    [Color(0xFF34C759), Color(0xFF30D158)], // green
    [Color(0xFFFF9F0A), Color(0xFFFF6B00)], // orange
    [Color(0xFFFF375F), Color(0xFFFF2D55)], // pink
    [Color(0xFFAF52DE), Color(0xFF5856D6)], // purple
    [Color(0xFF00C7BE), Color(0xFF30B0C7)], // teal
    [Color(0xFFFFCC00), Color(0xFFFF9500)], // yellow
    [Color(0xFFFF3A30), Color(0xFFFF6961)], // red
  ];

  List<Color> _gradient() {
    final idx = name.isEmpty ? 0 : name.hashCode.abs() % _gradients.length;
    return _gradients[idx];
  }

  String _initials() {
    final words = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return "?";
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient();
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? AppCachedImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).roundToDouble(),
                memCacheHeight: (size * 3).roundToDouble(),
                maxWidthDiskCache: (size * 4).roundToDouble(),
                maxHeightDiskCache: (size * 4).roundToDouble(),
                errorBuilder: (_) => _InitialsAvatar(
                  initials: _initials(),
                  gradient: gradient,
                  size: size,
                ),
                placeholderBuilder: (_) => _InitialsAvatar(
                  initials: _initials(),
                  gradient: gradient,
                  size: size,
                ),
              )
            : _InitialsAvatar(
                initials: _initials(),
                gradient: gradient,
                size: size,
              ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final List<Color> gradient;
  final double size;

  const _InitialsAvatar({
    required this.initials,
    required this.gradient,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
