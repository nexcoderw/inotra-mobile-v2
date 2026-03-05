import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";
import "highlight_comment.dart";

class HighlightCommentsSheet extends StatefulWidget {
  final Future<List<HighlightComment>> Function() loadComments;
  final Future<void> Function(String text) onSend;

  const HighlightCommentsSheet({
    super.key,
    required this.loadComments,
    required this.onSend,
  });

  @override
  State<HighlightCommentsSheet> createState() => _HighlightCommentsSheetState();
}

class _HighlightCommentsSheetState extends State<HighlightCommentsSheet> {
  bool _loading = true;
  bool _sending = false;
  List<HighlightComment> _comments = const [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final data = await widget.loadComments();
    if (mounted) {
      setState(() {
        _comments = data;
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _sending = true);
    await widget.onSend(text);
    setState(() => _sending = false);
    await _fetch();
    // Scroll to bottom after new comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height;
    final sheetMaxHeight = (maxH * 0.80).clamp(360.0, 740.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: BoxConstraints(maxHeight: sheetMaxHeight),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surface.withValues(alpha: 0.60)
                    : scheme.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.07),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    title: t(lang, "highlights.comments"),
                    count: _loading ? null : _comments.length,
                    loading: _loading && _comments.isNotEmpty,
                    scheme: scheme,
                    onClose: () => Navigator.of(context).maybePop(),
                    onRefresh: (_loading || _sending) ? null : _fetch,
                  ),
                  Expanded(
                    child: _loading && _comments.isEmpty
                        ? const _CommentSkeleton()
                        : _comments.isEmpty
                            ? _EmptyState(lang: lang, scheme: scheme)
                            : _CommentList(
                                comments: _comments,
                                lang: lang,
                                scheme: scheme,
                                scrollController: _scrollController,
                              ),
                  ),
                  _Divider(scheme: scheme),
                  _ComposerBar(
                    controller: _controller,
                    hint: t(lang, "highlights.static"),
                    enabled: !_loading && !_sending,
                    sending: _sending,
                    onSend: (_loading || _sending) ? null : _send,
                    scheme: scheme,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── Header ───────────────────────── */

class _SheetHeader extends StatelessWidget {
  final String title;
  final int? count;
  final bool loading;
  final ColorScheme scheme;
  final VoidCallback onClose;
  final VoidCallback? onRefresh;

  const _SheetHeader({
    required this.title,
    required this.count,
    required this.loading,
    required this.scheme,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (count != null && count! > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$count",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (loading) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRefresh != null)
                _IconBtn(
                  icon: HugeIcons.strokeRoundedRefresh,
                  scheme: scheme,
                  onTap: onRefresh!,
                ),
              _IconBtn(
                icon: HugeIcons.strokeRoundedCancel01,
                scheme: scheme,
                onTap: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: HugeIcon(
          icon: icon,
          size: 18,
          strokeWidth: 2,
          color: scheme.onSurface.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

/* ───────────────────────── Divider ───────────────────────── */

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  const _Divider({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.onSurface.withValues(alpha: 0.07),
    );
  }
}

/* ───────────────────────── Skeleton ───────────────────────── */

class _CommentSkeleton extends StatefulWidget {
  const _CommentSkeleton();

  @override
  State<_CommentSkeleton> createState() => _CommentSkeletonState();
}

class _CommentSkeletonState extends State<_CommentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fade,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (_, i) => _SkeletonRow(
          scheme: scheme,
          // Vary widths for realistic feel
          nameWidth: 60.0 + (i % 3) * 28.0,
          lineWidths: [
            100.0 + (i * 37.0) % 80.0,
            if (i % 2 == 0) 60.0 + (i * 19.0) % 50.0,
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final ColorScheme scheme;
  final double nameWidth;
  final List<double> lineWidths;

  const _SkeletonRow({
    required this.scheme,
    required this.nameWidth,
    required this.lineWidths,
  });

  @override
  Widget build(BuildContext context) {
    final base = scheme.onSurface.withValues(alpha: 0.10);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar skeleton
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Container(
                width: nameWidth,
                height: 11,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 7),
              // Text lines
              ...lineWidths.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Container(
                    width: w,
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ───────────────────────── Empty State ───────────────────────── */

class _EmptyState extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;

  const _EmptyState({required this.lang, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMessage02,
                size: 28,
                strokeWidth: 1.8,
                color: scheme.primary.withValues(alpha: 0.60),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t(lang, "common.empty"),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Comment List ───────────────────────── */

class _CommentList extends StatelessWidget {
  final List<HighlightComment> comments;
  final String lang;
  final ColorScheme scheme;
  final ScrollController scrollController;

  const _CommentList({
    required this.comments,
    required this.lang,
    required this.scheme,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: comments.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 10),
        color: scheme.onSurface.withValues(alpha: 0.06),
      ),
      itemBuilder: (_, i) => _CommentRow(
        author: comments[i].author ?? t(lang, "auth.anonymous"),
        text: comments[i].text ?? "",
        scheme: scheme,
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String author;
  final String text;
  final ColorScheme scheme;

  const _CommentRow({
    required this.author,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _initials(author);

    // Deterministic color from author name
    final hue = (author.codeUnits.fold(0, (a, b) => a + b) * 137) % 360;
    final avatarColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.55, isDark ? 0.45 : 0.55).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: avatarColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return "?";
  if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
  return "${parts.first.characters.first}${parts[1].characters.first}".toUpperCase();
}

/* ───────────────────────── Composer Bar ───────────────────────── */

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool sending;
  final VoidCallback? onSend;
  final ColorScheme scheme;
  final bool isDark;

  const _ComposerBar({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.scheme,
    required this.isDark,
  });

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? widget.scheme.primary.withValues(alpha: 0.40)
        : widget.scheme.onSurface.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: widget.scheme.onSurface.withValues(
                    alpha: widget.isDark ? 0.08 : 0.05,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.scheme.onSurface.withValues(alpha: 0.92),
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.scheme.onSurface.withValues(alpha: 0.38),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 44,
              height: 44,
              child: widget.sending
                  ? Container(
                      decoration: BoxDecoration(
                        color: widget.scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: (_hasText && widget.onSend != null) ? widget.onSend : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: widget.scheme.primary,
                        disabledBackgroundColor:
                            widget.scheme.primary.withValues(alpha: 0.28),
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSent,
                        size: 18,
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

