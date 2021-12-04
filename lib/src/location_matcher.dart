import 'country_coder.dart';
import 'location_set.dart';
import 'which_polygon.dart';

/// A callable class to match a location against a [LocationSet].
/// Pass a feature collection to the constructor to use additional
/// features. These features need to have `id` properties ending with
/// ".geojson".
///
/// You need to initialize the [CountryCoder] before using this class
/// with a `CountryCoder.instance.load()` or `loadAsync()`.
class LocationMatcher {
  late final WhichPolygon additionalPolygons;
  final countryCoder = CountryCoder.instance;

  LocationMatcher([Map<String, dynamic>? featureCollection]) {
    if (featureCollection != null) {
      final features =
          featureCollection['features'] as List<Map<String, dynamic>>;
      additionalPolygons = WhichPolygon(features);
    } else {
      additionalPolygons = WhichPolygon([]);
    }
  }

  /// Instantiates the class using an object from [serialize].
  factory LocationMatcher.fromSerialized(dynamic data) =>
      LocationMatcher()..additionalPolygons = WhichPolygon.fromSerialized(data);

  /// Returns a serializable object that can be passed between threads.
  dynamic serialize() => additionalPolygons.serialize();

  /// Tests whether a location ([lon], [lat]) matches the [locationSet] rules.
  /// First checks for `exclude` rules, so excluding a country but including
  /// a city in it won't work. Empty rules satisfy any location.
  bool call(double lon, double lat, LocationSet locationSet) {
    if (locationSet.isEmpty) return true;

    bool anyIncludes = false;

    // First check circular areas, since it's the fastest.
    if (locationSet.excludeCircular.any((area) => area.contains(lon, lat)))
      return false;

    anyIncludes |=
        locationSet.includeCircular.any((area) => area.contains(lon, lat));

    // Now check additional polygons.
    final List<String> includeGeojson = locationSet.include
        .where((element) => element.endsWith('.geojson'))
        .toList();
    final List<String> excludeGeojson = locationSet.exclude
        .where((element) => element.endsWith('.geojson'))
        .toList();

    if (includeGeojson.isNotEmpty || excludeGeojson.isNotEmpty) {
      final List<String> geojsonIds = additionalPolygons
          .all(lon, lat)
          .map((e) => e['id'] as String)
          .toList();

      if (excludeGeojson.any((id) => geojsonIds.contains(id))) return false;
      anyIncludes |= includeGeojson.any((id) => geojsonIds.contains(id));
    }

    // And finally employ CountryCoder for the remaining ids.
    if (locationSet.exclude.where((element) => !element.endsWith('.geojson'))
        .any((id) => countryCoder.isIn(lon: lon, lat: lat, inside: id)))
      return false;

    anyIncludes |=
        locationSet.include.where((element) => !element.endsWith('.geojson'))
            .any((id) => countryCoder.isIn(lon: lon, lat: lat, inside: id));

    return anyIncludes;
  }
}
