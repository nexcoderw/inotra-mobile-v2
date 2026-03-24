import "dart:async";
import "dart:convert";
import "dart:typed_data";
import "dart:ui";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/config/env.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/constants/api/place_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../../../main/presentation/widgets/page_header.dart";

const double _kPageFontSize = 12;
const TextStyle _kInputTextStyle = TextStyle(
  fontSize: _kPageFontSize,
  fontFamily: "DMSans",
  height: 1.2,
);

class MyListingFormWorkspace extends StatefulWidget {
  final bool isEditing;
  final String? listingId;
  final String? initialTitle;

  const MyListingFormWorkspace({
    super.key,
    required this.isEditing,
    this.listingId,
    this.initialTitle,
  });

  @override
  State<MyListingFormWorkspace> createState() => _MyListingFormWorkspaceState();
}

class _MyListingFormWorkspaceState extends State<MyListingFormWorkspace> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _whatsAppCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final FocusNode _addressFocusNode;

  final List<_ListingServiceDraft> _services = [];
  final List<_EditableListingImage> _existingImages = [];
  final List<_EditableListingImage> _newImages = [];
  final List<_GooglePlaceSuggestion> _addressSuggestions = [];
  final Map<String, _OpeningHoursDraft> _openingHours = _defaultOpeningHours();

  bool _busy = false;
  bool _loading = false;
  bool _loadingCategories = false;
  bool _addressLoading = false;
  bool _isApplyingAddressSelection = false;
  bool _isActive = true;
  String? _loadError;
  String _addressSessionToken = _buildPlacesSessionToken();
  Timer? _addressDebounce;

  List<_CategoryOption> _categories = const [];
  String? _selectedCategoryId;

  String get _lang => currentLangSync();
  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.value.user ?? const <String, dynamic>{};

    _nameCtrl = TextEditingController(text: widget.initialTitle ?? "");
    _descriptionCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _countryCtrl = TextEditingController(text: "Rwanda");
    _latitudeCtrl = TextEditingController();
    _longitudeCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(
      text: (user["phone_number"] ?? "").toString(),
    );
    _whatsAppCtrl = TextEditingController(
      text: (user["phone_number"] ?? "").toString(),
    );
    _emailCtrl = TextEditingController(text: (user["email"] ?? "").toString());
    _websiteCtrl = TextEditingController();
    _addressFocusNode = FocusNode();

    _services.add(_ListingServiceDraft());
    _loadCategories();

    if (_isEditing) {
      _loadListing();
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsAppCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressFocusNode.dispose();
    for (final service in _services) {
      service.dispose();
    }
    for (final hours in _openingHours.values) {
      hours.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return _StatePanel(
        icon: Icons.hourglass_top_rounded,
        title: _isEditing
            ? "Loading listing details"
            : "Preparing listing form",
        description: _isEditing
            ? "We are loading your listing so you can update it safely."
            : "Getting your listing workspace ready.",
        scheme: scheme,
      );
    }

    if (_loadError != null) {
      return _StatePanel(
        icon: Icons.cloud_off_rounded,
        title: "Unable to load listing",
        description: _loadError!,
        actionLabel: t(_lang, "common.try_again"),
        onAction: _isEditing ? _loadListing : _loadCategories,
        scheme: scheme,
      );
    }

    return Theme(
      data: _buildPageTheme(context),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: _kPageFontSize, fontFamily: "DMSans"),
        child: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                PageHeader(
                  title: _isEditing
                      ? t(_lang, "my_listings.edit_listing")
                      : t(_lang, "my_listings.add_listing"),
                  titleStyle: const TextStyle(
                    fontSize: _kPageFontSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                  ),
                ),
                const SizedBox(height: 10),
                _HeroCard(
                  isEditing: _isEditing,
                  title: _isEditing
                      ? "Refine your live listing"
                      : "Submit a premium listing",
                  subtitle: _isEditing
                      ? "Update listing content, address, hours, services, and media from one polished workspace."
                      : "Create a strong listing submission with precise location data, clear services, and premium visuals.",
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Basics",
                  icon: Icons.storefront_outlined,
                  child: Column(
                    children: [
                      _InputField(
                        label: "Listing name",
                        controller: _nameCtrl,
                        enabled: !_busy,
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return t(_lang, "auth.required_field");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _DropdownField(
                        label: "Category",
                        value: _selectedCategoryId,
                        enabled: !_busy,
                        isLoading: _loadingCategories,
                        items: _categories,
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _loadingCategories
                              ? "Loading live categories..."
                              : "Categories are suggested from currently available listings.",
                          style: TextStyle(
                            fontSize: _kPageFontSize,
                            fontFamily: "DMSans",
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: "Description",
                        controller: _descriptionCtrl,
                        enabled: !_busy,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Location",
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      _PlaceAutocompleteField(
                        label: "Address",
                        controller: _addressCtrl,
                        focusNode: _addressFocusNode,
                        enabled: !_busy,
                        isLoading: _addressLoading,
                        helperText:
                            "Start typing an address to pull real place suggestions from Google Maps.",
                        suggestions: _addressSuggestions,
                        onChanged: _onAddressChanged,
                        onSuggestionTap: _selectAddressSuggestion,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: "City",
                              controller: _cityCtrl,
                              enabled: !_busy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputField(
                              label: "Country",
                              controller: _countryCtrl,
                              enabled: !_busy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: "Latitude",
                              controller: _latitudeCtrl,
                              enabled: !_busy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputField(
                              label: "Longitude",
                              controller: _longitudeCtrl,
                              enabled: !_busy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Contact",
                  icon: Icons.phone_in_talk_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: "Phone",
                              controller: _phoneCtrl,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputField(
                              label: "WhatsApp",
                              controller: _whatsAppCtrl,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: "Email",
                              controller: _emailCtrl,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputField(
                              label: "Website",
                              controller: _websiteCtrl,
                              enabled: !_busy,
                              keyboardType: TextInputType.url,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Opening hours",
                  icon: Icons.access_time_rounded,
                  child: Column(
                    children: [
                      for (var i = 0; i < _dayDescriptors.length; i++) ...[
                        _HoursEditorRow(
                          descriptor: _dayDescriptors[i],
                          draft: _openingHours[_dayDescriptors[i].key]!,
                          enabled: !_busy,
                          onChanged: () => setState(() {}),
                        ),
                        if (i != _dayDescriptors.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Services",
                  icon: Icons.room_service_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _services.length; i++) ...[
                        _ServiceEditorCard(
                          key: ValueKey(_services[i]),
                          index: i,
                          service: _services[i],
                          enabled: !_busy,
                          onChanged: () => setState(() {}),
                          onRemove: _services.length > 1
                              ? () => _removeService(i)
                              : null,
                        ),
                        if (i != _services.length - 1)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 14),
                      _InlineSecondaryButton(
                        icon: Icons.add_rounded,
                        label: "Add service",
                        onTap: _busy ? null : _addService,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Media",
                  icon: Icons.photo_library_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ImagesDropzone(
                        onPick: _busy ? null : _pickImages,
                        imagesSelected: _visibleImageCount,
                        removalCount: _removedExistingImageCount,
                      ),
                      if (_existingImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          "Existing images",
                          style: TextStyle(
                            fontSize: _kPageFontSize,
                            fontFamily: "DMSans",
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ImagesGrid(
                          items: _existingImages,
                          allowToggleRemove: !_busy,
                          onToggleRemove: _toggleExistingImageRemoval,
                          onRemoveNew: null,
                        ),
                      ],
                      if (_newImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _isEditing
                              ? "New images to upload"
                              : "Selected images",
                          style: TextStyle(
                            fontSize: _kPageFontSize,
                            fontFamily: "DMSans",
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ImagesGrid(
                          items: _newImages,
                          allowToggleRemove: false,
                          onToggleRemove: null,
                          onRemoveNew: _removeNewImage,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "Visibility",
                    icon: Icons.verified_user_outlined,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _isActive = value),
                      title: Text(
                        "Listing is active",
                        style: TextStyle(
                          fontSize: _kPageFontSize,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        "Turn this off if you want to temporarily hide the listing from customers.",
                        style: TextStyle(
                          fontSize: _kPageFontSize,
                          fontFamily: "DMSans",
                          color: scheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _PrimarySubmitButton(
                  busy: _busy,
                  label: _isEditing ? "Save listing changes" : "Submit listing",
                  onTap: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildPageTheme(BuildContext context) {
    final base = Theme.of(context);
    final textTheme = base.textTheme;

    TextStyle normalize(
      TextStyle? style, {
      FontWeight? weight,
      double? height,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontSize: _kPageFontSize,
        fontFamily: "DMSans",
        fontWeight: weight ?? style?.fontWeight,
        height: height ?? style?.height,
      );
    }

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: normalize(textTheme.displayLarge),
        displayMedium: normalize(textTheme.displayMedium),
        displaySmall: normalize(textTheme.displaySmall),
        headlineLarge: normalize(textTheme.headlineLarge),
        headlineMedium: normalize(textTheme.headlineMedium),
        headlineSmall: normalize(textTheme.headlineSmall),
        titleLarge: normalize(textTheme.titleLarge, weight: FontWeight.w700),
        titleMedium: normalize(textTheme.titleMedium, weight: FontWeight.w700),
        titleSmall: normalize(textTheme.titleSmall, weight: FontWeight.w700),
        bodyLarge: normalize(textTheme.bodyLarge),
        bodyMedium: normalize(textTheme.bodyMedium),
        bodySmall: normalize(textTheme.bodySmall),
        labelLarge: normalize(textTheme.labelLarge, weight: FontWeight.w700),
        labelMedium: normalize(textTheme.labelMedium, weight: FontWeight.w700),
        labelSmall: normalize(textTheme.labelSmall, weight: FontWeight.w700),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: base.colorScheme.onSurface.withValues(alpha: 0.72),
        ),
        hintStyle: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: base.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        errorStyle: const TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: _kPageFontSize,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: _kPageFontSize,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: const TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() => _loadingCategories = true);
    }

    try {
      final uri = Api.url(
        PlaceEndpoints.list,
      ).replace(queryParameters: const {"page_size": "100"});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = _safeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rawResults = (body?["results"] as List?) ?? const [];
        final categories = <String, _CategoryOption>{};

        for (final item in rawResults.whereType<Map>()) {
          final map = Map<String, dynamic>.from(item);
          final id = (map["category_id"] ?? "").toString().trim();
          final name = (map["category_name"] ?? "").toString().trim();
          if (id.isEmpty || name.isEmpty) continue;
          categories.putIfAbsent(id, () => _CategoryOption(id: id, name: name));
        }

        if (!mounted) return;
        setState(() {
          _categories = categories.values.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          _loadingCategories = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loadingCategories = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  void _ensureCategoryOption(String? categoryId, String? categoryName) {
    if ((categoryId ?? "").trim().isEmpty ||
        (categoryName ?? "").trim().isEmpty) {
      return;
    }

    final id = categoryId!.trim();
    final name = categoryName!.trim();
    if (_categories.any((item) => item.id == id)) return;

    setState(() {
      _categories = [..._categories, _CategoryOption(id: id, name: name)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  Future<void> _loadListing() async {
    final listingId = widget.listingId;
    if (listingId == null || listingId.trim().isEmpty) {
      setState(() {
        _loadError = "Missing listing identifier.";
      });
      return;
    }

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      await _forceSignIn();
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      await _forceSignIn();
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final uri = Api.url(MyListingEndpoints.detail(listingId));
      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _forceSignIn();
        return;
      }

      final body = _safeJson(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body == null) {
        throw _ApiException(_extractError(body, response.statusCode));
      }

      _nameCtrl.text = (body["name"] ?? widget.initialTitle ?? "").toString();
      _descriptionCtrl.text = (body["description"] ?? "").toString();
      _addressCtrl.text = (body["address"] ?? "").toString();
      _cityCtrl.text = (body["city"] ?? "").toString();
      _countryCtrl.text =
          ((body["country"] ?? "Rwanda").toString()).trim().isEmpty
          ? "Rwanda"
          : (body["country"] ?? "Rwanda").toString();
      _latitudeCtrl.text = (body["latitude"] ?? "").toString();
      _longitudeCtrl.text = (body["longitude"] ?? "").toString();
      _phoneCtrl.text = (body["phone"] ?? "").toString();
      _whatsAppCtrl.text = (body["whatsapp"] ?? "").toString();
      _emailCtrl.text = (body["email"] ?? "").toString();
      _websiteCtrl.text = (body["website"] ?? "").toString();
      _selectedCategoryId =
          (body["category_id"] ?? "").toString().trim().isEmpty
          ? null
          : (body["category_id"] ?? "").toString();
      _isActive = body["is_active"] == true;

      _ensureCategoryOption(
        body["category_id"]?.toString(),
        body["category_name"]?.toString(),
      );

      final rawHours = body["opening_hours"];
      if (rawHours is Map) {
        for (final descriptor in _dayDescriptors) {
          final raw = rawHours[descriptor.key];
          final draft = _openingHours[descriptor.key]!;
          if (raw is Map) {
            draft.closed = false;
            draft.openCtrl.text = (raw["open"] ?? "").toString();
            draft.closeCtrl.text = (raw["close"] ?? "").toString();
          } else {
            draft.closed = true;
            draft.openCtrl.text = descriptor.defaultOpen;
            draft.closeCtrl.text = descriptor.defaultClose;
          }
        }
      }

      for (final service in _services) {
        service.dispose();
      }
      _services.clear();
      final rawServices = (body["services"] as List?) ?? const [];
      for (final raw in rawServices.whereType<Map>()) {
        _services.add(
          _ListingServiceDraft.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      if (_services.isEmpty) {
        _services.add(_ListingServiceDraft());
      }

      _existingImages
        ..clear()
        ..addAll(
          ((body["images"] as List?) ?? const []).whereType<Map>().map(
            (raw) =>
                _EditableListingImage.remote(Map<String, dynamic>.from(raw)),
          ),
        );
      _newImages.clear();

      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = null;
      });
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "We could not load this listing right now.";
      });
    }
  }

  void _onAddressChanged(String value) {
    if (_isApplyingAddressSelection) return;

    _addressDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _addressSuggestions.clear();
          _addressLoading = false;
        });
      }
      return;
    }

    _addressDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchAddressSuggestions(query),
    );
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    final apiKey = _googleMapApiKeyOrNull();
    if (apiKey == null) return;

    if (mounted) {
      setState(() => _addressLoading = true);
    }

    try {
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": query,
          "key": apiKey,
          "sessiontoken": _addressSessionToken,
          "components": "country:rw",
        },
      );

      final response = await http.get(uri);
      final body = _safeJson(response.body);
      final predictions = (body?["predictions"] as List?) ?? const [];

      if (!mounted || _addressCtrl.text.trim() != query) return;

      setState(() {
        _addressSuggestions
          ..clear()
          ..addAll(
            predictions
                .whereType<Map>()
                .map(
                  (item) => _GooglePlaceSuggestion.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
          );
        _addressLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions.clear();
        _addressLoading = false;
      });
    }
  }

  Future<void> _selectAddressSuggestion(
    _GooglePlaceSuggestion suggestion,
  ) async {
    final apiKey = _googleMapApiKeyOrNull();
    if (apiKey == null) return;

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() => _addressLoading = true);
    }

    try {
      final uri =
          Uri.https("maps.googleapis.com", "/maps/api/place/details/json", {
            "place_id": suggestion.placeId,
            "key": apiKey,
            "sessiontoken": _addressSessionToken,
            "fields": "formatted_address,geometry,address_component,name",
          });

      final response = await http.get(uri);
      final body = _safeJson(response.body);
      final result = body?["result"];
      if (result is! Map) {
        throw const _ApiException("Place details could not be loaded.");
      }

      final place = Map<String, dynamic>.from(result);
      final components =
          (place["address_components"] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          const <Map<String, dynamic>>[];

      String? componentOf(String type) {
        for (final component in components) {
          final types =
              (component["types"] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              const <String>[];
          if (types.contains(type)) {
            return component["long_name"]?.toString();
          }
        }
        return null;
      }

      final geometry = place["geometry"] as Map?;
      final location = geometry?["location"] as Map?;
      final lat = location?["lat"];
      final lng = location?["lng"];

      _isApplyingAddressSelection = true;
      _addressCtrl.text = (place["formatted_address"] ?? suggestion.description)
          .toString();
      _cityCtrl.text =
          componentOf("locality") ??
          componentOf("administrative_area_level_2") ??
          componentOf("administrative_area_level_1") ??
          _cityCtrl.text;
      _countryCtrl.text = componentOf("country") ?? _countryCtrl.text;
      _latitudeCtrl.text = lat == null ? _latitudeCtrl.text : lat.toString();
      _longitudeCtrl.text = lng == null ? _longitudeCtrl.text : lng.toString();
      _isApplyingAddressSelection = false;

      if (!mounted) return;
      setState(() {
        _addressSuggestions.clear();
        _addressLoading = false;
        _addressSessionToken = _buildPlacesSessionToken();
      });
    } catch (_) {
      _isApplyingAddressSelection = false;
      if (!mounted) return;
      setState(() {
        _addressLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final additions = picked.files
        .where((file) => file.bytes != null)
        .map(_EditableListingImage.local)
        .toList();
    if (additions.isEmpty) return;

    setState(() {
      _newImages.addAll(additions);
    });
  }

  void _toggleExistingImageRemoval(_EditableListingImage image) {
    setState(() {
      image.markedForRemoval = !image.markedForRemoval;
    });
  }

  void _removeNewImage(_EditableListingImage image) {
    setState(() {
      _newImages.remove(image);
    });
  }

  void _addService() {
    setState(() {
      _services.add(_ListingServiceDraft());
    });
  }

  void _removeService(int index) {
    final service = _services.removeAt(index);
    service.dispose();
    setState(() {});
  }

  Map<String, Map<String, String>> _buildOpeningHoursPayload() {
    final payload = <String, Map<String, String>>{};
    for (final descriptor in _dayDescriptors) {
      final draft = _openingHours[descriptor.key]!;
      final open = draft.openCtrl.text.trim();
      final close = draft.closeCtrl.text.trim();
      if (draft.closed || open.isEmpty || close.isEmpty) continue;
      payload[descriptor.key] = {"open": open, "close": close};
    }
    return payload;
  }

  List<Map<String, dynamic>> _buildServicesPayload() {
    return _services
        .map((service) {
          final name = service.nameCtrl.text.trim();
          if (name.isEmpty) return null;
          return {"name": name, "is_available": service.isAvailable};
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  int get _visibleImageCount {
    final existingVisible = _existingImages
        .where((image) => !image.markedForRemoval)
        .length;
    return existingVisible + _newImages.length;
  }

  int get _removedExistingImageCount {
    return _existingImages.where((image) => image.markedForRemoval).length;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final latitude = _latitudeCtrl.text.trim();
    final longitude = _longitudeCtrl.text.trim();
    if ((latitude.isEmpty && longitude.isNotEmpty) ||
        (latitude.isNotEmpty && longitude.isEmpty)) {
      _showErrorToast("Latitude and longitude must be provided together.");
      return;
    }

    final servicesPayload = _buildServicesPayload();
    if (servicesPayload.isEmpty) {
      _showErrorToast("Add at least one service before saving this listing.");
      return;
    }

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      await _forceSignIn();
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      await _forceSignIn();
      return;
    }

    setState(() => _busy = true);

    try {
      final uri = Api.url(
        _isEditing
            ? MyListingEndpoints.update(widget.listingId!)
            : MyListingEndpoints.submissionsAdd,
      );
      final request = http.MultipartRequest(_isEditing ? "PATCH" : "POST", uri);
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      request.fields["name"] = _nameCtrl.text.trim();
      if (_selectedCategoryId?.trim().isNotEmpty == true) {
        request.fields["category"] = _selectedCategoryId!.trim();
      } else if (_isEditing) {
        request.fields["category"] = "";
      }
      if (_descriptionCtrl.text.trim().isNotEmpty) {
        request.fields["description"] = _descriptionCtrl.text.trim();
      }
      if (_addressCtrl.text.trim().isNotEmpty) {
        request.fields["address"] = _addressCtrl.text.trim();
      }
      if (_cityCtrl.text.trim().isNotEmpty) {
        request.fields["city"] = _cityCtrl.text.trim();
      }
      if (_countryCtrl.text.trim().isNotEmpty) {
        request.fields["country"] = _countryCtrl.text.trim();
      }
      if (latitude.isNotEmpty && longitude.isNotEmpty) {
        request.fields["latitude"] = latitude;
        request.fields["longitude"] = longitude;
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        request.fields["phone"] = _phoneCtrl.text.trim();
      }
      if (_whatsAppCtrl.text.trim().isNotEmpty) {
        request.fields["whatsapp"] = _whatsAppCtrl.text.trim();
      }
      if (_emailCtrl.text.trim().isNotEmpty) {
        request.fields["email"] = _emailCtrl.text.trim();
      }
      if (_websiteCtrl.text.trim().isNotEmpty) {
        request.fields["website"] = _websiteCtrl.text.trim();
      }

      final openingHoursPayload = _buildOpeningHoursPayload();
      if (openingHoursPayload.isNotEmpty || _isEditing) {
        request.fields["opening_hours"] = jsonEncode(openingHoursPayload);
      }

      request.fields["services"] = jsonEncode(servicesPayload);

      if (_isEditing) {
        request.fields["is_active"] = _isActive ? "true" : "false";
        final removedIds = _existingImages
            .where((image) => image.markedForRemoval && image.id != null)
            .map((image) => image.id!)
            .toList();
        for (var i = 0; i < removedIds.length; i++) {
          request.fields["remove_image_ids[$i]"] = removedIds[i];
        }
      }

      for (final image in _newImages) {
        if (image.bytes == null) continue;
        request.files.add(
          http.MultipartFile.fromBytes(
            "images",
            image.bytes!,
            filename: image.fileName ?? "listing-image.jpg",
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = _safeJson(response.body);

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _forceSignIn();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(_extractError(body, response.statusCode));
      }

      final successMessage = (body?["message"] ?? "").toString().trim();
      if (successMessage.isNotEmpty && mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(successMessage),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }

      if (!mounted) return;
      if (_isEditing) {
        Navigator.pop(context, true);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.myListingSubmissions);
      }
    } on _ApiException catch (error) {
      _showErrorToast(error.message);
    } catch (_) {
      _showErrorToast(
        _isEditing
            ? "We could not update this listing right now."
            : "We could not submit this listing right now.",
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _forceSignIn() async {
    await AuthSession.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text("Unable to continue"),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  String? _googleMapApiKeyOrNull() {
    try {
      return Env.googleMapApiKey;
    } catch (_) {
      return null;
    }
  }

  static String _buildPlacesSessionToken() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic>? _safeJson(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(Map<String, dynamic>? body, int statusCode) {
    if (body == null) return "Request failed ($statusCode)";
    final message = body["message"];
    if (message is String && message.trim().isNotEmpty) {
      final errors = body["errors"];
      final flattened = _flattenErrors(errors);
      if (flattened != null && flattened.isNotEmpty) {
        return "${message.trim()} ${flattened.trim()}";
      }
      return message.trim();
    }

    final errors = _flattenErrors(body["errors"]);
    if (errors != null && errors.isNotEmpty) return errors;

    final detail = body["detail"] ?? body["error"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();

    return "Request failed ($statusCode)";
  }

  String? _flattenErrors(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty) {
      return _flattenErrors(value.first);
    }
    if (value is Map && value.isNotEmpty) {
      return _flattenErrors(value.values.first);
    }
    return null;
  }
}

class _HeroCard extends StatelessWidget {
  final bool isEditing;
  final String title;
  final String subtitle;

  const _HeroCard({
    required this.isEditing,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.secondary.withValues(alpha: 0.11),
            scheme.surface.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              isEditing
                  ? Icons.edit_location_alt_outlined
                  : Icons.add_business_outlined,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _kPageFontSize,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: _kPageFontSize,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.70),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: scheme.primary.withValues(alpha: 0.10),
                    ),
                    child: Icon(icon, color: scheme.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: _kPageFontSize,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceAutocompleteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLoading;
  final String helperText;
  final List<_GooglePlaceSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<_GooglePlaceSuggestion> onSuggestionTap;

  const _PlaceAutocompleteField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isLoading,
    required this.helperText,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onChanged,
          style: _kInputTextStyle,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              fontSize: _kPageFontSize,
              fontFamily: "DMSans",
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
            floatingLabelStyle: TextStyle(
              fontSize: _kPageFontSize,
              fontFamily: "DMSans",
              color: scheme.primary,
            ),
            hintStyle: TextStyle(
              fontSize: _kPageFontSize,
              fontFamily: "DMSans",
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            suffixIcon: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.travel_explore_rounded, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: scheme.primary, width: 1.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
          style: TextStyle(
            fontSize: _kPageFontSize,
            fontFamily: "DMSans",
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < suggestions.length; i++) ...[
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      title: Text(
                        suggestions[i].primaryText ??
                            suggestions[i].description,
                        style: TextStyle(
                          fontSize: _kPageFontSize,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      subtitle: suggestions[i].secondaryText == null
                          ? null
                          : Text(
                              suggestions[i].secondaryText!,
                              style: TextStyle(
                                fontSize: _kPageFontSize,
                                fontFamily: "DMSans",
                                color: scheme.onSurface.withValues(alpha: 0.62),
                              ),
                            ),
                      onTap: () => onSuggestionTap(suggestions[i]),
                    ),
                  ),
                  if (i != suggestions.length - 1)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: _kInputTextStyle,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        labelStyle: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
        floatingLabelStyle: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: scheme.primary,
        ),
        hintStyle: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final bool enabled;
  final bool isLoading;
  final List<_CategoryOption> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.isLoading,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(value),
      initialValue: value,
      onChanged: enabled && !isLoading ? onChanged : null,
      isExpanded: true,
      style: TextStyle(
        fontSize: _kPageFontSize,
        fontFamily: "DMSans",
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            "No category",
            style: TextStyle(
              fontSize: _kPageFontSize,
              fontFamily: "DMSans",
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
        ...items.map(
          (item) => DropdownMenuItem<String>(
            value: item.id,
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        suffixIcon: isLoading
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.3),
        ),
      ),
    );
  }
}

class _HoursEditorRow extends StatelessWidget {
  final _DayDescriptor descriptor;
  final _OpeningHoursDraft draft;
  final bool enabled;
  final VoidCallback onChanged;

  const _HoursEditorRow({
    required this.descriptor,
    required this.draft,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  descriptor.label,
                  style: TextStyle(
                    fontSize: _kPageFontSize,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: !draft.closed,
                onChanged: enabled
                    ? (value) {
                        draft.closed = !value;
                        if (!value) {
                          draft.openCtrl.text = descriptor.defaultOpen;
                          draft.closeCtrl.text = descriptor.defaultClose;
                        }
                        onChanged();
                      }
                    : null,
              ),
            ],
          ),
          Text(
            draft.closed ? "Closed" : "Open",
            style: TextStyle(
              fontSize: _kPageFontSize,
              fontFamily: "DMSans",
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          if (!draft.closed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    label: "Opens",
                    controller: draft.openCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    label: "Closes",
                    controller: draft.closeCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceEditorCard extends StatelessWidget {
  final int index;
  final _ListingServiceDraft service;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ServiceEditorCard({
    super.key,
    required this.index,
    required this.service,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Service ${index + 1}",
                style: TextStyle(
                  fontSize: _kPageFontSize,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  tooltip: "Remove service",
                ),
            ],
          ),
          _InputField(
            label: "Service name",
            controller: service.nameCtrl,
            enabled: enabled,
            validator: (value) {
              if (_hasAnyValue(service.nameCtrl.text) || service.isAvailable) {
                return null;
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: service.isAvailable,
            onChanged: enabled
                ? (value) {
                    service.isAvailable = value;
                    onChanged();
                  }
                : null,
            title: Text(
              "Service available",
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnyValue(String value) => value.trim().isNotEmpty;
}

class _ImagesDropzone extends StatelessWidget {
  final VoidCallback? onPick;
  final int imagesSelected;
  final int removalCount;

  const _ImagesDropzone({
    required this.onPick,
    required this.imagesSelected,
    required this.removalCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
            width: 1.3,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: scheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add listing images",
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap here to add photos. New photos appear immediately and can be removed before you save.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _MetaBadge(label: "$imagesSelected ready"),
                if (removalCount > 0)
                  _MetaBadge(
                    label: "$removalCount marked for removal",
                    tint: scheme.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<_EditableListingImage> items;
  final bool allowToggleRemove;
  final ValueChanged<_EditableListingImage>? onToggleRemove;
  final ValueChanged<_EditableListingImage>? onRemoveNew;

  const _ImagesGrid({
    required this.items,
    required this.allowToggleRemove,
    required this.onToggleRemove,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 960 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ImagePreviewTile(
          item: item,
          allowToggleRemove: allowToggleRemove,
          onToggleRemove: onToggleRemove,
          onRemoveNew: onRemoveNew,
        );
      },
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final _EditableListingImage item;
  final bool allowToggleRemove;
  final ValueChanged<_EditableListingImage>? onToggleRemove;
  final ValueChanged<_EditableListingImage>? onRemoveNew;

  const _ImagePreviewTile({
    required this.item,
    required this.allowToggleRemove,
    required this.onToggleRemove,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRemote = item.isRemote;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: item.bytes != null
                ? Image.memory(item.bytes!, fit: BoxFit.cover)
                : item.url != null
                ? Image.network(
                    item.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurface.withValues(alpha: 0.40),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: scheme.onSurface.withValues(alpha: 0.40),
                    ),
                  ),
          ),
          if (item.markedForRemoval)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                ),
                child: Center(
                  child: Text(
                    "Marked for removal",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: _kPageFontSize,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: _ImageBadge(label: isRemote ? "Existing" : "New"),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRemote && allowToggleRemove && onToggleRemove != null)
                  _ImageActionButton(
                    icon: item.markedForRemoval
                        ? Icons.undo_rounded
                        : Icons.delete_outline_rounded,
                    onTap: () => onToggleRemove!(item),
                  ),
                if (!isRemote && onRemoveNew != null)
                  _ImageActionButton(
                    icon: Icons.close_rounded,
                    onTap: () => onRemoveNew!(item),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              item.fileName ?? (isRemote ? "Saved image" : "Image"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;

  const _ImageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color? tint;

  const _MetaBadge({required this.label, this.tint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = tint ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.10),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _kPageFontSize,
          fontFamily: "DMSans",
          fontWeight: FontWeight.w800,
          color: tone,
        ),
      ),
    );
  }
}

class _InlineSecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _InlineSecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _PrimarySubmitButton extends StatelessWidget {
  final bool busy;
  final String label;
  final VoidCallback? onTap;

  const _PrimarySubmitButton({
    required this.busy,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: _kPageFontSize,
                fontFamily: "DMSans",
              ),
            ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ColorScheme scheme;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 44,
              color: scheme.onSurface.withValues(alpha: 0.34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kPageFontSize,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String id;
  final String name;

  const _CategoryOption({required this.id, required this.name});
}

class _ListingServiceDraft {
  final TextEditingController nameCtrl;
  bool isAvailable;

  _ListingServiceDraft({String name = "", this.isAvailable = true})
    : nameCtrl = TextEditingController(text: name);

  factory _ListingServiceDraft.fromJson(Map<String, dynamic> json) {
    return _ListingServiceDraft(
      name: (json["name"] ?? "").toString(),
      isAvailable: json["is_available"] != false,
    );
  }

  void dispose() {
    nameCtrl.dispose();
  }
}

class _OpeningHoursDraft {
  final TextEditingController openCtrl;
  final TextEditingController closeCtrl;
  bool closed;

  _OpeningHoursDraft({
    required String open,
    required String close,
    required this.closed,
  }) : openCtrl = TextEditingController(text: open),
       closeCtrl = TextEditingController(text: close);

  void dispose() {
    openCtrl.dispose();
    closeCtrl.dispose();
  }
}

class _EditableListingImage {
  final String? id;
  final String? url;
  final Uint8List? bytes;
  final String? fileName;
  final bool isRemote;
  bool markedForRemoval = false;

  _EditableListingImage({
    required this.id,
    required this.url,
    required this.bytes,
    required this.fileName,
    required this.isRemote,
  });

  factory _EditableListingImage.remote(Map<String, dynamic> json) {
    return _EditableListingImage(
      id: (json["id"] ?? "").toString(),
      url: (json["image_url"] ?? "").toString(),
      bytes: null,
      fileName: (json["caption"] ?? "").toString().trim().isNotEmpty
          ? (json["caption"] ?? "").toString()
          : "Existing image",
      isRemote: true,
    );
  }

  factory _EditableListingImage.local(PlatformFile file) {
    return _EditableListingImage(
      id: null,
      url: null,
      bytes: file.bytes,
      fileName: file.name,
      isRemote: false,
    );
  }
}

class _DayDescriptor {
  final String key;
  final String label;
  final String defaultOpen;
  final String defaultClose;

  const _DayDescriptor({
    required this.key,
    required this.label,
    required this.defaultOpen,
    required this.defaultClose,
  });
}

const _dayDescriptors = <_DayDescriptor>[
  _DayDescriptor(
    key: "monday",
    label: "Monday",
    defaultOpen: "09:00",
    defaultClose: "18:00",
  ),
  _DayDescriptor(
    key: "tuesday",
    label: "Tuesday",
    defaultOpen: "09:00",
    defaultClose: "18:00",
  ),
  _DayDescriptor(
    key: "wednesday",
    label: "Wednesday",
    defaultOpen: "09:00",
    defaultClose: "18:00",
  ),
  _DayDescriptor(
    key: "thursday",
    label: "Thursday",
    defaultOpen: "09:00",
    defaultClose: "18:00",
  ),
  _DayDescriptor(
    key: "friday",
    label: "Friday",
    defaultOpen: "09:00",
    defaultClose: "18:00",
  ),
  _DayDescriptor(
    key: "saturday",
    label: "Saturday",
    defaultOpen: "10:00",
    defaultClose: "16:00",
  ),
  _DayDescriptor(
    key: "sunday",
    label: "Sunday",
    defaultOpen: "10:00",
    defaultClose: "16:00",
  ),
];

Map<String, _OpeningHoursDraft> _defaultOpeningHours() {
  return {
    for (final descriptor in _dayDescriptors)
      descriptor.key: _OpeningHoursDraft(
        open: descriptor.defaultOpen,
        close: descriptor.defaultClose,
        closed: true,
      ),
  };
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

class _GooglePlaceSuggestion {
  final String placeId;
  final String description;
  final String? primaryText;
  final String? secondaryText;

  const _GooglePlaceSuggestion({
    required this.placeId,
    required this.description,
    this.primaryText,
    this.secondaryText,
  });

  factory _GooglePlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting = json["structured_formatting"] as Map?;
    return _GooglePlaceSuggestion(
      placeId: (json["place_id"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      primaryText: formatting?["main_text"]?.toString(),
      secondaryText: formatting?["secondary_text"]?.toString(),
    );
  }
}
