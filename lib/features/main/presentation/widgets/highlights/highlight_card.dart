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
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meta,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
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
                icon: liked ? HugeIcons.strokeRoundedHeart : HugeIcons.strokeRoundedHeart01,
                color: liked ? Colors.redAccent : Colors.white,
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
                icon: HugeIcons.strokeRoundedSend01,
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
  final HugeIcons icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: HugeIcon(
              icon: icon,
              size: 24,
              strokeWidth: 2,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
