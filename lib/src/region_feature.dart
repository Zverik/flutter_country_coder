
enum RegionLevel {
  /// Sark, Ascension Island, Diego Garcia, etc.
  subterritory,

  /// Puerto Rico, Gurnsey, Hong Kong, etc.
  territory,
  subcountryGroup,

  /// Ethiopia, Brazil, United States, etc.
  country,

  /// Great Britain, Macaronesia, Mariana Islands, etc.
  sharedLandform,

  /// Eastern Africa, South America, Channel Islands, etc.
  intermediateRegion,

  /// Sub-Saharan Africa, North America, Micronesia, etc.
  subregion,

  /// Africa, Americas, Antarctica, Asia, Europe, Oceania
  region,

  /// Outermost Regions of the EU, Overseas Countries and Territories of the EU
  subunion,

  /// European Union
  europeanUnion,

  /// United Nations
  unitedNations,

  /// all features
  world,
}

enum RegionIsoStatus {
  official,
  excReserved,
  userAssigned,
}

enum RegionDrivingSide {
  right,
  left,
}

enum RegionSpeedUnit {
  /// miles per hour
  mph,

  /// kilometers per hour
  kmh,
}

enum RegionHeightUnit {
  /// feet and inches
  feet,

  /// meters
  meters,
}

enum RegionProperties {
  iso1A2,
  iso1A3,
  iso1N3,
  m49,
  wikidata,
  emojiFlag,
  ccTLD,
  nameEn,
  aliases,
  country,
  groups,
  members,
  level,
  isoStatus,
  driveSide,
  roadSpeedUnit,
  roadHeightUnit,
  callingCodes,
}

class RegionFeature {
/// Unique identifier specific to country-coder
  final String id;

  /// ISO 3166-1 alpha-2 code
  final String? iso1A2;

  /// ISO 3166-1 alpha-3 code
  final String? iso1A3;

  /// ISO 3166-1 numeric-3 code
  final String? iso1N3;

  /// UN M49 code
  String? m49;

  /// Wikidata QID
  final String wikidata;

  /// The emoji flag sequence derived from this feature's ISO 3166-1 alpha-2 code
  String? emojiFlag;

  /// The ccTLD (country code top-level domain)
  String? ccTLD;

  /// The common English name
  final String nameEn;

  /// Additional identifiers which can be used to look up this feature;
  /// these cannot collide with the identifiers for any other feature
  late final List<String> aliases;

  /// For features entirely within a country, the ISO 3166-1 alpha-2 code for that country
  final String? country;

  /// The ISO 3166-1 alpha-2, M49, or QIDs of other features this feature is entirely within, including its country
  late final List<String> groups;

  /// The ISO 3166-1 alpha-2, M49, or QIDs of other features this feature contains;
  /// the inverse of [groups]
  late final List<String> members;

  /// The rough geographic type of this feature.
  /// Levels do not necessarily nest cleanly within each other.
  late final RegionLevel level;

  /// The status of this feature's ISO 3166-1 code(s), if any
  RegionIsoStatus? isoStatus;

  /// The side of the road that traffic drives on within this feature
  RegionDrivingSide? driveSide;

  /// The unit used for road traffic speeds within this feature
  RegionSpeedUnit? roadSpeedUnit;

  /// The unit used for road vehicle height restrictions within this feature
  RegionHeightUnit? roadHeightUnit;

  /// The international calling codes for this feature, sometimes including area codes
  /// e.g. `1`, `1 340`
  late List<String> callingCodes;

  /// Whether this region has geometry.
  final bool hasGeometry;

  RegionFeature({
    String? id,
    this.iso1A2,
    this.iso1A3,
    this.iso1N3,
    this.m49,
    required this.wikidata,
    this.emojiFlag,
    this.ccTLD,
    required this.nameEn,
    List<String>? aliases,
    this.country,
    List<String>? groups,
    List<String>? members,
    RegionLevel? level,
    this.isoStatus,
    this.driveSide,
    this.roadSpeedUnit,
    this.roadHeightUnit,
    List<String>? callingCodes,
    this.hasGeometry = true,
  }) : id = id ?? iso1A2 ?? m49 ?? wikidata {
    this.aliases = aliases ?? [];
    this.groups = groups ?? [];
    this.members = members ?? [];
    this.callingCodes = callingCodes ?? [];

    if (m49 == null && iso1N3 != null) {
      // M49 is a superset of ISO numerics so we only need to store one
      m49 = iso1N3;
    }

    if (level != RegionLevel.unitedNations) {
      if (ccTLD == null && iso1A2 != null) {
        // ccTLD is nearly the same as iso1A2, so we only need to explicitly code any exceptions
        ccTLD = '.${iso1A2!.toLowerCase()}';
      }
    }

    if (level == null) {
      if (country == null) {
        level = RegionLevel.country;
      } else if (iso1A2 == null || isoStatus == RegionIsoStatus.official) {
        level = RegionLevel.territory;
      } else {
        level = RegionLevel.subterritory;
      }
    }
    this.level = level;

    if (country != null && hasGeometry) {
      this.groups.add(country!);
    }
    if (m49 != '001') {
      this.groups.add('001');
    }

    if (iso1A2 != null) {
      // Calculates the emoji flag sequence from the alpha-2 code (if any) and caches it
      emojiFlag = String.fromCharCodes(iso1A2!.codeUnits.map((e) => e + 127397));
    }
  }

