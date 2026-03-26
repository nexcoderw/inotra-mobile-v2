// Shared data models for the chat conversation feature.
// These are intentionally public so all sub-components can reference them.

enum ShareTab { events, listings, packages }

// ─────────────────────────────────────────────────────────────────────────────
// SharedItem — a piece of content (event / listing / package) attached to a message
// ─────────────────────────────────────────────────────────────────────────────

class SharedItem {
  final String type; // "EVENT" | "LISTING" | "PACKAGE"
  final String id;
  final String? title;

  const SharedItem({required this.type, required this.id, this.title});

  factory SharedItem.fromJson(Map<String, dynamic> json) => SharedItem(
        type: (json["type"] ?? "").toString().toUpperCase(),
        id: (json["id"] ?? "").toString(),
        title: json["title"]?.toString(),
      );

  Map<String, String?> toSendBody() => {
        if (type == "EVENT") "shared_event_id": id,
        if (type == "LISTING") "shared_listing_id": id,
        if (type == "PACKAGE") "shared_package_id": id,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ConvMessage — a single chat message
// ─────────────────────────────────────────────────────────────────────────────

class ConvMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final SharedItem? shared;
  final bool pending;
  final bool failed;
  final String senderType; // "USER" | "AI" | "HUMAN" | "SYSTEM"
  final Map<String, dynamic> metadata;

  const ConvMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.shared,
    this.pending = false,
    this.failed = false,
    this.senderType = "",
    this.metadata = const {},
  });

  ConvMessage copyWith({bool? pending, bool? failed}) => ConvMessage(
        id: id,
        text: text,
        createdAt: createdAt,
        isMine: isMine,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        shared: shared,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        senderType: senderType,
        metadata: metadata,
      );

  factory ConvMessage.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    String? authorId;
    String? authorName;
    String? authorAvatarUrl;
    final sender = json["sender"];
    if (sender is Map) {
      authorId = sender["id"]?.toString();
      authorName = (sender["name"] ?? sender["full_name"] ?? sender["username"])?.toString();
      authorAvatarUrl = sender["avatar_url"]?.toString();
    }

    SharedItem? shared;
    final sharedRaw = json["shared"];
    if (sharedRaw is Map) {
      shared = SharedItem.fromJson(Map<String, dynamic>.from(sharedRaw));
    }

    final senderType = (json["sender_type"] ?? "").toString().toUpperCase();

    // For HUMAN messages (rep), prefer user_lang_text (translated into the user's language).
    final userLangText = (json["user_lang_text"] ?? "").toString().trim();
    final sourceText = (json["source_text"] ?? json["text"] ?? json["content"] ?? json["body"] ?? "").toString();
    final text = (senderType == "HUMAN" && userLangText.isNotEmpty) ? userLangText : sourceText;

    Map<String, dynamic> metadata = const {};
    final rawMeta = json["metadata"];
    if (rawMeta is Map) {
      metadata = Map<String, dynamic>.from(rawMeta);
    }

    return ConvMessage(
      id: (json["id"] ?? "").toString(),
      text: text,
      createdAt: tryParse(
            (json["created_at"] ?? json["timestamp"] ?? json["sent_at"])?.toString(),
          ) ??
          DateTime.now(),
      isMine: json["is_mine"] as bool? ?? false,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      shared: shared,
      senderType: senderType,
      metadata: metadata,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ShareOption — a search result item in the share picker
// ─────────────────────────────────────────────────────────────────────────────

class ShareOption {
  final String id;
  final String title;
  final String? subtitle;
  final ShareTab tab;

  const ShareOption({
    required this.id,
    required this.title,
    this.subtitle,
    required this.tab,
  });
}
