/// A single notification — sourced from the backend API and persisted locally.
class AppNotification {
  final String id;
  final String kind;       // "PLACE" | "EVENT" | "PACKAGE"
  final String entityId;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:        json["id"] as String,
      kind:      json["kind"] as String,
      entityId:  json["entity_id"] as String,
      title:     json["title"] as String,
      body:      json["body"] as String? ?? "",
      imageUrl:  json["image_url"] as String?,
      createdAt: DateTime.tryParse(json["created_at"] as String? ?? "") ?? DateTime.now(),
      isRead:    json["is_read"] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "id":         id,
        "kind":       kind,
        "entity_id":  entityId,
        "title":      title,
        "body":       body,
        "image_url":  imageUrl,
        "created_at": createdAt.toIso8601String(),
        "is_read":    isRead,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id:        id,
        kind:      kind,
        entityId:  entityId,
        title:     title,
        body:      body,
        imageUrl:  imageUrl,
        createdAt: createdAt,
        isRead:    isRead ?? this.isRead,
      );
}
