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

  Future<void> _openExternalMaps(BuildContext context) async {
    final lat = place.latitude;
    final lng = place.longitude;

    if (lat == null || lng == null) {
      final lang = currentLangSync();
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
      // Very rare, but safe fallback: open Google Maps in browser
      await launcher.MapLauncher.showDirections(
        mapType: launcher.MapType.google,
        destination: coords,
        destinationTitle: title,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text("${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}"),
              ),
              const Divider(height: 0),
              ...availableMaps.map((m) {
                return ListTile(
                  leading: Image(image: m.icon, width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.map)),
                  title: Text(m.mapName),
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
        ? CameraPosition(target: LatLng(lat!, lng!), zoom: 15)
        : const CameraPosition(target: LatLng(0, 0), zoom: 1);

    final marker = hasCoords
        ? {
            Marker(
              markerId: const MarkerId("place"),
              position: LatLng(lat!, lng!),
              infoWindow: InfoWindow(
                title: place.name.isNotEmpty ? place.name : t(lang, "listings.address"),
                snippet: place.address,
              ),
            ),
          }
        : <Marker>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.address"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: place.address.isNotEmpty ? place.address : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 12),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: hasCoords
                ? "${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}"
                : "--",
          ),
          const SizedBox(height: 16),

          // MAP CARD
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: scheme.surfaceVariant.withOpacity(0.55),
              child: InkWell(
                onTap: hasCoords ? () => _openExternalMaps(context) : null,
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: hasCoords
                            ? GoogleMap(
                                initialCameraPosition: camera,
                                markers: marker,
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                                compassEnabled: false,
                                tiltGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                mapType: MapType.normal,
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedMapsLocation02,
                                      size: 34,
                                      color: scheme.onSurface.withOpacity(0.55),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      t(lang, "listings.map_placeholder"),
                                      style: TextStyle(
                                        color: scheme.onSurface.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // subtle border overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: scheme.onSurface.withOpacity(0.10),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      // OPEN IN MAPS pill
                      if (hasCoords)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.surface.withOpacity(0.90),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withOpacity(0.12),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new, size: 18, color: scheme.onSurface),
                                const SizedBox(width: 8),
                                Text(
                                  t(lang, "listings.open_in_maps"),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
