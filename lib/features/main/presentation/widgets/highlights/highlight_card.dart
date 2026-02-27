import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class HighlightCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String meta;
  final bool liked;
  final int likes;
  final int comments;
  final int shares;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const HighlightCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.meta,
    required this.liked,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : scheme.onSurface;
    final metaColor =
        isDark ? Colors.white.withOpacity(0.85) : scheme.onSurface.withOpacity(0.75);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            child: Image.network(
              imageUrl ?? "",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: scheme.surfaceVariant,
                child: Icon(
                  Icons.image_not_supported,
                  color: scheme.onSurface.withOpacity(0.5),
                  size: 42,
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes == null
                        ? null
                        : progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1),
                  ),
                );
              },
            ),
          ),
        ),

        // ❌ Removed gradient overlay completely

        Positioned(
          left: 16,
          bottom: 26,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meta,
                style: TextStyle(
                  color: metaColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: liked
                    ? HugeIcons.strokeRoundedHeartCheck
                    : HugeIcons.strokeRoundedHeartAdd,
                selected: liked,
                label: "$likes",
                onTap: onLike,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: HugeIcons.strokeRoundedMessage02,
                label: "$comments",
                onTap: onComment,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: HugeIcons.strokeRoundedShare08,
                label: "$shares",
                onTap: onShare,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = selected ? Colors.redAccent : Colors.white;
    final textColor = isDark ? Colors.white : Colors.white.withOpacity(0.9);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // ✅ Transparent container (no shadow, no dark overlay)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: HugeIcon(
              icon: icon,
              size: 18,
              strokeWidth: 2,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
