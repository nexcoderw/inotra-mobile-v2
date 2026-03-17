final class AuditEndpoints {
  AuditEndpoints._();

  /// POST /api/audit/track/
  /// Body: { action, entity_type?, entity_id?, entity_label?, description?, metadata? }
  static const track = "api/audit/track/";
}
