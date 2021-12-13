import 'region_feature.dart';
import 'which_polygon.dart';

class RegionFeatureCollection {
  late final List<RegionFeature> regions;
  final Map<String, RegionFeature> regionsByCode = {};
  late final WhichPolygon<RegionFeature> whichPolygon;

  RegionFeatureCollection(Map<String, dynamic> featureCollection) {
    regions = [];
    final geometries = <Map<String, dynamic>>[];

    for (final feature in featureCollection['features']) {
      final geometry = feature['geometry'];
      final region =
          RegionFeature.fromJson(feature['properties'], geometry != null);
      regions.add(region);
      if (geometry != null) {
        geometries.add({
          'geometry': geometry,
          'properties': region,
        });
      }
    }

    _postProcessRegions();

    whichPolygon = WhichPolygon<RegionFeature>(geometries);
  }

  /// Restores inner structures from the serialized data.
  RegionFeatureCollection.fromSerialized(List<dynamic> data) {
    regions = data[0];
    for (final region in regions) _cacheFeatureByIDs(region);
    whichPolygon = WhichPolygon.fromSerialized(data[1]);
  }

  List<dynamic> serialize() {
    return [regions, whichPolygon.serialize()];
  }

  /// Returns the smallest feature of any kind containing the point, if any.
  RegionFeature? smallestRegion(double lon, double lat) {
    final region = whichPolygon(lon, lat);
    return region == null ? null : regionsByCode[region.id];
  }

  /// Returns the country feature containing `loc`, if any.
  RegionFeature? countryRegion(double lon, double lat) {
    final region = smallestRegion(lon, lat);
    if (region == null) return null;
    // a feature without `country` but with geometry is itself a country
    final countryCode = region.country ?? region.iso1A2;
    return regionsByCode[countryCode];
  }

  /// Returns the feature containing `loc` for the `opts`, if any.
  RegionFeature? regionForLoc(double lon, double lat,
      {RegionLevel? level, RegionLevel? maxLevel, RegionProperties? withProp}) {
    final targetLevel = level ?? RegionLevel.country;
    maxLevel ??= RegionLevel.world;

    if (maxLevel.index < targetLevel.index) return null;

    if (targetLevel == RegionLevel.country) {
      // attempt fast path for country-level coding
      final fastRegion = countryRegion(lon, lat);
      if (fastRegion != null && fastRegion.hasProperty(withProp)) {
        return fastRegion;
      }
    }

    final regions = regionsContaining(lon: lon, lat: lat);

    for (final region in regions) {
      if (region.level == targetLevel ||
          (region.level.index > targetLevel.index &&
              region.level.index <= maxLevel.index)) {
        if (region.hasProperty(withProp)) return region;
      }
    }
    return null;
  }

  RegionFeature? regionForID(dynamic id) {
    if (id == null) return null;
    String sid;
    if (id is int) {
      sid = id.toString().padLeft(3, '0');
    } else {
      sid = _canonicalID(id.toString());
    }
    return regionsByCode[sid];
  }

  List<RegionFeature> smallestRegionsForBBox(
      double minLon, double minLat, double maxLon, double maxLat) {
    return whichPolygon
        .bbox(minLon, minLat, maxLon, maxLat)
        .map((e) => regionsByCode[e.id]!)
        .toList();
  }

  List<RegionFeature> regionsContaining(
      {double? lon,
      double? lat,
      List<double>? bbox,
      dynamic query,
      bool strict = false}) {
    List<RegionFeature> matching;
    if (bbox != null) {
      assert(bbox.length == 4);
      matching = smallestRegionsForBBox(bbox[0], bbox[1], bbox[2], bbox[3]);
    } else if (lon != null && lat != null) {
      final region = smallestRegion(lon, lat);
      matching = region == null ? [] : [region];
    } else if (query != null) {
      final region = regionForID(query);
      matching = region == null ? [] : [region];
    } else {
      throw ArgumentError('Please specify either location, bbox or query.');
    }

    if (matching.isEmpty) return matching;

    List<RegionFeature> result;

    if (!strict || lat != null) {
      result = List.of(matching);
    } else {
      result = [];
    }

    for (final region in matching) {
      for (final groupId in region.groups) {
        final groupFeature = regionsByCode[groupId]!;
        if (!result.contains(groupFeature)) {
          result.add(groupFeature);
        }
      }
    }

    return result;
  }

  /// Returns the region matching [id] and all regions it contains, if any.
  /// If passing `true` for [strict], an exact match will not be included.
  List<RegionFeature> regionsIn(dynamic id, [bool strict = false]) {
    final region = regionForID(id);
    if (region == null) return [];

    final List<RegionFeature> result = [];

    if (!strict) result.add(region);

    for (final memberId in region.members) {
      result.add(regionsByCode[memberId]!);
    }

    return result;
  }

