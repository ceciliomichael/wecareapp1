/// Bohol Province Locations
/// Contains all municipalities and the city in Bohol, Philippines
class BoholLocations {
  /// Main city in Bohol (provincial capital)
  static const String tagbilaranCity = 'Tagbilaran City';

  /// All municipalities in Bohol (alphabetically ordered)
  static const List<String> municipalities = [
    'Alburquerque',
    'Alicia',
    'Anda',
    'Antequera',
    'Baclayon',
    'Balilihan',
    'Batuan',
    'Bien Unido',
    'Bilar',
    'Buenavista',
    'Calape',
    'Candijay',
    'Carmen',
    'Catigbian',
    'Clarin',
    'Corella',
    'Cortes',
    'Dagohoy',
    'Danao',
    'Dauis',
    'Dimiao',
    'Duero',
    'Garcia Hernandez',
    'Getafe',
    'Guindulman',
    'Inabanga',
    'Jagna',
    'Lila',
    'Loay',
    'Loboc',
    'Loon',
    'Mabini',
    'Maribojoc',
    'Panglao',
    'Pilar',
    'President Carlos P. Garcia',
    'Sagbayan',
    'San Isidro',
    'San Miguel',
    'Sevilla',
    'Sierra Bullones',
    'Sikatuna',
    'Talibon',
    'Trinidad',
    'Tubigon',
    'Ubay',
    'Valencia',
  ];

  /// Complete list of all locations (city + municipalities)
  static List<String> get allLocations {
    return [tagbilaranCity, ...municipalities]..sort();
  }

  /// Popular/Major locations for quick selection
  static const List<String> popularLocations = [
    'Tagbilaran City',
    'Panglao',
    'Tubigon',
    'Jagna',
    'Talibon',
    'Ubay',
    'Loon',
    'Carmen',
    'Dauis',
    'Baclayon',
  ];

  /// Tourist destination municipalities
  static const List<String> touristDestinations = [
    'Panglao',
    'Loboc',
    'Carmen', // Chocolate Hills
    'Loon',
    'Baclayon',
    'Corella',
    'Alburquerque',
    'Antequera',
  ];

  /// Coastal municipalities (for maritime-related jobs)
  static const List<String> coastalAreas = [
    'Tagbilaran City',
    'Panglao',
    'Dauis',
    'Baclayon',
    'Loon',
    'Maribojoc',
    'Tubigon',
    'Getafe',
    'Talibon',
    'Bien Unido',
    'Trinidad',
    'Ubay',
    'President Carlos P. Garcia',
    'Candijay',
    'Anda',
    'Guindulman',
    'Jagna',
  ];

  /// Check if a location is valid in Bohol
  static bool isValidLocation(String location) {
    return allLocations.contains(location);
  }

  /// Get location type (City or Municipality)
  static String getLocationType(String location) {
    if (location == tagbilaranCity) {
      return 'City';
    } else if (municipalities.contains(location)) {
      return 'Municipality';
    } else {
      return 'Unknown';
    }
  }

  /// Search locations by query
  static List<String> searchLocations(String query) {
    if (query.isEmpty) return allLocations;

    final lowercaseQuery = query.toLowerCase();
    return allLocations
        .where((location) => location.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
