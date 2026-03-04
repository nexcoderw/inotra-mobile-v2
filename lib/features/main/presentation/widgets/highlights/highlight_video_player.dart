import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:video_player/video_player.dart";

class HighlightVideoPlayer extends StatefulWidget {
  final String url;
  final bool isActive;

  const HighlightVideoPlayer({
    super.key,
    required this.url,
    required this.isActive,
  });

  @override
  State<HighlightVideoPlayer> createState() => _HighlightVideoPlayerState();
}

class _HighlightVideoPlayerState extends State<HighlightVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true;
  bool _showPlayPauseOverlay = false;
  bool _userPaused = false;
  Timer? _overlayTimer;
  late final AnimationController _overlayAnim;

  @override
  void initState() {
    super.initState();
    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(0.0);
      if (mounted) {
        setState(() => _initialized = true);
        if (widget.isActive && !_userPaused) {
          _controller.play();
        }
      }
    } catch (_) {
      // Failed to initialize — leave _initialized false to show fallback
    }
  }

  @override
  void didUpdateWidget(covariant HighlightVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) return;

    if (widget.isActive && !oldWidget.isActive && !_userPaused) {
      _controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _overlayAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_initialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _userPaused = true;
      } else {
        _controller.play();
        _userPaused = false;
      }
      _showPlayPauseOverlay = true;
    });

    _overlayAnim.forward(from: 0);
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _overlayAnim.reverse().then((_) {
          if (mounted) setState(() => _showPlayPauseOverlay = false);
        });
      }
    });
  }

  void _toggleMute() {
    if (!_initialized) return;
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    final s = d.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),

          // Play/Pause overlay (animated)
          if (_showPlayPauseOverlay)
            Center(
              child: FadeTransition(
                opacity: _overlayAnim,
                child: _GlassCircle(
                  size: 64,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),

          // Mute button (top-left, below safe area)
          Positioned(
            top: 52,
            left: 14,
            child: GestureDetector(
              onTap: _toggleMute,
              child: _GlassPill(
                child: HugeIcon(
                  icon: _muted
                      ? HugeIcons.strokeRoundedVolumeOff
                      : HugeIcons.strokeRoundedVolumeHigh,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Seek slider + time (bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _VideoSeekBar(controller: _controller, formatDuration: _formatDuration),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Seek Bar ----------------------------- */

class _VideoSeekBar extends StatefulWidget {
  final VideoPlayerController controller;
  final String Function(Duration) formatDuration;

  const _VideoSeekBar({required this.controller, required this.formatDuration});

  @override
  State<_VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<_VideoSeekBar> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (!_dragging && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final duration = value.duration;
    final position = value.position;
    final totalMs = duration.inMilliseconds.toDouble();
    final currentMs = _dragging ? _dragValue : position.inMilliseconds.toDouble();
    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.40),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.25),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.15),
                ),
                child: Slider(
                  value: progress,
                  onChangeStart: (v) {
                    _dragging = true;
                    _dragValue = v * totalMs;
                  },
                  onChanged: (v) {
                    setState(() => _dragValue = v * totalMs);
                  },
                  onChangeEnd: (v) {
                    _dragging = false;
                    widget.controller.seekTo(Duration(milliseconds: (v * totalMs).round()));
                  },
                ),
              ),
              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.formatDuration(
                        _dragging ? Duration(milliseconds: _dragValue.round()) : position,
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.formatDuration(duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Glass Widgets ----------------------------- */

class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;

  const _GlassCircle({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}
