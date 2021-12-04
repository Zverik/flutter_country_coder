/// A single ([lon], [lat]) point. It is used for storage
/// and function arguments only, so it doesn't have any
/// utility methods.
class Point {
  final double lat;
  final double lon;

  const Point(this.lon, this.lat);

  factory Point.fromJson(List<dynamic> coords) =>
      Point(coords[0].toDouble(), coords[1].toDouble());

  @override
  bool operator ==(Object other) {
    return other is Point && other.lat == lat && other.lon == lon;
  }

  @override
  int get hashCode => lat.hashCode + lon.hashCode;

  @override
  String toString() => '{$lon, $lat}';
}

/// A rectangular bounding box. Used for storage and for function
/// arguments.
class BBox {
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const BBox(this.minLon, this.minLat, this.maxLon, this.maxLat);

  Point get center => Point((minLon + maxLon) / 2.0, (minLat + maxLat) / 2.0);

  @override
  String toString() => '{$minLon, $minLat, $maxLon, $maxLat}';
}