  factory RegionFeature.fromJson(Map<String, dynamic> data, [bool hasGeometry = true]) {
    return RegionFeature(
      id: data['id'],
      iso1A2: data['iso1A2'],
      iso1A3: data['iso1A3'],
      iso1N3: data['iso1N3'],
      m49: data['m49'],
      wikidata: data['wikidata'],
      emojiFlag: data['emojiFlag'],
      ccTLD: data['ccTLD'],
      nameEn: data['nameEn'],
      aliases: data['aliases']?.whereType<String>().toList(),
      country: data['country'],
      groups: data['groups']?.whereType<String>().toList(),
      members: data['members']?.whereType<String>().toList(),
      level: _levelFromString(data['level']),
      isoStatus: _isoStatusFromString(data['isoStatus']),
      driveSide: _driveSideFromString(data['driveSide']),
      roadSpeedUnit: _speedUnitFromString(data['roadSpeedUnit']),
      roadHeightUnit: _heightUnitFromString(data['roadHeightUnit']),
      callingCodes: data['callingCodes']?.whereType<String>().toList(),
      hasGeometry: hasGeometry,
    );
  }

  static RegionLevel? _levelFromString(String? level) {
    if (level == null) return null;
    switch (level) {
      case 'world':
        return RegionLevel.world;
      case 'unitedNations':
        return RegionLevel.unitedNations;
      case 'union':
        return RegionLevel.europeanUnion;
      case 'subunion':
        return RegionLevel.subunion;
      case 'region':
        return RegionLevel.region;
      case 'subregion':
        return RegionLevel.subregion;
      case 'intermediateRegion':
        return RegionLevel.intermediateRegion;
      case 'sharedLandform':
        return RegionLevel.sharedLandform;
      case 'country':
        return RegionLevel.country;
      case 'subcountryGroup':
        return RegionLevel.subcountryGroup;
      case 'territory':
        return RegionLevel.territory;
      case 'subterritory':
        return RegionLevel.subterritory;
      default:
        throw ArgumentError('Unknown level: $level');
    }
  }

  static RegionIsoStatus? _isoStatusFromString(String? status) {
    switch (status) {
      case 'official':
        return RegionIsoStatus.official;
      case 'excRes':
        return RegionIsoStatus.excReserved;
      case 'usrAssn':
        return RegionIsoStatus.userAssigned;
      default:
        return null;
    }
  }

  static RegionDrivingSide? _driveSideFromString(String? side) {
    switch (side) {
      case 'left':
        return RegionDrivingSide.left;
      case 'right':
        return RegionDrivingSide.right;
      default:
        return null;
    }
  }

  static RegionSpeedUnit? _speedUnitFromString(String? unit) {
    switch (unit) {
      case 'mph':
        return RegionSpeedUnit.mph;
      case 'km/h':
        return RegionSpeedUnit.kmh;
      default:
        return null;
    }
  }

  static RegionHeightUnit? _heightUnitFromString(String? unit) {
    switch (unit) {
      case 'ft':
        return RegionHeightUnit.feet;
      case 'm':
        return RegionHeightUnit.meters;
      default:
        return null;
    }
  }

  List<String> getFeatureIDs() {
    final List<String> ids = [];
    if (iso1A2 != null) ids.add(iso1A2!);
    if (iso1A3 != null) ids.add(iso1A3!);
    if (m49 != null) ids.add(m49!);
    ids.add(wikidata);
    if (emojiFlag != null) ids.add(emojiFlag!);
    if (ccTLD != null) ids.add(ccTLD!);
    ids.add(nameEn);
    ids.addAll(aliases);
    return ids;
  }

  bool hasProperty(RegionProperties? prop) {
    if (prop == null) return true;
    switch (prop) {
      case RegionProperties.iso1A2:
        return iso1A2 != null;
      case RegionProperties.iso1A3:
        return iso1A3 != null;
      case RegionProperties.iso1N3:
        return iso1N3 != null;
      case RegionProperties.m49:
        return m49 != null;
      case RegionProperties.wikidata:
        return true;
      case RegionProperties.emojiFlag:
        return emojiFlag != null;
      case RegionProperties.ccTLD:
        return ccTLD != null;
      case RegionProperties.nameEn:
        return true;
      case RegionProperties.aliases:
        return aliases.isNotEmpty;
      case RegionProperties.country:
        return country != null;
      case RegionProperties.groups:
        return groups.isNotEmpty;
      case RegionProperties.members:
        return members.isNotEmpty;
      case RegionProperties.level:
        return true;
      case RegionProperties.isoStatus:
        return isoStatus != null;
      case RegionProperties.driveSide:
        return driveSide != null;
      case RegionProperties.roadSpeedUnit:
        return roadSpeedUnit != null;
      case RegionProperties.roadHeightUnit:
        return roadHeightUnit != null;
      case RegionProperties.callingCodes:
        return callingCodes.isNotEmpty;
    }
  }
}
