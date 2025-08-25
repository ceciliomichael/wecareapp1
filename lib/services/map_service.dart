import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for handling map-related operations for Bohol locations
class MapService {
  // Default coordinates for Bohol (Tagbilaran City center)
  static double get defaultLatitude =>
      double.tryParse(dotenv.env['DEFAULT_LATITUDE'] ?? '9.8349') ?? 9.8349;

  static double get defaultLongitude =>
      double.tryParse(dotenv.env['DEFAULT_LONGITUDE'] ?? '124.1438') ??
      124.1438;

  static LatLng get defaultLocation =>
      LatLng(defaultLatitude, defaultLongitude);

  /// Approximate coordinates for major Bohol locations
  /// Note: In a production app, these should be more precise and stored in a database
  static final Map<String, LatLng> _locationCoordinates = {
    // City
    'Tagbilaran City': LatLng(9.6496, 123.8536),

    // Major municipalities (approximate coordinates)
    'Panglao': LatLng(9.5831, 123.7544),
    'Dauis': LatLng(9.6167, 123.8167),
    'Baclayon': LatLng(9.6333, 123.9000),
    'Tubigon': LatLng(9.9500, 124.0833),
    'Loon': LatLng(9.8000, 123.6500),
    'Maribojoc': LatLng(9.7500, 123.8167),
    'Carmen': LatLng(9.9667, 124.1833), // Chocolate Hills area
    'Loboc': LatLng(9.6333, 124.0333),
    'Jagna': LatLng(9.6500, 124.3667),
    'Ubay': LatLng(10.0500, 124.4833),
    'Talibon': LatLng(10.1167, 124.3000),
    'Bien Unido': LatLng(10.1333, 124.3667),
    'Trinidad': LatLng(10.0833, 124.4000),
    'Alburquerque': LatLng(9.6667, 123.9500),
    'Loay': LatLng(9.6000, 123.9333),
    'Corella': LatLng(9.6833, 123.9167),
    'Sikatuna': LatLng(9.7167, 123.9667),
    'Balilihan': LatLng(9.7500, 123.9667),
    'Catigbian': LatLng(9.8167, 124.0000),
    'Sagbayan': LatLng(9.8667, 124.0833),
    'Batuan': LatLng(9.8167, 124.1500),
    'Bilar': LatLng(9.7833, 124.1333),
    'Valencia': LatLng(9.2833, 123.9333),
    'Dimiao': LatLng(9.3167, 123.9833),
    'Lila': LatLng(9.5833, 124.0000),
    'Sevilla': LatLng(9.5167, 123.9833),
    'Calape': LatLng(9.8333, 124.0000),
    'Antequera': LatLng(9.8000, 123.9167),
    'Pilar': LatLng(9.8333, 124.3167),
    'Dagohoy': LatLng(9.8833, 124.2000),
    'Danao': LatLng(10.0000, 124.2167),
    'Sierra Bullones': LatLng(9.9167, 124.2667),
    'San Miguel': LatLng(9.9333, 124.3333),
    'Clarin': LatLng(9.9667, 124.0167),
    'Inabanga': LatLng(9.9833, 124.0667),
    'Buenavista': LatLng(10.0000, 124.1167),
    'Getafe': LatLng(10.1333, 124.1500),
    'President Carlos P. Garcia': LatLng(9.8667, 124.5167),
    'Mabini': LatLng(9.8500, 124.5000),
    'Candijay': LatLng(9.8167, 124.5333),
    'Alicia': LatLng(9.9167, 124.4167),
    'Anda': LatLng(9.7333, 124.6000),
    'Guindulman': LatLng(9.7667, 124.4833),
    'Duero': LatLng(9.6833, 124.4000),
    'Garcia Hernandez': LatLng(9.5667, 124.2667),
    'San Isidro': LatLng(9.5000, 124.1833),
    'Cortes': LatLng(9.7000, 123.8833),
  };

  /// Get coordinates for a location
  static LatLng? getLocationCoordinates(String location) {
    return _locationCoordinates[location];
  }

  /// Get coordinates for a location, with fallback to default
  static LatLng getLocationCoordinatesWithFallback(String location) {
    return _locationCoordinates[location] ?? defaultLocation;
  }

  /// Check if coordinates are available for a location
  static bool hasCoordinates(String location) {
    return _locationCoordinates.containsKey(location);
  }

  /// Get the center point of Bohol for map initialization
  static LatLng getBoholCenter() {
    return LatLng(9.8349, 124.1438); // Center of Bohol
  }

  /// Get appropriate zoom level for Bohol province view
  static double getBoholZoomLevel() {
    return 10.0; // Good zoom level to see most of Bohol
  }

  /// Get zoom level for city/municipality view
  static double getCityZoomLevel() {
    return 13.0;
  }

  /// Get all locations with coordinates
  static Map<String, LatLng> getAllLocationCoordinates() {
    return Map<String, LatLng>.from(_locationCoordinates);
  }

  /// Calculate distance between two locations (in kilometers)
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Find nearest location to given coordinates
  static String? findNearestLocation(LatLng coordinates) {
    String? nearest;
    double minDistance = double.infinity;

    for (final entry in _locationCoordinates.entries) {
      final distance = calculateDistance(coordinates, entry.value);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = entry.key;
      }
    }

    return nearest;
  }

  /// Get locations within specified radius (in kilometers)
  static List<String> getLocationsWithinRadius(LatLng center, double radiusKm) {
    final List<String> nearbyLocations = [];

    for (final entry in _locationCoordinates.entries) {
      final distance = calculateDistance(center, entry.value);
      if (distance <= radiusKm) {
        nearbyLocations.add(entry.key);
      }
    }

    return nearbyLocations;
  }

  /// Get OpenStreetMap tile URL template
  static String getOpenStreetMapTileUrl() {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Get user agent for OpenStreetMap requests
  static String getUserAgent() {
    return 'WeCare Bohol App v1.0';
  }

  /// Validate if coordinates are within Bohol bounds (approximate)
  static bool isWithinBohol(LatLng coordinates) {
    // Approximate bounds of Bohol province
    const double northBound = 10.5;
    const double southBound = 9.2;
    const double eastBound = 124.8;
    const double westBound = 123.5;

    return coordinates.latitude >= southBound &&
        coordinates.latitude <= northBound &&
        coordinates.longitude >= westBound &&
        coordinates.longitude <= eastBound;
  }
}
