import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/observers/audit_route_observer.dart";
import "../../../../core/widgets/app_cached_image.dart";

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

class _ListingImagePreviewState extends State<ListingImagePreview>
    with WidgetsBindingObserver, RouteAware {
  late final PageController _controller;
  late int _index;

  Timer? _auto;
  Timer? _resumeAutoDebounce;
  ModalRoute<dynamic>? _route;
  bool _isAppInForeground = true;
  bool _isRouteVisible = true;

  List<String> get _images =>
      widget.images.where((e) => e.trim().isNotEmpty).toList();

  bool get _hasMany => _images.length > 1;
  bool get _canAutoPlay => _isAppInForeground && _isRouteVisible && _hasMany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final safeCount = _images.isNotEmpty ? _images.length : 1;
    _index = widget.initialIndex.clamp(0, safeCount - 1);
    _controller = PageController(initialPage: _index);

    _syncAutoState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _route)) return;

    AuditRouteObserver.instance.unsubscribe(this);
    _route = route;
    AuditRouteObserver.instance.subscribe(this, route as dynamic);
    _isRouteVisible = route.isCurrent;
    _syncAutoState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    _syncAutoState();
  }

  void _startAuto() {
    _auto?.cancel();
    _resumeAutoDebounce?.cancel();
    if (!_canAutoPlay) {
      _auto = null;
      return;
    }

    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_canAutoPlay) return;
      final next = (_index + 1) % _images.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAuto({bool resumeLater = true}) {
    _auto?.cancel();
    _auto = null;
    _resumeAutoDebounce?.cancel();

    if (resumeLater && _canAutoPlay) {
      _resumeAutoDebounce = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        _startAuto();
      });
    }
  }

  void _syncAutoState() {
    if (_canAutoPlay) {
      _startAuto();
      return;
    }
    _auto?.cancel();
    _auto = null;
    _resumeAutoDebounce?.cancel();
    _resumeAutoDebounce = null;
  }

  @override
  void didPush() {
    _isRouteVisible = true;
    _syncAutoState();
  }

  @override
  void didPopNext() {
    _isRouteVisible = true;
    _syncAutoState();
  }

  @override
  void didPushNext() {
    _isRouteVisible = false;
    _syncAutoState();
  }

  @override
  void didPop() {
    _isRouteVisible = false;
    _syncAutoState();
  }

  void _goTo(int page) {
    if (!_hasMany) return;
    _stopAuto();
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _prev() => _goTo((_index - 1 + _images.length) % _images.length);
  void _next() => _goTo((_index + 1) % _images.length);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuditRouteObserver.instance.unsubscribe(this);
    _auto?.cancel();
    _resumeAutoDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final images = _images.isNotEmpty ? _images : const [""];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(14),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {}, // prevent tap-through
        child: _GlassSheet(
          borderRadius: 26,
          child: Stack(
            children: [
              // Content
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Listener(
                  onPointerDown: (_) => _stopAuto(),
                  onPointerSignal: (_) => _stopAuto(),
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final url = images[i].trim();
                      if (url.isEmpty) return _Placeholder(scheme: scheme);

                      return Container(
                        color: Colors.black.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: InteractiveViewer(
                          clipBehavior: Clip.hardEdge,
                          minScale: 1,
                          maxScale: 4,
                          panEnabled: true,
                          scaleEnabled: true,
                          child: AppCachedImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            memCacheWidth: 1800,
                            memCacheHeight: 1400,
                            maxWidthDiskCache: 2400,
                            maxHeightDiskCache: 1800,
                            errorBuilder: (_) => _Placeholder(scheme: scheme),
                            placeholderBuilder: (_) =>
                                _Placeholder(scheme: scheme),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Top glass bar
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: _GlassBar(
                  child: Row(
                    children: [
                      _GlassIconButton(
                        tooltip: "Close",
                        icon: HugeIcons.strokeRoundedCancel02,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasMany
                              ? "Image ${_index + 1} of ${images.length}"
                              : "Image preview",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.92),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // Optional slot (e.g., share/download). Keep or remove.
                      // _GlassIconButton(
                      //   tooltip: "Share",
                      //   icon: HugeIcons.strokeRoundedShare05,
                      //   onTap: () {},
                      // ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _GlassBar(
                  child: Row(
                    children: [
                      if (_hasMany)
                        _GlassIconButton(
                          tooltip: "Previous",
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          onTap: _prev,
                        )
                      else
                        const SizedBox(width: 44),

                      const SizedBox(width: 8),
                      Expanded(
                        child: _Dots(count: images.length, index: _index),
                      ),
                      const SizedBox(width: 8),

                      if (_hasMany)
                        _GlassIconButton(
                          tooltip: "Next",
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          onTap: _next,
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass container used for the whole dialog body
class _GlassSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const _GlassSheet({required this.child, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: scheme.surface.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.30),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass bar used for top/bottom overlay controls
class _GlassBar extends StatelessWidget {
  final Widget child;
  const _GlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final String tooltip;
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: HugeIcon(
            icon: icon,
            color: scheme.onSurface.withOpacity(0.92),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: i == index ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: i == index
                ? Colors.white.withOpacity(0.92)
                : Colors.white.withOpacity(0.32),
          ),
        ),
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
      color: scheme.surfaceVariant.withOpacity(0.40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            color: scheme.onSurface.withOpacity(0.70),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            "Image unavailable",
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