  _postProcessRegions() {
    for (final r in regions) {
      _cacheFeatureByIDs(r);
    }

    // Must load `members` only after fully loading `featuresByID`
    for (final r in regions) {
      // ensure all groups are listed by their ID
      for (int i = 0; i < r.groups.length; i++) {
        r.groups[i] = regionsByCode[r.groups[i]]!.id;
      }
    }
    // Populate `members` as the inverse relationship of `groups`
    for (final r in regions) {
      for (final g in r.groups) {
        final groupFeature = regionsByCode[g]!;
        groupFeature.members.add(r.id);
      }
    }

    // Must load attributes only after loading geometry features into `members`
    for (final r in regions) {
      _loadSpeedUnit(r);
      _loadHeightUnit(r);
      _loadDrivingSide(r);
      _loadCallingCodes(r);
      _loadGroupGroups(r);
    }

    for (final r in regions) {
      r.groups.sort((id1, id2) {
        return regionsByCode[id1]!
            .level
            .index
            .compareTo(regionsByCode[id2]!.level.index);
      });
      if (r.members.isNotEmpty) {
        r.members.sort((id1, id2) {
          int res = regionsByCode[id1]!
              .level
              .index
              .compareTo(regionsByCode[id2]!.level.index);
          if (res == 0) {
            res = regions
                .indexOf(regionsByCode[id1]!)
                .compareTo(regions.indexOf(regionsByCode[id2]!));
          }
          return res;
        });
      }
    }
  }

  /// Caches features by their identifying strings for rapid lookup
  _cacheFeatureByIDs(RegionFeature region) {
    for (final id in region.getFeatureIDs()) {
      regionsByCode[_canonicalID(id)] = region;
    }
  }

  static final _kIdFilterRegex = RegExp(
    r"(?=(?!^(and|the|of|el|la|de)$))(\b(and|the|of|el|la|de)\b)|[-_ .,'()&[\]/]",
    caseSensitive: false,
  );

  String _canonicalID(String id) {
    return id.isEmpty || id[0] == '.'
        ? id.toUpperCase()
        : id.replaceAll(_kIdFilterRegex, '').toUpperCase();
  }

  _loadGroupGroups(RegionFeature region) {
    if (region.hasGeometry || region.members.isEmpty) return;
    final int levelIndex = region.level.index;
    List<String> sharedGroups = [];
    for (final memberId in region.members) {
      final member = regionsByCode[memberId]!;
      final memberGroups = member.groups.where((groupId) {
        return groupId != region.id &&
            levelIndex < regionsByCode[groupId]!.level.index;
      }).toList();
      if (memberId == region.members.first) {
        sharedGroups = memberGroups;
      } else {
        sharedGroups.retainWhere((groupId) => memberGroups.contains(groupId));
      }
    }

    region.groups.addAll(
        sharedGroups.where((groupId) => !region.groups.contains(groupId)));

    for (final groupId in sharedGroups) {
      final groupFeature = regionsByCode[groupId]!;
      if (!groupFeature.members.contains(region.id))
        groupFeature.members.add(region.id);
    }
  }

  _loadSpeedUnit(RegionFeature region) {
    if (region.hasGeometry) {
      // only `mph` regions are listed explicitly, else assume `km/h`
      if (region.roadSpeedUnit == null)
        region.roadSpeedUnit = RegionSpeedUnit.kmh;
    } else {
      final values = Set.of(region.members.map((id) {
        final member = regionsByCode[id]!;
        if (member.hasGeometry)
          return member.roadSpeedUnit ?? RegionSpeedUnit.kmh;
      }).whereType<RegionSpeedUnit>());

      // if all members have the same value then that's also the value for this feature
      if (values.length == 1) region.roadSpeedUnit = values.first;
    }
  }

  _loadHeightUnit(RegionFeature region) {
    if (region.hasGeometry) {
      // only `ft` regions are listed explicitly, else assume `m`
      if (region.roadHeightUnit == null)
        region.roadHeightUnit = RegionHeightUnit.meters;
    } else {
      final values = Set.of(region.members.map((id) {
        final member = regionsByCode[id]!;
        if (member.hasGeometry)
          return member.roadHeightUnit ?? RegionHeightUnit.meters;
      }).whereType<RegionHeightUnit>());

      // if all members have the same value then that's also the value for this feature
      if (values.length == 1) region.roadHeightUnit = values.first;
    }
  }

  _loadDrivingSide(RegionFeature region) {
    if (region.hasGeometry) {
      // only `left` regions are listed explicitly, else assume `right`
      if (region.driveSide == null) region.driveSide = RegionDrivingSide.right;
    } else {
      final values = Set.of(region.members.map((id) {
        final member = regionsByCode[id]!;
        if (member.hasGeometry)
          return member.driveSide ?? RegionDrivingSide.right;
      }).whereType<RegionDrivingSide>());

      // if all members have the same value then that's also the value for this feature
      if (values.length == 1) region.driveSide = values.first;
    }
  }

  _loadCallingCodes(RegionFeature region) {
    if (!region.hasGeometry && region.members.isNotEmpty) {
      region.callingCodes =
          Set.of(region.members.fold<List<String>>([], (array, id) {
        final member = regionsByCode[id]!;
        if (member.hasGeometry && member.callingCodes.isNotEmpty) {
          return array + member.callingCodes;
        }
        return array;
      })).toList();
    }
  }
}
