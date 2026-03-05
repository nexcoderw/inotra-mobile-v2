import "package:flutter/material.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvSkeleton — animated shimmer placeholder while messages load
// ─────────────────────────────────────────────────────────────────────────────

class ConvSkeleton extends StatefulWidget {
  const ConvSkeleton({super.key});

  @override
  State<ConvSkeleton> createState() => _ConvSkeletonState();
}

class _ConvSkeletonState extends State<ConvSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final base = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final glow = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = LinearGradient(
          begin: Alignment(-2.0 + _anim.value * 4, 0),
          end: Alignment(-1.0 + _anim.value * 4, 0),
          colors: [base, glow, base],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkeletonBubble(shimmer: shimmer, isMine: false, widthFactor: 0.62),
              const SizedBox(height: 3),
              _SkeletonBubble(shimmer: shimmer, isMine: false, widthFactor: 0.44),
              const SizedBox(height: 12),
              _SkeletonBubble(shimmer: shimmer, isMine: true, widthFactor: 0.50),
              const SizedBox(height: 3),
              _SkeletonBubble(shimmer: shimmer, isMine: true, widthFactor: 0.66),
              const SizedBox(height: 12),
              _SkeletonBubble(shimmer: shimmer, isMine: false, widthFactor: 0.55),
              const SizedBox(height: 12),
              _SkeletonBubble(shimmer: shimmer, isMine: true, widthFactor: 0.38),
              const SizedBox(height: 3),
              _SkeletonBubble(shimmer: shimmer, isMine: true, widthFactor: 0.58),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonBubble — a single shimmer bubble row
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBubble extends StatelessWidget {
  final Gradient shimmer;
  final bool isMine;
  final double widthFactor; // fraction of screen width

  const _SkeletonBubble({
    required this.shimmer,
    required this.isMine,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            // Avatar placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: shimmer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Bubble placeholder
          Container(
            height: 38,
            width: screenW * widthFactor,
            decoration: BoxDecoration(
              gradient: shimmer,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConvEmptyState / ConvErrorState — inline feedback states
// ─────────────────────────────────────────────────────────────────────────────

class ConvEmptyState extends StatelessWidget {
  final String lang;
  const ConvEmptyState({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Import t() inline to avoid circular deps — use the key directly via
    // a local fallback. The caller passes the lang string so we import t.
    // We keep this self-contained by not importing translations here — the
    // caller should wrap with an appropriate message. For now, hardcode.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withValues(alpha: 0.10),
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 30,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No messages yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Send a message to start the conversation.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.42),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConvErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ConvErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 38, color: scheme.error),
            const SizedBox(height: 14),
            Text(
              "Couldn't load messages",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text(
                "Try again",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
