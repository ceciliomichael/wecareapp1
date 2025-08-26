import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import '../constants/bohol_locations.dart';

/// A reusable map widget for displaying Bohol locations
class BoholMapWidget extends StatefulWidget {
  final String? selectedLocation;
  final List<String>? highlightedLocations;
  final Function(String?)? onLocationTapped;
  final bool showAllLocations;
  final double? height;
  final bool interactive;

  const BoholMapWidget({
    super.key,
    this.selectedLocation,
    this.highlightedLocations,
    this.onLocationTapped,
    this.showAllLocations = true,
    this.height,
    this.interactive = true,
  });

  @override
  State<BoholMapWidget> createState() => _BoholMapWidgetState();
}

class _BoholMapWidgetState extends State<BoholMapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Generate markers for locations
  List<Marker> _generateMarkers() {
    final List<Marker> markers = [];

    if (widget.showAllLocations) {
      // Show all locations with coordinates
      for (final entry in MapService.getAllLocationCoordinates().entries) {
        final location = entry.key;
        final coordinates = entry.value;

        final isSelected = widget.selectedLocation == location;
        final isHighlighted =
            widget.highlightedLocations?.contains(location) ?? false;

        markers.add(
          _createMarker(location, coordinates, isSelected, isHighlighted),
        );
      }
    } else if (widget.selectedLocation != null) {
      // Show only selected location
      final coordinates = MapService.getLocationCoordinates(
        widget.selectedLocation!,
      );
      if (coordinates != null) {
        markers.add(
          _createMarker(widget.selectedLocation!, coordinates, true, false),
        );
      }
    }

    // Add highlighted locations
    if (widget.highlightedLocations != null) {
      for (final location in widget.highlightedLocations!) {
        final coordinates = MapService.getLocationCoordinates(location);
        if (coordinates != null) {
          final isSelected = widget.selectedLocation == location;
          markers.add(_createMarker(location, coordinates, isSelected, true));
        }
      }
    }

    return markers;
  }

  /// Create a marker for a location
  Marker _createMarker(
    String location,
    LatLng coordinates,
    bool isSelected,
    bool isHighlighted,
  ) {
    Color markerColor;
    double markerSize;
    IconData markerIcon;

    if (isSelected) {
      markerColor = Colors.red;
      markerSize = 40;
      markerIcon = Icons.location_on;
    } else if (isHighlighted) {
      markerColor = Colors.orange;
      markerSize = 35;
      markerIcon = Icons.location_on;
    } else {
      markerColor = Colors.blue;
      markerSize = 30;
      markerIcon = Icons.location_on_outlined;
    }

    return Marker(
      point: coordinates,
      width: markerSize,
      height: markerSize,
      child: GestureDetector(
        onTap: () {
          if (widget.onLocationTapped != null) {
            widget.onLocationTapped!(location);
          }
          _showLocationInfo(location, coordinates);
        },
        child: Icon(markerIcon, color: markerColor, size: markerSize),
      ),
    );
  }

  /// Show information about a location
  void _showLocationInfo(String location, LatLng coordinates) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(location),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${BoholLocations.getLocationType(location)}'),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}',
              ),
              if (BoholLocations.isBusinessDistrict(location)) ...[
                const SizedBox(height: 8),
                const Text(
                  '🏢 Business District',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (BoholLocations.isResidentialArea(location)) ...[
                const SizedBox(height: 8),
                const Text(
                  '🏠 Residential Area',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (widget.onLocationTapped != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLocationTapped!(location);
                },
                child: const Text('Select'),
              ),
          ],
        );
      },
    );
  }

  /// Get initial center and zoom based on displayed locations
  MapOptions _getMapOptions() {
    LatLng center;
    double zoom;

    if (widget.selectedLocation != null) {
      final coordinates = MapService.getLocationCoordinates(
        widget.selectedLocation!,
      );
      center = coordinates ?? MapService.getBoholCenter();
      zoom = MapService.getCityZoomLevel();
    } else {
      center = MapService.getBoholCenter();
      zoom = MapService.getBoholZoomLevel();
    }

    return MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      minZoom: 9.0,
      maxZoom: 18.0,
      interactionOptions: InteractionOptions(
        flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: _getMapOptions(),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: MapService.getOpenStreetMapTileUrl(),
              userAgentPackageName: MapService.getUserAgent(),
              maxZoom: 18,
            ),

            // Markers layer
            MarkerLayer(markers: _generateMarkers()),

            // Attribution layer (required for OpenStreetMap)
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A simplified map widget for job cards
class JobLocationMapWidget extends StatelessWidget {
  final String location;
  final double height;

  const JobLocationMapWidget({
    super.key,
    required this.location,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return BoholMapWidget(
      selectedLocation: location,
      showAllLocations: false,
      height: height,
      interactive: false,
    );
  }
}

/// A location picker map widget
class LocationPickerMapWidget extends StatefulWidget {
  final String? initialLocation;
  final Function(String) onLocationSelected;

  const LocationPickerMapWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMapWidget> createState() =>
      _LocationPickerMapWidgetState();
}

class _LocationPickerMapWidgetState extends State<LocationPickerMapWidget> {
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedLocation != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: $_selectedLocation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onLocationSelected(_selectedLocation!);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: BoholMapWidget(
            selectedLocation: _selectedLocation,
            showAllLocations: true,
            onLocationTapped: (location) {
              if (location != null) {
                setState(() {
                  _selectedLocation = location;
                });
              }
            },
            interactive: true,
          ),
        ),
      ],
    );
  }
}
