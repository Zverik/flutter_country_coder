import 'data/borders.dart';
import 'region_feature.dart';
import 'region_features.dart';

import 'dart:convert';

/// An offline geocoder for countries and other big territories.
///
/// See also [LocationMatcher] for matching a location against multiple
/// regions, and [WhichPolygon] for a general point-in-polygon index.
class CountryCoder {
  RegionFeatureCollection? _borders;

  /// Returns a singleton instance of [CountryCoder].
  /// Note that you must initialize it using either [load]
  /// or [loadAsync] before using.
  /// Check for [ready] property to know when it's loaded.
  static final CountryCoder instance = CountryCoder._();

  // Prevent instantiating this class.
  CountryCoder._() {}

  /// Synchronously loads the border data and builds trees
  /// out of it. This can take up to a second, so in applications
  /// try calling [prepareData] in an non-UI thread first.
  CountryCoder load([List<dynamic>? prepared]) {
    if (!ready) {
      if (prepared != null) {
        _borders = RegionFeatureCollection.fromSerialized(prepared);
      } else {
        final data = JsonDecoder().convert(bordersRaw);
        _borders = RegionFeatureCollection(data);
      }
    }
    return this;
  }

  /// Loads the border data separately and returns it in a serialized form.
  /// Call this from inside the `compute()` function to process data
  /// in a background thread, and then pass the result to [load]. Like this:
  ///
  /// ```dart
  /// import 'package:flutter/foundation.dart' show compute;
  ///
  /// // ...
  /// CountryCoder.instance.load(await compute(CountryCoder.prepareData, null));
  /// ```
  static List<dynamic> prepareData(_) {
    final data = JsonDecoder().convert(bordersRaw);
    return RegionFeatureCollection(data).serialize();
  }

  /// Returns `true` when the data can be used.
  bool get ready => _borders != null;

  /// Throws an exception in case the data hasn't been loaded.
  _checkReady() {
    if (_borders == null)
      throw StateError(
          'Please call load() and wait until ready == true before using CountryCoder.');
  }

  /// Returns the smallest region enclosing a ([lon], [lat]) location,
  /// or a region that matches the query string / number.
  RegionFeature? smallestOrMatchingRegion(
      {double? lon, double? lat, dynamic query}) {
    _checkReady();
    if (lat != null && lon != null) {
      return _borders!.smallestRegion(lon, lat);
    } else if (query != null) {
      return _borders!.regionForID(query);
    } else {
      throw ArgumentError('Please specify either location or query.');
    }
  }

  /// Returns the region matching the given query string / number,
  /// or the one containing the ([lon], [lat]) location and
  /// matching the [level], [maxLevel], and [withProp] filters.
  /// Default [level] is _country_.
  RegionFeature? region(
      {double? lon,
      double? lat,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel,
      RegionProperties? withProp}) {
    _checkReady();
    if (lat != null && lon != null) {
      return _borders!.regionForLoc(lon, lat,
          level: level, maxLevel: maxLevel, withProp: withProp);
    } else if (query != null) {
      return _borders!.regionForID(query);
    } else {
      throw ArgumentError('Please specify either location or query.');
    }
  }

  /// Returns a list of regions that either contain the given ([lon], [lat])
  /// location, or intersect with a given [bbox] (which is `minLon`, `minLat`,
  /// `maxLon`, `maxLat`), or contain the region matching the [query]
  /// string / number. The result includes the entire region hierarchy, including
  /// the `001` region for the entire world.
  List<RegionFeature> regionsContaining(
      {double? lon,
      double? lat,
      List<double>? bbox,
      dynamic query,
      bool strict = false}) {
    _checkReady();
    return _borders!.regionsContaining(
        lon: lon, lat: lat, bbox: bbox, query: query, strict: strict);
  }

