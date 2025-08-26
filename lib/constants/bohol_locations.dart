/// Tagbilaran City Locations
/// Contains barangays in Tagbilaran City, Bohol, Philippines
class BoholLocations {
  /// Main city in Bohol (provincial capital)
  static const String tagbilaranCity = 'Tagbilaran City';

  /// All barangays in Tagbilaran City (alphabetically ordered)
  static const List<String> barangays = [
    'Bool',
    'Booy',
    'Cabawan',
    'Cogon',
    'Dampas',
    'Dao',
    'Manga',
    'Mansasa',
    'Poblacion I',
    'Poblacion II',
    'Poblacion III',
    'San Isidro',
    'Taloto',
    'Tiptip',
    'Ubujan',
  ];

  /// Complete list of all locations (barangays in Tagbilaran City)
  static List<String> get allLocations {
    return barangays.toList()..sort();
  }

  /// Popular/Central barangays for quick selection
  static const List<String> popularLocations = [
    'Poblacion I',
    'Poblacion II',
    'Poblacion III',
    'Cogon',
    'Mansasa',
    'Dao',
    'Bool',
    'Booy',
  ];

  /// Business district barangays
  static const List<String> businessDistrict = [
    'Poblacion I',
    'Poblacion II',
    'Poblacion III',
    'Cogon',
    'Dao',
  ];

  /// Residential barangays
  static const List<String> residentialAreas = [
    'Mansasa',
    'Bool',
    'Booy',
    'Cabawan',
    'Dampas',
    'Manga',
    'San Isidro',
    'Taloto',
    'Tiptip',
    'Ubujan',
  ];

  /// Check if a barangay is valid in Tagbilaran City
  static bool isValidLocation(String barangay) {
    return barangays.contains(barangay);
  }

  /// Get location type (always Barangay for this implementation)
  static String getLocationType(String location) {
    if (barangays.contains(location)) {
      return 'Barangay';
    } else {
      return 'Unknown';
    }
  }

  /// Get full address format
  static String getFullAddress(String barangay) {
    if (isValidLocation(barangay)) {
      return 'Barangay $barangay, $tagbilaranCity, Bohol';
    }
    return barangay;
  }

  /// Search barangays by query
  static List<String> searchLocations(String query) {
    if (query.isEmpty) return allLocations;

    final lowercaseQuery = query.toLowerCase();
    return allLocations
        .where((barangay) => barangay.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Check if barangay is in business district
  static bool isBusinessDistrict(String barangay) {
    return businessDistrict.contains(barangay);
  }

  /// Check if barangay is primarily residential
  static bool isResidentialArea(String barangay) {
    return residentialAreas.contains(barangay);
  }
}
