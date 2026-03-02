import "dart:async";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class ListingImagePreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ListingImagePreview({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ListingImagePreview> createState() => _ListingImagePreviewState();
}

class _ListingImagePreviewState extends State<ListingImagePreview> {
  late final PageController _controller;
  late int _index;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, (widget.images.length - 1).clamp(0, 999));
    _controller = PageController(initialPage: _index);
    _startAuto();
  }

  void _startAuto() {
    _auto?.cancel();
    if (widget.images.length <= 1) return;
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_index + 1) % widget.images.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = widget.images.isNotEmpty ? widget.images : [""];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final url = images[i].trim();
                if (url.isEmpty) {
                  return _Placeholder(scheme: scheme);
                }
                return InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _Placeholder(scheme: scheme),
                    loadingBuilder: (_, child, evt) =>
                        evt == null ? child : _Placeholder(scheme: scheme),
                  ),
                );
              },
            ),
          ),

          // Top controls
          Positioned(
            right: 10,
            top: 10,
            child: Material(
              color: Colors.black.withOpacity(0.35),
              shape: const CircleBorder(),
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedX,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),

          // Dots
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _index == i ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _index == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;
  const _Placeholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.7),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }
}
