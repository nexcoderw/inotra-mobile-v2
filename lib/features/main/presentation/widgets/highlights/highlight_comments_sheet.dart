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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(lang, "highlights.title"),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _loading ? null : _fetch,
                icon: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading && _comments.isEmpty) const LinearProgressIndicator(),
          if (_comments.isNotEmpty)
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: _comments.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: 18,
                    strokeWidth: 2,
                  ),
                  title: Text(
                    _comments[i].author ?? t(lang, "auth.anonymous"),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_comments[i].text ?? ""),
                ),
              ),
            )
          else if (!_loading)
            Text(
              t(lang, "common.empty"),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t(lang, "highlights.static"),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _loading ? null : _send,
              child: const Text(
                "Send",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
