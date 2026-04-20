import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "../../../../../core/widgets/app_cached_image.dart";
import "highlight_video_player.dart";

class HighlightMediaItem {
  final String url;
  final bool isVideo;
  const HighlightMediaItem({required this.url, required this.isVideo});
}

class HighlightCard extends StatefulWidget {
  final String? imageUrl;
  final List<HighlightMediaItem> mediaItems;
  final String title;
  final String? meta;
  final String? entityName;
  final bool liked;
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool expandedCaption;
  final VoidCallback onCaptionTap;
  final bool isActive;

  const HighlightCard({
    super.key,
    required this.imageUrl,
    this.mediaItems = const [],
    required this.title,
    this.meta,
    this.entityName,
    required this.liked,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.expandedCaption,
    required this.onCaptionTap,
    this.isActive = true,
  });

  @override
  State<HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  int _currentPage = 0;
  late final PageController _mediaPageController;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  List<HighlightMediaItem> get _effectiveMedia {
    if (widget.mediaItems.isNotEmpty) return widget.mediaItems;
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) {
      return [HighlightMediaItem(url: widget.imageUrl!, isVideo: false)];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = _effectiveMedia;
    final hasMultiple = media.length > 1;
    final currentIsVideo = media.isNotEmpty && media[_currentPage].isVideo;
    final infoBottom = currentIsVideo ? 64.0 : 14.0;
    final dotsBottom = currentIsVideo ? 148.0 : 100.0;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Stack(
        children: [
          // Media (carousel or single)
          Positioned.fill(
            child: hasMultiple
                ? PageView.builder(
                    controller: _mediaPageController,
                    itemCount: media.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _MediaSlide(
                      item: media[i],
                      scheme: scheme,
                      isActive: widget.isActive && _currentPage == i,
                    ),
                  )
                : media.isNotEmpty
                ? _MediaSlide(
                    item: media.first,
                    scheme: scheme,
                    isActive: widget.isActive,
                  )
                : Container(
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      size: 42,
                    ),
                  ),
          ),

          // Subtle overall vignette
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Counter pill (top right) — Instagram style "1/5"
          if (hasMultiple)
            Positioned(
              top: 52,
              right: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      "${_currentPage + 1}/${media.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            offset: Offset(0, 2),
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Dots indicator (center bottom area, above caption)
          if (hasMultiple)
            Positioned(
              left: 0,
              right: 0,
              bottom: dotsBottom,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          media.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _currentPage == i ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
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
                  icon: widget.liked
                      ? HugeIcons.strokeRoundedHeartCheck
                      : HugeIcons.strokeRoundedHeartAdd,
                  selected: widget.liked,
                  label: "${widget.likes}",
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 14),
                _ActionButton(
                  icon: HugeIcons.strokeRoundedMessage02,
                  label: "${widget.comments}",
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 14),
                _ActionButton(
                  icon: HugeIcons.strokeRoundedShare08,
                  label: "${widget.shares}",
                  onTap: widget.onShare,
                ),
                const SizedBox(height: 14),
                _ViewCount(views: widget.views),
              ],
            ),
          ),

          // Bottom info area (caption + optional place/event)
          Positioned(
            left: 14,
            right: 78,
            bottom: infoBottom,
            child: _BottomInfo(
              title: widget.title,
              meta: widget.meta,
              entityName: widget.entityName,
              expanded: widget.expandedCaption,
              onTap: widget.onCaptionTap,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Media Slide ----------------------------- */

class _MediaSlide extends StatelessWidget {
  final HighlightMediaItem item;
  final ColorScheme scheme;
  final bool isActive;

  const _MediaSlide({
    required this.item,
    required this.scheme,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return HighlightVideoPlayer(url: item.url, isActive: isActive);
    }

    return AppCachedImage(
      imageUrl: item.url,
      fit: BoxFit.cover,
      memCacheWidth: 1100,
      memCacheHeight: 1600,
      maxWidthDiskCache: 1400,
      maxHeightDiskCache: 1800,
      errorBuilder: (_) => _mediaFallback(),
      placeholderBuilder: (_) => _mediaFallback(),
    );
  }

  Widget _mediaFallback() {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        color: scheme.onSurface.withValues(alpha: 0.5),
        size: 42,
      ),
    );
  }
}

/* ----------------------------- Bottom Info ----------------------------- */

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
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.42),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
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
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
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
                      overflow: expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
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
  final parts = name
      .trim()
      .split(RegExp(r"\s+"))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return "";
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  final first = parts.first.characters.first;
  final second = parts[1].characters.first;
  return "$first$second".toUpperCase();
}

/* ----------------------------- View Count ----------------------------- */

String _formatCount(int n) {
  if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
  if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
  return "$n";
}

class _ViewCount extends StatelessWidget {
  final int views;
  const _ViewCount({required this.views});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedEye,
                size: 18,
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatCount(views),
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
    );
  }
}

/* ----------------------------- Action Button ----------------------------- */

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
    final iconColor = selected ? Colors.redAccent : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
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
