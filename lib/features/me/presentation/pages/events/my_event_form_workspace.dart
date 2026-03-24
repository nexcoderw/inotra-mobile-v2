import "dart:async";
import "dart:convert";
import "dart:typed_data";
import "dart:ui";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/config/env.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

const double _kPageFontSize = 12;
const TextStyle _kInputTextStyle = TextStyle(
  fontSize: _kPageFontSize,
  fontFamily: "DMSans",
  height: 1.2,
);

class MyEventFormWorkspace extends StatefulWidget {
  final bool isEditing;
  final String? eventId;
  final String? initialTitle;

  const MyEventFormWorkspace({
    super.key,
    required this.isEditing,
    this.eventId,
    this.initialTitle,
  });

  @override
  State<MyEventFormWorkspace> createState() => _MyEventFormWorkspaceState();
}

class _MyEventFormWorkspaceState extends State<MyEventFormWorkspace> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;
  late final TextEditingController _organizerNameCtrl;
  late final TextEditingController _organizerContactCtrl;
  late final FocusNode _venueFocusNode;

  final List<_TicketDraft> _tickets = [];
  final List<_GooglePlaceSuggestion> _venueSuggestions = [];

  DateTime? _startAt;
  DateTime? _endAt;
  Uint8List? _bannerBytes;
  String? _bannerFileName;
  String? _bannerUrl;
  bool _removeBanner = false;
  bool _busy = false;
  bool _loading = false;
  bool _venueLoading = false;
  bool _isApplyingVenueSelection = false;
  String? _loadError;
  String _venueSessionToken = _buildPlacesSessionToken();
  Timer? _venueDebounce;

  String get _lang => currentLangSync();

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? "");
    _descriptionCtrl = TextEditingController();
    _venueCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _countryCtrl = TextEditingController(text: "Rwanda");
    _latitudeCtrl = TextEditingController();
    _longitudeCtrl = TextEditingController();
    _organizerNameCtrl = TextEditingController();
    _organizerContactCtrl = TextEditingController();
    _venueFocusNode = FocusNode();

    if (_isEditing) {
      _loadEvent();
    } else {
      _tickets.add(_TicketDraft());
    }
  }

  @override
  void dispose() {
    _venueDebounce?.cancel();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _organizerNameCtrl.dispose();
    _organizerContactCtrl.dispose();
    _venueFocusNode.dispose();
    for (final ticket in _tickets) {
      ticket.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return _StatePanel(
        icon: Icons.hourglass_top_rounded,
        title: t(_lang, "my_events.form_loading_title"),
        description: t(_lang, "my_events.form_loading_subtitle"),
        scheme: scheme,
      );
    }

    if (_loadError != null) {
      return _StatePanel(
        icon: Icons.cloud_off_rounded,
        title: t(_lang, "my_events.form_error_title"),
        description: _loadError!,
        actionLabel: t(_lang, "common.try_again"),
        onAction: _loadEvent,
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
                      ? t(_lang, "my_events.edit_event")
                      : t(_lang, "my_events.add_event"),
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
                      ? t(_lang, "my_events.form_edit_title")
                      : t(_lang, "my_events.form_add_title"),
                  subtitle: _isEditing
                      ? t(_lang, "my_events.form_edit_subtitle")
                      : t(_lang, "my_events.form_add_subtitle"),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: t(_lang, "my_events.form_banner_section"),
                  icon: Icons.image_outlined,
                  child: _BannerDropzone(
                    bytes: _bannerBytes,
                    imageUrl: _bannerUrl,
                    fileName: _bannerFileName,
                    onPick: _busy ? null : _pickBanner,
                    onRemove: _busy ? null : _removeSelectedBanner,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: t(_lang, "my_events.form_basic_section"),
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    children: [
                      _InputField(
                        label: t(_lang, "my_events.form_title_label"),
                        controller: _titleCtrl,
                        enabled: !_busy,
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return t(_lang, "auth.required_field");
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: t(_lang, "my_events.form_description_label"),
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
                  title: t(_lang, "my_events.form_schedule_section"),
                  icon: Icons.schedule_rounded,
                  child: Column(
                    children: [
                      _DateTimeTile(
                        label: t(_lang, "my_events.form_start_label"),
                        value: _startAt,
                        onTap: _busy
                            ? null
                            : () => _pickDateTime(isStart: true),
                      ),
                      const SizedBox(height: 12),
                      _DateTimeTile(
                        label: t(_lang, "my_events.form_end_label"),
                        value: _endAt,
                        onTap: _busy
                            ? null
                            : () => _pickDateTime(isStart: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: t(_lang, "my_events.form_location_section"),
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      _VenueAutocompleteField(
                        label: t(_lang, "my_events.form_venue_label"),
                        controller: _venueCtrl,
                        focusNode: _venueFocusNode,
                        enabled: !_busy,
                        isLoading: _venueLoading,
                        suggestions: _venueSuggestions,
                        helperText: t(_lang, "my_events.form_venue_helper"),
                        onChanged: _onVenueChanged,
                        onSuggestionTap: _selectVenueSuggestion,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: t(_lang, "my_events.form_address_label"),
                        controller: _addressCtrl,
                        enabled: !_busy,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              label: t(_lang, "my_events.form_city_label"),
                              controller: _cityCtrl,
                              enabled: !_busy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputField(
                              label: t(_lang, "my_events.form_country_label"),
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
                              label: t(_lang, "my_events.form_latitude_label"),
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
                              label: t(_lang, "my_events.form_longitude_label"),
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
                  title: t(_lang, "my_events.form_organizer_section"),
                  icon: Icons.groups_rounded,
                  child: Column(
                    children: [
                      _InputField(
                        label: t(_lang, "my_events.form_organizer_name_label"),
                        controller: _organizerNameCtrl,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: t(
                          _lang,
                          "my_events.form_organizer_contact_label",
                        ),
                        controller: _organizerContactCtrl,
                        enabled: !_busy,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: t(_lang, "my_events.form_tickets_section"),
                  icon: Icons.confirmation_number_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _tickets.length; i++) ...[
                        _TicketEditorCard(
                          key: ValueKey(_tickets[i]),
                          index: i,
                          ticket: _tickets[i],
                          enabled: !_busy,
                          onRemove: _tickets.length > 1
                              ? () => _removeTicket(i)
                              : null,
                        ),
                        if (i != _tickets.length - 1)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 14),
                      _InlineSecondaryButton(
                        icon: Icons.add_rounded,
                        label: t(_lang, "my_events.form_add_ticket"),
                        onTap: _busy ? null : _addTicket,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _PrimarySubmitButton(
                  busy: _busy,
                  label: _isEditing
                      ? t(_lang, "my_events.form_update_action")
                      : t(_lang, "my_events.form_submit_action"),
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

  void _onVenueChanged(String value) {
    if (_isApplyingVenueSelection) return;

    _venueDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _venueSuggestions.clear();
          _venueLoading = false;
        });
      }
      return;
    }

    _venueDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchVenueSuggestions(query),
    );
  }

  Future<void> _fetchVenueSuggestions(String query) async {
    final apiKey = _googleMapApiKeyOrNull();
    if (apiKey == null) return;

    if (mounted) {
      setState(() => _venueLoading = true);
    }

    try {
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": query,
          "key": apiKey,
          "sessiontoken": _venueSessionToken,
          "components": "country:rw",
        },
      );

      final response = await http.get(uri);
      final body = _safeJson(response.body);
      final predictions = (body?["predictions"] as List?) ?? const [];

      if (!mounted || _venueCtrl.text.trim() != query) return;

      setState(() {
        _venueSuggestions
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
        _venueLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _venueSuggestions.clear();
        _venueLoading = false;
      });
    }
  }

  Future<void> _selectVenueSuggestion(_GooglePlaceSuggestion suggestion) async {
    final apiKey = _googleMapApiKeyOrNull();
    if (apiKey == null) return;

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() => _venueLoading = true);
    }

    try {
      final uri =
          Uri.https("maps.googleapis.com", "/maps/api/place/details/json", {
            "place_id": suggestion.placeId,
            "key": apiKey,
            "sessiontoken": _venueSessionToken,
            "fields": "name,formatted_address,geometry,address_component",
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

      _isApplyingVenueSelection = true;
      _venueCtrl.text =
          (place["name"] ?? suggestion.primaryText ?? suggestion.description)
              .toString();
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
      _isApplyingVenueSelection = false;

      if (!mounted) return;
      setState(() {
        _venueSuggestions.clear();
        _venueLoading = false;
        _venueSessionToken = _buildPlacesSessionToken();
      });
    } catch (_) {
      _isApplyingVenueSelection = false;
      if (!mounted) return;
      setState(() {
        _venueLoading = false;
      });
    }
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

  Future<void> _loadEvent() async {
    final eventId = widget.eventId;
    if (eventId == null || eventId.isEmpty) {
      setState(() {
        _loadError = t(_lang, "my_events.form_missing_event");
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
      final uri = Api.url(MyEventEndpoints.detail(eventId));
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

      _titleCtrl.text = (body["title"] ?? widget.initialTitle ?? "").toString();
      _descriptionCtrl.text = (body["description"] ?? "").toString();
      _venueCtrl.text = (body["venue_name"] ?? "").toString();
      _addressCtrl.text = (body["address"] ?? "").toString();
      _cityCtrl.text = (body["city"] ?? "").toString();
      _countryCtrl.text =
          ((body["country"] ?? "Rwanda").toString()).trim().isEmpty
          ? "Rwanda"
          : body["country"].toString();
      _latitudeCtrl.text = (body["latitude"] ?? "").toString();
      _longitudeCtrl.text = (body["longitude"] ?? "").toString();
      _organizerNameCtrl.text = (body["organizer_name"] ?? "").toString();
      _organizerContactCtrl.text = (body["organizer_contact"] ?? "").toString();
      _bannerUrl = (body["banner_url"] ?? "").toString().trim().isEmpty
          ? null
          : body["banner_url"].toString();
      _startAt = _parseDate(body["start_at"]?.toString());
      _endAt = _parseDate(body["end_at"]?.toString());

      for (final ticket in _tickets) {
        ticket.dispose();
      }
      _tickets
        ..clear()
        ..addAll(_parseTickets(body["tickets"]));
      if (_tickets.isEmpty) {
        _tickets.add(_TicketDraft());
      }

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
        _loadError = t(_lang, "my_events.form_load_failed");
      });
    }
  }

  List<_TicketDraft> _parseTickets(dynamic raw) {
    if (raw is! List) return const <_TicketDraft>[];
    return raw
        .whereType<Map>()
        .map((item) => _TicketDraft.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _pickBanner() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null) return;

    setState(() {
      _bannerBytes = file.bytes;
      _bannerFileName = file.name;
      _removeBanner = false;
    });
  }

  void _removeSelectedBanner() {
    setState(() {
      _bannerBytes = null;
      _bannerFileName = null;
      if (_bannerUrl != null) {
        _bannerUrl = null;
        _removeBanner = true;
      }
    });
  }

  void _addTicket() {
    setState(() {
      _tickets.add(_TicketDraft());
    });
  }

  void _removeTicket(int index) {
    final ticket = _tickets.removeAt(index);
    ticket.dispose();
    setState(() {});
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final existing = isStart ? _startAt : _endAt;
    final now = DateTime.now();
    final initialDate = existing ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 8),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(existing ?? now),
    );
    if (pickedTime == null || !mounted) return;

    final nextValue = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = nextValue;
        if (_endAt != null && _endAt!.isBefore(nextValue)) {
          _endAt = nextValue.add(const Duration(hours: 1));
        }
      } else {
        _endAt = nextValue;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startAt != null && _endAt != null && _endAt!.isBefore(_startAt!)) {
      _showErrorToast(t(_lang, "my_events.form_end_before_start"));
      return;
    }

    final latitude = _latitudeCtrl.text.trim();
    final longitude = _longitudeCtrl.text.trim();
    if ((latitude.isEmpty && longitude.isNotEmpty) ||
        (latitude.isNotEmpty && longitude.isEmpty)) {
      _showErrorToast(t(_lang, "my_events.form_coordinates_together"));
      return;
    }

    if (_tickets.isEmpty) {
      _showErrorToast(t(_lang, "my_events.form_ticket_required"));
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
            ? MyEventEndpoints.update(widget.eventId!)
            : MyEventEndpoints.submissionsAdd,
      );
      final request = http.MultipartRequest(_isEditing ? "PATCH" : "POST", uri);
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      request.fields["title"] = _titleCtrl.text.trim();
      if (_descriptionCtrl.text.trim().isNotEmpty) {
        request.fields["description"] = _descriptionCtrl.text.trim();
      }
      if (_startAt != null) {
        request.fields["start_at"] = _startAt!.toUtc().toIso8601String();
      }
      if (_endAt != null) {
        request.fields["end_at"] = _endAt!.toUtc().toIso8601String();
      }
      if (_venueCtrl.text.trim().isNotEmpty) {
        request.fields["venue_name"] = _venueCtrl.text.trim();
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
      if (_organizerNameCtrl.text.trim().isNotEmpty) {
        request.fields["organizer_name"] = _organizerNameCtrl.text.trim();
      }
      if (_organizerContactCtrl.text.trim().isNotEmpty) {
        request.fields["organizer_contact"] = _organizerContactCtrl.text.trim();
      }
      if (_isEditing && _removeBanner && _bannerBytes == null) {
        request.fields["remove_banner"] = "true";
      }

      request.fields["tickets"] = jsonEncode(
        _tickets.map((ticket) => ticket.toPayload()).toList(),
      );

      if (_bannerBytes != null && _bannerFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "banner",
            _bannerBytes!,
            filename: _bannerFileName!,
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
        Navigator.pushReplacementNamed(context, AppRoutes.myEventSubmissions);
      }
    } on _ApiException catch (error) {
      _showErrorToast(error.message);
    } catch (_) {
      _showErrorToast(t(_lang, "my_events.form_save_failed"));
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
      title: Text(t(_lang, "my_events.form_error_toast_title")),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

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

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
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
                  ? Icons.auto_fix_high_rounded
                  : Icons.add_circle_outline_rounded,
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

class _BannerDropzone extends StatelessWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final String? fileName;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  const _BannerDropzone({
    required this.bytes,
    required this.imageUrl,
    required this.fileName,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final hasImage =
        bytes != null || (imageUrl != null && imageUrl!.trim().isNotEmpty);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        height: 224,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
            width: 1.3,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: bytes != null
                        ? Image.memory(bytes!, fit: BoxFit.cover)
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _BannerPlaceholder(scheme: scheme),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.14),
                            Colors.black.withValues(alpha: 0.66),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _BannerActionChip(
                          icon: Icons.edit_outlined,
                          label: t(lang, "my_events.form_replace_banner"),
                          onTap: onPick,
                        ),
                        const SizedBox(width: 8),
                        _BannerActionChip(
                          icon: Icons.delete_outline_rounded,
                          label: t(lang, "my_events.form_remove_banner"),
                          onTap: onRemove,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName?.trim().isNotEmpty == true
                              ? fileName!.trim()
                              : t(lang, "my_events.form_banner_ready"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: _kPageFontSize,
                            fontFamily: "DMSans",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t(lang, "my_events.form_banner_hint"),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontWeight: FontWeight.w600,
                            fontSize: _kPageFontSize,
                            fontFamily: "DMSans",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _BannerPlaceholder(scheme: scheme),
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  final ColorScheme scheme;

  const _BannerPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.cloud_upload_outlined, color: scheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              t(lang, "my_events.form_pick_banner"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(lang, "my_events.form_banner_hint"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kPageFontSize,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BannerActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: _kPageFontSize,
                  fontFamily: "DMSans",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueAutocompleteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLoading;
  final String helperText;
  final List<_GooglePlaceSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<_GooglePlaceSuggestion> onSuggestionTap;

  const _VenueAutocompleteField({
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

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: _kPageFontSize,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value == null
                          ? t(lang, "my_events.form_select_date_time")
                          : DateFormat(
                              "EEE, dd MMM yyyy · hh:mm a",
                            ).format(value!),
                      style: TextStyle(
                        fontSize: _kPageFontSize,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketEditorCard extends StatefulWidget {
  final int index;
  final _TicketDraft ticket;
  final bool enabled;
  final VoidCallback? onRemove;

  const _TicketEditorCard({
    super.key,
    required this.index,
    required this.ticket,
    required this.enabled,
    required this.onRemove,
  });

  @override
  State<_TicketEditorCard> createState() => _TicketEditorCardState();
}

class _TicketEditorCardState extends State<_TicketEditorCard> {
  static const _suggestedCategories = [
    "FREE",
    "REGULAR",
    "VIP",
    "VVIP",
    "TABLE",
  ];

  @override
  void initState() {
    super.initState();
    widget.ticket.categoryCtrl.addListener(_handleCategoryChange);
  }

  @override
  void dispose() {
    widget.ticket.categoryCtrl.removeListener(_handleCategoryChange);
    super.dispose();
  }

  void _handleCategoryChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _TicketEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.ticket, widget.ticket)) {
      oldWidget.ticket.categoryCtrl.removeListener(_handleCategoryChange);
      widget.ticket.categoryCtrl.addListener(_handleCategoryChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    final categoryText = widget.ticket.categoryCtrl.text.trim().toUpperCase();
    final isFree = categoryText == "FREE";

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
                "${t(lang, "my_events.form_ticket_title")} ${widget.index + 1}",
                style: TextStyle(
                  fontSize: _kPageFontSize,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.enabled ? widget.onRemove : null,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  tooltip: t(lang, "my_events.form_remove_ticket"),
                ),
            ],
          ),
          _InputField(
            label: t(lang, "my_events.form_ticket_category_label"),
            controller: widget.ticket.categoryCtrl,
            enabled: widget.enabled,
            validator: (value) {
              if ((value ?? "").trim().isEmpty) {
                return t(lang, "auth.required_field");
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _suggestedCategories)
                ChoiceChip(
                  label: Text(
                    option,
                    style: const TextStyle(
                      fontSize: _kPageFontSize,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: categoryText == option,
                  onSelected: widget.enabled
                      ? (_) {
                          widget.ticket.categoryCtrl.text = option;
                          setState(() {});
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _InputField(
            label: t(lang, "my_events.form_ticket_price_label"),
            controller: widget.ticket.priceCtrl,
            enabled: widget.enabled && !isFree,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final category = widget.ticket.categoryCtrl.text
                  .trim()
                  .toUpperCase();
              if (category == "FREE") return null;
              if ((value ?? "").trim().isEmpty) {
                return t(lang, "auth.required_field");
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: widget.ticket.consumable,
            onChanged: widget.enabled
                ? (value) {
                    setState(() {
                      widget.ticket.consumable = value;
                      if (!value) {
                        widget.ticket.descriptionCtrl.clear();
                      }
                    });
                  }
                : null,
            contentPadding: EdgeInsets.zero,
            title: Text(
              t(lang, "my_events.form_ticket_consumable_label"),
              style: TextStyle(
                fontSize: _kPageFontSize,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (widget.ticket.consumable) ...[
            const SizedBox(height: 8),
            _InputField(
              label: t(lang, "my_events.form_ticket_consumable_description"),
              controller: widget.ticket.descriptionCtrl,
              enabled: widget.enabled,
              maxLines: 3,
              validator: (value) {
                if (widget.ticket.consumable && (value ?? "").trim().isEmpty) {
                  return t(lang, "auth.required_field");
                }
                return null;
              },
            ),
          ],
        ],
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

class _TicketDraft {
  final TextEditingController categoryCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController descriptionCtrl;
  bool consumable;

  _TicketDraft({
    String category = "",
    String price = "",
    String description = "",
    this.consumable = false,
  }) : categoryCtrl = TextEditingController(text: category),
       priceCtrl = TextEditingController(text: price),
       descriptionCtrl = TextEditingController(text: description);

  factory _TicketDraft.fromJson(Map<String, dynamic> json) {
    final price = json["price"];
    final priceLabel = price == null ? "" : price.toString();
    return _TicketDraft(
      category: (json["category"] ?? "").toString(),
      price: priceLabel,
      description: (json["consumable_description"] ?? "").toString(),
      consumable: json["consumable"] == true,
    );
  }

  Map<String, dynamic> toPayload() {
    final category = categoryCtrl.text.trim();
    final isFree = category.toUpperCase() == "FREE";
    return {
      "category": category,
      "price": isFree ? null : priceCtrl.text.trim(),
      "consumable": consumable,
      "consumable_description": consumable ? descriptionCtrl.text.trim() : null,
    };
  }

  void dispose() {
    categoryCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
  }
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