  /// Returns the ISO 3166-1 alpha-2 code for the region matching the arguments, if any.
  String? iso1A2Code(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.iso1A2,
    )?.iso1A2;
  }

  /// Returns the ISO 3166-1 alpha-3 code for the region matching the arguments, if any.
  String? iso1A3Code(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.iso1A3,
    )?.iso1A3;
  }

  /// Returns the ISO 3166-1 numeric-3 code for the region matching the arguments, if any.
  String? iso1N3Code(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.iso1N3,
    )?.iso1N3;
  }

  /// Returns the UN M49 code for the region matching the arguments, if any.
  String? m49Code(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.m49,
    )?.m49;
  }

  /// Returns the Wikidata QID code for the region matching the arguments, if any.
  String? wikidataQID(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.wikidata,
    )?.wikidata;
  }

  /// Returns the emoji flag sequence for the region matching the arguments, if any.
  String? emojiFlag(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.emojiFlag,
    )?.emojiFlag;
  }

  /// Returns the ccTLD (country code top-level domain) for the region
  /// matching the arguments, if any.
  String? ccTLD(
      {double? lat,
      double? lon,
      dynamic query,
      RegionLevel? level,
      RegionLevel? maxLevel}) {
    return region(
      lat: lat,
      lon: lon,
      query: query,
      level: level,
      maxLevel: maxLevel,
      withProp: RegionProperties.ccTLD,
    )?.ccTLD;
  }

  List<String> _propertiesForQuery(double? lon, double? lat, List<double>? bbox,
      String? Function(RegionFeature r) property) {
    return regionsContaining(lon: lon, lat: lat, bbox: bbox, strict: false)
        .map(property)
        .whereType<String>()
        .toList();
  }

  /// Returns all the ISO 3166-1 alpha-2 codes of regions at the location.
  List<String> iso1A2Codes(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.iso1A2);
  }

  /// Returns all the ISO 3166-1 alpha-3 codes of regions at the location.
  List<String> iso1A3Codes(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.iso1A3);
  }

  /// Returns all the ISO 3166-1 numeric-3 codes of regions at the location.
  List<String> iso1N3Codes(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.iso1N3);
  }

  /// Returns all the UN M49 codes of regions at the location.
  List<String> m49Codes(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.m49);
  }

  /// Returns all the Wikidata QIDs of regions at the location.
  List<String> wikidataQIDs(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.wikidata);
  }

  /// Returns all the emoji flag sequences of regions at the location.
  List<String> emojiFlags(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.emojiFlag);
  }

  /// Returns all the ccTLD (country code top-level domain) sequences
  /// of regions at the location.
  List<String> ccTLDs(double? lon, double? lat, List<double>? bbox) {
    return _propertiesForQuery(lon, lat, bbox, (r) => r.ccTLD);
  }

  /// Returns the region matching [id] and all regions it contains, if any.
  /// If passing `true` for [strict], an exact match will not be included.
  List<RegionFeature> regionsIn(dynamic id, [bool strict = false]) {
    _checkReady();
    return _borders!.regionsIn(id, strict);
  }

  // Returns true if the feature matching [query] is, or is a part of,
  // the feature matching [bounds].
  bool isIn({double? lon, double? lat, dynamic query, dynamic inside}) {
    final queried = smallestOrMatchingRegion(lon: lon, lat: lat, query: query);
    final boundsRegion = region(query: inside);

    if (queried == null) return false; // Outside any of the regions.
    if (boundsRegion == null)
      throw StateError('Could not find bounds by query $inside');

    if (queried.id == boundsRegion.id) return true;
    return queried.groups.contains(boundsRegion.id);
  }

  /// Returns true if the region matching [query] is within EU jurisdiction.
  bool isInEuropeanUnion({double? lon, double? lat, dynamic query}) {
    return isIn(lon: lon, lat: lat, query: query, inside: 'EU');
  }

  /// Returns true if the region matching [query] is, or is within,
  /// a United Nations member state.
  bool isInUnitedNations({double? lon, double? lat, dynamic query}) {
    return isIn(lon: lon, lat: lat, query: query, inside: 'UN');
  }

  /// Returns the side traffic drives on in the region matching [query].
  RegionDrivingSide? drivingSide({double? lon, double? lat, dynamic query}) {
    final region = smallestOrMatchingRegion(lon: lon, lat: lat, query: query);
    return region?.driveSide;
  }

  /// Returns the road speed unit for the region matching [query].
  RegionSpeedUnit? roadSpeedUnit({double? lon, double? lat, dynamic query}) {
    final region = smallestOrMatchingRegion(lon: lon, lat: lat, query: query);
    return region?.roadSpeedUnit;
  }

  /// Returns the road vehicle height restriction unit for the region matching [query].
  RegionHeightUnit? roadHeightUnit({double? lon, double? lat, dynamic query}) {
    final region = smallestOrMatchingRegion(lon: lon, lat: lat, query: query);
    return region?.roadHeightUnit;
  }

  /// Returns the full international calling codes for phone numbers in
  /// the region matching [query], if any.
  List<String> callingCodes({double? lon, double? lat, dynamic query}) {
    final region = smallestOrMatchingRegion(lon: lon, lat: lat, query: query);
    return region?.callingCodes ?? [];
  }
}
