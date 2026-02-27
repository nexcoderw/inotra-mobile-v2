import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class HighlightCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? meta;
  final String? entityName;
  final bool liked;
  final int likes;
  final int comments;
  final int shares;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool expandedCaption;
  final VoidCallback onCaptionTap;

  const HighlightCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.meta,
    this.entityName,
    required this.liked,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.expandedCaption,
    required this.onCaptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Stack(
        children: [
          // Media
          Positioned.fill(
            child: Image.network(
              imageUrl ?? "",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: scheme.surfaceVariant,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported,
                  color: scheme.onSurface.withOpacity(0.5),
                  size: 42,
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                final value = progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                        (progress.expectedTotalBytes ?? 1);
                return Center(child: CircularProgressIndicator(value: value));
              },
            ),
          ),

          // Subtle overall vignette (keeps the card premium on any image)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Right actions (Instagram Reel-like)
          Positioned(
            right: 14,
            bottom: 72,
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
                const SizedBox(height: 14),
                _ActionButton(
                  icon: HugeIcons.strokeRoundedMessage02,
                  label: "$comments",
                  onTap: onComment,
                ),
                const SizedBox(height: 14),
                _ActionButton(
                  icon: HugeIcons.strokeRoundedShare08,
                  label: "$shares",
                  onTap: onShare,
                ),
              ],
            ),
          ),

          // Bottom info area (caption + optional place/event)
          Positioned(
            left: 14,
            right: 78,
            bottom: 14,
            child: _BottomInfo(
              title: title,
              meta: meta,
              entityName: entityName,
              expanded: expandedCaption,
              onTap: onCaptionTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  final String title;
  final String? meta;
  final String? entityName;
  final bool expanded;
  final VoidCallback onTap;

  const _BottomInfo({
    required this.title,
    required this.meta,
    required this.entityName,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Instagram-like readability: blur + gradient + soft shadow behind text
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.10),
                Colors.black.withOpacity(0.42),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entityName != null && entityName!.isNotEmpty) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          child: Text(
                            _initials(entityName!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entityName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      title,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        shadows: [
                          Shadow(
                            blurRadius: 12,
                            offset: Offset(0, 3),
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (meta != null && meta!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      meta!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            offset: Offset(0, 3),
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return "";
  if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
  final first = parts.first.characters.first;
  final second = parts[1].characters.first;
  return "$first$second".toUpperCase();
}

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (selected ? Colors.redAccent : Colors.white);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          // Small glassy pill behind icon (clean + visible)
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                ),
                child: HugeIcon(
                  icon: icon,
                  size: 18,
                  strokeWidth: 2,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  blurRadius: 14,
                  offset: Offset(0, 3),
                  color: Colors.black87,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
