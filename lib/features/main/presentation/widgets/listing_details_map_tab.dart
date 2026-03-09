import "dart:ui";

import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:hugeicons/hugeicons.dart";
import "package:map_launcher/map_launcher.dart" as launcher;

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingMapTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingMapTab({super.key, required this.place});

  Widget _mapAppLeadingIcon(ColorScheme scheme, launcher.AvailableMap m) {
    final dynamic iconDyn = m.icon;

    if (iconDyn is String && iconDyn.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          iconDyn,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => HugeIcon(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            size: 22,
            color: scheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
      );
    }

    return HugeIcon(
      icon: HugeIcons.strokeRoundedMapsLocation02,
      size: 22,
      color: scheme.onSurface.withValues(alpha: 0.70),
    );
  }

  Future<void> _openExternalMaps(BuildContext context) async {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final lat = place.latitude;
    final lng = place.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(lang, "listings.no_data"))),
      );
      return;
    }

    final coords = launcher.Coords(lat, lng);
    final title = place.name.isNotEmpty ? place.name : "Destination";

    final availableMaps = await launcher.MapLauncher.installedMaps;

    if (!context.mounted) return;

    if (availableMaps.isEmpty) {
      await launcher.MapLauncher.showDirections(
        mapType: launcher.MapType.google,
        destination: coords,
        destinationTitle: title,
      );
      return;
    }

    final googleMapApp = availableMaps
        .where((m) => m.mapType == launcher.MapType.google)
        .cast<launcher.AvailableMap?>()
        .fold<launcher.AvailableMap?>(null, (prev, curr) => curr ?? prev);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMapsLocation02,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface.withValues(alpha: 0.92),
                            ),
                          ),
                          Text(
                            "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.08)),

              if (googleMapApp != null)
                ListTile(
                  leading: _mapAppLeadingIcon(scheme, googleMapApp),
                  title: Text(
                    "Google Maps",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.90),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await launcher.MapLauncher.showDirections(
                      mapType: launcher.MapType.google,
                      destination: coords,
                      destinationTitle: title,
                    );
                  },
                ),

              ...availableMaps.where((m) => m != googleMapApp).map((m) {
                return ListTile(
                  leading: _mapAppLeadingIcon(scheme, m),
                  title: Text(
                    m.mapName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.90),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await m.showMarker(
                      coords: coords,
                      title: title,
                      description: place.address,
                    );
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    final lat = place.latitude;
    final lng = place.longitude;
    final hasCoords = lat != null && lng != null;

    final camera = hasCoords
        ? CameraPosition(target: LatLng(lat, lng), zoom: 15)
        : const CameraPosition(target: LatLng(0, 0), zoom: 1);

    final markers = hasCoords
        ? <Marker>{
            Marker(
              markerId: const MarkerId("place"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: place.name.isNotEmpty
                    ? place.name
                    : t(lang, "listings.address"),
                snippet: place.address,
              ),
            ),
          }
        : <Marker>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address glass card
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  label: t(lang, "listings.address"),
                  scheme: scheme,
                ),
                const SizedBox(height: 12),
                _AddressRow(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  label: place.address.isNotEmpty
                      ? place.address
                      : t(lang, "listings.no_data"),
                  scheme: scheme,
                ),
                if (hasCoords) ...[
                  const SizedBox(height: 8),
                  _AddressRow(
                    icon: HugeIcons.strokeRoundedGlobalSearch,
                    label:
                        "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}",
                    scheme: scheme,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Map glass card
          _GlassSection(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: 300,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasCoords
                          ? GoogleMap(
                              initialCameraPosition: camera,
                              markers: markers,
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              mapType: MapType.normal,
                            )
                          : Container(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedMapsLocation02,
                                      size: 34,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      t(lang, "listings.map_placeholder"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Subtle border overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  scheme.onSurface.withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    // Open in maps pill
                    if (hasCoords)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: () => _openExternalMaps(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: scheme.surface
                                      .withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowUpRight01,
                                      size: 15,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      t(lang, "listings.open_in_maps"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.88),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Glass section ----------------------------- */

class _GlassSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _GlassSection({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ----------------------------- Section header ----------------------------- */

class _SectionHeader extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(icon: icon, size: 14, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.92),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Address row ----------------------------- */

class _AddressRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            size: 15,
            color: scheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.82),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
