import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../../../core/config/api.dart";
import "../../../../../../core/constants/api/event_endpoints.dart";
import "../../../../../../core/constants/api/package_endpoints.dart";
import "../../../../../../core/constants/api/place_endpoints.dart";
import "../../../../../../i18n/translations.dart";
import "models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvSharePickerSheet — DraggableScrollableSheet to pick an item to share
// Returns SharedItem via Navigator.pop on selection
// ─────────────────────────────────────────────────────────────────────────────

class ConvSharePickerSheet extends StatefulWidget {
  final String lang;
  final String accessToken;

  const ConvSharePickerSheet({
    super.key,
    required this.lang,
    required this.accessToken,
  });

  @override
  State<ConvSharePickerSheet> createState() => _ConvSharePickerSheetState();
}

class _ConvSharePickerSheetState extends State<ConvSharePickerSheet> {
  ShareTab _tab = ShareTab.events;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ShareOption> _options = [];
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadOptions("");
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadOptions(_searchCtrl.text.trim());
    });
  }

  Future<void> _loadOptions(String query) async {
    if (!mounted) return;
    setState(() {
      _fetching = true;
      _options = [];
    });

    try {
      final String endpoint;
      switch (_tab) {
        case ShareTab.events:
          endpoint = EventEndpoints.list;
          break;
        case ShareTab.listings:
          endpoint = PlaceEndpoints.list;
          break;
        case ShareTab.packages:
          endpoint = PackageEndpoints.list;
          break;
      }

      final params = {
        "page": "1",
        "page_size": "12",
        "ordering": "created_at",
        "sort": "desc",
        if (query.isNotEmpty) "search": query,
      };

      final uri = Api.url(endpoint).replace(queryParameters: params);
      final resp = await http.get(uri, headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${widget.accessToken}",
      });

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        if (decoded is Map) {
          raw = (decoded["results"] as List?) ?? const [];
        } else if (decoded is List) {
          raw = decoded;
        }

        final opts = raw.whereType<Map>().map((item) {
          final map = Map<String, dynamic>.from(item);
          final id = (map["id"] ?? "").toString();
          final title = (map["name"] ?? map["title"] ?? id).toString();
          final subtitle =
              (map["location"] ?? map["address"] ?? map["description"])
                  ?.toString();
          return ShareOption(id: id, title: title, subtitle: subtitle, tab: _tab);
        }).toList();

        setState(() {
          _options = opts;
          _fetching = false;
        });
      } else {
        if (mounted) setState(() => _fetching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _switchTab(ShareTab tab) {
    if (_tab == tab) return;
    _searchCtrl.clear();
    setState(() {
      _tab = tab;
      _options = [];
    });
    _loadOptions("");
  }

  String get _sharedType {
    switch (_tab) {
      case ShareTab.events:
        return "EVENT";
      case ShareTab.listings:
        return "LISTING";
      case ShareTab.packages:
        return "PACKAGE";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final lang = widget.lang;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.65, 0.92],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      t(lang, "chat.share_title"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.07),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.60),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tab chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _TabChip(
                      label: t(lang, "chat.share_events"),
                      active: _tab == ShareTab.events,
                      onTap: () => _switchTab(ShareTab.events),
                      isDark: isDark,
                      scheme: scheme,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: t(lang, "chat.share_listings"),
                      active: _tab == ShareTab.listings,
                      onTap: () => _switchTab(ShareTab.listings),
                      isDark: isDark,
                      scheme: scheme,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: t(lang, "chat.share_packages"),
                      active: _tab == ShareTab.packages,
                      onTap: () => _switchTab(ShareTab.packages),
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.7,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 14.5, color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: t(lang, "chat.share_search_hint"),
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 14.5,
                      ),
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.38),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Results
              Expanded(
                child: _fetching
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF007AFF),
                        ),
                      )
                    : _options.isEmpty
                        ? Center(
                            child: Text(
                              t(lang, "chat.share_no_results"),
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface.withValues(alpha: 0.40),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 28),
                            itemCount: _options.length,
                            itemBuilder: (context, index) {
                              final opt = _options[index];
                              return _ShareOptionTile(
                                option: opt,
                                isDark: isDark,
                                scheme: scheme,
                                onTap: () => Navigator.of(context).pop(
                                  SharedItem(
                                    type: _sharedType,
                                    id: opt.id,
                                    title: opt.title,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabChip
// ─────────────────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF007AFF)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF007AFF)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.09)),
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? Colors.white
                : scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShareOptionTile
// ─────────────────────────────────────────────────────────────────────────────

class _ShareOptionTile extends StatelessWidget {
  final ShareOption option;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.option,
    required this.isDark,
    required this.scheme,
    required this.onTap,
  });

  dynamic _icon() {
    switch (option.tab) {
      case ShareTab.events:
        return HugeIcons.strokeRoundedCalendar03;
      case ShareTab.packages:
        return HugeIcons.strokeRoundedLuggage01;
      default:
        return HugeIcons.strokeRoundedLocation01;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: _icon(),
                  size: 20,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.28),
            ),
          ],
        ),
      ),
    );
  }
}
