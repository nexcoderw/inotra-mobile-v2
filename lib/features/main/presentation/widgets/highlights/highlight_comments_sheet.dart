import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";
import "package:inotra/core/config/app_routes.dart";
import "package:inotra/core/services/auth_session.dart";
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
  bool _loading = false;
  List<HighlightComment> _comments = const [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
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
    await widget.onSend(text);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    // ✅ flexible height for all screens (small phones -> tablets)
    final maxH = MediaQuery.of(context).size.height;
    final sheetMaxHeight = (maxH * 0.78).clamp(360.0, 720.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: BoxConstraints(maxHeight: sheetMaxHeight),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                // ✅ main surface: no border, no shadow, no gradient
                color: scheme.surface.withOpacity(isDark ? 0.55 : 0.82),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ easy close: drag handle + close button
                  Container(
                    width: 46,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2, bottom: 10),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(lang, "highlights.title"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withOpacity(0.95),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Close",
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: scheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                      IconButton(
                        tooltip: "Refresh",
                        onPressed: _loading ? null : _fetch,
                        icon: _loading
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: scheme.onSurface.withOpacity(0.75),
                              ),
                      ),
                    ],
                  ),

                  if (_loading && _comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                        color: scheme.primary,
                        backgroundColor: scheme.onSurface.withOpacity(0.08),
                        minHeight: 2,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ✅ flexible list: expands to fill available space
                  Expanded(
                    child: _comments.isNotEmpty
                        ? ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _comments.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 14,
                              thickness: 1,
                              color: scheme.onSurface.withOpacity(0.08),
                            ),
                            itemBuilder: (_, i) => _CommentRow(
                              author: _comments[i].author ?? t(lang, "auth.anonymous"),
                              text: _comments[i].text ?? "",
                            ),
                          )
                        : (!_loading)
                            ? Center(
                                child: Text(
                                  t(lang, "common.empty"),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface.withOpacity(0.70),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 12),

                  // ✅ composer (flexible + premium, still same logic)
                  _ComposerBar(
                    controller: _controller,
                    hint: t(lang, "highlights.static"),
                    enabled: !_loading,
                    onSend: _loading ? null : _send,
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

class _CommentRow extends StatelessWidget {
  final String author;
  final String text;

  const _CommentRow({
    required this.author,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(isDark ? 0.42 : 0.70),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              size: 16,
              strokeWidth: 2,
              // ✅ icon adapts by theme: dark -> white, light -> primary
              color: isDark ? Colors.white : scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.94),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.25,
                  color: scheme.onSurface.withOpacity(0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final VoidCallback? onSend;

  const _ComposerBar({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = _focused
        ? scheme.primary.withOpacity(0.30)
        : scheme.onSurface.withOpacity(0.10);

    return Row(
      children: [
        Expanded(
          child: Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(isDark ? 0.45 : 0.70),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withOpacity(0.92),
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ✅ send button: circular, no shadow, theme-safe
        SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onSend,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.send_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}
