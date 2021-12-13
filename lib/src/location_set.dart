import 'dart:math' as math;

/// An object to define regions where something should or should not
/// be included. Regions are referenced by any of the following:
///
/// - Strings recognized by the [CountryCoder] class. These include ISO-3166-1
///     codes, UN M.49 numeric codes, and some Wikidata QIDs. See
///     [ideditor.codes](https://ideditor.codes) for a full list.
/// - Filenames for custom geojson features. Pass them to [LocationMatcher]
///     class if you need as a GeoJSON object. Each feature should have an `id`
///     that ends in `.geojson`. For example, `new-jersey.geojson`.
/// - Circular areas defined with [LocationSetRadius] objects.
///
/// See [location-conflation](https://github.com/ideditor/location-conflation)
/// for some information, although there can be differences due to
/// different implementation in this library.
class LocationSet {
  final List<String> include;
  final List<String> exclude;
  final List<LocationSetRadius> includeCircular;
  final List<LocationSetRadius> excludeCircular;

  const LocationSet({
    this.include = const [],
    this.exclude = const [],
    this.includeCircular = const [],
    this.excludeCircular = const [],
  });

  bool get isEmpty =>
      include.isEmpty &&
      exclude.isEmpty &&
      includeCircular.isEmpty &&
      excludeCircular.isEmpty;

  LocationSet.fromJson(Map<String, dynamic> data)
      : include = data['include'] == null
            ? []
            : (data['include'] as List).whereType<String>().toList(),
        exclude = data['exclude'] == null
            ? []
            : (data['exclude'] as List).whereType<String>().toList(),
        includeCircular = data['include'] == null
            ? []
            : (data['include'] as List)
                .whereType<List>()
                .map((e) => LocationSetRadius.fromJson(e))
                .toList(),
        excludeCircular = data['exclude'] == null
            ? []
            : (data['exclude'] as List)
                .whereType<List>()
                .map((e) => LocationSetRadius.fromJson(e))
                .toList();

  Map<String, List<dynamic>> toJson() {
    Map<String, List<dynamic>> result = {};

    if (include.isNotEmpty) result['include'] = include;

    if (includeCircular.isNotEmpty) {
      result['include'] = (result['include'] ?? []) +
          includeCircular.map((e) => e.toJson()).toList();
    }

    if (exclude.isNotEmpty) result['exclude'] = exclude;

    if (excludeCircular.isNotEmpty) {
      result['exclude'] = (result['exclude'] ?? []) +
          excludeCircular.map((e) => e.toJson()).toList();
    }

    return result;
  }
}

/// Use this class to include or exclude circular areas with a given
/// center and given radius. The latter is defined in kilometers.
/// If not specified, radius defaults to 25 km.
class LocationSetRadius {
  final double longitude;
  final double latitude;
  final double radius;

  static const kDefaultRadius = 25.0;

  const LocationSetRadius(this.longitude, this.latitude,
      [this.radius = kDefaultRadius]);

  LocationSetRadius.fromJson(List<dynamic> data)
      : longitude = data[0].toDouble(),
        latitude = data[1].toDouble(),
        radius = data.length > 2 ? data[2].toDouble() : kDefaultRadius;

  List<double> toJson() =>
      [longitude, latitude, if (radius != kDefaultRadius) radius];

  /// Returns `true` if the given location is inside the area.
  /// Calculates the distance using the Haversine algorithm.
  /// Accuracy can be out by 0.3%.
  bool contains(double lon, double lat) {
    final f1 = _degToRadian(latitude);
    final f2 = _degToRadian(lat);

    final sinDLat = math.sin((f2 - f1) / 2);
    final sinDLng = math.sin((_degToRadian(longitude) - _degToRadian(lon)) / 2);

    // Sides
    final a =
        sinDLat * sinDLat + sinDLng * sinDLng * math.cos(f1) * math.cos(f2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadius * c < radius;
  }

  static double _degToRadian(final double deg) => deg * (math.pi / 180.0);

  /// Equator radius in km (WGS84 ellipsoid)
  static const double _earthRadius = 6378.137;
}
